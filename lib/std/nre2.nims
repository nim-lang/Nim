import std/os

if getCommand() == "doc":
  # std/nre2 requires nim-regex and it requires nim-unicodedb.
  # when build documentation on CI, git clone them as nimble is not available

  const PkgDir = "build/deps"
  const Pkgs = ["nim-regex", "nim-unicodedb"]

  for n in Pkgs:
    if not dirExists(PkgDir / n):
      exec("git clone -q https://github.com/nitely/" & n & " " & (PkgDir / n))

    switch("path", "$nim" / PkgDir / n / "src")
