#!/usr/bin/env node

import { existsSync } from "node:fs";
import { execSync, execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = dirname(fileURLToPath(import.meta.url));
const entry = join(root, "src", "index.ts");

if (!existsSync(join(root, "node_modules"))) {
  execSync("npm install --no-fund --no-audit", { cwd: root, stdio: "ignore" });
}

const [major] = process.versions.node.split(".").map(Number);
if (major >= 23) {
  execFileSync(process.execPath, [entry], { cwd: root, stdio: "inherit" });
} else {
  execFileSync("npx", ["tsx", entry], { cwd: root, stdio: "inherit" });
}
