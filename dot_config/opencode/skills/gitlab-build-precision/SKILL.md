---
name: gitlab-build-precision
description: >-
  Use this whenever building, modifying, or debugging something that touches
  GitLab — code, CI/CD config, a repo's structure, an issue, MR, pipeline, or
  work item — or that needs architecture/relationship context (callers,
  dependencies, blast radius). The point is precision, not citation: the
  current state of a repo, issue, MR, or pipeline must come from a live,
  source-of-record tool call, never from memory or a stale doc. Trigger this
  even when the user doesn't say "check" or "verify" — if you're about to
  assume the state of something on GitLab.com to justify a code change, this
  is the skill that stops you and routes you to the right tool first. Prefers
  the GitLab MCP server for repo/issue/MR/pipeline reads and writes, because
  its typed responses remove any guessing about output shape, falling back to
  the glab CLI when MCP has no tool for the job, when the work is text
  manipulation like grepping file contents or job traces, or when MCP is
  unavailable. Also routes to Orbit (code structure and relationships) and
  the public web.
---

# GitLab Build Precision

## Response style: ASD-STE100 Simplified Technical English (STE)

Write all responses under this skill in ASD-STE100 Simplified Technical
English. Follow these rules for every response, including explanations,
plans, and summaries:

1. Write short sentences. Do not write more than 20 words in one sentence.
2. Write one fact or one instruction in each sentence.
3. Use the active voice. Do not use the passive voice. Example: write "Run
   the pipeline" and not "The pipeline should be run."
4. Use simple, common words. Do not use rare words or jargon. If you must
   use a technical term (e.g. "pipeline", "merge request"), use it the same
   way each time.
5. Use "must" for a rule. Use "can" to show that an action is possible. Do
   not use "may" to give permission.
6. Do not put more than three nouns together in a row.
7. Use lists and tables to show steps or facts. Do not write long
   paragraphs.
8. Use the present tense where you can. Do not use complex verb tenses.
9. Write direct sentences. Do not use idioms or metaphors.
10. Keep each paragraph short. Put only one main idea in a paragraph.

This style rule changes how you write. It does not change what you check or
build. Still check live GitLab state before you act, per the rules below.

The point of this skill is that assumptions about GitLab's current state must
be *checked*, not merely plausible. Repo contents, issue/MR state, pipeline
status, and CI config drift constantly — including your own memory of a
conversation from ten minutes ago. A change built on a stale assumption is
worse than a slower one built on a checked fact. So: check the live source
before acting on it, especially before writing.

Unlike a research-and-cite workflow, there's no requirement to quote exact
passages or produce a Source: line — this is about which tool to reach for and
trusting only the source of record, not about producing a citable answer.

## Core rules

1. **Check before acting on an assumption.** Never build a change, a comment,
   or a next step on top of an assumed repo/issue/MR/pipeline state — even
   when confident. Confidence is not verification.
2. **Don't guess GitLab MCP or Orbit's own behavior.** Don't assume a tool's
   inputs, outputs, or side effects from memory of a similar-sounding API.
   Check `get_mcp_server_version` / `list_commands` / the tool's own schema
   when unsure, rather than guessing and finding out from a failed call or,
   worse, an unintended write.
3. **Correctness over agreement.** If the live state contradicts the premise
   of what you're being asked to build, say so plainly before proceeding.
   Don't build on top of a false premise just because it was in the request.
4. **If it can't be verified, say so and stop before writing.** Do not fill
   the gap with a plausible-sounding implementation detail. Ask, or fall back
   to a narrower action you can verify.
5. **Writes still need normal judgment.** This skill is about precision, not
   about blocking writes — creating issues, updating MRs, commenting, and
   triggering pipelines are all in scope while building. Apply your usual
   judgment about confirming destructive or hard-to-reverse actions; this
   skill just makes sure the write is based on checked state, not a guess.

## Tool routing

Pick by *where the answer actually lives*. Using the wrong tool produces a
confidently wrong basis for the change you're about to make — assuming a
config file's contents instead of just reading it, when the file is right
there in the repo, is the classic version of this.

