# BYOI — Build Your Own ISO

This guide walks you through building your **own** Kiro ISO from this repository, even if
you have never built anything before. Every command can be copied and pasted as-is. Take it
one step at a time — you can't break your own computer by building an ISO; the result is just
a file you can throw away.

---

## 1. What you're about to do

You're going to turn this folder of settings and package lists into a **bootable `.iso` file**
— the same kind of file you'd download to make a USB installer. It's built with Arch Linux's
official tool, `mkarchiso`, driven by one script.

- **Time:** about 30–60 minutes the first time, less after that (mostly downloading packages).
- **Disk space:** roughly **15 GB** free in your home folder.
- **Result:** `~/kiro-Out/kiro-vYY.MM.DD-x86_64.iso`, ready to boot in a virtual machine or
  write to a USB stick.

---

## 2. What you need

- **An Arch-based computer.** Any of these work: **Arch Linux, Kiro, EndeavourOS, CachyOS,
  Garuda.** The build tool (`mkarchiso`) is Arch-only.
  - *On Windows, Ubuntu, Fedora, or a Mac?* You can still build — just do it inside an Arch
    Linux **virtual machine** or **container**. See the
    [Arch Wiki: Archiso](https://wiki.archlinux.org/title/Archiso) for setting that up, then
    follow this guide inside it.
- **A normal user account with `sudo`** (the everyday account you log in with). **Do not** run
  the build as `root` — the script asks for your password when it needs it.
- **An internet connection** — the build downloads packages.
- **Nothing else to install by hand.** The build sets up the extra software repositories it
  needs (Chaotic-AUR and CachyOS) automatically.

---

## 3. Get the code

Open a terminal and run:

```bash
git clone https://github.com/kirodubes/kiro-iso.git
cd kiro-iso
```

> If you don't have `git` yet: `sudo pacman -S --needed git`, then run the commands above.

That's it — you now have the whole builder in a folder called `kiro-iso`.

*(There's a `setup.sh` in here too. That's only for maintainers who push changes back to
GitHub. You can ignore it.)*

---

## 4. Build it

From inside the `kiro-iso/build-scripts` folder, run one command:

```bash
./build-the-iso.sh
```

That's the whole build. Here's what happens while it runs:

- It checks your machine has what it needs (`archiso`, `grub`) and installs anything missing.
- It sets up the **Chaotic-AUR** and **CachyOS** repositories for you if they aren't already
  there — this is automatic, you don't do anything.
- It asks for your `sudo` **password** once or twice (typing shows nothing — that's normal).
- It works through twelve numbered phases — version, packages, keyring, kernel, then the big one,
  `mkarchiso`, which actually squashes everything into the ISO.

Lots of text scrolls past. That's normal. Leave it running.

You will see error-messages - that is normal too.

---

## 5. Optional: tweak it before building

You don't have to change anything — the defaults are good. But if you want to, open
`build-scripts/build.conf` (a plain settings file — assignments only, no code):

```bash
bump_version="yes"                 # auto-set the version to today's date
nvidia_driver="open"               # open | 580xx | 390xx  (NVIDIA driver set)
kernel="linux-cachyos linux-zen"   # which kernel(s) to include; first = the one it boots
editions="xfce ohmychadwm"         # which desktop/WM session(s) to bake in
default_session="xfce"             # which session the live ISO logs into
```

| Setting | What it does | Leave it as |
|---------|--------------|-------------|
| `nvidia_driver` | Which NVIDIA driver ships. `open` suits modern cards; `580xx`/`390xx` are for older ones | `open` if unsure |
| `kernel` | Which Linux kernel(s) the ISO carries | the default |
| `bump_version` | Whether to stamp today's date as the version | `yes` |
| `editions` | Which desktop/WM sessions to include. Add e.g. `i3` or `qtile`; or go minimal like `editions="cinnamon"` | `"xfce ohmychadwm"` |
| `default_session` | Which session the live ISO autologs into (must be one of `editions`) | `xfce` |

Want **extra apps** that aren't on the ISO by default? List their keys (one per line) in
`build-scripts/package-additions.conf` — e.g. add a line `wps` to bake in WPS Office. An empty
file (the default) adds nothing.

Save the file, then run `./build-the-iso.sh`.

---

## 6. Where's my ISO?

When the build finishes you'll find everything in `~/kiro-Out/`:

```bash
ls -lh ~/kiro-Out/
```

- `kiro-vYY.MM.DD-x86_64.iso` — your ISO
- `.sha1`, `.sha256`, `.md5` — checksums (proof the file isn't corrupted)
- `.pkglist.txt` — the full list of packages that went in

---

## 7. Test it safely (do this before real hardware)

Always boot your fresh ISO in a **virtual machine** first — never write an untested ISO
straight to your main computer's disk. A quick QEMU test:

```bash
sudo pacman -S --needed qemu-desktop edk2-ovmf   # one-time
qemu-system-x86_64 -enable-kvm -m 4096 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -cdrom ~/kiro-Out/kiro-*.iso
```

Or just point VirtualBox / GNOME Boxes at the ISO. If it boots to the desktop, you built it
right.

---

## 8. The repositories, explained (do I need special access?)

**No.** Everything the build pulls from is **public** — no account, no password, no private
keys. There are four extra software sources:

| Repository | What it provides | Setup needed |
|------------|------------------|--------------|
| `kiro_repo` | Kiro's own packages | None — it's just a public web address |
| `nemesis_repo` | Themes, shells, configs | None — public web address |
| `chaotic-aur` | Pre-built community packages | Done **automatically** by `./build-the-iso.sh` |
| `cachyos` | The `linux-cachyos` kernel | Done **automatically** by `./build-the-iso.sh` |

So the honest answer to "what access do we need?" is: just an internet connection.

---

## 9. When it breaks — common fixes

| Symptom | Fix |
|---------|-----|
| `No space left on device` | Free up ~15 GB; the build writes to `~/kiro-build` and `~/kiro-Out` |
| Downloads fail / time out | Check your internet; re-run `./build-the-iso.sh` (it picks back up cleanly) |
| `mkarchiso: command not found` | You're not on an Arch-based system — build inside an Arch VM (see §2) |
| A keyring / signature error | Re-run `./build-the-iso.sh`; it refreshes the Chaotic and CachyOS keyrings |
| "do not run as root" | Run `./build-the-iso.sh` as your **normal** user, not with `sudo` in front |

If a run dies partway, just run `./build-the-iso.sh` again — it rebuilds from a clean slate each time.

---

## 10. Make it yours

This is the fun part. The ISO is *yours* to change:

- **Add or remove software:** edit `archiso/packages.x86_64` (one package per line). It has
  comment tiers telling you what's safe to change.
- **Add opt-in apps the easy way:** list app keys in `build-scripts/package-additions.conf`
  instead of editing the package list by hand (see §5).
- **Ship a different desktop or window manager:** set `editions=` in `build-scripts/build.conf`
  (see §5) — e.g. `editions="xfce ohmychadwm i3"` adds an i3 session, or `editions="cinnamon"`
  builds a pure-Cinnamon ISO.
- **Change settings/files on the live system:** drop files into `archiso/airootfs/` — anything
  there lands at `/` on the built ISO.
- **Pick a different kernel or NVIDIA driver:** see §5.


> **Coming later:** a clickable GTK app — *Kiro ISO Builder* — that runs this whole process in
> a window and fixes common host problems for you with one click. For now, `./build-the-iso.sh` is all
> you need.

---

Happy building. If you make something cool, share it — that's the whole point of letting you
build your own.
