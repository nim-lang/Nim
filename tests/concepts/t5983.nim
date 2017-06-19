discard """
  output: "20.0 USD"
"""

import typetraits

const currencies = ["USD", "EUR"] # in real code 120 currencies

type USD* = distinct float # in real code 120 types generates using macro
type EUR* = distinct float

type CurrencyAmount = concept c
  type t = c.type
  const name = c.type.name
  name in currencies

proc `$`(x: CurrencyAmount): string =
  $float(x) & " " & x.name

let amount = 20.USD
echo amount

