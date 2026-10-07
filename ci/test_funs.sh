#!/usr/bin/env bash
# Offline regression tests for the shared bootstrap and CI helpers.
set -eu
trap 'echo "CI helper test failed at line $LINENO" >&2' ERR

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/nim-ci-helpers.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

source_repo="$test_dir/source"
workspace="$test_dir/workspace"
mkdir -p "$source_repo" "$workspace/config" "$workspace/bin"
git init -q "$source_repo"
git -C "$source_repo" config user.name 'CI helper tests'
git -C "$source_repo" config user.email 'ci@example.invalid'
git -C "$source_repo" config commit.gpgsign false
cat > "$source_repo/Makefile" <<'EOF'
.PHONY: all
all:
	cp bootstrap ../bin/nim
	chmod +x ../bin/nim
EOF
cat > "$source_repo/bootstrap" <<'EOF'
#!/bin/sh
echo 'pinned bootstrap'
EOF
git -C "$source_repo" add Makefile bootstrap
git -C "$source_repo" commit -qm 'Pinned bootstrap'
pin=$(git -C "$source_repo" rev-parse HEAD)
source_branch=$(git -C "$source_repo" symbolic-ref --short HEAD)
sed 's/pinned bootstrap/branch head/' "$source_repo/bootstrap" > "$test_dir/bootstrap"
cp "$test_dir/bootstrap" "$source_repo/bootstrap"
git -C "$source_repo" commit -qam 'Advance the branch beyond the pin'
tip=$(git -C "$source_repo" rev-parse HEAD)
cat > "$workspace/config/build_config.txt" <<EOF
nim_csourcesDir=csources_v3
nim_csourcesUrl='$source_repo'
nim_csourcesBranch=$source_branch
nim_csourcesHash=$pin
EOF
cached="$workspace/bin/nim_csources_$pin"
git init -q "$workspace"
git -C "$workspace" config user.name 'CI helper tests'
git -C "$workspace" config user.email 'ci@example.invalid'
git -C "$workspace" config commit.gpgsign false
echo 'Nim parent repository' > "$workspace/marker"
git -C "$workspace" add marker
git -C "$workspace" commit -qm 'Parent repository must not change'
parent_pin=$(git -C "$workspace" rev-parse HEAD)

bootstrap() {
  # A separate shell preserves errexit even when this command is used in an if.
  NIM_CSOURCES_STRICT=${NIM_CSOURCES_STRICT:-1} \
    bash -ec 'cd "$1"; . "$2"; nimBuildCsourcesIfNeeded CC=gcc' \
    _ "$workspace" "$repo_dir/ci/funs.sh"
}

bootstrap > "$test_dir/build.log" 2>&1
test "$(git -C "$workspace/csources_v3" rev-parse HEAD)" = "$pin"
test "$("$workspace/bin/nim" -v)" = 'pinned bootstrap'
test -x "$cached"
echo 'PASS: a cold bootstrap fetches a historical pin, not the branch head'

echo 'untracked build output' > "$workspace/csources_v3/bootstrap.o"
rm "$workspace/bin/nim"
bootstrap > "$test_dir/build-output.log" 2>&1
test "$("$workspace/bin/nim" -v)" = 'pinned bootstrap'
test -f "$workspace/csources_v3/bootstrap.o"
echo 'PASS: strict cache hits tolerate and preserve normal untracked build output'

git -C "$workspace/csources_v3" fetch -q "$source_repo" "$tip"
git -C "$workspace/csources_v3" checkout -q --detach "$tip"
rm "$cached"
bootstrap > "$test_dir/reuse.log" 2>&1
test "$(git -C "$workspace/csources_v3" rev-parse HEAD)" = "$pin"
test "$("$workspace/bin/nim" -v)" = 'pinned bootstrap'
echo 'PASS: an existing csources checkout is returned to the configured pin'

# Keep a valid pin cache present: a developer's supplied sources take priority.
git -C "$workspace/csources_v3" checkout -q --detach "$tip"
NIM_CSOURCES_STRICT=0 bootstrap > "$test_dir/local-checkout.log" 2>&1
test "$(git -C "$workspace/csources_v3" rev-parse HEAD)" = "$tip"
test "$("$workspace/bin/nim" -v)" = 'branch head'
test "$("$cached" -v)" = 'pinned bootstrap'
echo 'PASS: local builds preserve a custom checkout without replacing the pin cache'

echo '# local modification' >> "$workspace/csources_v3/bootstrap"
NIM_CSOURCES_STRICT=0 bootstrap > "$test_dir/local-dirty.log" 2>&1
test "$(tail -n 1 "$workspace/csources_v3/bootstrap")" = '# local modification'
if bootstrap > "$test_dir/strict-dirty.log" 2>&1; then
  echo 'FAIL: strict mode accepted dirty csources' >&2
  exit 1
fi
test "$(git -C "$workspace/csources_v3" rev-parse HEAD)" = "$tip"
echo 'PASS: local edits are preserved and strict CI refuses a dirty checkout'

