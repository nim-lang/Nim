type
  VtableBaseA* = ref object of RootObj

method say*(a: VtableBaseA): string {.base.} =
  "base"
