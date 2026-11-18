var counter* {.threadvar.}: int
var names* {.threadvar.}: seq[string]

proc bump*(): int =
  inc counter
  counter

proc remember*(name: string) =
  names.add name
