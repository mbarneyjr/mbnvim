#!/usr/bin/env node

const {
  getLanguageService: getAslJsonLanguageService,
  getYamlLanguageService: getAslYamlLanguageService,
  ClientCapabilities,
} = require("amazon-states-language-service");
const {
  createConnection,
  DocumentRangeFormattingRequest,
  LSPErrorCodes,
  NotificationType,
  RequestType,
  ResponseError,
  TextDocuments,
  TextDocumentSyncKind,
} = require("vscode-languageserver/node");
const { TextDocument } = require("vscode-languageserver-textdocument");
const { posix } = require("path");
const URL = require("url");

const JSON_ASL = "asl";
const YAML_ASL = "asl-yaml";

const ResultLimitReached = new NotificationType("asl/resultLimitReached");
const ForceValidateRequest = new RequestType("asl/validate");

function formatError(message, err) {
  if (err instanceof Error) {
    return `${message}: ${err.message}\n${err.stack}`;
  } else if (typeof err === "string") {
    return `${message}: ${err}`;
  } else if (err) {
    return `${message}: ${err.toString()}`;
  }
  return message;
}

function cancelValue() {
  return new ResponseError(LSPErrorCodes.RequestCancelled, "Request cancelled");
}

function runSafeAsync(func, errorVal, errorMessage, token) {
  return new Promise((resolve) => {
    setImmediate(() => {
      if (token.isCancellationRequested) {
        resolve(cancelValue());
      }
      return func().then(
        (result) => {
          if (token.isCancellationRequested) {
            resolve(cancelValue());
          } else {
            resolve(result);
          }
        },
        (e) => {
          console.error(formatError(errorMessage, e));
          resolve(errorVal);
        },
      );
    });
  });
}

function runSafe(func, errorVal, errorMessage, token) {
  return new Promise((resolve) => {
    setImmediate(() => {
      if (token.isCancellationRequested) {
        resolve(cancelValue());
      } else {
        try {
          const result = func();
          if (token.isCancellationRequested) {
            resolve(cancelValue());
          } else {
            resolve(result);
          }
        } catch (e) {
          console.error(formatError(errorMessage, e));
          resolve(errorVal);
        }
      }
    });
  });
}

function getLanguageModelCache(maxEntries, cleanupIntervalTimeInSec, parse) {
  let languageModels = {};
  let nModels = 0;

  let cleanupInterval;
  if (cleanupIntervalTimeInSec > 0) {
    cleanupInterval = setInterval(() => {
      const cutoffTime = Date.now() - cleanupIntervalTimeInSec * 1000;
      for (const uri of Object.keys(languageModels)) {
        if (languageModels[uri].cTime < cutoffTime) {
          delete languageModels[uri];
          nModels--;
        }
      }
    }, cleanupIntervalTimeInSec * 1000);
  }

  return {
    get(document) {
      const version = document.version;
      const languageId = document.languageId;
      const info = languageModels[document.uri];
      if (info && info.version === version && info.languageId === languageId) {
        info.cTime = Date.now();
        return info.languageModel;
      }
      const languageModel = parse(document);
      languageModels[document.uri] = {
        languageModel,
        version,
        languageId,
        cTime: Date.now(),
      };
      if (!info) {
        nModels++;
      }
      if (nModels === maxEntries) {
        let oldestTime = Number.MAX_VALUE;
        let oldestUri;
        for (const uri of Object.keys(languageModels)) {
          if (languageModels[uri].cTime < oldestTime) {
            oldestUri = uri;
            oldestTime = languageModels[uri].cTime;
          }
        }
        if (oldestUri) {
          delete languageModels[oldestUri];
          nModels--;
        }
      }
      return languageModel;
    },
    onDocumentRemoved(document) {
      if (languageModels[document.uri]) {
        delete languageModels[document.uri];
        nModels--;
      }
    },
    dispose() {
      if (typeof cleanupInterval !== "undefined") {
        clearInterval(cleanupInterval);
        cleanupInterval = undefined;
        languageModels = {};
        nModels = 0;
      }
    },
  };
}

const connection = createConnection();

process.on("unhandledRejection", (e) => {
  console.error(formatError("Unhandled exception", e));
});
process.on("uncaughtException", (e) => {
  console.error(formatError("Unhandled exception", e));
});

console.log = connection.console.log.bind(connection.console);
console.error = connection.console.error.bind(connection.console);

