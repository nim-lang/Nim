# Helper for `ttryimport`: chooses a code path via stew-style `tryImport`, which
# hides the optional `import moptdep` inside a template (see mtryimportlib.nim).
# No `import moptdep` is textually visible here, and the `else` branch does not
# import it either, so a wrong `compiles` result would never self-heal.
# Guards that `compiles((; import moptdep))` resolves the SAME under `nim ic` as
# under whole-program `nim c` (where it is `true`).
import mtryimportlib

when tryImport moptdep:
  proc chosen*(): string = optValue()
else:
  proc chosen*(): string = "optional-MISSING"
