# IDEAS

## Claude's Ideashop

### Build health dashboard — post-build HTML report
After `mkarchiso` completes, generate a simple static HTML file in `~/kiro-Out/` alongside the ISO that lists: build date, kiro version, NVIDIA driver selected, total package count, ISO size, and all three checksums in one place. A single `xdg-open` command opens it in the browser. Rationale: right now the build information is scattered across terminal output, the pkglist file, and three separate checksum files. A single report page makes it easy to screenshot and share when posting a new release, and gives a quick sanity check that the right driver was injected before uploading.
