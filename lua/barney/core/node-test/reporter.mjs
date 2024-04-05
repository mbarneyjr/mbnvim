/**
 * @param {import("node:test/reporters").TestEvent[]} source
 */
export default async function* customReporter(source) {
  for await (const event of source) {
    switch (event.type) {
      case "test:dequeue":
        break;
      case "test:enqueue":
        break;
      case "test:start":
        break;
      case "test:pass":
        break;
      case "test:fail": {
        if (event.data.details.type === "suite") break;
        const filePath = decodeURI(event.data.file?.replace("file://", "") ?? "");
        let error = `${event.data.details.error.message}`;
        yield `${filePath}:${event.data.line}:${event.data.column} ${error}\n`;
        break;
      }
      case "test:watch:drained":
        break;
      case "test:plan":
        break;
      case "test:diagnostic":
        break;
      case "test:stderr":
        break;
      case "test:stdout":
        break;
      default:
        break;
    }
  }
}