const workspaceContext = {
  resolveRelativePath: (relativePath, resource) => {
    return URL.resolve(resource, relativePath);
  },
};

let aslJsonLanguageService = getAslJsonLanguageService({
  workspaceContext,
  contributions: [],
  clientCapabilities: ClientCapabilities.LATEST,
});
let aslYamlLanguageService = getAslYamlLanguageService({
  workspaceContext,
  contributions: [],
  clientCapabilities: ClientCapabilities.LATEST,
});

const documents = new TextDocuments(TextDocument);
documents.listen(connection);

let clientSnippetSupport = false;
let dynamicFormatterRegistration = false;
let hierarchicalDocumentSymbolSupport = false;

let foldingRangeLimitDefault = Number.MAX_VALUE;
let foldingRangeLimit = Number.MAX_VALUE;
let resultLimit = Number.MAX_VALUE;

connection.onInitialize((params) => {
  aslJsonLanguageService = getAslJsonLanguageService({
    workspaceContext,
    contributions: [],
    clientCapabilities: params.capabilities,
  });
  aslYamlLanguageService = getAslYamlLanguageService({
    workspaceContext,
    contributions: [],
    clientCapabilities: params.capabilities,
  });

  function getClientCapability(name, def) {
    const keys = name.split(".");
    let c = params.capabilities;
    for (let i = 0; c && i < keys.length; i++) {
      if (!Object.hasOwn(c, keys[i])) {
        return def;
      }
      c = c[keys[i]];
    }
    return c;
  }

  // upstream reads params.initializationOptions unguarded; guard because
  // clients other than the toolkit's may omit it entirely
  const provideFormatter = params.initializationOptions?.provideFormatter;

  clientSnippetSupport = getClientCapability(
    "textDocument.completion.completionItem.snippetSupport",
    false,
  );
  dynamicFormatterRegistration =
    getClientCapability(
      "textDocument.rangeFormatting.dynamicRegistration",
      false,
    ) && typeof provideFormatter !== "boolean";
  foldingRangeLimitDefault = getClientCapability(
    "textDocument.foldingRange.rangeLimit",
    Number.MAX_VALUE,
  );
  hierarchicalDocumentSymbolSupport = getClientCapability(
    "textDocument.documentSymbol.hierarchicalDocumentSymbolSupport",
    false,
  );

  return {
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Incremental,
      completionProvider: clientSnippetSupport
        ? { resolveProvider: true, triggerCharacters: ['"'] }
        : undefined,
      hoverProvider: true,
      documentSymbolProvider: true,
      documentRangeFormattingProvider: provideFormatter === true,
      colorProvider: {},
      foldingRangeProvider: true,
      selectionRangeProvider: true,
    },
  };
});

class LimitExceededWarnings {
  static pendingWarnings = {};

  static cancel(uri) {
    const warning = LimitExceededWarnings.pendingWarnings[uri];
    if (warning && warning.timeout) {
      clearTimeout(warning.timeout);
      delete LimitExceededWarnings.pendingWarnings[uri];
    }
  }

  static onResultLimitExceeded(uri, maxResults, name) {
    return () => {
      let warning = LimitExceededWarnings.pendingWarnings[uri];
      if (warning) {
        if (!warning.timeout) {
          // already shown
          return;
        }
        warning.features[name] = name;
        warning.timeout.refresh();
      } else {
        warning = { features: { [name]: name } };
        warning.timeout = setTimeout(() => {
          void connection.sendNotification(
            ResultLimitReached,
            `${posix.basename(uri)}: For performance reasons, ${Object.keys(
              warning.features,
            ).join(" and ")} have been limited to ${maxResults} items.`,
          );
          warning.timeout = undefined;
        }, 2000);
        LimitExceededWarnings.pendingWarnings[uri] = warning;
      }
    };
  }
}

let formatterRegistration;

