# IDEAS

## Claude's Ideashop

### Monthly audit diff — compare audit runs over time

After each monthly `audit.sh` run, save the output to `~/kiro-audit-YYYY-MM-DD.txt` and diff against the previous month's file. A one-liner wrapper script (`audit-compare.sh`) runs the audit, saves the result, then prints `diff` against the last saved file with color highlighting. Over time this builds a regression history: when a PASS becomes a FAIL you know exactly which ISO build introduced it, without having to remember what changed. Rationale: the audit currently shows current state; the diff shows drift.

### ISO-to-ISO package diff script

After each build, compare the new `pkglist.txt` against the previous one and print three sections: packages added, packages removed, packages with a version change. A 10-line bash script using `comm` on sorted files is all it takes. Rationale: right now there is no quick way to see "what actually changed in this build vs the last one?" — you have to diff two raw pkglist files by hand. A diff summary at the end of `build-the-iso.sh` (or as a standalone `diff-pkglists.sh`) gives an instant audit trail and catches accidental package additions or removals before the ISO is uploaded.

### kiro-audit --fix mode — auto-remediate known failures

Add a `--fix` flag to `kiro-audit` that automatically corrects the issues it finds: delete `10-archiso.conf` if present, run `systemd-tmpfiles --create` to enforce CUPS permissions, mask legacy daemons. Each fix is printed before execution and gated behind the flag — the default run stays read-only. Rationale: running the audit on a machine installed from an older ISO currently produces actionable FAILs with no way to resolve them except copying commands from the output manually. A `--fix` mode closes the loop.

### Security sysctl regression check in audit.sh

Add a security section to `audit.sh` that reads the live sysctl values and compares them against the expected baseline from `99-kiro-optimizations.conf`. If `kernel.kptr_restrict` is `0` instead of `2`, or `fs.suid_dumpable` is `2` instead of `0`, the audit prints a FAIL. Rationale: the sysctl file being present doesn't guarantee the values are active — a conflicting drop-in, a kernel that ignores the key, or a sysctl applied before the file loads could silently undo hardening. A live-value check confirms the security profile is actually in effect, not just on disk.

### Release announcement generator

After `/kiro-ready` returns GO, auto-generate a paste-ready release announcement: version, build date, ISO size and SHA256, kiro-audit score, and a three-bullet "what's new" summary drawn from the CHANGELOG entry for that date. One command produces a forum/GitHub release post template — no copy-pasting from three different files. Rationale: every release currently requires manually assembling the same information from CHANGELOG, the checksum files, and the audit output; a generator closes that gap and ensures the announcement is always accurate.

### Build health dashboard — post-build HTML report
After `mkarchiso` completes, generate a simple static HTML file in `~/kiro-Out/` alongside the ISO that lists: build date, kiro version, NVIDIA driver selected, total package count, ISO size, and all three checksums in one place. A single `xdg-open` command opens it in the browser. Rationale: right now the build information is scattered across terminal output, the pkglist file, and three separate checksum files. A single report page makes it easy to screenshot and share when posting a new release, and gives a quick sanity check that the right driver was injected before uploading.

### Build-time airootfs exec-bit guard

Before calling `mkarchiso`, have `build-the-iso.sh` scan the airootfs for scripts under `*/bin/*` that are missing their exec bit and warn (or abort): `find "$buildFolder/archiso/airootfs" -path "*/bin/*" -type f ! -perm -u+x`. This session burned hours because `kiro-trust-desktop-launchers` shipped `644` — git recorded it `100755`, but the overlay/squashfs did not preserve the bit, and the failure was invisible until the booted ISO. Rationale: a lost exec bit is silent (the file is present, just not runnable) and only bites at runtime on the live system; a one-line pre-build check turns a multi-hour live-VM debug into an instant warning, and nudges toward the durable fixes (pin in `file_permissions`, or invoke via `bash`).

### GTK4 application to build the Kiro ISO

A GTK4 Python front-end for `build-the-iso.sh` — the same modular style as ATT. One window with a few sections: kernel(s) (multi-select list driven by `detect_available_kernels`), live-boot kernel (radio when multiple are picked), NVIDIA driver (open / 580xx / 390xx), version bump on/off, picker preference (auto/gum/dialog), and a "Build" button that streams the script's stdout into a scrolling terminal view. Rationale: the current build script is fully scriptable but lives behind a config block at the top of a 600-line bash file — every option that already exists as a variable (`kernel`, `picker`, `nvidia_driver`, `bump_version`) is a checkbox or dropdown in disguise. A small GTK wrapper makes "build your own Kiro ISO" reachable for users who never want to edit a bash file, while keeping the existing CLI path intact for power users. Naming: `kiro-iso-builder` (separate package, not part of ATT), runs as a normal user since the underlying script calls `sudo` internally.
