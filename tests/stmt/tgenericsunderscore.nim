# issue #21435

proc foo[_](x: typedesc[_]): string = "BAR" #[tt.Error
                        ^ the special identifier '_' is ignored in declarations and cannot be used]#
