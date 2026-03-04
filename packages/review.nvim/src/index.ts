import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { createHash } from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, dirname } from "node:path";

function getDiagnosticsFilePath(): string {
  const cwd = process.cwd();
  const hash = createHash("sha256").update(cwd).digest("hex").slice(0, 16);
  return join(homedir(), ".cache", "review.nvim", hash, "diagnostics.json");
}

async function writeDiagnostics(diagnostics: unknown[]): Promise<string> {
  const filePath = getDiagnosticsFilePath();
  await mkdir(dirname(filePath), { recursive: true });
  await writeFile(filePath, JSON.stringify(diagnostics, null, 2));
  return filePath;
}

const server = new McpServer({
  name: "review.nvim",
  version: "1.0.0",
});

server.registerTool(
  "publish_diagnostics",
  {
    description:
      "Publish code review diagnostics to the editor. " +
      "Each diagnostic must include an absolute filePath, 1-indexed line number, " +
      "severity (error/warning/info/hint), and a message describing the finding.",
    inputSchema: {
      diagnostics: z
        .array(
          z.object({
            filePath: z.string().describe("Absolute path to the file"),
            line: z.number().describe("1-indexed line number"),
            severity: z
              .enum(["error", "warning", "info", "hint"])
              .describe("Diagnostic severity level"),
            message: z.string().describe("The review finding message"),
          })
        )
        .describe("List of diagnostic findings to publish"),
    },
  },
  async ({ diagnostics }) => {
    const filePath = await writeDiagnostics(diagnostics);
    return {
      content: [
        {
          type: "text" as const,
          text: `Published ${diagnostics.length} diagnostic(s) to ${filePath}`,
        },
      ],
    };
  }
);

server.registerTool(
  "clear_diagnostics",
  {
    description: "Clear all code review diagnostics from the editor.",
    inputSchema: {},
  },
  async () => {
    const filePath = await writeDiagnostics([]);
    return {
      content: [
        {
          type: "text" as const,
          text: `Cleared all review diagnostics (${filePath})`,
        },
      ],
    };
  }
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("review.nvim MCP server started");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
