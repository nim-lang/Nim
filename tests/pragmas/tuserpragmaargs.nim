var foo {.exportc: "abc".} = 123
{.pragma: importc2, importc.}
var bar {.importc2: "abc".}: int #[tt.Error
                  ^ user pragma cannot have arguments]#
echo bar