connection.onDidChangeConfiguration((change) => {
  const settings = change.settings;
  // upstream only reads aws.stepfunctions.asl; also accept a bare asl section
  const aslSettings = settings?.aws?.stepfunctions?.asl ?? settings?.asl;

  foldingRangeLimit = Math.trunc(
    Math.max(aslSettings?.resultLimit || foldingRangeLimitDefault, 0),
  );
  resultLimit = Math.trunc(
    Math.max(aslSettings?.resultLimit || Number.MAX_VALUE, 0),
  );

  // dynamically enable & disable the formatter
  if (dynamicFormatterRegistration) {
    const enableFormatter = aslSettings?.format?.enable;
    if (enableFormatter) {
      if (!formatterRegistration) {
        formatterRegistration = connection.client.register(
          DocumentRangeFormattingRequest.type,
          {
            documentSelector: [{ language: JSON_ASL }, { language: YAML_ASL }],
          },
        );
      }
    } else if (formatterRegistration) {
      formatterRegistration.then(
        (r) => r.dispose(),
        (e) => {
          console.error("formatterRegistration failed: %s", e.message);
        },
      );
      formatterRegistration = undefined;
    }
  }
});

// Retry schema validation on all open documents
connection.onRequest(ForceValidateRequest, async (uri) => {
  return new Promise((resolve) => {
    const document = documents.get(uri);
    if (document) {
      validateTextDocument(document, (diagnostics) => {
        resolve(diagnostics);
      });
    } else {
      resolve([]);
    }
  });
});

documents.onDidChangeContent((change) => {
  LimitExceededWarnings.cancel(change.document.uri);
  triggerValidation(change.document);
});

// a document has closed: clear all diagnostics
documents.onDidClose((event) => {
  LimitExceededWarnings.cancel(event.document.uri);
  cleanPendingValidation(event.document);
  void connection.sendDiagnostics({ uri: event.document.uri, diagnostics: [] });
});

const pendingValidationRequests = {};
const validationDelayMs = 500;

function cleanPendingValidation(textDocument) {
  const request = pendingValidationRequests[textDocument.uri];
  if (request) {
    clearTimeout(request);
    delete pendingValidationRequests[textDocument.uri];
  }
}

function triggerValidation(textDocument) {
  cleanPendingValidation(textDocument);
  pendingValidationRequests[textDocument.uri] = setTimeout(() => {
    delete pendingValidationRequests[textDocument.uri];
    validateTextDocument(textDocument);
  }, validationDelayMs);
}

// sets language service depending on document language
function getLanguageService(langId) {
  if (langId === YAML_ASL) {
    return aslYamlLanguageService;
  } else {
    return aslJsonLanguageService;
  }
}

function validateTextDocument(textDocument, callback) {
  const respond = (diagnostics) => {
    void connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
    if (callback) {
      callback(diagnostics);
    }
  };
  if (textDocument.getText().length === 0) {
    respond([]);
    return;
  }
  const jsonDocument = getJSONDocument(textDocument);
  const version = textDocument.version;

  const documentSettings = { comments: "error", trailingCommas: "error" };
  getLanguageService(textDocument.languageId)
    .doValidation(textDocument, jsonDocument, documentSettings)
    .then(
      (diagnostics) => {
        setTimeout(() => {
          const currDocument = documents.get(textDocument.uri);
          if (currDocument && currDocument.version === version) {
            respond(diagnostics); // Send the computed diagnostics to the client.
          }
        }, 100);
      },
      (error) => {
        connection.console.error(
          formatError(`Error while validating ${textDocument.uri}`, error),
        );
      },
    );
}

connection.onDidChangeWatchedFiles((change) => {
  // Monitored files have changed
  let hasChanges = false;
  for (const c of change.changes) {
    if (getLanguageService("asl").resetSchema(c.uri)) {
      hasChanges = true;
    }
  }
  if (hasChanges) {
    documents.all().forEach(triggerValidation);
  }
});

const jsonDocuments = getLanguageModelCache(10, 60, (document) =>
  getLanguageService("asl").parseJSONDocument(document),
);
documents.onDidClose((e) => {
  jsonDocuments.onDocumentRemoved(e.document);
});
connection.onShutdown(() => {
  jsonDocuments.dispose();
});

function getJSONDocument(document) {
  return jsonDocuments.get(document);
}

connection.onCompletion((textDocumentPosition, token) => {
  return runSafeAsync(
    async () => {
      const document = documents.get(textDocumentPosition.textDocument.uri);
      if (document) {
        const jsonDocument = getJSONDocument(document);
        return await getLanguageService(document.languageId).doComplete(
          document,
          textDocumentPosition.position,
          jsonDocument,
        );
      }
      return undefined;
    },
    undefined,
    `Error while computing completions for ${textDocumentPosition.textDocument.uri}`,
    token,
  );
});

