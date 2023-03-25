type
  Noice* = object
    hidden: int

  Ciao* = object
    hidden1: int
    hidden2: int

  Gull* = ref object
    hidden1: int
    field*: int
    hidden2: int
    field2*: int


template jjj*(): Noice =
  var x = 7
  Noice(hidden: 15)

template said*(): Ciao =
  var x = 7
  Ciao(hidden1: 15 + x, 1)

proc foo*: Gull =
  result = Gull(1, 2, 3, 4)
