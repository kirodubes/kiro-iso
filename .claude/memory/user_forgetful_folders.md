---
name: user-forgetful-folders
description: Erik can forget which folder (production vs beta) to build from — always confirm before a build
metadata: 
  node_type: memory
  type: user
  originSessionId: 042ff59e-c3e9-493f-97c1-1c8e034df034
---

Erik can be forgetful about which ISO folder to build from. When a build or test is about to happen, proactively confirm which repo he intends to use:

- **Production**: `~/KIRO/kiro-iso/` + `kiro-calamares-config/`
- **Beta/Testing**: `~/KIRO/kiro-iso-next/` + `kiro-calamares-config-next/`

**Why:** Erik confirmed this himself after building from `kiro-iso` (production) instead of `kiro-iso-next` (where the Liquorix kernel changes were made), then being confused why linux-lqx wasn't in the ISO.

**How to apply:** Before any build command, state which folder the build will run from and ask for confirmation if there's any ambiguity.
