discard """
targets: "c"
ccodecheck: "\\i @('atmaatsmodule_name_clashesdotnim_DatInit000')"
ccodecheck: "\\i @('atmbatsmodule_name_clashesdotnim_DatInit000')"
joinable: false
"""

# Test module name clashes within same package.
# This was created to test that module symbol mangling functioned correctly
# for the C backend when there are one or more modules with the same name in
# a package, and more than one of them require module initialization procs.
# I'm not sure of the simplest method to cause the init procs to be generated.

import a/module_name_clashes

print A()
