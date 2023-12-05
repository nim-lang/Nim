## This module implements helpers for determining special directories used by apps.

## .. importdoc:: paths.nim

from std/private/osappdirs import nil
import std/paths
import std/envvars

proc getHomeDir*(): Path {.inline, tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the home directory of the current user.
  ##
  ## This proc is wrapped by the `expandTilde proc`_
  ## for the convenience of processing paths coming from user configuration files.
  ##
  ## See also:
  ## * `getConfigDir proc`_
  ## * `getTempDir proc`_
  result = Path(osappdirs.getHomeDir())

proc getDataDir*(): Path {.inline, tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the data directory of the current user for applications.
  ## 
  ## On non-Windows OSs, this proc conforms to the XDG Base Directory
  ## spec. Thus, this proc returns the value of the `XDG_DATA_HOME` environment
  ## variable if it is set, otherwise it returns the default configuration
  ## directory ("~/.local/share" or "~/Library/Application Support" on macOS).
  ## 
  ## See also:
  ## * `getHomeDir proc`_
  ## * `getConfigDir proc`_
  ## * `getTempDir proc`_
  ## * `expandTilde proc`_
  ## * `getCurrentDir proc`_
  ## * `setCurrentDir proc`_
  result = Path(osappdirs.getDataDir())

proc getConfigDir*(): Path {.inline, tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the config directory of the current user for applications.
  ##
  ## On non-Windows OSs, this proc conforms to the XDG Base Directory
  ## spec. Thus, this proc returns the value of the `XDG_CONFIG_HOME` environment
  ## variable if it is set, otherwise it returns the default configuration
  ## directory ("~/.config/").
  ##
  ## An OS-dependent trailing slash is always present at the end of the
  ## returned string: `\\` on Windows and `/` on all other OSs.
  ##
  ## See also:
  ## * `getHomeDir proc`_
  ## * `getTempDir proc`_
  result = Path(osappdirs.getConfigDir())

proc getCacheDir*(): Path {.inline.} =
  ## Returns the cache directory of the current user for applications.
  ##
  ## This makes use of the following environment variables:
  ##
  ## * On Windows: `getEnv("LOCALAPPDATA")`
  ##
  ## * On macOS: `getEnv("XDG_CACHE_HOME", getEnv("HOME") / "Library/Caches")`
  ##
  ## * On other platforms: `getEnv("XDG_CACHE_HOME", getEnv("HOME") / ".cache")`
  ##
  ## **See also:**
  ## * `getHomeDir proc`_
  ## * `getTempDir proc`_
  ## * `getConfigDir proc`_
  # follows https://crates.io/crates/platform-dirs
  result = Path(osappdirs.getCacheDir())

proc getCacheDir*(app: Path): Path {.inline.} =
  ## Returns the cache directory for an application `app`.
  ##
  ## * On Windows, this uses: `getCacheDir() / app / "cache"`
  ## * On other platforms, this uses: `getCacheDir() / app`
  result = Path(osappdirs.getCacheDir(app.string))

proc getTempDir*(): Path {.inline, tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the temporary directory of the current user for applications to
  ## save temporary files in.
  ##
  ## On Windows, it calls [GetTempPath](https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw).
  ## On Posix based platforms, it will check `TMPDIR`, `TEMP`, `TMP` and `TEMPDIR` environment variables in order.
  ## On all platforms, `/tmp` will be returned if the procs fails.
  ##
  ## You can override this implementation
  ## by adding `-d:tempDir=mytempname` to your compiler invocation.
  ##
  ## .. Note:: This proc does not check whether the returned path exists.
  ##
  ## See also:
  ## * `getHomeDir proc`_
  ## * `getConfigDir proc`_
  result = Path(osappdirs.getTempDir())
