discard """
  targets: "c cpp"
"""

import mvtables_reentry_a

type
  MainType = ref object of VtableBaseA

method say*(m: MainType): string =
  "main"

when isMainModule:
  import mvtables_reentry_b

  let a: VtableBaseA = VtableDerivedB()
  doAssert a.say() == "derived"
  let m: VtableBaseA = MainType()
  doAssert m.say() == "main"
