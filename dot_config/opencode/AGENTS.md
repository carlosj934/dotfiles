# Global OpenCode Instructions

<!-- Memory MCP disabled; restore these sections when it is enabled again.

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

-->

## Writing style: ASD-STE100

Write all prose in ASD-STE100 Simplified Technical English: terminal responses,
docs, commit messages, MR and issue text, comments, and docstrings.

- Procedural sentences: 20 words maximum. Descriptive sentences: 25 words maximum.
- One instruction or one topic in each sentence.
- Active voice, simple tenses, imperative for instructions.
- One word for one meaning, used the same each time.
- Simple verbs in place of phrasal verbs and idioms.

Keep code, commands, paths, identifiers, quotes, error output, and product names verbatim.

Before you send text, check each sentence against the word limits.

## Code comments

Write a comment only for a *why* that the code cannot show, such as a workaround,
a hidden constraint, or an external issue link. Each comment is one sentence.
Docstrings follow the same rule, unless the repo's linter requires more.
Leave existing comments as they are, outside the code you change.

## Code search: tilth

For code search, file reads, file lists, and diffs in a repository, use the tilth MCP server
through `execute` (`tools.tilth.*`) before the built-in tools:

- `tilth_search` for grep, `tilth_read` for read, `tilth_list` for glob, `tilth_diff` for git diff.

For text outside the repository, such as job logs or command output, use the shell.
If tilth is not available or returns an error, use the built-in tools.

## GitLab

Read GitLab state (repo files, issues, MRs, pipelines) live in this session before you build on it;
earlier turns and memory are stale.

For the target project, use the project from a URL or `group/project#123` reference first.
If there is none, use the current repo's `git remote`. If the project is not clear, ask before you create.

