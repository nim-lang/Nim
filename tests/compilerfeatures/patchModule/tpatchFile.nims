# See `tpatchFile`

switch("hint", "all:off")
switch("warning", "all:off")
--warning:CannotOpen

# Patch a foreign and `stdlib` module:
patchFile("stdlib", "httpclient", "mpatchFile")

# Try importing the target module in the patch:
patchFile("stdlib", "oids", "mpatchFile_imports_patch_target")

# Try including the target module in the patch:
patchFile("stdlib", "net", "mpatchFile_includes_patch_target")

#======================================
# Test how non-module paths are handled
#======================================

# # Create some test dependencies:
import std/[os, strformat, macros]
macro buildLib(module) =
  let id = module.strVal
  quote do:
    echo staticExec(getCurrentCompilerExe() & "c --verbosity:0 --nimMainPrefix:" & `id` &
                    " --noMain --app:staticLib  -o:" & `id` & ".lib " & `id` & ".nim")
buildLib mpatchModule_cmdline_linked_a
buildLib mpatchModule_pragma_linked_a
buildLib mpatchModule_cmdline_linked_b
buildLib mpatchModule_pragma_linked_b

# XXX: These paths are being prefixed with `thisDir()` because `--link` and
#      `--compile` don't try resolving the path relative to this script.
#      I think that is a bug.
switch("link", thisDir()/"mpatchModule_cmdline_linked_a.lib")
switch("compile", thisDir()/"tpatchModule_cmdline_compiled_a.c")

# # Patch module:
# patchModule("mpatchModule_cmdline_linked_a.lib", "mpatchModule_cmdline_linked_b.lib")

# # Try patching a non-module path relative to this script that is `system.staticRead`:
# patchModule("../dummy.txt", "../readme.md")

# Try patching a non-module path relative to a search path that is `system.staticRead`:
switch("path", ".."/"..")
patchFile("compiler", "dummy", "../readme.md")
