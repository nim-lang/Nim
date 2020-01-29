# import * from 'xyz'
proc esImportAll*(nameOrPath: cstring) {.importcpp: "import * from #".}

# import xyz from 'xyz'
proc esImportDefault*(name: cstring, nameOrPath: cstring) {.
    importcpp: "import # from #".}

# import { default as abc } from 'xyz'
proc esImportDefaultAs*(name: cstring, nameOrPath: cstring) {.
    importcpp: "import { default as # } from #".}

# import { x } from 'xyz'
proc esImport*(name: cstring, nameOrPath: cstring) {.
    importcpp: "import { # } from #".}

