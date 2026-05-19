# IDEAS

## Claude's Ideashop

### Monthly audit diff — compare audit runs over time

After each monthly `audit.sh` run, save the output to `~/kiro-audit-YYYY-MM-DD.txt` and diff against the previous month's file. A one-liner wrapper script (`audit-compare.sh`) runs the audit, saves the result, then prints `diff` against the last saved file with color highlighting. Over time this builds a regression history: when a PASS becomes a FAIL you know exactly which ISO build introduced it, without having to remember what changed. Rationale: the audit currently shows current state; the diff shows drift.

### ISO-to-ISO package diff script

After each build, compare the new `pkglist.txt` against the previous one and print three sections: packages added, packages removed, packages with a version change. A 10-line bash script using `comm` on sorted files is all it takes. Rationale: right now there is no quick way to see "what actually changed in this build vs the last one?" — you have to diff two raw pkglist files by hand. A diff summary at the end of `build-the-iso.sh` (or as a standalone `diff-pkglists.sh`) gives an instant audit trail and catches accidental package additions or removals before the ISO is uploaded.

### Security sysctl regression check in audit.sh

Add a security section to `audit.sh` that reads the live sysctl values and compares them against the expected baseline from `99-kiro-optimizations.conf`. If `kernel.kptr_restrict` is `0` instead of `2`, or `fs.suid_dumpable` is `2` instead of `0`, the audit prints a FAIL. Rationale: the sysctl file being present doesn't guarantee the values are active — a conflicting drop-in, a kernel that ignores the key, or a sysctl applied before the file loads could silently undo hardening. A live-value check confirms the security profile is actually in effect, not just on disk.

### Build health dashboard — post-build HTML report
After `mkarchiso` completes, generate a simple static HTML file in `~/kiro-Out/` alongside the ISO that lists: build date, kiro version, NVIDIA driver selected, total package count, ISO size, and all three checksums in one place. A single `xdg-open` command opens it in the browser. Rationale: right now the build information is scattered across terminal output, the pkglist file, and three separate checksum files. A single report page makes it easy to screenshot and share when posting a new release, and gives a quick sanity check that the right driver was injected before uploading.
