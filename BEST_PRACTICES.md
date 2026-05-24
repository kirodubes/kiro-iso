# Claude Best Practices

## 2026-05-18 (session end — kiro-iso-next TODO housekeeping)

**Tip: Display any list Claude will be asked to reference by number — use sequential numbers top to bottom, across all sections**
When a list will be referenced conversationally ("3 done", "move 2 to backlog"), number every item sequentially from 1 regardless of section boundaries. Section headers reset context but not numbering. The user says "1" and means item 1 — they do not say "first item in Backlog". A numbered display costs nothing to produce and eliminates all "which one do you mean?" clarification. Apply this everywhere: TODO lists, package lists, audit findings, any multi-item display the user will act on by reference.

**Tip: Mark TODO items with explicit "Verified working" — never leave "Needs test" notes in Done**
A Done item that still says "Needs build + audio test" is not done. Before moving any item to Done, either verify it yourself or get explicit confirmation from the user. Then replace the pending-test note with "Verified working." in the item text. A Done section with lingering caveats creates false confidence and forces future sessions to re-investigate whether the item was actually closed. If the text still has a conditional, the item stays in Backlog.

## 2026-05-18 (session end — kiro-iso-next audit)

**Tip: In bash with `set -euo pipefail`, use `counter=$((counter + 1))` not `((counter++))` — the latter exits the script when the counter is zero**
`((expression))` is an arithmetic command that exits with status 1 when the expression evaluates to 0. With `set -e` active, `((counter++))` when `counter=0` exits the entire script at that line — silently, with no error message. The fix is `counter=$((counter + 1))`, which is a variable assignment and always exits 0. This pattern bites especially in audit/counter scripts where all counters start at zero. Always use the assignment form for increment-style arithmetic in `set -e` scripts.

**Tip: When capturing large SSH command output, redirect to a remote file then `cat` — don't pipe through SSH**
`ssh host "long_command"` truncates silently when output exceeds the tool's capture buffer. The fix is a two-step: `ssh host "command > /tmp/result.txt 2>&1"` (let it run to completion remotely), then `ssh host "cat /tmp/result.txt"` (fetch the finished output). This pattern also decouples the command's runtime from the SSH connection timeout — a 5-minute `pacman -Qk` scan won't drop the connection mid-run. Apply it any time a remote command produces more than ~100 lines or takes more than a few seconds.

## 2026-05-18 (session end — edu-system-files config audit)

**Tip: Before deploying any multi-block config file, grep for duplicate keys — the last value wins silently and earlier blocks become false documentation**
`grep -oP '^\w[\w\.]+' /etc/sysctl.d/file.conf | sort | uniq -d` finds duplicate sysctl keys in seconds. For journald/systemd drop-ins, check repeated option names the same way. In this session, `net.core.netdev_max_backlog` had conflicting values (4096 vs 5000) at two points in the same file, `RateLimitBurst` was set three times ending at 0 (disabling rate limiting entirely), and `Compress`/`Seal` were set and then contradicted. The earlier blocks documented an intent that the file wasn't actually implementing. Audit before shipping.

**Tip: Security hardening settings have usability costs — test them against real developer workflows before distributing**
`kernel.sysrq=0` removes the REISUB emergency reboot sequence; a hung system requires a hard power-off instead of a clean sync-and-reboot. `kernel.yama.ptrace_scope=2` breaks gdb, strace, rr, and every IDE debug adapter that attaches to a running process rather than spawning one. These settings look correct in a hardening guide but break real daily work on a developer desktop. Before shipping a hardened sysctl config to end users, validate each security knob against: can the user debug a crash? can they recover a frozen system? can containers still function?

## 2026-05-18 (session end — .claude cleanup)

**Tip: Audit `settings.json` allow list for session artifacts — one-time approvals accumulate silently**
Every time you click "Allow" on a novel Bash command, an entry lands in `settings.json`. Over weeks this fills with hardcoded line-range reads (`sed -n '55,62p' file.py`), one-time refactor commands (`sed -i 's/old/new/g' *.py`), and per-file linter invocations superseded by a hook. Periodically run `jq '.permissions.allow[]' ~/.claude/settings.json` and ask: "is this a repeating pattern or a stale artifact?" Delete the artifacts; replace repeating patterns with generic glob forms (`Bash(ruff check *)`). After several months of normal use, the list will have grown 3–4× beyond what is genuinely useful — today's cleanup went from 62 entries to 20.

**Tip: A script in `~/.claude/hooks/` does NOT auto-run — every hook needs an explicit `settings.json` entry**
Claude Code does not discover hook scripts from the `hooks/` directory. A `hooks/session-start.sh` that exists but is absent from `settings.json` under the right event key (`SessionStart`, `PostToolUse`, etc.) never fires. Verify which hooks are actually wired with `jq '.hooks' ~/.claude/settings.json`. The gap between "script file exists" and "hook actually fires" can leave automation silently doing nothing for months — confirmed today when `session-start.sh` was found unwired despite being documented as running every session.

## 2026-05-18 (session end — plymouth-theme-startrek)

**Tip: Plymouth breathing/glow animations use two layered sprites — one scaled, one at Z(-1) — driven by Math.Sin on state.time**
In Plymouth's script language, `Image.Scale(w, h)` creates a scaled copy once at startup (no per-frame cost). Place the scaled copy behind the main sprite with `SetZ(-1)` and center it by offsetting half the size delta. Then drive both sprites with `breath = (Math.Sin(state.time * 0.05) + 1) / 2` in the refresh callback: main sprite 0.8→1.0 opacity, glow sprite 0.0→0.45. `state.time` increments by 1.0 each refresh call; at Plymouth's 50 Hz rate, `* 0.05` gives a ~2.5-second breathing cycle. Adjust the multiplier to taste — 0.03 for slower, 0.08 for faster.

**Tip: Test Plymouth themes without rebooting — `plymouthd --no-daemon --debug` in one terminal, `plymouth --show-splash` in another**
Rebooting to check every Plymouth script change wastes minutes per iteration. Instead: `sudo plymouthd --no-daemon --debug` starts the daemon in the foreground (Ctrl-C to stop); then in a second terminal `sudo plymouth --show-splash` renders the theme. Script errors appear in the first terminal's output. `sudo plymouth quit` tears it down cleanly. This loop — edit script, show-splash, inspect, quit — cuts Plymouth development time dramatically.


## 2026-05-19 (session end — kiro-iso audit expansion + test box)

**Tip: Use `declare -A` associative arrays in bash audit scripts for key/expected-value checks — one loop replaces N identical if-blocks**
Instead of writing a separate `sysctl -n key` + compare block for each security parameter, declare `declare -A expected=([kernel.kptr_restrict]=2 [fs.suid_dumpable]=0 ...)` and loop: `for key in "${!expected[@]}"; do actual=$(sysctl -n "$key"); [[ "$actual" == "${expected[$key]}" ]] && pass ... || fail ...; done`. Adding a new check costs one line in the array, not 4 lines of new code. The same pattern applies to any audit script that checks multiple key/value pairs — file permissions, config values, systemd unit states.

**Tip: When a `-git` AUR package doesn't pick up your latest commit via `paru -S`, copy the binary directly for immediate testing — rebuild the package separately**
`paru -S pkg-git` reinstalls from the cached `.pkg.tar.zst` if the pkgver hasn't changed, even after a new upstream commit. For rapid iteration during a session (edit → test → edit), use `scp localfile remote:/tmp/file && ssh remote "sudo cp /tmp/file /usr/local/bin/file"` to deploy instantly, then let the package rebuild happen on its own schedule (next `paru -Syu`, or force with `paru -S --rebuild pkg-git`). Never leave the manually copied version in place permanently — it will be overwritten by the next package upgrade.

## 2026-05-19 (session end — kiro-iso security audit)

**Tip: Use `tmpfiles.d` with the `z` directive to enforce file permissions idempotently at every boot — not a one-time chmod**
`chmod` in a post-install script runs once and can be undone by package updates or upgrades. A `tmpfiles.d` entry like `z /etc/cups/classes.conf 0600 root cups - -` is applied by `systemd-tmpfiles-setup.service` at every boot, making the permission sticky. The `z` type sets ownership and mode only if the path exists — it never creates the file. Use this for any config file whose package ships it world-readable but which contains sensitive data (CUPS printer URIs, credentials, API keys). One file in `/etc/tmpfiles.d/` beats patching the package or scripting around it.

**Tip: `VBoxManage modifyvm --natpf1` only works when the VM is stopped — use `VBoxManage controlvm natpf1` for live VMs**
`VBoxManage modifyvm "Name" --natpf1 "rule,tcp,,2022,,22"` requires the VM to be in `poweroff`, `saved`, or `aborted` state — running it against a live VM returns an error. For a running VM, use `VBoxManage controlvm "Name" natpf1 "rule,tcp,,2022,,22"` (no `--` prefix, no `modifyvm`). When scripting VM setup, detect state first with `VBoxManage showvminfo --machinereadable | grep '^VMState='` and dispatch to the correct command. Also: when grepping machinereadable output for an existing NAT rule, match `"rulename,` (name + comma) not `"rulename"` — the format is `natpf1="rulename,tcp,,port,,22"` so the closing quote never follows the name directly.

## 2026-05-19 (session end — Startup-HQ)

**Tip: In setup scripts, put all interactive prompts at the very top of `main()` — before any irreversible side effects**
A user who answers "no" to the chroot prompt at step 12 has already sat through 11 steps of work that is now wasted. Move every interactive `read`-based prompt to the start of `main()`, in decision order. The script makes all decisions upfront, then executes without interruption. If a prompt is buried in a function that also does work (like `setup_archlinux_chroot`), keep the prompt logic at the top of that function and call the function first. Side effects that the user hasn't approved should never precede the approval.

**Tip: Add a `preflight_checks()` as the first call in `main()` for any setup script — validate before touching anything**
Check all hard dependencies before any side effects: required binaries present (`rsync`, `git`, `pacman`), required paths accessible, running user is not root (or is root, depending on the script). A preflight that fails prints exactly what is missing and exits 1. Without it, a missing binary causes a confusing mid-script failure after irreversible steps have already run. The function costs ten lines and prevents every "script blew up halfway through" scenario.



## 2026-05-18 (session end — alacritty-tweak-tool, second session)

**Tip: Disable Claude Code notification sounds with `"preferredNotifChannel": "notifications_disabled"` in `~/.claude/settings.json`**
Claude Code emits OS notifications (and sometimes a terminal bell) when it finishes a task or needs input. On Arch Linux with Alacritty these land as sound alerts. Setting `"preferredNotifChannel": "notifications_disabled"` in `~/.claude/settings.json` turns off the notification channel entirely — no bell, no popup. Useful in focused work environments where the sound is distracting. To re-enable later, remove the key or set it to `"auto"`.

**Tip: Design asset directories for zero-code extension — a metadata file per directory is all that's needed**
When building a feature that has many interchangeable assets (themes, plugins, presets), make the discovery mechanism filesystem-driven: scan a parent directory, read a `source.json` (or equivalent) in each subdirectory, and build the runtime list from that. Adding a new source then costs zero Python changes — drop a new directory with `source.json` and the app finds it automatically. This session: the `data/themes/kiro/` Kiro theme group was fully wired up with just two TOML files and a `source.json`, no Python edits needed.

## 2026-05-18 (session end — alacritty-tweak-tool)

**Tip: `notify::width` does NOT fire on GTK4 widgets — use a polling timer to detect VTE resize**
In GTK4, `widget.connect("notify::width", handler)` looks like it should fire when the widget allocation changes, but `width` is a computed accessor, not a real GObject notify property. The signal never arrives. For detecting VTE column count changes (e.g. to respawn fastfetch on window resize), the only reliable approach is a `GLib.timeout_add(500, poll_fn)` started on the `map` signal. Inside the poll: call `vte.get_column_count()`, compare to the last known value, and act on change. Add a two-poll stability check (`state["pending"]`) to avoid spawning during an in-progress resize.

**Tip: Strip `COLUMNS` from the environment before spawning a child process in a VTE terminal**
When the app is started from a terminal, the parent shell sets `COLUMNS` in the environment. Tools like `fastfetch` read `COLUMNS` first and use it to size their output — bypassing the PTY's `ioctl(TIOCGWINSZ)` entirely. The result: fastfetch renders at the parent shell's width, not the VTE widget's width. Fix: build `envv = [f"{k}={v}" for k, v in os.environ.items() if k != "COLUMNS"]` and pass it as the `envv` argument to `vte.spawn_async()`. With `COLUMNS` absent, the child reads the PTY dimensions correctly.

## 2026-05-18 (session end — claude bootstrap)

**Tip: Create `.gitignore` before the first commit in any repo destined for a public host**
A `.gitignore` added after a file is already tracked does nothing — git keeps versioning it. The right habit: write `.gitignore` as the very first file, before any other content is committed. For bootstrap/config repos the minimum list is `settings.local.json`, `.env*`, `*.key`, `*.token`, `*.pem`, `*.secret`. A credential that slips into history before the ignore rule exists requires `git filter-repo` to scrub — a painful, disruptive operation on any published repo.

**Tip: Grep staged content for secrets before every push from a public repo automation script**
`git diff --cached | grep -qiE 'API_KEY|SECRET_KEY|ACCESS_TOKEN|PASSWORD[[:space:]]*=|PRIVATE_KEY|BEGIN RSA PRIVATE'` aborts a push script before the commit lands. Add it as a `check_for_secrets()` function called after staging and before `git commit` in any `up.sh`-style script. The grep runs on the diff, not the whole file, so false positives on variable *names* are rare. If it fires, print `git diff --cached --stat` so the user sees exactly what triggered it. One wrong push to a public repo means credential rotation — the check costs milliseconds.

**Tip: In automation scripts, track exactly which files were copied — don't rely on `git add -A` to stage only what changed**
Declare `CHANGED_FILES=()` at the top and pass the relative destination path to `mark_changed()` every time a file is copied: `mark_changed "hooks/session-start.sh"`. Then commit with `git add -- "${CHANGED_FILES[@]}"`. This ensures the commit contains only the files the script actually synced — not unrelated files that happen to sit in the same directory. `git add -A` in a sync script is silent about what it picks up; the array makes it explicit and auditable.

**Tip: Print `git diff --cached --stat` before every automated commit so push scripts are self-documenting**
One line added before `git commit` in any `up.sh`-style script gives a human-readable summary of what is about to ship — file names and line counts. Combined with a secrets check, this turns a silent automation into one where you always know what went up and why. Cost: zero. Benefit: you never have to run `git log -p` to reconstruct what the script did last time.

## 2026-05-18 (session end — claude bootstrap, round 2)

**Tip: A proper `.gitignore` makes `git add --all` safe in general push scripts — only targeted sync scripts need per-file tracking**
Once `.gitignore` covers sensitive patterns (`*.key`, `*.token`, `.env*`, `settings.local.json`), `git add --all .` in a general-purpose `up.sh` is acceptable — the ignore rules are the right place to declare "never commit these." Only targeted sync scripts (like `sync-bootstrap.sh`) that copy specific files need the `CHANGED_FILES` array pattern, because those scripts must not accidentally stage unrelated files that happen to sit in the same directory. Don't apply per-file tracking everywhere — match the tool to the use case.

**Tip: `TODO.md` and `CHANGELOG.md` are the two minimum context files every project needs — create them before first commit**
`CHANGELOG.md` tells Claude what happened last session; `TODO.md` tells it what's next. Reading both at session start gives complete orientation in under a minute, with no re-explaining, no git-log archaeology, no "what were we doing?" warm-up. Creating them empty before any code is committed costs nothing and pays forward every future session. Add both to the `session-start` skill read order so they're always loaded automatically.

## 2026-05-17 (session end — Startup-HQ)

**Tip: Custom slash commands go in `~/.claude/commands/`, not `~/.claude/skills/`**
Files in `~/.claude/skills/` are only invocable via the internal Skill tool — typing `/<name>` in the prompt gives "unknown command". User-typeable slash commands must be `.md` files in `~/.claude/commands/`; the filename (without `.md`) becomes the command name. If a skill is meant to be triggered by the user directly, move it to `commands/`. Also update any sync script (e.g. `sync-bootstrap.sh`) to mirror the `commands/` directory, not just `skills/`.

**Tip: Consolidate setup scripts to a single entry point per machine role**
Having two scripts (`get-me-started` + `create-new-hq.sh`) for the same machine role forces the user to remember which to run and in what order. When one is a strict subset of the other, merge the smaller one in as functions called from `main()`. The result is one authoritative runbook where reading `main()` top-to-bottom tells the full story. Keep separate scripts only when they target genuinely different audiences (root vs user) or different trigger points (pre-reboot vs post-reboot).

## 2026-05-17 (session end — claude bootstrap)

**Tip: Encode multi-step checklists as skills, not as CLAUDE.md prose**
A `/session-end` skill runs the full EOD workflow in one command — CHANGELOG, memory sync, tips, commit, push. CLAUDE.md prose requires Claude to parse and remember each step every time, and steps get skipped. A skill is a direct instruction set stored in `.claude/skills/<name>/SKILL.md` and invoked with `/<name>`. Any repeating multi-step workflow (review pass, migration checklist, release process) belongs in a skill, not in conversation or CLAUDE.md.

**Tip: Use the `SessionStart` hook for automatic maintenance — not manual reminders**
Anything that should happen every session without thinking (git pull, sync a folder, run a health check) belongs in `~/.claude/hooks/session-start.sh`, wired into settings.json as a `SessionStart` hook. It fires silently before Claude responds, stays quiet when nothing changed, and surfaces output only when something needs attention. The alternative — a reminder in CLAUDE.md — gets ignored or forgotten. If a task is truly mandatory every session, automate it.

## 2026-05-17 (session end — alacritty-tweak-tool, round 2)

