---
description: TDD navigator. File edits ask, git commit, git push, and MR creation are denied.
mode: primary
permissions:
  - action: edit
    resource: "*"
    effect: ask
  - action: shell
    resource: "git commit *"
    effect: deny
  - action: shell
    resource: "git push *"
    effect: deny
  - action: shell
    resource: "git -C * commit *"
    effect: deny
  - action: shell
    resource: "git -C * push *"
    effect: deny
  - action: shell
    resource: "glab mr create *"
    effect: deny
---
