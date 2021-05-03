import std/private/since
import strutils

since (1, 1):
  const
    invalidFilenameChars* = {'/', '\\', ':', '*', '?', '"', '<', '>', '|', '\0'} ## \
    ## Chars that may produce invalid filenames across Linux, Windows, Mac, etc.
    ## You can check if your filename contains these chars and strip them for safety,
    ## See also `isPortableFilename`.
    ##
    ## Mac bans ``{':', `/`, '\0'}``, Linux bans ``{`/`, '\0'}``, Windows bans all of these.
    ##
    ## .. Note:: other characters that may cause problems are non-printable characters, e.g.
    ##    ascii characters in the range `0..31`, or characters not in the range `128..255`.
    invalidFilenames* = [
      "CON", "PRN", "AUX", "NUL",
      "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
      "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"] ## \
    ## Filenames that may be invalid across Linux, Windows, Mac, etc.
    ## You can check if your filename match these and rename it for safety
    ## (Currently all invalid filenames are from Windows only).
    ##
    ## Example: `con.txt` and `CON` are invalid, but `con.bar.txt` is valid.

#[
xxx add `runnableExamples` pending https://github.com/timotheecour/Nim/issues/716
xxx we also need to handle this rule: `Use any character in the current code page for a name, including Unicode characters and characters in the extended character set (128–255), except for the following: [...]`
for e.g., `char(1)` may be invalid.
refs: https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
]#

const 
  windowsPathMaxLen* = 259 ## Maximum path length on windows excluding a terminating ``\0``.
    # See also https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=cmd
    # This is intentionally exposed for all platforms, and prefixed with `windows`,
    # so clients can write portable code.
    # This corresponds to `MAX_PATH` = 260 which include trailings ``\0``.

const
  windowsFilenameMaxLen* = 255 ## Maximum filename length on windows, e.g., 255 consecutive `a` is valid.
  # it's hard to find official docs regarding whether it includes or excludes terminating ``\0``, but
  # this link shows it excludes it: https://arstechnica.com/civis/viewtopic.php?f=17&t=1466908
  # the doc comment makes this hopefully clear. ``\0`` is only meaningful for the whole path, not a path component.
  # see also `lpMaximumComponentLength`.

const
  windowsDirPartMaxLen* = 243
    ## Maximum length of a directory component on windows, e.g. `foo` has length 3.

  windowsDirMaxLen* = 246
    ## Maximum length of a directory name on windows, including the drive prefix, e.g. ``C:\a\foo`` has length 8.
    ##
    ## This is such that you can always create an ``8.3`` file (e.g. ``12345678.txt``) inside it, e.g.:
    ## ``246 + 1('\') + 12 + 1('\0') = 259 + 1``
    # refs https://social.technet.microsoft.com/Forums/windows/en-US/43945b2c-f123-46d7-9ba9-dd6abc967dd4/maximum-path-length-limitation-on-windows-is-255-or-247?forum=w7itprogeneral
    # offers a good explanation; see also: https://en.wikipedia.org/wiki/8.3_filename

from os import splitFile

func isPortableFilename*(filename: string, maxLen = windowsFilenameMaxLen): bool {.since: (1, 5, 1).} =
  ## Returns true if `filename` is portable for cross-platform use.
  ##
  ## This is useful if you want to copy or save files across Windows, Linux, Mac, etc.
  ## It uses `invalidFilenameChars`, `invalidFilenames` and `maxLen` to verify `filename`.
  ##
  ## .. Note:: this can also be used for validating dir components, but note that
  ##   windows paths have other limits, see `windowsPathMaxLen`, `windowsDirPartMaxLen`, `windowsDirMaxLen`.
  runnableExamples:
    block:
      assert isPortableFilename("abc", maxLen = 3) # `maxLen` excludes the trailing ``\0``
      assert not isPortableFilename("abcd", maxLen = 3)

    for name in [
      "\xA0foo", # no break-space is valid
      "files.tar.gz", ".htaccess",
      "with some internal spaces .txt", # so long ' ' is not leading/trailing
      "mixed_CASE_",
      "con.foo.txt", # despite `con` being in `invalidFilenames`.
    ]:
      assert isPortableFilename(name), name

    for name in [
        "", # empty
        "foo/bar", r"foo\bar", # contains `/` or ``\``
        "foo:bar", # doesn't work in some osx programs
        " foo", "foo ", # leading/trailing ' ' is invalid in some windows programs
        "foo.", # trailing `.`
        "con", "CON", "con.txt", "AUX.bat", # see `invalidFilenames`.
      ]:
      assert not isPortableFilename(name), name
  # https://docs.microsoft.com/en-us/dotnet/api/system.io.pathtoolongexception
  # https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=cmd
  # https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
  # https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
  # https://docs.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/file-folder-name-whitespace-characters
  # Note, a trailing '\0' is only meaningful when discussing path length, not filename length.
  # https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=cmd
  # super helpful explanation regarding path length limitations: https://social.technet.microsoft.com/Forums/windows/en-US/43945b2c-f123-46d7-9ba9-dd6abc967dd4/maximum-path-length-limitation-on-windows-is-255-or-247?forum=w7itprogeneral
  if filename.len > maxLen: result = false
  elif filename.len == 0: result = false
  elif filename[0] == ' ': result = false
  elif filename[^1] in {' ', '.'}: result = false
  elif find(filename, invalidFilenameChars) != -1: result = false
    # xxx also exclude characters not in `128..255` ?
  else:
    let f = filename.splitFile
    for a in invalidFilenames:
      if cmpIgnoreCase(f.name, a) == 0: return false
    result = true
