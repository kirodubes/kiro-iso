---
name: feedback-session-end-merge
description: "At session end, read key docs from kiro-iso-next and merge relevant content into the production repo"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 79366d0a-465d-4341-871b-6371474234df
---

At session end, before closing, read the following files from `~/KIRO/kiro-iso-next/`:
- `CHANGELOG.md`
- `TODO.md`
- `IDEAS.md`
- `CLAUDE.md`
- `README.md`

Then merge any relevant updates into the corresponding files in `~/KIRO/kiro-iso/` (this production repo). "Relevant" means: completed features ready to land in production, notes about the Liquorix experiment status, new ideas, updated instructions, or anything that should be reflected in the stable branch docs.

**Why:** User added this as a standing session-end step so that documentation stays in sync between the two repos without manual effort.

**How to apply:** Add this read-and-merge step to the session-end ritual, after updating CHANGELOG/TODO/IDEAS/CLAUDE.md with the current session's work, and before committing.
