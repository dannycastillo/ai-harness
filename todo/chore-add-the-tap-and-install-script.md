# chore: the Homebrew formula and install.sh

- **Priority:** medium
- **Branch:** chore/add-the-tap-and-install-script
- **Touches:** NEW install.sh, NEW packaging/*, README.md
- **Blocked by:** feat-version-and-release.md, chore-drop-the-layout-guard.md, chore-make-the-repo-public.md

## Goal
A stranger installs with `brew install dannycastillo/tap/ai-harness` or one `curl | sh` line, and gets a working `aih`.

## Why
adr-2026-09-26-one-install-per-machine names both channels.

## Notes
- `packaging/ai-harness.rb`: the formula. `url` the release tarball,
  `sha256`, `libexec.install Dir["*"]`, `bin.write_exec_script
  libexec/"bin/aih"`, `test do` runs `aih version`. A human copies it into
  `dannycastillo/homebrew-tap` per release (`docs/releasing.md` gains that
  step).
- `install.sh`: POSIX sh. Downloads
  `https://github.com/dannycastillo/ai-harness/releases/download/v$V/ai-harness-$V.tar.gz`,
  checks the sha256 from the release's `.sha256` file, unpacks into
  `${XDG_DATA_HOME:-$HOME/.local/share}/ai-harness`, writes
  `~/.local/bin/aih`, prints what it did and whether `~/.local/bin` is on
  PATH. `AI_HARNESS_VERSION` picks a version; `AI_HARNESS_TARBALL` points
  at a local file for testing. Never runs as root, never touches a repo.
- Test the script against a local tarball from `git archive HEAD`, not
  the network. Test the formula with `brew install --build-from-source
  packaging/ai-harness.rb` if brew is present; otherwise `ruby -c`.
- **Never create the tap repo or a release from a worker.** Both are a
  human's.

## Done when
- [ ] `AI_HARNESS_TARBALL=<local> sh install.sh` into a scratch `HOME` leaves a working `aih version` and the launcher
- [ ] the script refuses a bad checksum with one line and changes nothing
- [ ] `packaging/ai-harness.rb` passes `ruby -c` and, with brew present, installs from source and its `test do` passes
- [ ] `docs/releasing.md` includes updating the tap
- [ ] README's install section shows both lines
- [ ] `aih gate` passes