rm -rf "$workspace/csources_v3"
mkdir "$workspace/csources_v3"
cp "$source_repo/Makefile" "$workspace/csources_v3/Makefile"
sed 's/branch head/supplied archive/' "$source_repo/bootstrap" > "$workspace/csources_v3/bootstrap"
NIM_CSOURCES_STRICT=0 bootstrap > "$test_dir/local-archive.log" 2>&1
test "$("$workspace/bin/nim" -v)" = 'supplied archive'
test "$("$cached" -v)" = 'pinned bootstrap'
if bootstrap > "$test_dir/strict-archive.log" 2>&1; then
  echo 'FAIL: strict mode accepted an archive as a Git checkout' >&2
  exit 1
fi
test "$(git -C "$workspace" rev-parse HEAD)" = "$parent_pin"
test ! -f "$workspace/.git/shallow"
test "$(cat "$workspace/marker")" = 'Nim parent repository'
mkdir "$workspace/csources_v3/.git"
if bootstrap > "$test_dir/interrupted-init.log" 2>&1; then
  echo 'FAIL: strict mode accepted an incomplete git init' >&2
  exit 1
fi
test "$(git -C "$workspace" rev-parse HEAD)" = "$parent_pin"
test ! -f "$workspace/.git/shallow"
echo 'PASS: archives build locally and Git never operates on the enclosing Nim repo'

rm -rf "$workspace/csources_v3"
mv "$source_repo" "$test_dir/offline-source"
rm "$workspace/bin/nim"
bootstrap > "$test_dir/cache.log" 2>&1
test "$("$workspace/bin/nim" -v)" = 'pinned bootstrap'
test ! -d "$workspace/csources_v3"
echo 'PASS: a cache hit installs bin/nim without fetching or rebuilding'

rm "$cached"
if bootstrap > "$test_dir/fetch-failure.log" 2>&1; then
  echo 'FAIL: a failed fetch was reported as a successful bootstrap' >&2
  exit 1
fi
test ! -e "$cached"
echo 'PASS: a failed fetch does not publish a bootstrap compiler'

mv "$test_dir/offline-source" "$source_repo"
mkdir "$test_dir/commands"
cat > "$test_dir/commands/make" <<'EOF'
#!/bin/sh
exit 17
EOF
chmod +x "$test_dir/commands/make"
if PATH="$test_dir/commands:$PATH" bootstrap > "$test_dir/make-failure.log" 2>&1; then
  echo 'FAIL: a failed make was reported as a successful bootstrap' >&2
  exit 1
else
  test "$?" -eq 17
fi
test ! -e "$cached"
echo 'PASS: a failed build does not cache an older bin/nim'

if NIM_CSOURCES_STRICT=1 PATH="$test_dir/commands:$PATH" bash -ec \
    'cd "$1"; . "$2"; if nimBuildCsourcesIfNeeded CC=gcc; then exit 0; else exit $?; fi' \
    _ "$workspace" "$repo_dir/ci/funs.sh" > "$test_dir/conditional-failure.log" 2>&1; then
  echo 'FAIL: checking bootstrap status hid a failed build' >&2
  exit 1
else
  test "$?" -eq 17
fi
test ! -e "$cached"
echo 'PASS: bootstrap failure propagates even when the caller checks its status'

cat > "$workspace/koch" <<'EOF'
#!/bin/sh
touch koch-was-run
EOF
chmod +x "$workspace/koch"
if bash -ec 'cd "$1"; . "$2"; nim() { return 42; }; nimInternalBuildKochAndRunCI' \
    _ "$workspace" "$repo_dir/ci/funs.sh" > "$test_dir/koch-failure.log" 2>&1; then
  echo 'FAIL: a failed koch compilation was ignored' >&2
  exit 1
else
  test "$?" -eq 42
fi
test ! -e "$workspace/koch-was-run"
echo 'PASS: a failed koch compilation does not run a stale koch executable'

cat > "$test_dir/commands/curl" <<'EOF'
#!/bin/sh
for arg do
  if test "$arg" = '--fail'; then
    exit 22
  fi
done
exit 0
EOF
cat > "$test_dir/commands/7z" <<'EOF'
#!/bin/sh
touch archive-was-extracted
EOF
chmod +x "$test_dir/commands/curl" "$test_dir/commands/7z"
mkdir "$workspace/dist"
if PATH="$test_dir/commands:$PATH" bash -ec \
    'cd "$1"; . "$2"; nimInternalInstallDepsWindows' \
    _ "$workspace" "$repo_dir/ci/funs.sh" > "$test_dir/download-failure.log" 2>&1; then
  echo 'FAIL: an HTTP download failure was ignored' >&2
  exit 1
else
  test "$?" -eq 22
fi
test ! -e "$workspace/archive-was-extracted"
echo 'PASS: HTTP failures stop dependency installation before extraction'

rm -rf "$workspace/csources_v3"
real_git=$(command -v git)
cat > "$test_dir/commands/git" <<EOF
#!/bin/sh
if test "\$1" = fetch; then
  for arg do
    if test "\$arg" = --depth; then
      exit 23
    fi
  done
fi
exec '$real_git' "\$@"
EOF
chmod +x "$test_dir/commands/git"
# Earlier tests installed a deliberately failing make wrapper.
rm "$test_dir/commands/make"
PATH="$test_dir/commands:$PATH" bootstrap > "$test_dir/fallback.log" 2>&1
test "$(git -C "$workspace/csources_v3" rev-parse HEAD)" = "$pin"
test "$("$workspace/bin/nim" -v)" = 'pinned bootstrap'
echo 'PASS: branch-history fallback still builds the exact historical pin'
