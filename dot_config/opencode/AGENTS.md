# Global OpenCode Instructions

## Session Context

Session context (boot gates, blockers, reminders) is **automatically injected** at the start of each session and after compaction. You do not need to call any tools to load it.

Boot gates (⛔) in the session context are **standing instructions** - follow them when the relevant situation arises.

**If you do not see boot context** (no boot gates, no blockers section, no reminders) in the system prompt after this AGENTS.md section, call `memory_get_boot_context()` to load it manually. This is a fallback for when automatic injection fails.

## Memory Usage

Throughout the session:
- Before working on an MR/issue/epic, call `memory_get_context(entity_ref)` to get history
- Use `memory_claim_item()` before making changes to prevent conflicts
- Store important decisions, blockers, and procedures with `memory_remember()`
- Release claimed items when done with `memory_release_item()`
- Use `memory_recall(query)` to search for relevant context

## Session Tracking

When ending a session or summarizing work done, include the session ID (shown in the session context footer) to enable continuation tracking across sessions.

Full memory system documentation: `opencode-memory/BOOTSTRAP.md`

