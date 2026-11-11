var counter* = 0
proc bump*() = inc counter
proc show*(): string = "counter " & $counter & ", version 2"
