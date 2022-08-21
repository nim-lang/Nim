import pkgA/module as A
import pkgB/module as B
import pkgC/module as C

doAssert pkgATest() == 1, "Simple pkgA-0.1.0 wasn't added to path correctly."
doAssert pkgBTest() == 0xDEADBEEF, "pkgB-#head wasn't picked over pkgB-0.1.0"
doAssert pkgCTest() == 0xDEADBEEF, "pkgC-#head wasn't picked over pkgC-#aa11"
