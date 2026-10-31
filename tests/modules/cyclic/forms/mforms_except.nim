import ../timport_forms {.cyclic.} except hidden

proc hidden*(): int = 20
proc fe*(): int = fa() + 1 + hidden()
