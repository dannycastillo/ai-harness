#!/bin/sh
# install.sh — installs the aih launcher and its tree for one user.
#
#   curl -fsSL https://raw.githubusercontent.com/dannycastillo/ai-harness/main/install.sh | sh
#
# AI_HARNESS_VERSION picks a release tag (a bare X.Y.Z, no "v"); unset, the
# latest release. AI_HARNESS_TARBALL points at a local tarball for testing,
# skipping the download — a same-named ".sha256" file next to it, if
# present, is still checked.
#
# Never runs as root and never touches anything outside $HOME.

set -eu

REPO="dannycastillo/ai-harness"

die() {
	echo "install.sh: $1" >&2
	exit 1
}

[ "$(id -u)" -ne 0 ] || die "refuses to run as root"

fetch() {
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$1" -o "$2"
	elif command -v wget >/dev/null 2>&1; then
		wget -q "$1" -O "$2"
	else
		die "need curl or wget"
	fi
}

sha256() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$1" | awk '{print $1}'
	else
		die "need sha256sum or shasum"
	fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ -n "${AI_HARNESS_TARBALL:-}" ]; then
	tarball=$AI_HARNESS_TARBALL
	[ -f "$tarball" ] || die "no such file: $tarball"
	sha_file="$tarball.sha256"
	[ -f "$sha_file" ] || sha_file=""
else
	if [ -n "${AI_HARNESS_VERSION:-}" ]; then
		version=$AI_HARNESS_VERSION
	else
		latest_json="$tmp/latest.json"
		fetch "https://api.github.com/repos/$REPO/releases/latest" "$latest_json"
		version=$(sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' "$latest_json" | head -n1)
		[ -n "$version" ] || die "could not determine the latest version"
	fi
	asset="ai-harness-$version.tar.gz"
	tarball="$tmp/$asset"
	fetch "https://github.com/$REPO/releases/download/v$version/$asset" "$tarball"
	sha_file="$tmp/$asset.sha256"
	fetch "https://github.com/$REPO/releases/download/v$version/$asset.sha256" "$sha_file"
fi

if [ -n "$sha_file" ]; then
	want=$(awk '{print $1}' "$sha_file")
	have=$(sha256 "$tarball")
	[ "$want" = "$have" ] || die "checksum mismatch for $tarball — nothing installed"
fi

extract_dir="$tmp/extract"
mkdir -p "$extract_dir"
tar -xzf "$tarball" -C "$extract_dir"

top=$(find "$extract_dir" -mindepth 1 -maxdepth 1)
top_count=$(printf '%s\n' "$top" | grep -c .)
if [ "$top_count" -eq 1 ] && [ -d "$top" ]; then
	src=$top
else
	src=$extract_dir
fi
[ -f "$src/bin/aih" ] || die "tarball has no bin/aih"

data_home=${XDG_DATA_HOME:-$HOME/.local/share}
install_dir="$data_home/ai-harness"
bin_dir="$HOME/.local/bin"

mkdir -p "$data_home" "$bin_dir"
rm -rf "$install_dir"
mv "$src" "$install_dir"

cat >"$bin_dir/aih" <<EOF
#!/bin/sh
exec "\${AI_HARNESS_HOME:-$install_dir}/bin/aih" "\$@"
EOF
chmod +x "$bin_dir/aih"

printf 'installed ai-harness into %s\n' "$install_dir"
printf 'wrote the launcher to %s\n' "$bin_dir/aih"
case ":$PATH:" in
*":$bin_dir:"*)
	printf '%s is on PATH — run: aih version\n' "$bin_dir"
	;;
*)
	printf '%s is not on PATH — add it to your shell profile\n' "$bin_dir"
	;;
esac
