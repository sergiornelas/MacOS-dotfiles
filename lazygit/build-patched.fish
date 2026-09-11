#!/usr/bin/env fish
#
# Builds lazygit with syntax highlighting in the merge conflicts view.
#
# Upstream renders that view itself (it's the raw file, not a diff) so the
# configured diff renderer never touches it and every line comes out in the
# default colour. patches/conflict-syntax-highlighting.patch runs the content
# through chroma instead. See https://github.com/jesseduffield/lazygit/issues/1735
#
# The result lands in ~/.local/bin, which sits ahead of Homebrew in $PATH, so
# `lazygit` picks it up. Re-run this after every `brew upgrade lazygit` to
# rebuild against the new version (otherwise the patched binary silently keeps
# you on the old one).
#
#   fish ~/.config/lazygit/build-patched.fish            # match the brewed version
#   fish ~/.config/lazygit/build-patched.fish v0.65.0    # or pin a tag

set -l SRC "$HOME/.local/src/lazygit"
set -l PATCH "$HOME/.config/lazygit/patches/conflict-syntax-highlighting.patch"
set -l DEST "$HOME/.local/bin/lazygit"

if not type -q go
    echo "go is not installed: brew install go" >&2
    exit 1
end

# The version to build: the argument, else whatever Homebrew has, else latest.
set -l TAG $argv[1]
if test -z "$TAG"
    set -l brewed (brew list --versions lazygit 2>/dev/null | string split ' ')[2]
    if test -n "$brewed"
        set TAG "v$brewed"
    else
        set TAG (git ls-remote --tags --sort=-v:refname https://github.com/jesseduffield/lazygit.git \
            | string match -rg 'refs/tags/(v[0-9.]+)$' | head -1)
    end
end

echo "building lazygit $TAG"

if not test -d "$SRC"
    mkdir -p (dirname "$SRC")
    git clone https://github.com/jesseduffield/lazygit.git "$SRC"; or exit 1
end

git -C "$SRC" fetch --tags origin; or exit 1
git -C "$SRC" checkout --force "$TAG"; or exit 1
git -C "$SRC" clean -fd -- pkg; or exit 1

git -C "$SRC" apply --verbose "$PATCH"
or begin
    echo "the patch no longer applies to $TAG -- rebase it against the new source" >&2
    exit 1
end

# lazygit vendors its dependencies, so chroma has to be vendored in too.
go -C "$SRC" mod vendor; or exit 1
go -C "$SRC" build -trimpath \
    -ldflags="-s -w -X main.version=$TAG-syntax -X main.buildSource=source -X main.date="(date -u +%Y-%m-%dT%H:%M:%SZ) \
    -o "$DEST" .; or exit 1

echo "installed $DEST"
$DEST --version