connection.onCompletionResolve((completionItem, token) => {
  return runSafeAsync(
    () => {
      // the asl-yaml-languageservice uses doResolve from the asl service
      return getLanguageService("asl").doResolve(completionItem);
    },
    completionItem,
    "Error while resolving completion proposal",
    token,
  );
});

connection.onHover((textDocumentPositionParams, token) => {
  return runSafeAsync(
    async () => {
      const document = documents.get(
        textDocumentPositionParams.textDocument.uri,
      );
      if (document) {
        const jsonDocument = getJSONDocument(document);
        return getLanguageService(document.languageId).doHover(
          document,
          textDocumentPositionParams.position,
          jsonDocument,
        );
      }
      return undefined;
    },
    undefined,
    `Error while computing hover for ${textDocumentPositionParams.textDocument.uri}`,
    token,
  );
});

connection.onDocumentSymbol((documentSymbolParams, token) => {
  return runSafe(
    () => {
      const document = documents.get(documentSymbolParams.textDocument.uri);
      if (document) {
        const jsonDocument = getJSONDocument(document);
        const onResultLimitExceeded =
          LimitExceededWarnings.onResultLimitExceeded(
            document.uri,
            resultLimit,
            "document symbols",
          );
        if (hierarchicalDocumentSymbolSupport) {
          return getLanguageService(document.languageId).findDocumentSymbols2(
            document,
            jsonDocument,
            {
              resultLimit,
              onResultLimitExceeded,
            },
          );
        } else {
          return getLanguageService(document.languageId).findDocumentSymbols(
            document,
            jsonDocument,
            {
              resultLimit,
              onResultLimitExceeded,
            },
          );
        }
      }
      return [];
    },
    [],
    `Error while computing document symbols for ${documentSymbolParams.textDocument.uri}`,
    token,
  );
});

connection.onDocumentRangeFormatting((formatParams, token) => {
  return runSafe(
    () => {
      const document = documents.get(formatParams.textDocument.uri);
      if (document) {
        return getLanguageService(document.languageId).format(
          document,
          formatParams.range,
          formatParams.options,
        );
      }
      return [];
    },
    [],
    `Error while formatting range for ${formatParams.textDocument.uri}`,
    token,
  );
});

connection.onDocumentColor((params, token) => {
  return runSafeAsync(
    async () => {
      const document = documents.get(params.textDocument.uri);
      if (document) {
        const onResultLimitExceeded =
          LimitExceededWarnings.onResultLimitExceeded(
            document.uri,
            resultLimit,
            "document colors",
          );
        const jsonDocument = getJSONDocument(document);
        return getLanguageService(document.languageId).findDocumentColors(
          document,
          jsonDocument,
          {
            resultLimit,
            onResultLimitExceeded,
          },
        );
      }
      return [];
    },
    [],
    `Error while computing document colors for ${params.textDocument.uri}`,
    token,
  );
});

connection.onColorPresentation((params, token) => {
  return runSafe(
    () => {
      const document = documents.get(params.textDocument.uri);
      if (document) {
        const jsonDocument = getJSONDocument(document);
        return getLanguageService(document.languageId).getColorPresentations(
          document,
          jsonDocument,
          params.color,
          params.range,
        );
      }
      return [];
    },
    [],
    `Error while computing color presentations for ${params.textDocument.uri}`,
    token,
  );
});

connection.onFoldingRanges((params, token) => {
  return runSafe(
    () => {
      const document = documents.get(params.textDocument.uri);
      if (document) {
        const onRangeLimitExceeded =
          LimitExceededWarnings.onResultLimitExceeded(
            document.uri,
            foldingRangeLimit,
            "folding ranges",
          );
        return getLanguageService(document.languageId).getFoldingRanges(
          document,
          {
            rangeLimit: foldingRangeLimit,
            onRangeLimitExceeded,
          },
        );
      }
      return undefined;
    },
    undefined,
    `Error while computing folding ranges for ${params.textDocument.uri}`,
    token,
  );
});

connection.onSelectionRanges((params, token) => {
  return runSafe(
    () => {
      const document = documents.get(params.textDocument.uri);
      if (document) {
        const jsonDocument = getJSONDocument(document);
        return getLanguageService(document.languageId).getSelectionRanges(
          document,
          params.positions,
          jsonDocument,
        );
      }
      return [];
    },
    [],
    `Error while computing selection ranges for ${params.textDocument.uri}`,
    token,
  );
});

// Listen on the connection
connection.listen();