**Tip: Cache directory contents with `(file_count, max_mtime)` as the invalidation key — no hashing needed**
`os.scandir()` gives you mtime and name cheaply. `(len(entries), max(e.stat().st_mtime for e in entries))` catches file additions, deletions, and in-place edits with zero file reads. Store it as a JSON list alongside the cached data; compare with `==`. This pattern is appropriate wherever you have a directory of immutable-ish files that are expensive to parse (TOML, XML, etc.) and want a fast warm-path on subsequent runs.

**Tip: `tomlkit` is slow by design — use it only for writes, not reads**
`tomlkit` preserves comments and formatting by doing a full document parse. For read-only use (loading theme colors, reading config values), the overhead is unnecessary. Cache parsed data as plain JSON (`json.dump`/`json.load`) after the first tomlkit parse so subsequent reads hit the fast C JSON parser. Only call tomlkit when you need to write back a file while preserving its comments.

## 2026-05-17 (session end — alacritty-tweak-tool)

**Tip: In GTK4, use `close-request` + `get_width()`/`get_height()` to persist window size — not `notify::default-width`**
`notify::default-width` only fires when `set_default_size()` is called in code, not when the user drags the window edge. To capture the actual user-resized dimensions, connect to `close-request` and call `self.get_width()` / `self.get_height()` there. Also ensure any "Quit" buttons call `window.close()` rather than `get_application().quit()`, otherwise `close-request` is bypassed entirely and the save never runs.

**Tip: On Arch Linux, `vte3` is GTK3 and `vte4` is GTK4 — they share the same GI namespace `Vte 2.91` but conflict at runtime**
Both packages expose `gi.repository.Vte` version `3.91`, but `vte3` links against GTK3. Importing `Vte` after GTK4 is already loaded raises `gi.RepositoryError`. Guard the import with `gi.require_version('Vte', '3.91')` inside a `try/except (ImportError, ValueError, Exception)` block and degrade gracefully when it fails. Always name the dependency `vte4` in Arch package metadata and user-facing docs.

## 2026-05-16 (session end — ATT)

**Tip: When launching a GUI app as the real user from a root process, always override HOME explicitly — `sudo -E` inherits root's HOME**
`sudo -E -u <user> command` preserves the calling environment so DISPLAY and WAYLAND_DISPLAY survive, but HOME stays `/root`. The app then reads config from `/root/.config/` instead of the user's home. Fix: `sudo -E -u <user> env HOME=/home/<user> command`. Anytime you use `sudo -u` from ATT (or any root process) to launch a user-space GUI or config tool, include `env HOME=fn.home` — without it the app appears to work but silently reads and writes the wrong config directory.

**Tip: To reorder sections in a GTK page, only move the `append()` calls — widget construction order does not matter**
GTK4 builds widgets in memory and only inserts them into the visual tree at `append()` time. So reordering sections means moving lines in the "Pack to stack" block at the bottom of the `gui()` function — not cut-and-pasting the construction code. Moving construction code as well is unnecessary churn and risks breaking `self.*` attribute references. Keep widget construction in a stable order (e.g. top-to-bottom by feature) and treat the append block as the single source of truth for visual order.

## 2026-05-16 (session end)

**Tip: Use `curl -s <raw-URL>` to fetch an upstream PKGBUILD for comparison — don't guess, use the GitLab/GitHub raw URL**
When comparing your PKGBUILD against an upstream reference (Chaotic, CachyOS, AUR), get the raw file directly: `curl -s "https://gitlab.com/chaotic-aur/pkgbuilds/-/raw/main/<package>/PKGBUILD"` or use `gh api repos/<owner>/<repo>/contents/<path>`. Store the URL in your CLAUDE.md Reference links section so future sessions don't need to hunt for it again. This is faster than WebFetch and avoids HTML noise.

**Tip: Put shareable links in CLAUDE.md under a "Reference links" section — not just in the file they describe**
A shareable onboarding link (`claude.ai/claude-code/onboard/...`) or upstream PKGBUILD URL is only useful if it survives sessions. CLAUDE.md is read at the start of every session; files like COMPARISON.md are not. Anything you'd want to hand to a new collaborator — upstream refs, share links, key decisions — belongs in CLAUDE.md's Reference links section. That section is also the right place to document why you diverged from upstream.

## 2026-05-15 (session end)

**Tip: When you have many timing data points, print a sorted summary table — not individual lines**
Scattered `print(f"[TIMING] module: {elapsed:.3f}s")` lines require you to scroll and mentally rank. Instead, collect all timings into a dict, then print once at the end: `for label, t in sorted(times.items(), key=lambda x: x[1], reverse=True)`. Slowest is always first, regressions are obvious at a glance, and the format matches the background-init table already in ATT. The pattern costs one dict and three lines — use it anywhere you have more than four timing points.

**Tip: Time your splash screen — if startup is under ~0.5 s, the splash is adding latency, not hiding it**
A splash screen only helps when it masks a genuinely slow load. Once optimisations (lazy imports, deferred init) bring startup under half a second, the splash flickers on and off faster than the eye can read it — which feels like a glitch, not feedback. Measure with `[RESPONSIVE] Window visible after Xs`. When that number drops below 0.5 s, remove the splash and replace it with a brief in-app notification fired at the end of background init (e.g. "Config backups complete") — that communicates what actually happened rather than just "loading."

## 2026-05-15

**Tip: When doing a `replace_all` rename, always rename longer names before shorter ones that are substrings**
If you rename `vboxstack1` before `vboxstack10`, every instance of `vboxstack10` becomes `vbox_new10` — broken. Always rename the longest/most-specific variant first (`vboxstack10` → `vbox_themer`), then the shorter one (`vboxstack1` → `vbox_i3`). This applies to any replace-all operation: list all variants, sort by length descending, rename in that order. Claude will follow the same rule if you brief it once — say "rename the 10-suffix first".

**Tip: Use a per-file checklist for any systematic review or migration — close each session by ticking what's done**
For any task that spans 20+ files over multiple sessions (review pass, migration, naming cleanup), keep a `review.md` with one checkbox per file. Tick each file only after commit+push, not when you finish the edit. When context is compacted or you return the next day, a glance at the file tells you exactly where to resume — no re-reading git log, no re-deriving which files were touched. Claude can read and update the checklist automatically as part of each tab's commit.

## 2026-05-13

**Tip: Batch your TODO observations before dictating — paste 5–10 at once instead of one at a time**
When testing an app and finding UX bugs, jot them in a scratch file as you go, then paste the whole list into one message: "add all of these to TODO.md". Claude formats, categorises, and writes all entries in one turn. Dictating one item per message burns context and time — each round-trip re-reads the file and re-parses your intent. Batching is 5–10× faster for the same output.

**Tip: Ask Claude to identify the shared root cause across a list of bugs before fixing any of them**
Today's session found 6+ separate "greyed-out buttons / missing labels after install" bugs across different pages. Rather than fixing each one individually, prompt: "What root cause do these all share and what is the one-line fix pattern?" Claude identifies the common pattern (`wait_and_refresh` missing) and you can fix all instances in one focused pass — instead of six separate sessions each re-deriving the same answer.

## 2026-05-12 (edu-sddm session)

**Tip: Use `/cost` in Claude Code to track session cost and context usage**
Type `/cost` at any point in a Claude Code session to see how much context has been consumed and the estimated cost so far. Useful for deciding when to start a fresh session — long sessions with lots of file reads and tool calls accumulate context quickly and become more expensive per response.

**Tip: Paste screenshots directly — Claude reads images natively**
Instead of transcribing log output or error messages by hand, paste a screenshot directly into the chat. Claude processes the image and extracts the relevant text automatically. Faster than typing, and you can't accidentally misread a hex value or PID.

## 2026-05-12 (session 101)

**Tip: `Gtk.GestureClick` with `set_button(3)` works on any widget — not just buttons**
`Gtk.GestureClick.new(); gesture.set_button(3); widget.add_controller(gesture)` attaches a right-click handler to any GTK4 widget: labels, images, boxes, even hyperlink labels. Use `gesture.connect("pressed", lambda g, n, x, y: ...)` — the `x, y` coords are widget-relative and can be fed directly to `popover.set_pointing_to(rect)` to anchor the popover under the cursor. This is the GTK4 replacement for the deprecated `button-press-event` signal.

**Tip: When a helper is reused by a second module, move it to the shared utility module immediately**
If a function starts in `ai.py` and `kernel_gui.py` also needs it, the right fix is to move it to `functions.py` — not to `import ai` from `kernel_gui`. Cross-feature imports create hidden dependency cycles: `kernel_gui` → `ai` → `functions` means a syntax error in `ai.py` silently breaks the kernel tab too. Shared utilities belong in a shared module; feature modules should only import upward into `functions`, never sideways into each other.

## 2026-05-12 (session 100)

**Tip: Launch `GTK_DEBUG=interactive python3 your_app.py` to inspect any live widget without reading source**
A floating inspector opens alongside your app. Click any widget and it shows its CSS node name, applied CSS classes, state flags (`:hover`, `:focus`, `:active`), and full parent hierarchy — all the info you need to write a CSS selector or diagnose a layout bug. Faster than grep-ing through all `_gui.py` files looking for a widget name; the inspector reads the live object tree directly.

**Tip: `git stash` doesn't sync to remote — work stashed on one machine is invisible on another**
`git push` / `git pull` only transfer commits and branches, not the stash list. If you stash a half-finished change on your Kiro machine and switch to Omarchy, `git stash list` there will be empty. Use a WIP commit (`git commit -m "wip: ..."`) instead of a stash when you need the work accessible across machines. You can always `git reset HEAD~1` to un-commit it when you pick it back up.

## 2026-05-12 (session 99)

**Tip: Run `vulture usr/share/archlinux-tweak-tool/ --min-confidence 80` periodically to find dead code that flake8 misses**
`flake8` catches unused imports and unbound names but not unused function parameters, unreachable branches, or functions that are defined but never called. `vulture` finds all of these. At 80% confidence it skips most GTK dynamic-dispatch false positives. The output splits naturally into two categories: GTK callback params that just need a `_` prefix, and genuinely dead code to remove. Run it after any large refactor — today it found 15 issues in one pass across 13 files.

**Tip: Before fixing a widget that "does nothing", check whether its container is ever appended to the layout**
Today `btn_dark_theme` had a complete implementation — state management, callback, label updates — but `hbox6` (its container) was never appended to `ivbox`. The button was invisible and unreachable. `grep -n "hbox6" gui.py` found the definition and the `append(btn_dark_theme)` call but no `ivbox.append(hbox6)`. Pattern: when a widget seems broken, check the full chain — widget → box → parent — before reading the callback logic.

## 2026-05-11 (session 98)

**Tip: When a "fix" button leaves a warning visible, check whether the fix function runs ALL checks that the status function verifies**
`refresh_sdboot_status` checked both `/etc/kernel/cmdline` AND boot entries. `on_sdboot_fix_clicked` branched on `_use_cmdline` — when True it patched only the cmdline. Status never saw `all_ok = True` so the warning stayed. The pattern: grep for every condition inside the refresh function, then verify the fix function hits every one of them. If the fix branches, the status check must too — or merge both into one thread.