| Question is about | Use |
|---|---|
| A specific repo, file, issue, MR, work item, pipeline, release, branch, or project member — current state, before you build on it | **GitLab MCP first**, falling back to the **`glab` CLI** |
| Callers, imports, dependencies, blast radius, cross-project/cross-entity joins, repo maps — before changing something with unclear reach | **Orbit** (`list_commands` → `invoke_command`) |
| Public product documentation, tiers, supported versions, deprecations | **web_fetch on docs.gitlab.com**, found via `web_search` |
| Anything external: standards, third-party tools, library/framework behavior | **web_search** + `web_fetch` |

Combine freely. A "wire up CI to do X" task usually needs the current pipeline
config (GitLab MCP / `glab`) *plus* whatever relationship context Orbit can
surface about what else touches it.

### GitLab MCP (default)

- Default to the MCP tools for reads and routine writes: `get_project`,
  `get_repository_file`, `get_merge_request`, `get_work_item`, `get_pipeline`,
  `get_job`, the `list_*` family, and the `save_*` tools for writes. Responses
  are typed JSON, so you never have to guess at output shape the way you do
  with human-formatted CLI text.
- Read files with `get_repository_file` at an explicit ref; read
  issues/MRs/work items with the corresponding get/list tools before assuming
  their state.
- Use `search` / `semantic_search` when the project is unknown; use direct
  gets when it's known. These have no real `glab` equivalent.
- Prefer one call with the right `include` facet over several narrow calls —
  `get_merge_request` with `include: ["diffs"]` beats chaining separate reads.
- Writes (create/update/comment/merge/pipeline actions) are expected as part
  of building — just base them on a state you actually checked this session,
  not on an earlier turn's assumption that might now be stale.

### glab CLI (fallback)

Reach for `glab` via bash when MCP can't do the job — not by default:

- **No MCP tool covers it.** `glab api <endpoint>` reaches any REST endpoint
  the MCP server doesn't expose: bridge jobs of a parent pipeline, `ci/lint`,
  CI/CD variables, job artifacts, container registry tags, protected branches.
- **The work is text manipulation.** Grepping file contents, stripping ANSI
  escapes from a job trace with `sed`, unzipping artifacts, pulling one line
  out of a large response. MCP hands back whole objects; a shell pipeline
  hands back the five bytes you actually wanted.
- **It's a git or local operation** — `glab repo clone`, `glab mr checkout`.
- **MCP errors out or is unavailable.** Don't retry blindly; switch and say
  that you fell back.

Guardrails when you do use it:

- Never assume `glab`'s flags or output shape from memory — run `glab <cmd>
  --help` if unsure, the same way you wouldn't guess an MCP tool's schema.
- Always filter the output. A bare `glab api projects/<id>` returns ~6KB of
  JSON; pipe it through `grep` or `python3 -c` and keep only what you need.
- Batch related calls into one bash block, but keep the block short. Each
  `glab` invocation costs ~0.65s of process startup, so a six-call chain
  becomes a four-second tool call.

### Orbit

- Call `list_commands` first to get input schemas — don't guess the DSL.
- Reach for this before a change with unclear blast radius: renaming a
  function, changing a shared module, touching something with unknown
  callers. For a single known MR, project, or user, or a simple count,
  ordinary GitLab MCP tools are enough.

### Web

- Prefer `docs.gitlab.com` and `handbook.gitlab.com` over blogs and
  aggregators for anything GitLab-specific.
- For library/framework/SDK/CLI questions, prefer the project's official
  documentation site over blogs and aggregators.
- `web_search` results are snippets — `web_fetch` the page before treating it
  as ground truth for a design decision.

## Workflow

1. **Decompose.** Split the task into the individual factual assumptions it
   rests on. "Add a stage to this pipeline that only runs on protected
   branches" rests on assumptions about the current pipeline config and the
   protected-branch rules — both checkable, neither to be assumed.
2. **Route** each assumption to the right tool from the table above.
3. **Check** with short, targeted queries/reads — prefer several narrow
   checks over one broad guess.
4. **Flag conflicts.** If checked sources disagree (e.g. an old MR
   description says one thing, the actual current pipeline config does
   another), surface both and say which one you're building against and
   why — don't silently pick one.
5. **Build**, based on what you checked, not what you assumed going in. For Go
   code, favor a test-driven approach: write (or update) a failing test that
   captures the checked expected behavior before writing the implementation,
   then implement to make it pass.
6. **If something couldn't be verified**, say so explicitly before writing
   anything that depends on it, and propose the narrowest safe next step
   (e.g. "confirm this MR isn't already open before I create a new one").
