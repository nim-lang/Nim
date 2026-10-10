import mvtables_reentry_a

type
  VtableDerivedB* = ref object of VtableBaseA

method say*(d: VtableDerivedB): string =
  "derived"
