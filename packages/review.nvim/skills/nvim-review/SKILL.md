---
description: Review code changes and publish findings as Neovim editor diagnostics
disable-model-invocation: true
---

Review the current git diff and publish findings as editor diagnostics using the `publish_diagnostics` MCP tool.

1. First, call `clear_diagnostics` to remove any previous review findings.
2. Review all of the git staged changes in this repository (do not report on unstaged changes).
3. Review the changes thoroughly. Focus on:
   - Bugs, logic errors, and edge cases
   - Security issues
   - Missing error handling
   - Performance concerns
   - Consistency with existing code style and patterns
4. Call the `publish_diagnostics` tool with your findings. Each diagnostic must have an absolute `filePath`, 1-indexed `line` number, `severity` (error/warning/info/hint), and a descriptive `message`.
5. Summarize what you found.

If the user provides additional instructions after invoking this command, incorporate them into your review focus (e.g., "focus on security", "only look at test files").
