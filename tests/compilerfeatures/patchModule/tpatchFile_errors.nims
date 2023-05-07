# See `tpatchFile_errors`

switch("hint", "all:off")
switch("warning", "all:off")
--warning:CannotOpen

# Try importing the target module in the patch:
patchFile("stdlib", "oids", "mpatchFile_imports_patch_target")

# Try including the target module in the patch:
patchFile("stdlib", "net", "mpatchFile_includes_patch_target")
