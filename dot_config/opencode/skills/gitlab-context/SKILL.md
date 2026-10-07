---
name: gitlab-context
description: Load live GitLab context (issue, MR, epic, pipeline) and use it for the user's task.
disable-model-invocation: true
---

# GitLab context

Load the GitLab context that the user's task needs, then do the task with it.
Each claim about GitLab state comes from a live call in this session.

## Steps

1. **Find the targets** from URLs or references (`group/project#123`, `!123`, `&123`) in the
   user's message or earlier in the conversation. If there is no target, ask for one.
2. **Read each target and its discussion** with the GitLab MCP server through `execute`
   (`get_work_item`, `get_merge_request`, `get_pipeline`). Check the `include` facets in the
   tool schema, and get notes or discussions in the same call.
3. **Follow one hop** when the task needs it: parent, children, linked issues, related MRs,
   and the latest pipeline. If the user asks for the full tree, repeat on each child until
   no children remain.
4. **Add code relationships** when the task touches code. Run Orbit `get_graph_schema`
   first, then `query_graph`.
5. **Do the task.** Base each statement and each change on what you read. Name each item
   you could not read, if it affects the result.

If the message has no task, give a three-sentence summary and wait for the user's question.

Use `glab api` only for data that no MCP tool returns, such as CI/CD variables or `ci/lint`.
