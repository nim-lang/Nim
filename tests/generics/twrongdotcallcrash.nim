# issue #25000

proc r(T: typedesc[int]): int = discard
proc c[J: typedesc[uint]](u = J.r) = discard #[tt.Error
                               ^ undeclared field: 'r']#
c[uint]()
