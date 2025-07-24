type
  Noice* = object
    hidden: int

template jjj*: Noice =
  Noice(hidden: 15)

type Opt* = object
  o: int

template none*(O: type Opt): Opt = Opt(o: 0)