**Tip: Patching kernel command-line parameters in boot entries never requires rebuilding the initramfs**
The bootloader reads the `options` line (or `/etc/kernel/cmdline`) at boot and passes it to the kernel — it is not baked into the initramfs. The two Plymouth operations that DO need a rebuild are: (1) adding the `plymouth` hook to `/etc/mkinitcpio.conf` (ATT's install script runs `mkinitcpio -P` automatically), and (2) changing the active theme (`plymouth-set-default-theme -R` does the rebuild). Adding `quiet splash` to entry files or `/etc/kernel/cmdline` takes effect on the next boot with no extra step.

## 2026-05-11 (session 97)

**Tip: Use `trap 'echo ""; read -p "Press Enter to close..."' EXIT` in ATT bash scripts — the terminal stays open even when `set -euo pipefail` aborts early**
With `set -euo pipefail`, any failing command exits bash immediately — without a trap, the terminal window closes before the user can read the error. Adding the trap as the second line (right after `set -euo`) fires on every EXIT including error exits: the user always gets to see what went wrong. Remove the explicit `read -p` at the end of the script — the trap makes it redundant.

**Tip: Check the Arch Wiki before implementing any bootloader or initramfs integration — file paths and required parameters differ from what you'd guess**
Plymouth needs BOTH `quiet` and `splash` (not just `splash`) or it falls back to the text details theme. systemd-boot entries live in `/boot/loader/entries/` on standard Arch but `/boot/efi/loader/entries/` on Kiro — and three other path variants on other setups. The wiki's "Configuration" section for any system tool lists exact paths and all variants; skipping it leads to code that works on one machine and silently does nothing on others.

## 2026-05-11 (session 93)

**Tip: Write a "next step" note in chat before running `/compact` — it's the one thing that survives compression**
Before running `/compact`, type a single sentence like "next: add the refresh() closure to wait_and_refresh in sddm_gui.py." That sentence lands at the top of the compacted summary and is the first thing the resized context sees. Without it, `/compact` preserves what you did but not what you were *about* to do — you lose the specific detail that drove the whole session.

**Tip: Add `fn.debug_print(f"state: {variable}")` at callback entry to confirm what the callback actually receives**
When a GTK4 callback seems to have no effect, the root cause is almost always wrong state, not wrong logic. One `debug_print` at the top of the callback, run with `--debug`, shows the exact value at the moment of the call — whether a widget is None, whether a flag is already True, whether a path doesn't exist. Reading five files to reason about what the state *should* be costs 10× more than seeing what it *is* in a single launch. Remove the line after diagnosing.

## 2026-05-11 (session 92)

**Tip: Use `journalctl -b | grep sddm` to filter SDDM load events — `sddm-greeter` vs `sddm-greeter-qt6` in the PID line tells you the Qt version immediately**
`journalctl -b | grep sddm` strips all kernel/network noise and shows only the greeter's QML load sequence, version errors, and fallback notices. The process name in brackets is the diagnostic signal: `sddm-greeter[PID]` = Qt5 greeter; `sddm-greeter-qt6[PID]` = Qt6 greeter. "Library import requires a version" in the output means the Qt5 greeter rejected unversioned QML imports. "Fallback to embedded theme" means the theme failed to load entirely.

**Tip: A black SDDM screen in VirtualBox with MESA ZINK errors is a GPU driver issue, not a theme bug — install Guest Additions or switch to VBoxSVGA**
When journalctl shows `MESA: error: ZINK: vkEnumeratePhysicalDevices failed` and `libEGL warning: failed to create dri2 screen`, the Wayland compositor can't initialize the GPU pipeline and renders nothing. The theme may have loaded cleanly (no "fallback" line). Fix options: install VirtualBox Guest Additions (provides `vboxvideo` driver), switch Display → Screen → Graphics Controller to VBoxSVGA, or set `DisplayServer=x11` in `/etc/sddm.conf` to avoid Wayland entirely for VirtualBox testing.

## 2026-05-10 (session 91)

**Tip: Use `sha256sums=('SKIP')` for git+ sources in PKGBUILD — checksums on git repos are always invalid**
`source=("git+https://...")` clones the repo at build time; a SHA256 hash is meaningless because the content changes with each commit. Use `SKIP` and rely on git's own object integrity. For release tarballs downloaded by URL, generate real sums with `updpkgsums` or `makepkg -g`.

**Tip: Use a `.install` file in PKGBUILD to run `plymouth-set-default-theme` post-install — not a pacman hook**
A `pkgname.install` file with `post_install()` and `pre_remove()` functions is the correct place to call `plymouth-set-default-theme` because it runs as root in the right context and is part of the package contract. A separate pacman hook works but adds a second file to maintain. The install file ships inside the package and is automatically discovered when `install=` is set in PKGBUILD.

## 2026-05-09 (session 85)

**Tip: In a post-install refresh closure, always check the text entry and auto-load — don't make the user click twice**
After a package install, the user's folder path is already in `self.sddm_folder_entry` (or any entry they filled earlier). Read it in the `refresh()` closure with `.get_text().strip()`, check `fn.path.isdir()`, and call the loader directly. This turns an install-then-click-Load workflow into install-done-thumbs-appear. Apply this pattern to any action that needs secondary data the user already provided.

**Tip: Consolidate all post-install UI state changes into one `refresh()` closure — never split them across the callback and the thread**
All of: enabling buttons, swapping visible/hidden widgets, repopulating dropdowns, and triggering dependent loaders should live inside the single `refresh()` function called via `GLib.idle_add`. Putting any of those calls outside the closure (e.g. directly after `process = Popen(...)`) runs them before the install finishes. One closure, one `GLib.idle_add` call, guaranteed correct ordering.

## 2026-05-09 (session 84)

**Tip: Always check for `-git` AUR variants when guarding UI on package presence**
`check_package_installed("sddm")` returns False for users who installed `sddm-git` from AUR — the page stays blank with no error. For any package that has common AUR variants (`-git`, `-bin`, `-nightly`), use an `or` chain: `check_package_installed("pkg") or check_package_installed("pkg-git")`. One extra check prevents a whole page being invisible to AUR users.

**Tip: Skip plan mode for single-line, fully reversible edits — just state the change and wait for "y"**
Plan mode is for changes touching more than 2 files or with irreversible side effects. A 1-line `or` guard in one file needs no plan — just say "I'll change line N from X to Y — shall I?" and wait. Invoking plan mode for trivial edits costs extra tokens and slows the session for no safety gain. Reserve it for when it actually prevents mistakes.

## 2026-05-09 (session 83)

**Tip: Use `!` in the Claude Code prompt to run a command and paste its output directly into the conversation**
Typing `! bash ~/.bin/<your-script> in the prompt runs the command in your terminal session and sends its output straight to Claude — no copy-paste needed. Useful whenever a script errors and you want Claude to diagnose it without manually copying terminal output.

**Tip: Add `set -x` at the top of a bash script temporarily when an error trap fires with no clear cause**
`set -x` prints every command and its expanded arguments before execution — you see exactly which line failed and what values the variables had at that moment. Much faster than reading through the logic manually. Remove it after diagnosing; leaving it in floods the terminal on every run.

## 2026-05-09 (session 82)

**Tip: Press `Escape` to cancel Claude Code's current response mid-generation and redirect**
If Claude starts generating a long implementation you didn't want, pressing Escape stops it immediately. You pay only for tokens generated so far, not the full response. Then redirect with a follow-up message. Most cost-effective on large file writes or multi-step plans that drifted from your intent — stop early rather than waiting for the full output and then reverting.

**Tip: Run `/help` at session start to see every available skill and slash command**
Claude Code loads different skills depending on project context. `/help` lists all slash commands active in the current session — built-in ones (`/cost`, `/compact`, `/model`, `/fast`) plus project skills (`/simplify`, `/review`, `/ultrareview`, `/security-review`). Discovery is free; you only pay when you actually invoke a skill. If a skill you expect isn't listed, it hasn't been loaded — check your CLAUDE.md or settings.

**Tip: When porting a function between scripts, paste it in chat so Claude checks dependencies before touching any file**
Pasting the exact function body lets Claude scan for every variable it references (`SETTINGS_DIR`, `TARGET_USER`, etc.) and flag which ones are missing from the target script — before a single edit. Describing the function in words forces Claude to guess names and signatures, which costs a follow-up correction round-trip.

**Tip: Confirm variable definitions exist in the target file before adding a function that uses them**
A function copied from another script may depend on variables (`SCRIPT_DIR`, `TARGET_USER`) that are defined there but absent in the destination. Before inserting the function body, check whether those definitions exist — if not, add them first. Missing definitions cause silent failures or `unbound variable` crashes under `set -u`, which are hard to trace back to the copy-paste.

## 2026-05-08 (session 81)

**Tip: Show Claude a reference script when asking it to produce a similar one — it extracts the exact pattern in one shot**
Pasting the ArcoLinux grub migration script immediately told Claude the full grub-install + grub-mkconfig sequence, the correct flags, and the typical EFI directory. Without it, Claude would have produced a minimal `grub-mkconfig`-only script and missed grub-install entirely. Any time you have a "this worked before" script, paste it before asking for the new one — Claude reads the intent from working code faster than from prose description.

**Tip: Say "this runs in a non-interactive bash shell" when asking Claude to write detection logic — `command -v` is PATH-dependent**
Scripts launched via `Popen(["alacritty", "-e", "bash", "-c", script])` run in a non-interactive, non-login shell. `command -v grub-mkconfig` can return empty even when the binary exists if `/usr/bin` isn't in PATH for that shell context. Use `[ -x /usr/bin/binary ]` instead — it tests the file directly, no PATH lookup needed, and is always reliable regardless of how the shell was started.

## 2026-05-08 (session 80)

**Tip: State the exact target value in your first message when doing a version bump — Claude skips the upstream lookup**
Saying "update the kernel to 7.0.5-1" in your opening message lets Claude go straight to the PKGBUILD edit. Saying "update the kernel" makes Claude fetch the upstream releases page first to find the version, costing an extra web fetch and one extra round-trip. The less Claude has to discover, the faster and cheaper the session.

**Tip: Never hand-edit b2sums after a kernel version bump — `build-kernel.sh` runs `updpkgsums` automatically**
After changing `_minor` and `_tagrel` in PKGBUILD, the b2sums become stale. But `build-kernel.sh` calls `updpkgsums` as part of its normal flow, which downloads the new tarball and recomputes all checksums in place. Running `makepkg -si` directly will fail with a checksum mismatch; always go through the wrapper script for version bumps.

## 2026-05-08 (session 79)

**Tip: To trace a startup error in ATT, grep `fn.log_error(str(error))` — it's the only pattern that prints ERROR DETECTED**
Instead of reading every file that runs at startup, search the specific logging call: `grep -rn "fn.log_error(str(error))" *.py`. Every match is a catch site where an unknown exception is formatted and displayed. Then read the `try:` block above each match and ask: "could this raise IndexError?" That narrows the search from 20+ files to a handful of candidates in one command.

**Tip: `fn.get_position()` returns 0 (not -1) on not-found — always check the returned line contains your search string before indexing it**
`fn.get_position(lines, "ZSH_THEME=")` defaults to 0 when the search term is absent. `lines[0]` is valid Python so no IndexError — but it's the *wrong* line. Indexing `.split("=")[1]` on a line that has no `=` then crashes. The guard is: `if "ZSH_THEME=" not in lines[pos]:` — verify the element matches before trusting the position. Apply this pattern to any code that calls `fn.get_position()` and immediately indexes the result.

## 2026-05-08 (session 78)

**Tip: Use `/ultrareview` to get an independent multi-agent cloud review of any branch**
`/ultrareview` bundles your current branch and sends it to several parallel review agents, each reading from a fresh perspective — no bias from your session's context. For bash scripts that run as root and modify system files (like pacman.conf or fstab), independent review catches idempotency issues, missing guards, and dangerous tee/append patterns that inline review often misses. User-triggered and billed separately; the cost is trivial vs a broken `/etc/pacman.conf`.

**Tip: In Claude Code, press `#` in the terminal to open a file picker and inject a file path directly into context**
Typing `#` in the Claude Code terminal opens an autocomplete file picker — no need to type the full path or open the file in the IDE first. Select the file and its path is injected into the message. Useful when you want Claude to read a specific config before editing, or when you're in a terminal-only workflow without the VSCode extension.

## 2026-05-08 (session 77)

**Tip: Pass `run_in_background: true` on independent Agent calls to run them truly in parallel**
When you have two unrelated subagents (e.g. a flake8 scan of module A and a security review of module B), add `run_in_background: true` to both Agent calls in the same message. Both agents start immediately and you're notified when each completes — wall-clock time is cut in half compared to sequential agent calls. Only use this when neither agent's result is needed as input to the other.

**Tip: Use `/security-review` before committing multi-file changes to catch permission and injection bugs**
`/security-review` spawns a dedicated security-focused agent that scans the current branch's pending changes for OWASP-class issues: command injection, path traversal, privilege escalation, unvalidated input. It reads only the diff, not the whole codebase — fast and cheap. Best triggered after a feature that touches subprocess calls, file I/O, or any code that runs as root under pkexec.

## 2026-05-08 (session 76)

**Tip: Use the `Plan` subagent to get a full implementation plan before writing any code on complex tasks**
`Agent({ subagent_type: "Plan", prompt: "Design the implementation for X..." })` returns a step-by-step plan with identified critical files and architectural tradeoffs — without touching a single file. Use it before any task touching more than 2 files. It costs one agent call and prevents the expensive backtrack when you realize mid-implementation the approach was wrong.

**Tip: Run `/fewer-permission-prompts` once after a typical session to build an allowlist and stop seeing the same prompts repeatedly**
The `fewer-permission-prompts` skill scans your transcripts for read-only Bash and MCP tool calls you've approved before, then adds a prioritized allowlist to `.claude/settings.json`. The harness then auto-approves those tool calls in future sessions — no more "allow grep?" prompts for commands you approve every single time. Run it once after a representative session, not after every session.

## 2026-05-08 (session 75)

**Tip: Pass `env=fn.get_terminal_env()` to every Popen that launches a GUI app, not just alacritty**
`fn.get_terminal_env()` rebuilds `WAYLAND_DISPLAY` and `XDG_RUNTIME_DIR` from `/run/user/<uid>` — the vars that `pkexec` strips. This fix is usually applied to alacritty launches, but any GUI app launched via `Popen` (bazaar, gnome-software, pamac, etc.) needs the same env or it silently fails to connect to the display on machines where the env is clean. The symptom: "works on my PC, not on others" — your machine happens to have the vars already in environ; others don't.

**Tip: "Works on my PC, not on others" almost always means stripped env vars from pkexec/sudo**
When a feature launches fine under your user session but fails when ATT runs elevated, the first thing to check is whether `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, or `DBUS_SESSION_BUS_ADDRESS` is present in `os.environ` at the point of the Popen call. Add a one-line `fn.debug_print(os.environ.get("WAYLAND_DISPLAY"))` in the callback, relaunch with `--debug`, and compare output. If it prints `None`, wrap the Popen with `env=fn.get_terminal_env()` — takes 30 seconds to diagnose and 5 seconds to fix.

## 2026-05-08 (session 74)

**Tip: Pass `isolation: "worktree"` to an Agent call to experiment on a throwaway branch**
When asking Claude to attempt a risky refactor or multi-file migration, use `Agent({ isolation: "worktree", ... })` — the agent works on an isolated git worktree (a separate checkout of the repo). If the experiment makes things worse, the branch is abandoned; if it makes no changes at all, the worktree is auto-cleaned. Your working tree is never touched. Use this any time you want "try it and show me" without committing to anything.

**Tip: Pass `model: "opus"` on individual Agent calls to use Opus only for the hard sub-task**
You can override the model per agent: `Agent({ model: "opus", prompt: "..." })`. This lets you pay Opus rates only for the one task that needs deep multi-file reasoning (architecture review, security audit, complex refactor), while the rest of the session runs on Sonnet. You get the best model where it matters without switching your entire session — more cost-efficient than `/model opus` which applies globally.

## 2026-05-07 (session 73)

**Tip: Use `fastfetch --format json | jq '.[] | select(.type=="DE")'` to see exactly which source fastfetch used for DE detection**
The JSON output shows the exact env var or file that provided each value — no source code needed. `"type": "DE"` entry shows the detected value and which detection path hit. Useful any time a fetch tool reports something unexpected: the JSON reveals whether it read `XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION`, or a file on disk.

**Tip: Spawn an `Explore` subagent for "why does X detect Y?" questions — keeps your main context clean**
When diagnosing a detection question (DE, shell, session type), the answer requires 3–5 sequential reads and env greps. Delegating to `Agent(subagent_type="Explore")` burns the agent's own context window, not yours — you get the answer in one result message instead of 4 tool-call dumps. Reserve the main context for work that needs it.

## 2026-05-07 (session 72)

**Tip: Check `fn.desktop` via XDG_CURRENT_DESKTOP to provide context-aware warnings without user input**
ATT already reads `os.environ.get("XDG_CURRENT_DESKTOP", "")` into `fn.desktop` at startup. For any feature incompatible with certain DEs (like GTK themes on Plasma), build a conditional hbox/label at GUI creation time that detects and warns upfront. No extra UI complexity, no dialogs — the warning appears naturally as part of the page and costs zero overhead. Pattern: check `"KDE" in fn.desktop or "plasma" in fn.desktop.lower()`, conditionally append hbox if true.

**Tip: Create GUI elements in conditional blocks to keep warnings clean — only append if populated**
When conditionally building a warning widget, use `.get_first_child() is not None` before appending to the parent container. This prevents empty hboxes from cluttering the layout if the condition isn't met. The widget is built but invisible; only append if it has content. Applies to any context-specific warning or status display that shouldn't appear on all systems.

## 2026-05-05 (session 65)

**Tip: Read `/proc/<pid>/environ` to recover stripped env vars when ATT runs as root**
`pkexec` and `sudo` strip session env vars like `XDG_CURRENT_DESKTOP` and `DESKTOP_SESSION`. To recover them, iterate `/proc/*/environ`, find a process owned by `LOGNAME == fn.sudo_username`, and parse its null-delimited env. This lets ATT detect the real desktop session without requiring the user to pass extra flags. Wrap each file read in `try/except (PermissionError, OSError)` — some `/proc` entries are transient.

**Tip: Run user-space D-Bus tools from root with `sudo -u user XDG_RUNTIME_DIR=... DBUS_SESSION_BUS_ADDRESS=...`**
Tools like `xfconf-query` and `gsettings` talk to the user's running daemon via D-Bus. When ATT runs as root, these calls return empty results or silently fail because the D-Bus session is unreachable. The fix: prefix every command with `sudo -u {fn.sudo_username} XDG_RUNTIME_DIR=/run/user/{uid} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{uid}/bus` and run with `shell=True`. ATT already uses this for `variety --preferences` — apply the same pattern to any user-space config tool.

## 2026-05-05 (session 64)

**Tip: Put live system state directly in GTK StackSwitcher tab labels — no extra widget needed**
`stack.add_titled(vbox, "id", "BASH (active)")` puts the current state right in the tab label the user sees before clicking. Derive the label from real data at GUI construction time (`fn.get_shell()`, `fn.check_package_installed()`). Zero extra widgets, zero extra GTK signal connections — the label itself carries the context.

**Tip: Use `pwd.getpwnam(username).pw_shell` instead of `os.getenv("SHELL")` for login-shell detection**
`$SHELL` reflects the *current running* shell, which is always `fish` if you launched ATT from a fish terminal — even if the user's login shell is bash. `pwd.getpwnam(fn.sudo_username).pw_shell` reads the passwd database directly and returns the actual configured login shell regardless of how the process was launched. Always authoritative, never misleading.

## 2026-05-05 (session 63)

**Tip: Demote high-frequency internal status lines from `log_*` to `debug_print` — reserve log_* for user-meaningful events**
Messages that fire on every folder change, scroll event, or background tick add noise to the console and dilute the signal from real actions. If a line is "I'm doing my normal job" rather than "something the user triggered just happened," it belongs in `debug_print` (visible only with `--debug`). In ATT the rule of thumb: `log_subsection` for a user-initiated step, `debug_print` for internal bookkeeping.

**Tip: For one-liner fixes, state the file:line and the exact old→new change in your message — Claude edits in one round-trip**
Instead of "remove the noisy log line from wallpaper.py," say "`wallpaper.py:188` — change `fn.log_subsection(...)` to `fn.debug_print(...)`." Claude makes exactly that edit with no file-scan, no follow-up question. The more precise your message, the fewer tool calls and the lower the token cost.

## 2026-05-05 (session 62)

**Tip: Cache config files that are read many times — invalidate only on write**
If a single config file (like `/etc/pacman.conf`) is read by 5+ functions at startup, add a module-level `_conf_cache = None`, a `get_lines()` function that reads once and caches, and an `invalidate()` call after every write. In ATT this cut ~23 redundant disk reads at startup. The pattern is invisible to callers — they just call `fn.get_pacman_conf_lines()` instead of `open(fn.pacman)`.

**Tip: Read the code before acting on a multi-agent review finding — half the flags are false positives**
Three-agent reviews surface many findings, but "5-second read" disproves many of them — a claimed "3s blocking call on main thread" was actually dead code never called; a "7× file reads" was one read with 7 flags parsed in a loop. For each finding, run one grep or read the function before editing. Fixing a false positive costs a revert; verifying costs one tool call.

## 2026-05-05 (session 61)

**Tip: Two-word requests on a selected block are the highest-signal, lowest-token edit requests**
Select the code in VSCode, then type "improve" or "simplify" — the selection scopes the change, the verb defines the goal. No file name, no line numbers, no explanation needed. Claude infers the target from context and proposes the exact diff.

**Tip: When Claude proposes a change and you approve with "y", it edits immediately — say "show the diff first" if you want to review before it touches the file**
A plan + "y" is a two-step confirmation with no staging. If the change is larger than a few lines or touches multiple files, ask "show me the full diff" before approving so you can verify scope before any file is written.

## 2026-05-05 (session 60)

**Tip: Use `/simplify` after edits to catch quality issues fast**
Instead of manually reviewing code after a change, run `/simplify` — it spawns a review agent that checks for reuse, quality, and efficiency across the changed code, then fixes what it finds. Saves a separate review pass.

**Tip: Scope your prompts to one widget at a time for UI tweaks**
For small GTK layout changes (make button X bold, change label Y to markup), a single-sentence prompt is more cost-effective than describing the whole page. The less context Claude has to process, the cheaper and faster the response. Chain single-widget prompts rather than batching.

## 2026-05-05 (session 59)

**Tip: Scope compliance questions to one rule at a time for faster, more actionable output**
"Do SDDM buttons comply with the `_widget` convention?" gets a yes/no + a diff-ready list instantly. "Do they comply with our rules?" requires reading the whole file against every rule before the first finding. Narrower questions = less token burn and more precise results. When you want a full sweep, chain single-rule questions rather than asking one broad one.

**Tip: Use `grep -n "def on_.*widget=" sddm.py` to find `_widget` violations without reading the whole file**
`grep -n "def on_.*widget[^_]" *.py` catches every callback that uses `widget` instead of `_widget` in all GUI/logic files at once. Combine with `grep -v "_widget"` to exclude correct ones. Faster than reading file-by-file, and you see filename + line number ready to fix.

## 2026-05-05 (session 58)

**Tip: Grep for `Gtk.Button(label=` with a keyword filter to inventory action buttons without reading the whole file**
`grep -n 'Gtk.Button(label=' sddm_gui.py | grep -i 'install\|remove\|enable'` shows every relevant button and its label in one shot. This answered "did we have an install sddm-git button?" in two commands — no file read, no scrolling. Use this pattern any time you need to confirm a UI element exists before deciding whether to add one.

**Tip: When verifying a feature, check both `feature.py` and `feature_gui.py` in one grep pass**
`grep -n "sddm_enable\|sddm_git" sddm.py sddm_gui.py` searches both files simultaneously and prefixes every match with its filename. Confirms that the backend function and its GUI binding both exist — or surfaces which half is missing — in a single command.

## 2026-05-05 (session 51)

**Tip: Use `claude --continue` to resume the last session without re-explaining context**
Running `claude --continue` in the terminal picks up the previous conversation exactly where it left off — all file context, decisions, and in-progress work intact. Useful when you close the IDE and come back to the same task. No need to re-paste file names or re-describe what you were doing.

**Tip: Run `/clear` when switching to an unrelated task mid-session**
Accumulated tool output from a previous task inflates the context window and can nudge Claude toward off-topic suggestions. `/clear` resets the conversation to a clean state while keeping the session open. Cheaper per token and more focused than continuing in a context full of irrelevant file reads.

## 2026-05-05 (session 50)

**Tip: Use `/simplify` after a focused coding session to catch quality issues across reuse, quality, and efficiency**
`/simplify` launches three parallel review agents simultaneously — one checks for duplicated logic, one for code quality smells, one for performance issues. The findings include real line numbers and concrete fixes. Particularly good at catching bugs that are invisible when you're writing code (e.g. type mismatches in function calls).

**Tip: Scope code reviews to a single file for more precise findings**
When asking Claude to review code, specify a single file rather than "the project." Narrower scope produces findings with real line numbers and concrete fix suggestions rather than vague architectural advice. For a whole-project sweep, use parallel agents — one file per agent.

## 2026-05-04 (session 49)

**Tip: Use `/save <filename>` in Claude Code to export the current conversation to markdown**
Useful when a session produces a design decision, architecture choice, or reference worth keeping. The exported file can be checked into the repo or added to your notes — cheaper than re-explaining the decision in a future session.

**Tip: Type `#filename` in Claude Code chat to attach a file directly as context**
Claude Code auto-completes `#` references to full file paths and attaches the content inline — no IDE open required, no separate read step, zero extra tool cost. Precise and fast for single-file questions.

## 2026-05-04 (session 48)

**Tip: Open a reference script in the IDE before asking for a rewrite — Claude sees it automatically**
The Claude Code VSCode extension sends `ide_opened_file` events for every file you open. Opening a well-formed reference script before asking "rewrite with our template" gives Claude both files in context — it matches helper names, separator width, and formatting without you pasting anything. Zero extra tokens, precise output.

**Tip: Always quote `$HOME` in bash scripts — the concatenation style `$HOME"/path"` is a quoting antipattern**
With `set -euo pipefail`, any unset variable causes an immediate exit. Use `"$HOME/DATA"` throughout — it handles paths with spaces and is unambiguously correct. The older `$HOME"/DATA"` form found in legacy ArcoLinux scripts mixes quoting modes unnecessarily and will confuse any future reader.

## 2026-05-04 (session 47)

**Tip: Always add `2>&1` when redirecting diagnostic command output to `/dev/null`**
`ping -c 1 8.8.8.8 > /dev/null` silences stdout but lets stderr leak — you see "connect: Network is unreachable" in the terminal even when the script is handling the failure correctly. `> /dev/null 2>&1` suppresses both streams. This matters for connectivity checks, `curl`, and any command whose error text you're already handling in code.

**Tip: Use `bash -n script.sh` to syntax-check a bash script without executing it**
`bash -n` parses the entire script and reports syntax errors — missing `fi`, unmatched quotes, bad substitutions — without running a single command. Run it before testing any script that modifies system state. It catches structural mistakes in seconds at zero risk, before `set -euo pipefail` aborts the script mid-execution.

## 2026-05-04 (session 46)

**Tip: Run `/review` on a rewritten bash script before committing — rewrites silently change behavior**
A structural rewrite (adding color helpers, splitting steps into `header` sections) is easy to get 95% right. `/review` catches the 5% where a conditional, path, or quoting changed unintentionally. One review pass takes seconds; a broken `skel` that wipes `.config` costs the user's entire session.

**Tip: Paste the absolute file path in chat to give Claude a file without opening it in the IDE**
Typing `/home/erik/EDU/.../usr/bin/skell` directly in the message is enough — Claude reads it with no extra IDE action. Useful when you're in a terminal, when the file is not currently open, or when you want to scope the question to one specific file without context drift.

## 2026-05-04 (session 45)

**Tip: Replace `if [ $? -ne 0 ]` with `if ! command` for cleaner bash error guards**
`if ! sudo -u "$USER" git clone ...` is more idiomatic than capturing `$?` on the next line. It also avoids a subtle bug: any command between the one you're checking and the `if [ $? ... ]` line will clobber `$?`. The `if !` form is atomic — it checks the exit code of exactly the command you name, with no race condition.

**Tip: Name tput color codes at the top of every bash script, not inline at each echo**
Defining `CYAN=$(tput setaf 6)` / `RESET=$(tput sgr0)` once at the top and then using `${CYAN}text${RESET}` everywhere else is both cheaper (tput is only forked once per color) and easier to maintain — changing cyan to bold-cyan is one-line edit, not a grep-and-replace across every echo in the file.

## 2026-05-04 (session 44)

**Tip: Use `/review` on a bash script after reformatting to verify logic was not silently altered**
After a structural rewrite (adding color helpers, splitting into sections), run `/review` on the script to confirm the underlying logic is identical to the original. A cosmetic rewrite is easy to get 95% right — review catches the 5% where a conditional or path subtly changed.

**Tip: Use `@filename` in your prompt to pin a specific file into context without opening it in the IDE first**
Typing `@filename` in Claude Code chat attaches that file's content inline. Claude receives it immediately without a separate read step — zero extra tool cost and faster responses. Useful when you want Claude focused on one file without it reading others speculatively.

## 2026-05-04 (session 43)

**Tip: Use `/compact` to free context window space mid-session**
When a long session has accumulated a lot of tool output, `/compact` summarizes prior context and frees up context window space. This keeps cost down and avoids hitting the context limit without losing important state. Most effective after large file reads or lengthy grep output.

**Tip: Prefix questions with "exploratory:" to get a recommendation without implementation**
Prefixing a question with "exploratory:" signals you want tradeoffs and a recommendation only — not code. Claude skips the dive into files and gives a 2–3 sentence answer. This saves tokens and avoids wasted work before you've decided on an approach.

## 2026-05-04 (session 42)

**Tip: Use `/review` on a bash script after reformatting to verify logic was not silently altered**
After a structural rewrite (adding color helpers, splitting into sections), run `/review` on the script to confirm the underlying logic is identical to the original. A cosmetic rewrite is easy to get 95% right — review catches the 5% where a conditional or path subtly changed. One pass before shipping beats a bug report from a user whose sddm.conf was wiped instead of backed up.

**Tip: Keep bash helper functions (separator/header/success/info/warn/error) in a sourced lib, not copy-pasted**
If two or more scripts in the same project share the same color-helper block, extract it into a sourced file (e.g. `data/bin/lib/colors.sh`) and `source` it at the top of each script. Copy-pasting the block into every script creates maintenance debt — if the cyan color code or separator width changes, you update it in N places instead of one.

## 2026-05-04 (session 41)

**Tip: Guard every button that invokes an external tool with a package check — not just install/remove buttons**
Buttons that launch viewer tools (`fzf`, `bat`, `alacritty`) fail silently if the tool isn't installed — the terminal flashes and closes with no feedback. Add `fn.check_package_installed("tool")` at the top of the callback and return early with `fn.log_info` + `fn.show_in_app_notification` if missing. This pattern applies to any callback that shells out to a non-system binary, not just package managers.

**Tip: Use `for pkg in ("fzf", "bat"):` to guard multiple required tools in one block**
When a callback needs two external tools, a single `for` loop over a tuple is cleaner than two separate `if not check_package_installed()` blocks. Each iteration checks one package and returns early with a named error message. The user sees exactly which tool is missing — and you avoid copy-pasting the same guard four lines apart.

## 2026-05-04 (session 40)

**Tip: Place prerequisite checks at the first user action that needs them, not the last one**
If a package is required for feature X, the check belongs on the button that starts the workflow — not on a downstream action like "set default". In this session, `pacman-hook-kernel-install` was only checked on "Set as Default" but was already needed at kernel install time. The fix: move `get_missing_requirements()` into the install callback so the user is prompted before the terminal opens, not after they've installed a kernel and hit the next step.

**Tip: Daemon threads can't show GTK dialogs directly — use GLib.idle_add to hand back to the main loop**
GTK is single-threaded. Any dialog, notification, or widget update inside a `daemon=True` thread will silently fail or cause a crash. Wrap all GTK calls from threads with `fn.GLib.idle_add(your_gtk_function, arg1, arg2)` — this queues the call onto the main loop and runs it safely. For dialogs that need `self` and `Gtk`, pass them as positional args: `GLib.idle_add(_offer_install_packages, self, Gtk, fn, missing)`.

## 2026-05-04 (session 39)

**Tip: Pass a page/file name to `/review` instead of a PR number for a direct code review**
`/review icons page` triggers a review of the relevant source files without needing an open PR. Faster than describing files in a prompt and scoped to exactly what you care about. Any descriptive label works — Claude maps it to the right files.

**Tip: Chain `/review` with `/simplify` for a two-pass improvement cycle**
`/review` surfaces correctness and convention issues; `/simplify` targets duplication and reuse. The two skills focus on different problem classes and produce better combined results than either alone. Run review first to get line references, then pass those to `/simplify`.

**Tip: Prefix your request with "report only, don't change anything" to get pure analysis**
Claude will skip all Edit/Write tool calls and stay in read-only mode. Useful when you want a code review, audit, or survey without any risk of accidental changes.

## 2026-05-04 (session 38)

**Tip: Use `claude --continue` to resume the last session without re-explaining context**
Running `claude --continue` in the terminal re-opens the most recent conversation with all prior context intact — no session-start briefing needed. Useful when you close the terminal mid-task and want to pick up exactly where you left off. Pair it with a clear CHANGELOG entry so the resumed session starts with verified state, not just conversation memory.

**Tip: `gh` (GitHub CLI) is a separate package — install it once for PR-native workflows**
`sudo pacman -S github-cli && gh auth login` unlocks `/review <PR#>`, `gh pr create`, `gh pr list`, and issue management directly from Claude Code. Without it, PR review falls back to diff-reading in the main context window, which costs more tokens and loses the multi-agent benefit. One-time setup, permanent workflow improvement.

## 2026-05-04 (session 37)

**Tip: Filter dmesg by log level to skip informational noise**
`sudo dmesg -l err,crit,alert,emerg` shows only actual errors without grepping through thousands of lines. Much faster than `grep -i error` which also matches benign lines like "Correctable Errors collector initialized."

**Tip: Pipe dmesg through `--color=always | less -R` for colorized severity**
`sudo dmesg --color=always | less -R` gives you color-coded output in the pager — critical messages appear red, warnings yellow, info white. Severity becomes visually scannable in seconds rather than reading each line for context.

## 2026-05-04 (session 36)

**Tip: Use `/review` to get a multi-agent code review of your current branch without leaving Claude Code**
`/review` spawns several parallel review agents, each reading the branch changes from a different angle (logic, security, style). The findings come back as a structured report with file:line references. Faster and cheaper than asking Claude to review a diff inline — no main context bloat, independent perspective.

**Tip: Prefix a prompt with `think` or `think hard` to trigger extended reasoning before Claude answers**
For architectural decisions, subtle bugs, or any question where a fast answer is likely to be wrong, start your message with "think:" or "think hard:". Claude reasons through the problem explicitly before producing output — catches edge cases and tradeoffs that a direct answer skips. Reserve it for genuinely hard problems; it costs more tokens than a normal reply.

## 2026-05-04 (session 35)

**Tip: When you find a pattern bug in one item, immediately ask "are there similar cases?" for all of them**
When a remove/install button has no visible effect, check whether the label is `self.label` or just a local in `gui()`. Locals are out of scope in callbacks. Ask "and blueberry? and blueman?" in sequence (or all at once) — same fix applies. Naming each case separately costs 3× as many messages as one sweep.

**Tip: The root cause of "button has no effect on the label" is almost always scope, not logic**
If a callback doesn't update the UI, the first thing to check is whether the label variable is `self.label` or a local in `gui()`. Locals are invisible to callbacks. Fix: promote to `self.*` in the GUI file, then reference `self.*` in the callback. This pattern repeats across every GTK GUI file.

## 2026-05-04 (session 32)

**Tip: Use `#` to inject file context directly in Claude Code chat**
Type `#` followed by a filename in the chat input to attach that file's content inline. Claude receives it immediately without a separate read step — zero extra tool cost and faster responses.

**Tip: Scope prompts to one module at a time for large codebases**
Asking "fix all issues in desktopr.py" costs far fewer tokens than "fix all issues across the project" and produces more accurate results. Smaller scope = higher precision + lower cost. Chain single-module prompts rather than batching everything.

## 2026-05-03 (session 31)

**Tip: Use `claude --print` for quick one-off script audits**
Run `claude --print "check this script for permission issues" < script.sh` to get a fast non-interactive analysis without opening a full session. Good for CI or pre-commit hooks.

**Tip: Highlight code in VSCode before typing your request to scope Claude's edit precisely**
When you select a function (or any block) in the editor before sending your message, Claude receives the selection as context. Combine this with a specific instruction ("add an SSH check similar to the GPG one") and Claude edits exactly that block without guessing scope from the broader file.

## 2026-05-03 (session 28)

**Tip: Name GTK widgets with `set_name()` for surgical CSS targeting**
`widget.set_name("my_id")` lets you write `#my_id` selectors in GTK CSS, giving you precise control over one widget without affecting others of the same type. Useful for one-off style overrides (e.g. a single dropdown that needs different popup height) without broad side-effects.

**Tip: GTK4 dropdown popup height is CSS-controlled, not Python API**
There is no Python method on `Gtk.DropDown` to control how many rows the popup shows. Override it in CSS via the `popover scrolledwindow` node: `#my_dropdown popover scrolledwindow { min-height: 520px; }`. `min-height` is the reliable lever; `max-height: none` has no effect in GTK CSS.

## 2026-05-03 (session 26)

**Tip: When a switch/button has no effect, trace the full call chain before assuming a GTK bug**
"The switch doesn't do anything" usually isn't GTK — it's a disconnect between the callback and the underlying helper. Trace: widget connect → callback function → helper call → what the helper actually dispatches on. In this session, `toggle_test_repos` dispatched on string keys (`"community-testing"`, `"community"`) but the callback passed `"extra-testing"` — a key that silently matched nothing. Grep the helper for your key string before assuming the write is failing.

**Tip: When removing a function, scope the deletion to exactly what was asked — don't cascade into the GUI**
If the user asks to remove `on_pacman_toggle5`, remove only that function (and its direct connect call). Do NOT also remove the widget, the layout row, and the lazy-load set_active — those may still be needed connected to a different handler. Always confirm scope before touching more than the named symbol.

## 2026-05-03 (session 23)

**Tip: Before implementing new functionality, grep the existing codebase — it may already be there**
When adding a feature (e.g. Chaotic AUR toggle), search for the relevant keywords first (`grep -rn "chaotic" *.py`). In this session the full implementation — switch, callback, `ensure_chaotic_packages`, `is_chaotic_aur_enabled` — was already in `pacman.py`/`pacman_functions.py`/`pacman_gui.py`. Reading before writing avoids duplicating logic in the wrong file entirely.

**Tip: Keep signing steps even when bundling packages locally — `pacman -U` still verifies signatures**
When switching from downloading packages to using locally bundled `.pkg.tar.zst` files, the `pacman-key --recv-key` / `--lsign-key` steps remain necessary. `pacman -U` checks the package's own signature before installing it; without the signing key trusted locally, the install will fail regardless of where the file came from.

## 2026-05-03 (session 22)

**Tip: Read dead code before deleting it — it may be hiding a real bug above it**
When Claude flags unreachable code (a line after `return None`, a block that's never appended), read what it *would* have done before removing it. In this session, a `show_in_app_notification` was dead after a `return None` — moving it before the return revealed that the `except` block was already catching a real silent failure (`pacman -Qo` always failing in pkexec context). Dead code isn't always wrong logic; sometimes it's the only clue that something above it is broken.

**Tip: Use `pacman -Q <name>` over `pacman -Qo <path>` for package detection in elevated processes**
`pacman -Qo /usr/bin/yay` does a reverse file→package lookup and can fail silently when run under pkexec or sudo environments. `pacman -Q yay-git` queries by name directly and is always reliable. When you know the expected package name variants (git, bin, bare), iterate through them — it's more explicit, faster, and never breaks due to permission context.

## 2026-05-03 (session 21)

**Tip: Use `/compact` mid-session when you've loaded many large files**
Typing `/compact` compresses the conversation history while preserving key facts and decisions. This cuts context-window cost for the rest of the session without losing important context. Use it after a bulk file-read phase (e.g. after a flake8 pass over 10 files) before switching to a new task.

**Tip: Run `grep -rn "pattern" *.py` yourself for simple lookups — don't spawn an agent for it**
For single-pattern searches ("find all arco refs", "find all subprocess.call usages"), run the grep yourself in the terminal and paste the output. It's instant, free, and Claude can work from your paste directly. Spawning an Explore agent is the right call only when the search spans many directories or needs interpretation — not for a one-liner grep you already know how to write.

## 2026-05-01 (session 1)

**Tip: Use /init at project start to auto-load architecture context**
Running `/init` generates a focused CLAUDE.md that future sessions load automatically. You never have to re-explain the codebase structure or conventions. Think of it as amortized context cost — pay once, benefit every session.

**Tip: Ask questions before issuing commands to avoid expensive backtracking**
For exploratory questions ("how does X work?", "what approach should I take?"), phrase them as questions rather than commands. Claude gives a recommendation + tradeoff in 2–3 sentences at near-zero cost, versus jumping straight to implementation and then backtracking if the direction was wrong.

## 2026-05-01 (session 3)

**Tip: Use git log + diff to brief Claude at session start instead of re-explaining**
Instead of typing "here's what I changed recently", just run `git log --oneline -10` and `git diff HEAD` in the chat or let Claude read them. Claude reconstructs full context from the diff — no prose summary needed. This saves tokens and avoids the drift that happens when your verbal summary doesn't match what's actually in the code.

**Tip: CLAUDE.md rules are re-read every session — use them to encode permanent decisions**
Any preference you've had to correct Claude on more than once belongs in CLAUDE.md as an imperative, not in a chat message. Chat corrections last one session; CLAUDE.md corrections last forever. Examples: "never use subprocess.call()", "always run flake8 before finishing Python work", "never commit without being asked."

## 2026-05-01 (session 4)

**Tip: /init should always be paired with a CHANGELOG.md check**
Running `/init` generates a CLAUDE.md for the repo. At the same time, check whether a CHANGELOG.md exists — if not, create one (global rules require every project to have one). Both files serve as session-persistent context: CLAUDE.md for architecture, CHANGELOG.md for what changed and why.

**Tip: Ask multiple independent questions in one message to get parallel reads**
When you have several unrelated questions (e.g. "what does file A do, what does file B do"), put them in a single message. Claude parallelizes independent reads and tool calls within one turn — asking them separately means waiting for each round-trip in sequence, which is significantly slower and more expensive.

## 2026-05-01 (session 5)

**Tip: Use plan mode before any change that's hard to reverse**
Trigger `/plan` (or enter plan mode) before changes touching more than 2 files or with irreversible side effects. Claude shows exactly what it intends to modify and why before touching anything. For long build pipelines like kernel compilation, a wrong config change means an hour of wasted time — plan mode eliminates that entirely.

**Tip: /init creates instant architectural context for any repo, not just your own**
When dropped into an unfamiliar repo (upstream source, a colleague's project, a dependency you need to patch), run `/init` first. Claude reads the code and produces a focused CLAUDE.md in under a minute — faster and more accurate than reading READMEs yourself, and it persists for every future session in that repo.

## 2026-05-01 (session 6)

**Tip: Use /init early on any Calamares or installer config repo — the pipeline order matters most**
For installer configs like Calamares, the execution sequence in `settings.conf` is the most critical thing to understand. Paste the sequence into a CLAUDE.md and Claude won't have to rediscover it by tracing 20+ module files each session. One-time read, permanent context.

**Tip: Anchor Claude to your actual return convention before asking it to modify Python modules**
If your modules use a non-standard return pattern (e.g. `None` on success, `(title, message)` tuple on error), include one example in your first message. Claude has no live framework docs, so without this anchor it will invent a plausible-looking but wrong API. A single concrete example is faster than correcting broken code.

## 2026-05-01 (session 7)

**Tip: Use `subagent_type: "Explore"` to analyze many files without polluting your context window**
When Claude needs to survey a codebase (find a pattern, map all callers, understand structure), spawn an Explore agent via the Agent tool. It reads excerpts across files and returns a clean summary — your main context stays focused on the actual work rather than accumulating raw file dumps.

**Tip: Give Claude the target glob when making batch edits across many files**
For repetitive changes across a directory (e.g. "add this line to every script in `usr/local/bin/`"), specify the exact file pattern upfront rather than asking Claude to discover scope first. This skips a slow exploration phase and gets directly to editing — cutting both latency and token cost.

## 2026-05-01 (session 8)

**Tip: /init uses an Explore subagent — you don't pay context cost for the file scan**
When you run `/init`, Claude spawns an Explore agent to survey the repo. That agent's full output (hundreds of lines of file reads) never lands in your main context window — only the summary comes back. This makes `/init` cheap to run even on large repos with many config files.

**Tip: Write CLAUDE.md `## Key config notes` sections for non-obvious values**
Config repos like dotfiles often have intentional-looking "mistakes" (e.g. `vm.swappiness = 100` for ZRAM, a disabled udev rule, a repo that requires a GPG key pre-installed). Document these in CLAUDE.md as explicit notes so Claude never "fixes" them. Without this, Claude treats surprising values as bugs to correct.

## 2026-05-01 (session 9)

**Tip: Use both global and project CLAUDE.md — Claude reads both, project overrides global**
Keep universal preferences in `~/.claude/CLAUDE.md` and repo-specific context (frozen files, package names, current milestone) in the project's `.claude/CLAUDE.md`. Claude reads both every session; project rules take precedence. This avoids cluttering global config with context that only matters in one repo.

**Tip: Ask "what do you remember about me?" at session start to verify memory loaded correctly**
Memory files can be missing or stale. A quick check before real work confirms Claude has the right context — prevents silent drift where Claude gives subtly wrong advice because it's missing a key constraint from a prior session.

## 2026-05-01 (session 2)

**Tip: Global vs project CLAUDE.md — know what belongs where**
The global `~/.claude/CLAUDE.md` is loaded in every conversation across all projects. Keep it focused on who you are, cross-project preferences, and universal code style rules. Project-specific conventions (GTK4 callback patterns, frozen file lists, module architecture) belong in the project's own `CLAUDE.md`. Mixing the two bloats the global file and dilutes the signal.

**Tip: Treat CLAUDE.md as executable spec, not documentation**
Claude reads CLAUDE.md before every session and acts on it literally. Write rules as imperatives ("always run flake8 before considering Python work done", "never touch frozen files without confirmation") rather than descriptions ("we use flake8"). The more specific and action-oriented the rule, the more reliably it is followed — vague guidelines get interpreted loosely.

## 2026-05-02 (session 10)

**Tip: Map objectives to concrete checklist items to avoid missing work at release time**
When a project has a numbered objectives list (like ATT's 25 developer objectives), convert the high-level ones into a checklist before final release. Objectives 11–24 often hide concrete tasks (data migration, lint passes, dead code removal) that don't appear in the task list. A quick grep of CLAUDE.md objectives against git status catches incomplete work that would otherwise slip through the cracks.

**Tip: Run flake8 with `--select=F401` to isolate unused import cleanup**
When fixing unused imports across a large codebase, don't run full flake8 (E402, E128 noise clutters the signal). Instead, run `flake8 --select=F401 *.py` to see only unused imports. This isolates the actionable signal from style preferences and intentional patterns, making batch cleanup faster and more reliable.

## 2026-05-02 (session 10 - continued)

**Tip: In utility modules, always grep for actual usage before removing F401-flagged imports**
Utility modules like `functions.py` often intentionally re-export standard library imports so dependent code can access them via the central module's namespace (e.g., `fn.getpid()` instead of importing `os.getpid` everywhere). Flake8 sees "not used in this file" and flags them as F401, but they're actually critical re-exports. Before removing any F401 from a central utility, grep first: `grep -rn "fn\.IMPORTNAME"`. If found, restore with `# noqa: F401` to mark it as intentional.

## 2026-05-02 (session 11)

**Tip: Trust tested commands over theoretical solutions—validate user test cases before refactoring**
When a user says "this command works" and provides test output, use that as ground truth before making code changes. Theoretical improvements (like switching from `-Rs` to `-Rdd` for safety) may not be needed if the actual tested case is already correct. This prevents unnecessary rewrites and maintains code simplicity — keep what works.

**Tip: Use `python3 -c "import module; print('✓')"` to validate imports without launching the full app**
Full GTK apps won't run headless, but imports can be tested instantly with a one-liner. This catches syntax errors and missing dependencies in seconds without needing X11, a display, or any GUI dependencies. Much faster than trying to launch the app.

## 2026-05-02 (session 12)

**Tip: Ask "where exactly?" when spatial instructions are ambiguous — don't guess on UI layout changes**
When instructions involve moving UI elements ("move it up", "put it after X"), ask for confirmation of exact position rather than guessing. A single clarifying question ("do you mean two hbox levels up, or something else?") prevents multiple reverts that waste your time and tokens. Spatial edits are easy to get wrong; clarification is cheap.

**Tip: Always review current file state before editing multi-part UI structures**
GTK layouts with multiple hbox containers can break easily if you change one part without checking dependencies (like vboxstack3.append calls that reference the hbox). Read the full surrounding context before editing — the 30 seconds of extra reading prevents 5 minutes of revert cycles when append statements reference removed or renamed containers.

## 2026-05-03 (session 13)

**Tip: Encode UI layout standards as CLAUDE.md rules, not just one-off corrections**
When you correct an inconsistency (e.g. a page using plain text where others use bold markup for section headers), capture the canonical pattern as a numbered objective in CLAUDE.md immediately. Chat corrections apply only to the current session; CLAUDE.md rules apply to every future change on every page. A one-line rule prevents the same drift from appearing on the next page someone edits.

**Tip: Check cross-page consistency before declaring a UI feature "done"**
When you finish styling one page, grep the same pattern across all *_gui.py files to see if other pages are inconsistent. For example, `grep -rn "set_text" *_gui.py` reveals which pages are still using plain text where bold markup is expected. Catching drift at review time — not during user testing — is far cheaper.**

## 2026-05-03 (session 14)

**Tip: State your intent before editing files — "approve?" forces a useful confirmation checkpoint**
When Claude says "here's exactly what I'll change — approve?" before touching any file, it costs nothing and catches misunderstood requirements before any code is written. Encode this as a CLAUDE.md rule ("state exactly what you intend to change and why, then wait for approval") and Claude will apply it automatically every session — no need to remind it each time.

**Tip: Highlight code in VSCode before asking a question — Claude sees your selection automatically**
The Claude Code VSCode extension includes your active editor selection in conversation context. Instead of pasting a function into chat, just select it in the editor and ask your question — Claude already has it. This saves copy-paste friction and keeps the conversation shorter, especially for targeted questions about a specific function or block.

## 2026-05-03 (session 15)

**Tip: Use /ultrareview before milestone commits for independent multi-agent review**
`/ultrareview` spawns a separate review agent that reads your current branch without any of your session's context or bias — genuinely independent eyes. Use it before closing out a milestone (M3 lint pass, M4 feature tests) to catch issues you've normalized during the session. It's billed separately but cheaper than shipping a broken tab.

**Tip: Switch to Haiku for fast lookups — save Sonnet tokens for real reasoning**
For quick questions ("what does this flake8 code mean?", "what's the pacman flag for dependency removal?"), switch model with `/model haiku` in Claude Code. Haiku answers factual lookups in under a second at a fraction of the cost. Switch back to Sonnet (`/model sonnet`) when you need multi-file reasoning. This is the most direct way to control session cost.

## 2026-05-03 (session 17)

**Tip: Use `/review` before testing a tab — let Claude spot broken widget refs before you launch the app**
Run `/review` on a GUI file before doing a live test. Claude catches broken `self.` attribute references, missing callback `_widget` params, and wrong `set_markup`/`set_text` calls before you open a terminal. One pass costs a few seconds; a launch-crash-fix cycle costs several minutes.

**Tip: Scope prompts to one file at a time for precise answers**
"Check fastfetch_gui.py for issues" gives precise answers with line numbers. "Check all GUI files" produces diluted, high-level findings that miss specific bugs. Tighter scope = better signal at lower token cost. When you need cross-file analysis, use a subagent via the Agent tool so your main context stays clean.

## 2026-05-03 (session 18)

**Tip: When a fix doesn't work, point Claude to a working example in the same codebase**
Instead of re-explaining the problem ("the terminal still hangs"), say "check what you did in the install switch and do similar." Claude reads the working code, finds the pattern, and applies it exactly — no guesswork about what "similar" means. One sentence beats a paragraph of description.

**Tip: Don't hand-roll subprocess scripts when a tested helper already exists in functions.py**
Before writing a custom `Popen` + bash script inline, grep `functions.py` for a matching helper (`launch_pacman_install_in_terminal`, `launch_pacman_remove_in_terminal`, etc.). These helpers already handle temp-file logging, success/failure messages, and the `read -p` prompt correctly. Using them prevents the exact pipe-deadlock bug that hand-rolled scripts tend to introduce.

## 2026-05-03 (session 19)

**Tip: Use /plan before running scripts that modify system state (chroot, pacman, nspawn)**
Chroot and arch-nspawn operations modify persistent directories on disk. Type `/plan` first so Claude shows the exact sequence of `sudo` commands and affected paths before any shell invocation. A wrong `rm -rf` on a chroot directory costs 15+ minutes of rebuild time.

**Tip: Paste a shell error directly without explanation — Claude reads stderr and infers full context**
When a script fails, paste the raw terminal output directly into chat without preamble. Claude reads the failing command, exit code, and path from the error text — no description needed. Describing the error in prose is slower and often omits the exact detail Claude needs to diagnose it.

## 2026-05-03 (session 20)

**Tip: Use `/cost` to check token usage mid-session.**
Typing `/cost` in the Claude Code prompt shows cumulative input/output tokens and estimated cost for the current session. Useful for catching runaway context before it gets expensive.

**Tip: Scope your reads with `offset` + `limit` to avoid burning context on large files.**
When you know roughly where something is (e.g. "the main() function is around line 80"), pass `offset` and `limit` to the Read tool instead of loading the whole file. Cuts token cost significantly on long scripts.

## 2026-05-03 (session 25)

**Tip: Use `/fast` to toggle faster output on Claude Opus 4.6**
Typing `/fast` in Claude Code switches to Fast mode — same Opus 4.6 model, faster output. Use it for flake8 passes, quick edits, or any task where you're waiting on output speed rather than deep reasoning. Toggle it off again for complex multi-file planning. No model downgrade, just output pacing.

**Tip: Use the `schedule` skill to set up one-time or recurring remote agents**
`/schedule` creates cron-based routines that run Claude Code agents even when your terminal is closed. Useful for things like "run flake8 on this project every Monday" or "check the build status at 3pm". The agents run remotely and report back — you don't need to be present. Much more reliable than leaving a loop running in a terminal.

## 2026-05-03 (session 24)

**Tip: Use `/compact` when switching tasks mid-session — it clears accumulated file reads from context**
After a bulk read phase (reading a script, several GUI files, or a large CHANGELOG), type `/compact` before switching to a new unrelated task. It summarizes what was important and drops the raw file content, keeping the next task's context clean and cheap.

**Tip: Paste a script and ask "what does this do?" before asking for changes — intent mismatches surface instantly**
For shell scripts especially, "what does this do?" costs one message and catches intent drift (e.g. version-checking logic when you just want a download). Correcting the intent before writing anything is far cheaper than reverting generated code.

## 2026-05-03 (session 16)

**Tip: Use "plan it out — then summarize and ask to proceed" to make Claude a reviewer, not just an executor**
Phrasing a request as "plan it out first" forces Claude to show the exact files and lines it intends to change before touching anything. This gives you a free review step — you can redirect, reject, or refine before any code is written. The cost is one extra message; the benefit is no unexpected side effects.

**Tip: Check if source files already exist in your settings tree before writing them manually**
When adding a new config file deployment to a script, Claude can verify the source path first (e.g. `find personal/settings/systemd -type f`). In this session, `restart-on-failure.conf` was already present at the expected path — no manual write needed. A one-second find prevents a duplicate write and a confusing diff.

## 2026-05-03 (session 29)

**Tip: Use `/review` on a GUI file after a rename pass to catch missed references**
After renaming widgets (`hbox3` → `hbox_title`), run `/review` on the file before testing. Claude catches any stray references to the old name that weren't updated in the same edit — especially `self.*` attributes that are set in one place but read in callbacks. One pass costs seconds; a GTK `AttributeError` at runtime costs a full relaunch cycle.

**Tip: Before editing a widget file, check every created widget is actually appended**
When reading a GTK GUI file, grep for `= Gtk.Box(` and then verify each variable name appears in an `append()` call. Widgets that are created but never appended are invisible dead code — they cost memory and confuse future readers. In this session, `self.hbox26` was created on line 93 but never appended anywhere. Always remove these in the same pass as any naming cleanup.

## 2026-05-03 (session 30)

**Tip: Use `#` at the start of a message in Claude Code to leave a note without triggering a response**
Prefixing a message with `#` tells Claude Code to treat it as a comment — it logs to context but Claude doesn't act on it. Handy for dropping a breadcrumb mid-session ("# next: test on Wayland") without burning tokens on a reply you don't need.

**Tip: Pre-load all hover-state assets at startup and cache them — never decode from disk inside a mouse event**
For GTK4 apps that swap icons on hover, loading SVGs inside `on_mouse_in`/`on_mouse_out` blocks the main loop every single event. Instead, load all normal + blur textures once in a background thread at startup (`_load_pixbufs_async`), store them as `self._textures["shutdown_blur"]` etc., then hover handlers just call `widget.set_paintable(self._textures[key])` — zero file I/O, zero rasterization on hover.

## 2026-05-04 (session 34)

**Tip: Use `/review` instead of "read X" when your goal is code review**
Asking Claude to "read pacman pages" dumps raw file content into your context window — expensive and unstructured. `/review` spawns a dedicated review agent that reads the same files, identifies actual issues with file:line references, and returns a structured report without bloating your main context. One command, better signal, lower cost.

**Tip: When you spot a scope/bug in one function, ask "are there similar cases?" before fixing just that one**
Pattern bugs (e.g. a `self` reference out of scope, a missing `_widget` param, a bare `&` in markup) almost always appear in more than one place. Ask "grep for similar patterns across *.py" first — Claude finds all instances in one pass. Fixing them together costs one session; discovering them one-at-a-time costs five.

## 2026-05-04 (session 33)

**Tip: Use `/review` on a multi-page PR to get a split by reviewer role — security, logic, style**
When reviewing changes across several files, `/review` spawns parallel agents each focused on a different dimension. You get targeted findings per role rather than one generic pass. More signal per token than asking "does this look good?"

**Tip: Paste just function signatures (not bodies) to get architectural overview at low cost**
For a long callback file you need to understand quickly, paste only the `def` lines and ask "which of these might have side effects on system state?" You get an architectural map at a fraction of the token cost of sending full function bodies.

## 2026-05-03 (session 27)

**Tip: Ask for options before asking for implementation — "give me options" costs one message**
For any output that's subjective (label text, error messages, UI copy), ask "give me options" first. Claude presents 3–5 variants at near-zero cost, you pick one in a single word, then Claude implements. Today's phrasing question is the exact pattern — faster and cheaper than generating and revising implementation.

**Tip: Use `fn.log_info` (not `print`) for startup messages so they appear in the in-app log too**
ATT has dual logging: `print()` goes to console only; `fn.log_info/log_success/log_warn` goes to both console and the in-app notification area. For any startup hint or status line that a user should see while running ATT without a terminal, always use the `fn.log_*` family — `print()` is invisible inside the app.

**Tip: GLib.idle_add with return False runs your callback exactly once after the main loop starts**
When you need a GTK dialog or notification to appear only after the window is fully rendered, wrap it in `GLib.idle_add(func)` where `func` returns `False`. Returning `False` tells GLib not to repeat the callback — returning `True` (or a truthy value like a tuple) would keep re-firing it on every idle cycle.

**Tip: Scope Claude's context by opening only relevant files in VSCode before starting a session**
Claude sees your open files via `ide_opened_file` events. Opening only the files relevant to the current task (e.g. kernel_gui.py + kernel.py for kernel work) helps Claude zero in immediately without broad codebase searches, saving tokens and producing more focused responses.

## 2026-05-05 (session 57)

**Tip: Use `/review <page name>` to catch install/uninstall pattern violations before testing**
Asking `/review maintenance page` surfaces broken patterns (direct Popen in callback, premature set_sensitive, missing remove guard) with exact line numbers — faster than launching the app and watching a button misbehave. One review pass before a test run catches three class of bugs at once: threading, timing, and guard logic.

**Tip: When `fn.install_package()` is async, never call `set_sensitive()` immediately after it**
`fn.install_package()` spawns a daemon thread + terminal and returns immediately. Any `set_sensitive(True)` call on the next line fires before the package is installed. The fix is to inline a daemon thread that calls `.wait()` on the Popen and only then calls `GLib.idle_add(widget.set_sensitive, True)` — this is the Bibata pattern already in maintenance.py.

## 2026-05-05 (session 56)

**Tip: Use `/ultrareview` for multi-file architecture decisions**
`/ultrareview` spins up a cloud-based multi-agent review of your branch. For anything touching 5+ files or introducing a new pattern, it gives independent, thorough coverage that inline review misses — each agent reads from a fresh perspective. User-triggered and billed separately; costs less than shipping a broken pattern.

**Tip: Scope prompts to one file at a time for large codebases**
"Fix the aider install in ai.py" gets a precise, reviewable diff. "Fix all install patterns" risks a large change you can't easily audit. Narrow prompts = smaller diffs = easier `git blame` later. Chain single-file prompts rather than batching.

## 2026-05-05 (session 55)

**Tip: Use `/review` before `/simplify` on permission-related code — correctness beats cleanliness**
`fn.permissions(fn.fish_config)` looks correct but silently leaves the parent directory root-owned when `makedirs` just created it. `/review` catches this class of "right call, wrong target" bug; `/simplify` won't. For any code that calls `chown`, `chmod`, or `makedirs` as root, run a review pass focused on "what exactly is being chowned and is it enough?" before shipping.

**Tip: Scope your question to one function to get a root-cause diagnosis, not a symptom report**
Instead of "why does fish have permission errors?", ask "in `on_install_att_fish_config_clicked` in shell.py, does `fn.permissions()` on line 124 chown the directory that `makedirs` just created?" — one function, one line, one yes/no question. Claude reads exactly that and gives a definitive answer at minimal cost, rather than scanning the whole file for permission-related patterns.

## 2026-05-05 (session 54)

**Tip: Use Pango `<big>` for a one-step font bump in GTK labels — no Python API needed**
`label.set_markup("<big><b>text</b></big>")` bumps the font up one step using Pango markup alone. For more control, use `<span size="large">` (values: `xx-small` → `xx-large`). No need to touch CSS or GtkCssProvider for simple size tweaks on individual labels.

**Tip: Highlight code in VSCode before sending your request — Claude receives the selection automatically**
The Claude Code VSCode extension injects your active editor selection as `<ide_selection>` context. For targeted edits like changing a label property, select the exact lines and ask — Claude edits precisely that block without scanning the rest of the file. One-word confirmations ("y") work because Claude carries the full prior context.

## 2026-05-04 (session 53)

**Tip: When writing a post-install refresh closure, grep `self\.` in the file to find every widget that reflects the changed state**
A refresh closure that only updates button visibility often misses other widgets — dropdowns, labels, entry sensitivity — that also depend on whether a package is installed. After writing the refresh block, run `grep "self\." <file> | grep -i theme` (or the relevant keyword). In this session `self.theme_sddm` was the missing piece: installed themes appear in a `Gtk.DropDown` that was never repopulated after install/remove.

**Tip: Refreshing a `Gtk.DropDown` model requires a splice-clear then re-populate — toggling visibility alone is not enough**
`widget.set_visible(True)` only shows a stale list. To reflect filesystem changes, call the populator helper inside `GLib.idle_add(refresh)`: `pop_theme_box(self, self.theme_sddm)`. The helper clears the model with `m.splice(0, m.get_n_items(), [])` and rebuilds from disk — this is the only way the user sees the newly installed or removed item in the list.

## 2026-05-04 (session 52)

**Tip: Grep for `GLib.idle_add\|wait_and_refresh\|process.wait` to map every post-terminal-close refresh hook**
When debugging "why doesn't X update after Y action?", this single grep across the codebase shows every place where a terminal close triggers a UI refresh. You can see at a glance what's wired up and what's missing — in this session it revealed that desktopr refreshes its own status label but never notifies themer to repopulate WM dropdowns.

**Tip: Use `/review` on a source file before implementing a cross-module change — it surfaces startup-only init patterns**
Running `/review` on `themer_gui.py` before writing a refresh hook would have shown that all WM dropdowns are populated once at startup, guarded by `check_package_installed()`, with no on-demand path. Knowing that upfront lets you design the right fix (a `refresh_themer_dropdowns()` call in desktopr's post-install hook) instead of discovering the gap mid-implementation.

## 2026-05-04 (session 51)

**Tip: Prefer `XDG_SESSION_TYPE` over `loginctl` parsing for session detection in bash scripts**
`XDG_SESSION_TYPE` is set by the display manager at login and is always a single, clean string. `loginctl` output is tabular and breaks when a user has multiple active sessions — the `awk '{print $1}'` approach returns multiple IDs that cause "No session 'X Y' known" errors. Use `XDG_SESSION_TYPE` as primary; fall back to loginctl only as a last resort, with `| head -1` to guard against multi-session users.

**Tip: Paste `filepath:linenum` in chat to point Claude at an exact line without any preamble**
Instead of saying "line 45 of the launcher script has a problem", type `usr/bin/archlinux-tweak-tool:45` directly in your message. Claude recognizes the pattern, reads that file at that line, and starts from exactly the right context — no broad file scan, no asking which file you mean. Works for any language file Claude can read.

## 2026-05-04 (session 50)

**Tip: Name the pattern you want to match, not just the problem — Claude implements faster when you reference existing code**
Instead of "fix the system page to check if fzf is installed", say "make system.py match the check-and-bail pattern already in log_callbacks.py". Claude reads the reference, extracts the exact pattern, and applies it consistently across all 14 callbacks in one pass — no back-and-forth on what the pattern should look like.

**Tip: One-word answers work — Claude reads confirmation from context**
After Claude states an exact plan ("I'd change X to Y in file Z — shall I?"), a single "y" is enough. Claude carries full context from the prior message. You don't need to re-explain or confirm details. Saves keystrokes and keeps the session moving without extra round-trips.

## 2026-05-05 (session 52)

**Tip: Use `/ultrareview` after multi-file edits across separate repos**
When you change the same logical thing in two repos at once (source tree + live config), `/ultrareview` can verify both sides are consistent and nothing was missed — catches drift before it becomes a support bug.

**Tip: Highlight the broken line before asking "why is X wrong?" — Claude sees your selection**
The VSCode extension sends your IDE selection as context. Selecting the rofi font line before asking why icons render wrong would have let Claude spot the `DejaVu Sans Mono` mismatch immediately, without a multi-step grep hunt through the project. Zero extra tokens, instant root cause.

**Tip: Mechanical bulk changes belong to Claude, not manual edits**
When the same value (like a separator width) needs updating across many files, tell Claude "change X to Y across all files that use it." Claude greps to find every occurrence, then applies all edits in one shot with sed -i — faster and less error-prone than editing file by file yourself.

**Tip: Ask "where is X used?" before opening files**
For exploratory questions like "did we remove X?" or "where is Y defined?", ask Claude directly — it greps the codebase instantly and reports back. No need to open files or search manually in VSCode. Save file-opens for when you actually need to read or edit the content.

## 2026-05-07 (session 71)

**Tip: Reference tutorial.md when you're unsure how to phrase a request — it's indexed by goal, not topic**
The tutorial at `~/.claude/tutorial.md` is organized by *what you're trying to do* (exploratory question, precise edit, cost optimization) not by tool type. When you think "how should I ask Claude this?" instead of reading 85+ scattered tips, open the tutorial and jump to the matching goal section. It's faster and cuts context-switching time in half.

**Tip: Batch independent reads + questions into one message to parallelize work**
Instead of "read file A / what's the error in B / check if C exists" in three messages, ask all three at once: "read file A, diagnose this error in B, check if C exists." Claude parallelizes independent reads within one turn — asking sequentially means waiting for each round-trip, which is significantly slower and costs more tokens. Batch when questions don't depend on each other; sequence only when the second question needs the first answer.

## 2026-05-06 (session 70)

**Tip: Use `{ cmd1 && cmd2; } || cmd3` when you need OR against a compound AND in bash**
Without the curly braces, `cmd1 && cmd2 || cmd3` only falls through to `cmd3` when `cmd2` fails — if `cmd1` fails, the shell short-circuits at `&&` and `cmd3` never runs. Wrapping the AND chain in `{ ...; }` makes both halves of the `||` explicit. This came up in `is_omarchy()`: `{ grep check && grep -qi; } || [[ -f marker ]]` is correct; the braceless form silently skips the marker check when plymouthd.conf is missing.

**Tip: Use a marker file (`/etc/att/att-<name>-marker`) to let handle.sh detect ATT-tagged distros without Python or X11**
ATT can write a zero-byte file like `/etc/att/att-omarchy-marker` after confirming a distro. Then `handle.sh` checks `[[ -f /etc/att/att-omarchy-marker ]]` — no plymouth service, no Python subprocess, no GUI session required. This pattern decouples distro detection from runtime environment: scripts that run at boot or in chroot get a reliable `is_omarchy()` signal without any display dependency.

## 2026-05-06 (session 69)

**Tip: Use Plan Mode for codebase-wide naming convention changes — Explore agents inventory ALL occurrences before you touch anything**
When a rename spans 10+ files (e.g. `.bak` → `-bak`), enter plan mode and spawn an Explore agent with "find every occurrence of X in all .py files and categorise by HOME vs SYSTEM path." You get a complete table of file:line references. You verify scope before a single edit, and nothing is missed because you counted wrong mid-way through.

**Tip: In the Edit tool, do `replace_all=True` on the suffix first, then a second pass for mid-string occurrences**
`replace_all=True` on `".bak"` → `"-bak"` (with the quotes as part of the match string) handles all Python string-literal patterns in one shot — both `+ ".bak"` concatenations and `"/etc/hosts.bak"` literals. A second `replace_all` on `.bak` (with trailing space) catches the same token mid-string (in debug messages). Two targeted passes replace 30+ individual edits with zero risk of a missed instance, and unlike sed, the Edit tool errors if the old string doesn't exist.

## 2026-05-06 (session 68)

**Tip: Use `["su", "-", fn.sudo_username, "-c", "tool"]` to launch user-space tools from a root process**
When ATT runs under pkexec/sudo and needs to launch a tool that reads `~/.config/` (like powermenu, rofi, or any XDG-aware binary), `Popen("tool &", shell=True)` runs as root — the tool sees root's home and misses the user's config. Use `["su", "-", fn.sudo_username, "-c", "tool"]` instead: the `-` flag creates a full login shell for the real user, setting `$HOME`, `$PATH`, and `$XDG_*` correctly. No `shell=True` needed.

**Tip: After installing a package that stores its config in `/etc/skel/`, copy it to `$HOME` with correct ownership**
Packages like `edu-powermenu-git` install their default config under `/etc/skel/.config/<tool>/`. The user's own `~/.config/<tool>/` must be populated before the tool can run. In the post-install `wait_install()` thread, check `fn.path.exists(skel_src) and not fn.path.exists(user_dst)` then `fn.shutil.copytree(skel_src, user_dst)` followed by `fn.permissions(user_dst)`. The existence check prevents overwriting user customizations on re-installs.

## 2026-05-06 (session 67)

**Tip: Replace `Gtk.Picture` with a CSS-colored box when you need a truly fixed-height bar**
`Gtk.ContentFit.CONTAIN` scales the image to maintain aspect ratio — a 500×25 image in a 1456px-wide window grows to ~70px tall. No amount of `set_size_request` fixes that because the picture's natural size grows with the window width. The real fix: drop the picture entirely, use a `Gtk.Box` with `add_css_class()` and a one-line `Gtk.CssProvider` with `background-color`. Then `set_size_request(-1, 30)` actually pins the height because nothing is fighting it.

**Tip: `set_size_request` in GTK4 sets a minimum, not a maximum — pair with `set_vexpand(False)` and remove any expanding child**
A widget with `set_size_request(-1, 25)` can still receive more allocation if its parent gives it extra space or if a child reports a larger natural size. To truly pin the height, you need three things: `set_size_request(-1, N)`, `set_vexpand(False)`, AND no child widget whose natural height exceeds N. If a child (`Gtk.Picture`, `Gtk.Overlay`) reports a taller natural size than your target, the widget grows regardless of the size_request.

## 2026-05-06 (session 66)

**Tip: Fake a desktop environment with `XDG_CURRENT_DESKTOP=X` to test conditional UI without switching DEs**
`sudo XDG_CURRENT_DESKTOP=GNOME python3 archlinux-tweak-tool.py` makes ATT think it's running on GNOME — any widget guarded by `should_show_picker()` hides instantly. No VM, no re-login. Works for any env-var-driven guard in ATT: test the "full DE" path and the "WM" path in seconds by changing one env var at launch.

**Tip: Use a frozenset + `any()` for multi-desktop hide logic — never a long elif chain**
`return not any(name in desktop for name in _HIDE_PICKER_DESKTOPS)` with a `frozenset(["gnome", "kde", ...])` constant is O(1) lookup and one line of logic. Adding a new desktop to the hide list is a one-word edit to the constant — not a new elif branch. More importantly, the constant is self-documenting: the whole policy is visible in one place, not scattered across a chain of string checks.

**Tip: Say "just for me" to get leaner, more direct code**
When you tell Claude a script or tool is only for your own use, it skips generalization, defensive edge-case handling, and abstraction it would otherwise add for a public-facing tool. The result is shorter, more direct code that does exactly what you need without boilerplate you'll never hit.

**Tip: Point Claude at the source of truth before asking it to derive values**
Instead of asking "what files does ATT back up?", open `functions_backup.py` first and let Claude read it, then ask for the list. Claude derives the exact paths from the actual code rather than guessing — you get a correct hardcoded list on the first try instead of hallucinated paths that need fixing.

## 2026-05-05 (session 53)

**Tip: Use `/review` to get a code review of staged changes before committing**
It runs a multi-file analysis that catches patterns Claude might miss in single-file edits. Faster than asking "does this look right?" in chat — just stage your files and invoke it.

**Tip: Scope questions to a specific file to cut token cost**
Instead of "how should I handle async in ATT?", ask "in `themes_gui.py`, should the thumbnail loader use `GLib.idle_add` or a thread pool?" Narrower context = fewer tokens wasted on generic explanations = faster, cheaper, more actionable answers.

## 2026-05-10 (session 90)

**Tip: Create project-level custom slash commands in `.claude/commands/` — invoke them like any built-in**
Any `.md` file you drop in `.claude/commands/<name>.md` becomes a `/project:name` command available every session without opening CLAUDE.md. For ATT, a `flake8-all.md` containing "Run flake8 on `usr/share/archlinux-tweak-tool/*.py --max-line-length 120` and fix all violations" means you type `/project:flake8-all` instead of describing the incantation each time. Commands are project-scoped, version-controlled, and visible in `/help`.

**Tip: Pin frequently-needed constants to CLAUDE.md to eliminate read tool calls at session start**
If every session reads `functions.py` for the same half-dozen constants (`fn.sudo_username`, `fn.distr`, `fn.desktop`), add a one-section "Quick Reference" block to CLAUDE.md listing their definitions. Claude loads CLAUDE.md before any tool call — those constants are already in context when you start asking questions. Saves 2–4 tool calls per session on large modules that otherwise get read just for one value.

## 2026-05-10 (session 89)

**Tip: Use `not (A and B and C)` for multi-condition hide guards — the positive form states intent clearly**
`_hide = (distro == "x" and "plasma" in desktop and pkg_installed and svc_active)` then `if not _hide or fn.DEV:` reads as "hide only when all four are true." The negative form `if distro != "x" or "plasma" not in desktop or ...` inverts every condition and is error-prone to extend. State what causes hiding, then negate it once.

**Tip: Combine `fn.distr` and `fn.desktop` to target a specific DE on a specific distro — never distro alone**
`fn.distr == "cachyos"` is true for CachyOS users on any DE, including i3, Hyprland, or BSPWM. `fn.distr == "cachyos" and "plasma" in fn.desktop.lower()` targets only the CachyOS-Plasma combination. Whenever a UI element should hide for a particular distro+DE pairing, always AND both checks — distro alone is too broad and will surprise users on that distro with a different DE.

## 2026-05-10 (session 88)

**Tip: Guard a tab's `stack.add_titled()` call — not the page build — when hiding by distro**
Build the page unconditionally so internal `self.*` attributes (like `self.rebuild_sddm_page`) always exist and never cause AttributeError on other distros. Wrap only the `stack.add_titled(vbox, ...)` line with `if fn.distr != "x" or fn.DEV:`. One-line guard, zero broken references.

**Tip: Always pair a package install with `systemctl enable --force` in the same terminal window**
Never split install and enable across two terminal sessions or two buttons. If the terminal closes between them, the service is installed but inactive and the user has no idea why. One Alacritty window, one bash -c string: `sudo pacman -S pkg; sudo systemctl enable pkg --force; read -p 'Press Enter to close'` — the user sees both steps complete before the terminal dismisses.

## 2026-05-10 (session 87)

**Tip: Use `gh repo edit --description "..."` to update repo metadata from the terminal**
`gh repo edit --description "My new description" --homepage "https://..."` updates GitHub repo metadata without touching the browser. Also works for `--visibility`, `--topics`, and `--add-topic`. Faster than navigating Settings → General for small one-field changes, and scriptable when you're updating multiple repos at once.

**Tip: `gh api repos/<owner>/<repo>` dumps the full GitHub repo JSON — including fork relationship fields**
`gh api repos/<owner>/<repo> | jq '{fork, parent: .parent.full_name, source: .source.full_name}'` shows whether a repo is a fork and what it's forked from, without opening a browser. Useful for scripting fork audits across many repos or verifying a detach completed. The `parent` and `source` fields disappear once the repo is made independent.

## 2026-05-09 (session 86)

**Tip: Qt 6 QML imports drop the version suffix — unversioned imports are the forward-compatible pattern**
`import QtQuick` and `import QtQuick.Controls` (no version number) resolve to whatever Qt version is installed. Any QML module that ships with Qt 6 works this way. Keep the version only for third-party or display-manager-specific modules that still require it (e.g. `import SddmComponents 2.0`). A versioned import like `import QtQuick 2.12` fails on Qt 6 SDDM builds.

**Tip: Switch to `/model haiku` for trivial mechanical edits — save Sonnet tokens for reasoning tasks**
Three find-and-replace operations in small files cost a fraction of Sonnet tokens on Haiku. Use `/model haiku` for tasks like import-line updates, variable renames, or single-line config changes, then switch back with `/model sonnet` when you need multi-file reasoning or architectural decisions. The `/model` command persists for the rest of the session so one switch covers a batch of trivial edits.

## 2026-05-11 (session 96)

**Tip: Use `vbox_not_installed` / `vbox_installed` with `set_visible()` toggle for any feature that may be absent at launch**
Build both states inside `gui()` at startup — `vbox_not_installed.set_visible(not pkg)` and `vbox_installed.set_visible(pkg)`. After the install terminal closes, `GLib.idle_add(on_done)` re-checks the package state and calls `vbox_not_installed.set_visible(False); vbox_installed.set_visible(True)`. No second call into `gui()`, no tab rebuild, no restart required — the switch is instant and `self.*` attributes built during startup remain valid.

**Tip: Use `\budev\b` word-boundary anchors when inserting a hook into /etc/mkinitcpio.conf via sed**
A plain `sed 's/udev/udev plymouth/'` would also match any token containing "udev" as a substring (e.g. a future `udev-more` hook). Use `sed -i 's/\budev\b/udev plymouth/'` — the `\b` anchors ensure only the exact word "udev" is replaced. This is also the form that works correctly when the HOOKS line uses a mix of spaces and tabs.

## 2026-05-11 (session 95)

**Tip: Use `systemctl is-enabled` not `is-active` when guarding persistent UI decisions**
`is-active` reflects runtime state and returns false if the service hasn't started yet (e.g. early in boot, or after a crash). `is-enabled` reflects the configured intent — whether the service will start on next boot. For ATT tab guards that persist across reboots (like hiding SDDM when `plasma-login` owns the session), `is-enabled` is authoritative: the user configured it that way, regardless of current runtime state. Use `is-active` only when you need "is it running right now?" — not "is it supposed to run?"

**Tip: Remove `fn.DEV` bypasses from stable guards once they are tested — they leak hidden UI to debug users**
`fn.DEV` bypasses are useful during development, but leaving them on a production guard means anyone who launches with `--dev` sees tabs that should be invisible — breaking the user's expectation and potentially exposing unfinished UI. Once a guard is tested and trusted, remove the `or fn.DEV` clause entirely. The guard should be unconditional. If you later need to re-test it, add `--dev` back temporarily; don't ship with it.

## 2026-05-11 (session 94)

**Tip: Use `/compact` then type `! <command>` to both free context and inject live command output in one move**
After `/compact` summarizes the session, your very next message can be `! bash fix-permissions-ssh.sh` — the `!` prefix runs the command and its stdout lands directly in context as verified output. This pattern is especially useful for system scripts: compact the prior history, then immediately confirm the script ran cleanly before continuing with the next task. No copy-paste, no context bloat from a long prior conversation.

**Tip: Run `/security-review` on any script that calls `chmod`, `chown`, or modifies `/etc` before executing it**
`/security-review` reads only the diff or named files — it doesn't scan the whole repo. Invoking it against a single system script (like `fix-permissions-ssh.sh`) takes seconds and catches path traversal risks, wildcard expansion hazards, and missing `set -euo pipefail`. Cheaper than debugging a permissions regression on a live machine.

## 2026-05-12 (session 97)

**Tip: Always set `HOME` explicitly when passing a custom env to `Popen` for commands run via `runuser`**
`os.environ.copy()` copies root's environment — HOME=/root. When you run a script as the real user via `runuser -u <user> --`, any `~` expansion inside that script still resolves to root's HOME unless you explicitly set `env["HOME"] = "/home/<user>"`. This is the silent failure mode for tools like `edu-powermenu` that reference `~/.config/...` — the script runs without error but opens the wrong (nonexistent) path.

**Tip: On Plasma/Wayland, GUI apps spawned from a pkexec/sudo process need `WAYLAND_DISPLAY` injected — `os.environ` won't have it**
When ATT runs as root via pkexec, `DISPLAY` and `WAYLAND_DISPLAY` are stripped from the environment as a security measure. Any `Popen` call that omits `env=` inherits this stripped env, so GTK/Qt apps fail to open a window. The fix is a helper like `get_terminal_env()` that reads `XDG_RUNTIME_DIR`, scans the runtime dir for `wayland-*` sockets, and injects them. Apply it to every `Popen` call that opens a GUI app or terminal emulator.

## 2026-05-12 (session 98)

**Tip: Frame batch-failure bugs as "one X must not block another X" — Claude recognises the isolation pattern immediately**
When a loop, batch install, or multi-step operation aborts on the first failure, describing it as "one package can not block another package" tells Claude the root cause is atomicity, not a missing flag. Claude will immediately propose the per-item loop with isolated error handling rather than asking clarifying questions. The more precisely you name the failure mode, the less back-and-forth you need.

**Tip: A single "y" is a valid approval — use it to save tokens and keep context tight**
After Claude states exactly what it intends to change and why, a bare "y" is sufficient. Claude treats it as explicit confirmation and proceeds without re-explaining the plan. Avoid repeating or paraphrasing the plan back — every extra token in the approval message is context Claude carries forward. Short approvals also make transcripts easier to scan when you review what was done.

## 2026-05-12 (session 99)

**Tip: Replace `idx = [0]` closure mutation with `nonlocal` in Python 3**
The `idx = [0]` / `idx[0] += 1` pattern is a Python 2 workaround for closures that need to rebind a variable. In Python 3, `nonlocal idx` does this cleanly. When you see a mutable list used as a single-slot counter inside a nested function, that's the pattern — replace it: declare `idx = 0` in the outer scope, add `nonlocal idx` at the top of the inner function, then use `idx += 1` directly. The code is shorter and the intent is explicit.

**Tip: Two writes to the same config file in one handler is a red flag — one is likely stale**
If a button callback calls `setup_x_config()` and then immediately calls `set_x_value()` that also writes to the same file, one of them is leftover from a refactor. The second write either overwrites the first (silently undoing it) or re-applies the same values (wasteful). When reviewing or touching a save/apply handler, grep for every write to its target file path before adding another one — and if you find two, trace which one was introduced later and consolidate.

**Tip: Use `fn.distr` guards at `stack.add_titled()`, not at page build time**
Build the page unconditionally so internal `self.*` attributes always exist. Only the `stack.add_titled()` call needs the guard. This way every other module can safely reference `self.fastfetch_*` or similar attributes without an AttributeError on the guarded distro. One-line guard at the registration point, zero broken references elsewhere.

**Tip: Narrow your question to one file to cut token cost and get sharper answers**
"Does gui.py handle all distro guards consistently?" costs ~3× fewer tokens than "check the whole codebase for inconsistent guards" and produces a more precise, actionable answer. Chain single-file questions rather than broad sweeps — you stay in control of what gets loaded into context, and the answers are easier to act on immediately.

## 2026-05-12 (session 100)

**Tip: Move UI refresh calls outside conditional guards when they read the filesystem directly**
A refresh function that reads `/usr/share/sddm/themes/` (or any directory) to repopulate a dropdown doesn't need a package-installed guard around it — the filesystem is always the ground truth. Guards are only needed when the refresh would write to something or when the absence of data is itself a failure. Placing an unconditional filesystem read outside the `if package_installed:` block makes UI state correct even when pacman's in-memory database lags behind the actual removal.

**Tip: Use `git diff HEAD~N..HEAD -- <file>` to audit what changed across a block of sessions**
When a file has grown and you're not sure what was added recently, `git diff HEAD~5..HEAD -- path/to/file.py` gives you a clean before/after for the last N commits. Grep the `+` lines for new functions and the `-` lines for removals. This is faster than reading the full file and gives you exactly the "what changed" view without having to reconstruct it from `git log`.

## 2026-05-12 (session 101)

**Tip: When a package removal leaves files behind, the cause is almost always a modified tracked file**
pacman removes only the files it installed. If ATT (or the user) overwrites a file inside a package's directory (e.g. copying a wallpaper into `/usr/share/sddm/themes/edu-simplicity/images/`), pacman removes the original tracked path but any file it didn't install stays. The directory itself won't be removed while it still has contents. The fix pattern: after confirming removal, explicitly `shutil.rmtree` the known package directory before refreshing any UI that lists it.

**Tip: Describe the observable symptom, not the assumed cause, to get the shortest path to a fix**
"edu-simplicity is still in the dropdown after removal" is more useful than "the dropdown isn't refreshing." The first tells Claude to check the filesystem; the second sends it looking at signal wiring. Symptom-first descriptions let Claude skip the wrong hypothesis and go straight to `ls /usr/share/sddm/themes/` — which immediately reveals the leftover directory. One sentence of what you *see* beats two sentences of what you *think* is broken.

## 2026-05-12 (session 102)

**Tip: Use `git pull --rebase` in shared-repo scripts instead of plain `git pull`**
Plain `git pull` creates a merge commit every time two machines diverge, cluttering history with "Merge branch 'main' of ..." entries. `git pull --rebase` replays your local commits on top of the remote, keeping history linear and readable. For a `up.sh`-style script that runs on multiple machines, `--rebase` is almost always the right choice — the only exception is when you intentionally want to preserve merge topology.

**Tip: Warm a per-session cache in one bulk call rather than caching lazily on first access**
Lazy caching (cache on first call) eliminates repeat lookups but still pays N subprocess costs for N unique keys. If you know all the keys upfront (e.g. every package ATT will ever check), run one `pacman -Q` at startup, parse the output into a set, and pre-fill the entire cache dict in one pass. Subsequent calls are pure dict lookups with zero subprocesses. The calling code doesn't need to change — the cache is transparent.

**Tip: `git pull --rebase --autostash` handles unstaged changes automatically**
If you run `git pull --rebase` with unstaged changes, git refuses with "You have unstaged changes." The `--autostash` flag makes git stash silently before rebasing and pop after — one flag replaces the manual stash/pop dance. Useful in `up.sh`-style scripts that run on a dirty working tree.

**Tip: Name your stashes to find them later**
Plain `git stash` creates an anonymous entry. `git stash push -m "wip: icons refactor"` names it so `git stash list` is readable when you have multiple stashes. You can then `git stash apply stash@{1}` to restore a specific one instead of always popping the top.

## 2026-05-12 (session 103)

**Tip: Describe where you *found* a mystery file to skip the grep yourself**
When you see an unexpected file (e.g. `settings.ini` with termite config in `~/.config/archlinux-tweak-tool/`), telling Claude the full path immediately lets it run a targeted `grep -rn "termite"` across the codebase in one shot. Without the path you get a generic "check the code" answer; with it Claude can confirm in seconds that the file is a dead leftover and nothing in the current codebase writes it.

**Tip: Use `/search` or `grep` in the agent to audit dead assets before deleting them**
Before removing a script, config file, or data asset, always grep the codebase for its filename or path. A file that looks unused may be referenced by a path string in a Python variable, a bash heredoc, or a desktop file. One `grep -rn "filename"` call rules out every live reference in seconds and is much cheaper than tracing the removal back after a crash.

## 2026-05-13 (session 104)

**Tip: Invoke `/review` for structured code reviews instead of asking in chat**
`/review` runs a multi-pass review with severity tiers and reads the full call chain across files — it caught a `process.communicate()` misuse in ai.py that a chat-level review would have missed without also reading functions.py. Use it before merges or after completing a feature; it costs a few more tokens but surfaces cross-file bugs that single-file reading misses.

**Tip: Name the cross-file relationship in your review request to cut token cost**
"Review the install/remove flow in ai.py against the terminal-launch pattern in functions.py" goes straight to the relevant relationship. "Review page ai tools" causes Claude to read both files fully and then reconstruct the relationship from scratch — more tokens, slower, same result. The more specific the scope, the cheaper and faster the answer.

## 2026-05-13 (session 105)

**Tip: Front-load a cache invalidation call before every post-install state check**
When you have a per-session package cache and you need to re-check install state after a terminal closes, always call `invalidate_pkg_cache()` *before* `check_package_installed()` — not after. The check reads the cache; invalidating after is a no-op for the current call. Pattern: `process.wait()` → `invalidate_pkg_cache()` → `check_package_installed(pkg)`. Doing it in this order is the bug sweep we ran across 10+ files this session.

**Tip: Use "check first" pattern instead of installing unconditionally in button callbacks**
When a button should "launch X if installed, else install then launch," check `check_package_installed("X")` *before* spawning anything. If installed, run immediately on the calling thread (or a simple `_run_cmd`). If not, open the install terminal, wait in a daemon thread, invalidate the cache, re-check, then launch. This replaces the race condition of `install_package()` (non-blocking) followed immediately by a launch call — the launch always fires before the install finishes.

## 2026-05-13 (session 106)

**Tip: Grep the function name to find all conditional UI guards in one shot**
When you suspect a UI row is hidden behind a runtime check (like `fn.is_wayland_session()`), run `grep -rn "is_wayland_session"` across the codebase rather than reading every GUI file. You immediately see every callsite — construction guards and append guards — and can judge whether any should be lifted without opening a single file first.

**Tip: Paste the selected code lines directly into chat to skip the "find the file" round-trip**
Select the relevant lines in VS Code, paste them into the message, and Claude works on exactly that code — no file read needed, no context spent finding the right location. Useful when you remember seeing something but not where: describe it and paste the closest approximation; Claude will locate or reconstruct the pattern from the snippet alone.

## 2026-05-13 (session 107)

**Tip: Use `/clear` between unrelated tasks to prevent context bleed**
When you switch from debugging one feature to working on something completely different, run `/clear` to reset the conversation. Stale context from the previous task can silently skew Claude's recommendations — it may anchor to a pattern it just saw even when it no longer applies. A fresh context gives a cleaner, more accurate answer.

**Tip: Ask "is this already done?" before implementing — stale TODOs are common**
Before starting a task from a TODO list or memory, ask Claude to check the current code state first. Implementations often get done but the TODO entry never gets removed. Checking takes seconds; re-implementing something that already exists wastes tokens and creates confusion about which version is canonical.

## 2026-05-13 (session 108)

**Tip: Show Claude an existing reference file when creating a near-duplicate**
When asking Claude to create a script "similar to X," open X in the IDE or name it explicitly. Claude reads it once, extracts the exact structure (helpers, patterns, error handling), and produces a consistent output without guessing. Without the reference, it falls back to a generic template that drifts from your project's standard.

**Tip: Keep package lists authoritative in one place and reference them everywhere**
The ohmychadwm package list lives in `desktopr.py` — the script was generated directly from it. When you add or remove a package, update `desktopr.py` and regenerate any derived scripts from it. Maintaining two independent lists guarantees they diverge. One source of truth prevents install/uninstall mismatches between the GUI and the standalone script.

## 2026-05-13 (session 109)

**Tip: Audit script directories with a two-command grep — one for files, one for callers**
Run `find data/bin -type f` to list all scripts, then grep the Python source for each name. Diff the two lists to find orphans in under a minute. Scripts that exist but have no callers anywhere in the repo are dead code — delete them. This pattern works for any asset directory (images, config templates, etc.).

**Tip: Ask Claude to scope an audit before doing any editing — you get the full picture first**
For "which X are unused?" questions, ask Claude to list the findings before touching anything. You see the complete set (4 orphans in this case) and can make a single informed delete decision rather than approving removals one-by-one as they're discovered mid-edit. Separating discovery from action keeps you in control and avoids accidental deletions.

## 2026-05-13 (session 110)

**Tip: Add a `LOG_DELEGATES` set to audit scripts for functions that always log internally**
When a callback delegates to a helper that already calls `log_*`, the audit script can't see into the helper's body. Keep a `LOG_DELEGATES` set of known always-logging helpers (e.g. `open_url_in_browser`, `install_package`) and treat calls to them as covered. This avoids 24 false-positive "missing" reports without duplicating log calls in every wrapper.

**Tip: Fix the shared helper instead of repeating the same log call in 24 wrappers**
When many callbacks all call the same helper function, put the `fn.log_info(...)` inside the helper once — not in each callback. This keeps the callsite clean, guarantees the log is always present, and means the audit's `LOG_DELEGATES` set is the only place to update if the helper is renamed.

## 2026-05-13 (session 111)

**Tip: Search for attribute references before trusting a codebase-wide except swallow**
When a function body is wrapped in `try/except Exception: pass`, attribute errors vanish silently. Before accepting that code "works", grep the whole repo for every `self.*` attribute the block references. If an attribute has zero definitions (no `self.attr =` anywhere), the line is dead code — remove it rather than letting the except hide it forever.

**Tip: Pair a disabled button with a tooltip — never leave a greyed-out widget unexplained**
A `set_sensitive(False)` with no `set_tooltip_text()` leaves the user guessing. Always add a tooltip on the same condition that disables the button. For repo-gated buttons the tooltip text should name the repos and point to where to enable them ("Enable nemesis_repo and chaotic-aur in the Pacman tab"). One line; huge improvement in pure-Arch or first-run UX.

## 2026-05-13 (session 112)

**Tip: Frame cross-file consistency checks as "find X missing Y" — read-only first, edit second**
When auditing a pattern like "every notification needs a matching log call", ask Claude to list all discrepancies before touching any file. You get the complete set to review, can reject false positives, and then approve a single targeted edit pass. This is cheaper and safer than a write-first sweep that may miss some cases or fix the wrong ones.

**Tip: Use `/ultrareview` for cross-file consistency audits**
When a coding standard must hold across many files (e.g. every `show_in_app_notification` paired with a `log_*`), `/ultrareview` spawns parallel agents that reason across the whole branch at once. A single-agent grep scan can miss cases inside nested lambdas, GLib.idle_add wrappers, or indirectly called helpers — multi-agent review catches all of them.

## 2026-05-13 (session 113)

**Tip: Verify package repo membership before writing an install script — `pacman -Si <pkg>` tells you immediately**
Before coding any install button that calls `pacman -S`, run `pacman -Si <package>` locally. If it returns "error: package '<name>' was not found", the package is AUR-only (or distro-repo-specific) and cannot be installed with plain pacman. Catch this in the design phase, not after a user reports a broken button.

**Tip: Never mix official-repo and AUR packages in one `pacman -S` call**
If an install script bundles an official-repo package with an AUR package in a single `pacman -S`, the whole transaction aborts when pacman can't resolve the AUR target — the official-repo package also fails to install. Always split: pacman for official packages first, then the AUR helper (`sudo -u "$REAL_USER" yay -S ...`) for AUR packages in a separate step.

**Tip: Always capture and check Popen.wait()'s return code — discarding it silently hides failures**
In ATT, `_run_terminal` called `Popen(...).wait()` without capturing the return code, so a failed terminal script (exit 1) still triggered `log_success` and a success notification. The fix is one line: `returncode = Popen(...).wait()` then branch on it. Whenever you wrap a subprocess in a helper, verify both the success and the failure path each call a `log_*` function.

## 2026-05-13 (session 114)

**Tip: Replace `threading.Event().wait(N)` with `process.wait()` — a fixed sleep never knows when the terminal actually closed**
A blind `fn.threading.Event().wait(2)` after launching a pacman terminal runs the post-install check while the terminal is still open. The package check always returns the pre-install state. The fix is `process = fn.launch_pacman_install_in_terminal(...); if process: process.wait()`. The thread blocks until the user closes the terminal, then `check_package_installed` fires at the right moment.

**Tip: Use `/review <module>` to scope a review to one feature area — Claude treats it as a logical module path**
When you want a review limited to one tab or subsystem (e.g. `services/printing`), pass it as the argument to `/review`. Claude will interpret it as a module path and search the codebase for the matching files rather than trying to find a PR or branch with that name. Faster and cheaper than reviewing the whole file or opening a PR for a review-only session.

## 2026-05-13 (session 115)

**Tip: Use `sudo -H` when running AUR helpers as the real user — without it, HOME stays as root's home**
`sudo -u erik paru -S ...` inherits `HOME=/root` from the root process. Paru/yay do devel checks by running `git ls-remote`, and git reads `HOME` to find gitconfig — so it looks at `/root/.git` and fails. Fix: always pass `-H` (`sudo -H -u erik paru -S ...`) to reset HOME to the target user's home. Also prepend `unset GIT_DIR GIT_WORK_TREE` to the bash script to clear any git env vars inherited from the parent process.

**Tip: Diagnose environment-pollution bugs by tracing the full process tree, not just the failing command**
When a command fails with a wrong-path error (`fatal: error reading '/root/.git'`), the cause is rarely in that command itself — it's in the environment it inherited. Ask Claude: "what process launched this, and what env did it inherit?" For ATT: pkexec → root Python → alacritty → bash → sudo → paru. Each step can leak HOME, GIT_DIR, DISPLAY, etc. If you paste the process tree and the error to Claude, it can pinpoint which step failed to sanitize.

## 2026-05-13 (session 116)

**Tip: Always call `fn.invalidate_pkg_cache()` in every `wait_and_refresh` closure after a terminal install/remove**
`check_package_installed` caches its result in `_pkg_cache`. If you don't call `fn.invalidate_pkg_cache()` before refreshing a label after a terminal install, the cache still holds the pre-install `False` and the label never updates. Rule: every `wait_and_refresh` that calls `_refresh_*_label` must call `fn.invalidate_pkg_cache()` first.

**Tip: When a UI label doesn't update after install, check the cache before the GTK code**
"Label doesn't show installed after install" is almost always one of three causes, in order: (1) the package cache is stale — check for `_pkg_cache` and missing `invalidate_pkg_cache()` calls; (2) the refresh function is never called — check `GLib.idle_add` wiring; (3) markup is escaped wrong — check `&amp;` vs `&`. Always rule out (1) first; it's a single grep.

**Tip: State the rule first, then say "do a complete check" — Claude audits the whole codebase at once**
When you discover a pattern that should hold everywhere (e.g. "every wait_and_refresh must call invalidate_pkg_cache"), feed Claude the rule and then say "do a complete check." This triggers a codebase-wide grep, classifies every instance as compliant or missing, and produces a ranked fix list — in one prompt. Asking "is this file correct?" file-by-file is 10× slower and misses cross-file patterns.

**Tip: Giving Claude the correct line and the wrong line together gets a faster, more accurate fix**
When reporting a bug, include one example of the correct pattern alongside the broken one (e.g. "sddm.py:704 has it right, sddm.py:612 doesn't"). Claude can diff the two examples directly instead of inferring the rule from the description alone. This cuts ambiguity, avoids a clarification round-trip, and produces edits you can approve without a second read.

## 2026-05-14 (session 117)

**Tip: Test on a minimal environment (pure Arch + one DE) to expose distro-guard gaps before release**
Running ATT on bare Arch + XFCE4 surfaces bugs that never appear on Kiro: missing packages that ATT assumes are installed, `fn.distr` returning "arch" where code expects "kiro", and XFCE-specific wallpaper paths. This is a cheap, high-signal test that catches guard omissions before users hit them. Keep a VirtualBox snapshot at "clean install" state so you can always reset and retest.

**Tip: Paste the full terminal error (including the Python traceback) to Claude — the filename and line number in the traceback pinpoint the fix in seconds**
When ATT crashes on a tab, the Python traceback always includes the exact file and line number. Pasting it to Claude is faster than describing the symptom — Claude can read the offending line directly, see what assumption it violated (e.g. `fn.distr == "kiro"` check missing), and propose an edit without any back-and-forth. A description like "the themes tab crashed" starts a guessing game; the traceback ends it.

## 2026-05-14

**Tip: Before writing an install function, ask "what if the required repo isn't enabled?" — repo-gated packages always need a fallback**
Today's fastfetch install silently failed on pure Arch because `fastfetch-git` only exists in chaotic-AUR/nemesis. The fix: check `fn.check_chaotic_aur_active() or fn.check_nemesis_repo_active()` and fall back to the official-repo equivalent. Any time you see a `-git` or AUR-only package in an install callback, stop and ask: "what does a user without that repo get?" Write the fallback at the same time, not later.

**Tip: Let the remove function guide the install function — if remove already sniffs both package names, install should mirror that logic**
`on_remove_fast` already did `pacman -Q fastfetch-git` to decide which package to remove. That pattern was the clue that two package names were in play. Reading the remove function first would have revealed the gap in the install function immediately, without any external research. When writing or reviewing an install callback, always read the paired remove callback first.

## 2026-05-14 (session 118)

**Tip: Any post-kernel-operation helper must return a Popen — not run subprocess inline — so every caller can .wait() uniformly in a daemon thread**
`run_grub_update()` and `run_dracut()` both return a `Popen` object (or `None` when not applicable). Every caller does the same two lines: `proc = kernel.run_X(self)` then `if proc: proc.wait()`. If you ever wrote `subprocess.run(["dracut", ...])` directly inside a callback, that blocks the daemon thread correctly but can't be composed with other steps. Returning Popen lets the caller chain GRUB + dracut + refresh in sequence without duplicating the launch logic.

**Tip: VirtualBox is the wrong environment for bootloader/initramfs integration tests — the machine-ID dirs must already exist**
`dracut --regenerate-all --force` writes initramfs images into `/boot/efi/<machine-id>/<kernel-version>/`. Those directories are created by `kernel-install` at first kernel install time. A fresh VirtualBox VM that was never booted from a real Arch/Garuda ISO has no ESP, no machine-ID dir, and no kernel-version subdirs — the command fails immediately. Test dracut and systemd-boot integration only on a system that has actually been installed via the normal installer, or keep a VM snapshot taken after first boot where those dirs exist.

## 2026-05-14 (session 119)

**Tip: The AUR RPC v5 `/info` endpoint returns package metadata without needing an AUR helper installed**
`https://aur.archlinux.org/rpc/v5/info?arg[]=pkg1&arg[]=pkg2` returns JSON with `LastModified`, `Version`, `Maintainer`, `NumVotes`, and more for each named package. It accepts up to 250 `arg[]` parameters in one request — batch your whole list. This is pure stdlib (`urllib.request`) with no pacman or yay dependency, and it works offline-gracefully (catch the exception and return an empty dict). Use it whenever you need AUR metadata that `-Ss` output doesn't carry.

**Tip: Fetch expensive data lazily — only when the user activates the feature that needs it**
Today's sort-by-date switch only hits the AUR RPC the first time it's flipped ON, not at page load. Pattern: initialize state as an empty dict/list, check `if not _cache` inside the toggle handler, fetch in a background thread, then `GLib.idle_add` the re-render. If the user never toggles the switch, zero network calls are made. Apply this to any UI feature that needs slow data: the user opts in by interacting, not by opening the page.

## 2026-05-14 (session 120)

**Tip: `pos > 0` is almost never what you mean — use `pos >= 0` when -1 is the sentinel**
Any time a search function returns `-1` for "not found" and a non-negative index for "found", the found-check must be `>= 0`, not `> 0`. `pos > 0` silently excludes index 0 (the first line of the file). This class of bug never surfaces in tests unless the match happens to be on line 0. The rule is simple: if the function is modelled on `str.find()` (returns -1 on miss), always write `if pos >= 0`, never `if pos > 0`.

**Tip: Replace a block of near-identical functions with a dict + one dispatch function — `replace_all` handles the rename fallout**
Four `set_checkboxes_*` functions that each contained 28 `set_active()` calls were collapsed into module-level preset dicts + one `_apply_preset(self, states)` function. The derived `_PRESET_NONE = {attr: False for attr in _PRESET_ALL}` can never drift. The rename from `lIP`/`PIP` to `l_ip`/`p_ip` touched many files — using Edit with `replace_all=True` handled every occurrence in one call per file. Pattern: when you need a variable-name rename that spans a whole file, `replace_all=True` is safer and faster than a sequence of targeted edits.

## 2026-05-16 (session end ATT alacritty-tweak-tool)

**Tip: Use `notify::position` on `Gtk.Paned` to persist the divider position across launches — no "on close" handler needed**
Connect `paned.connect("notify::position", lambda *_: save_prefs())` immediately after creating the paned. Because `notify::position` fires on every pixel the user drags, the prefs file always holds the latest split position — even if the app crashes without a clean shutdown. Restore with `paned.set_position(prefs.get("key", default))` at build time. This is more reliable than a window-destroy or delete-event handler, which can be skipped if the WM kills the process.

**Tip: Give each paned widget its own prefs key even when they share the same default position**
When two tabs both use a split layout, separate keys (`paned_themes_pos`, `paned_appearance_pos`) let the user tune each tab independently — a wide list on one tab and a narrower settings panel on another. A single shared key forces a compromise. The cost is one extra string per tab; the benefit is per-widget muscle memory that survives restarts.

## 2026-05-18 (session end ATT simplify pass)

**Tip: Call your `_refresh_*` helpers at init time — don't duplicate the if/else inline**
When you add a `_refresh_label(self)` helper to update a widget post-install, call it at GUI build time too (immediately after `self.label = Gtk.Label(...)`). The widget only needs to exist before the refresh function runs — no circular dependency. Duplicating the if/else inline creates two sources of truth: a future label wording change requires edits in two places and the duplication is invisible until `/simplify` catches it.

**Tip: Run `/simplify` after every multi-session feature addition, not just after large refactors**
Code reuse gaps like init/refresh duplication accumulate silently across sessions: one session adds the `_refresh_*` helper, the next session writes the GUI init without knowing the helper exists. `/simplify` catches these in one pass by launching three agents in parallel (reuse, quality, efficiency). It's cheap on a clean working tree — the diff is small and the agents run fast. Treat it as a post-feature hygiene step, not an occasional deep-clean.

## 2026-05-18 (session end arcolinux-nemesis)

**Tip: Install `flake8` and `ruff` as system packages, not pip deps — they survive virtualenv resets and are always on PATH**
Linting tools installed via pip into a virtualenv disappear the moment the env is recreated or switched. Installing them via pacman (`flake8`, `ruff`) makes them available system-wide for every project, every shell, every CI-equivalent manual run. For nemesis-based setups, add them to the core packages list in `110-install-core-software.sh` so they're guaranteed on any fresh Arch install. The rule: if you run a tool in every project, it belongs in the system package list, not per-project deps.

**Tip: Curl-check new mirrorlist entries before committing — a dead mirror adds 3–5 second timeouts to every `pacman -Syu`**
When adding mirrors to a mirrorlist manually, validate them first: `curl -s --max-time 3 -o /dev/null -w "%{http_code}" "https://new-mirror.example/$repo/os/$arch/core.db"` with `$repo=core $arch=x86_64`. A 2xx response means the mirror is live; anything else means skip it. Pacman tries every enabled mirror on timeout, so one dead entry multiplies the slowdown across every sync. A 5-second spot-check per new mirror pays for itself on the first `pacman -Syu`.

## 2026-05-18 (session end kiro-iso build script standardization)

**Tip: Always anchor script paths to SCRIPT_DIR, never to $PWD — callers set $PWD, not you**
Any script that uses bare relative paths like `cp pacman.conf /etc/pacman.conf` will silently operate on the wrong file when called from a different directory. The fix is a single line at the top: `SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"`. Then every path becomes `"${SCRIPT_DIR}/pacman.conf"`. This matters most for scripts called by other scripts (build orchestrators, CI), where the caller's working directory is unpredictable. The rule: if a script reads or writes files relative to itself, use SCRIPT_DIR. If it operates on the user's current project, $PWD is intentional — know the difference.

**Tip: Guard tput with [[ -t 1 ]] or your color codes will corrupt piped and redirected output**
`tput setaf 2` emits raw escape sequences. In a terminal they render as color; in a pipe, a log file, or CI output they appear as literal garbage characters. The correct pattern: `if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then RED="$(tput setaf 1)"; ...; else RED="" GREEN="" ...; fi`. The `[[ -t 1 ]]` check tests whether stdout is an interactive terminal. With this guard, the same script is human-readable in a terminal and machine-readable when captured. Apply this pattern once at the top; the log functions then use the variables unconditionally.

## 2026-05-18 (session end kiro-iso cleanup)

**Tip: When removing a feature, grep the whole repo first — then leave CHANGELOG history untouched**
Before removing a package name, variable, or DE reference, run `grep -rn "term" . --include="*.sh" --include="*.md" --include="*.conf"` to find every occurrence. Fix all forward-facing files (scripts, docs, config). Then stop: CHANGELOG entries that mention the removed thing are historical record — rewriting them to pretend the feature never existed destroys the audit trail. The rule: grep everything, fix the present, preserve the past.

**Tip: Audit README file references with ls before committing — stale paths erode trust faster than missing docs**
A README that lists files which don't exist (enable-oomd.sh, personal_repo/, packages.bootstrap) is worse than a shorter README, because it tells readers the project is poorly maintained. Before finalising any docs change, run `ls <each-file-or-dir-mentioned>` to verify they exist. For project trees in particular, generate the list from the actual filesystem rather than writing it from memory — `find . -maxdepth 2 -not -path './.git/*'` gives you the ground truth in seconds.

## 2026-05-19 (session end kiro-calamares-config-next promotion)

**Tip: After promoting beta config to production, grep the production repo for the beta suffix before committing**
When copying files from a `-next` repo to its production sibling, package names, self-removal commands, and debug strings often still reference `-next`. Run `grep -rn "next" --include="*.conf" --include="*.py" --include="*.sh" --include="*.md" --include="PKGBUILD" <production-repo>/ | grep -v "\.git/"` immediately after the file copies and before staging anything. Review every hit: fix stale repo/package name references; leave Python `__next__`/`.next()`, Calamares config keys, and `provides=('<package>-next')` virtual package entries untouched. One missed string (like a `pacman -R <package>-next` in post-install cleanup) will silently fail to remove the installer package on every production install.

**Tip: Pair the config repo to its matching ISO repo — never cross them when suggesting a build command**
In a project with parallel stable/beta tracks (e.g. `kiro-calamares-config` + `kiro-iso`, `kiro-calamares-config-next` + `kiro-iso-next`), always trigger the ISO build in the repo that matches the config repo you just pushed to. The ISO build pulls the Calamares package from GitHub Pages, which was published by the config repo's CI. Crossing them (building `kiro-iso` after pushing to `kiro-calamares-config-next`) results in the wrong Calamares package being bundled and a confusing mismatch between what was tested and what ships.

## 2026-05-19 (edu-system-files session)

**Tip: In kiro-common.sh, `log_error` is the ERR trap handler — never pass it a plain message string**
`log_error lineno cmd` is wired to `trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR`. Calling it as `log_error "must be root"` treats the string as the line number and wraps it in the full `⚠️ ERROR DETECTED` banner — confusing to users and semantically wrong. For any user-facing error message (root checks, bad arguments, missing dependencies), use `echo "${RED}message${RESET}" >&2; exit 1` instead. `log_error` is only for the trap.

**Tip: `mandb` runs on a daily systemd timer, not at boot — run it manually after deploying new man pages**
`man-db.timer` fires once daily with up to 12 hours of random delay. A freshly copied `.8` file won't appear in `man kiro<Tab>` completion until the timer fires or you run `sudo mandb` yourself. Any deploy script that installs man pages to `/usr/share/man/` should call `mandb` as its last step, or the user will hit a confusing "no completions" gap that fixes itself overnight.
