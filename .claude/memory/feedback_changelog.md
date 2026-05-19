---
name: Changelog style preferences
description: How the user wants CHANGELOG.md structured and written in this project — elaborate, not concise
type: feedback
originSessionId: 34017a39-96f4-4c97-8d5c-dad201c05c98
---
User wants CHANGELOG.md to be **elaborate and explanatory**, not concise. Each entry should explain:
- What changed (the fact)
- Why it was done (the motivation or problem being solved)
- What benefit it brings (the outcome for the user or project)

**Structure:**
- Newest entries first
- Daily ISO rebuilds (version bump + mirrorlist only) grouped into a single line
- Substantive changes get their own dated section with prose paragraphs and categorized sub-headers
- Bold text for package names, file names, and key terms
- Lists are fine for enumerating items, but each item should have an explanation, not just a name

**Why:** User explicitly requested "not concise" and "elaborate about the changes — explain the benefits and the why" when asking for the changelog rewrite on 2026-05-01. This overrides the original concise style set earlier.

**How to apply:** When asked to update or generate CHANGELOG.md, write full paragraphs with context and reasoning — not single-bullet summaries. Think of it as a developer-facing narrative of project evolution, not a dry diff summary. The old CLAUDE.md spec ("concise") is superseded by this preference.
