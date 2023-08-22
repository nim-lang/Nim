# bug #16706

block: # reduced example
  type
    A = object of RootObj
      a0: string
    B = object
      b0: seq[A]
  var c = newSeq[A](2)
  var d = B(b0: c)

when true: # original example
  import std/[options, tables, times]

  type
    Data* = object
      shifts*: OrderedTable[int64, Shift]
      balance*: float

    Shift* = object
      quoted*: bool
      date*: DateTime
      description*: string
      start*: Option[DateTime]
      finish*: Option[DateTime]
      breakTime*: Option[Duration]
      rate*: float
      qty: Option[float]
      id*: int64

  let shift = Shift(
    quoted: true,
    date: parse("2000-01-01", "yyyy-MM-dd"),
    description: "abcdef",
    start: none(DateTime),
    finish: none(DateTime),
    breakTime: none(Duration),
    rate: 462.11,
    qty: some(10.0),
    id: getTime().toUnix()
  )

  var shifts: OrderedTable[int64, Shift]
  shifts[shift.id] = shift

  discard Data(
    shifts: shifts,
    balance: 0.00
  )
