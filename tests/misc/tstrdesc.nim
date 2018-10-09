var
  x: array[0..2, int]

x = [0, 1, 2]

type
  TStringDesc {.final.} = object
    len, space: int # len and space without counting the terminating zero
    data: array[0..0, char] # for the '\0' character

var
  emptyString {.exportc: "emptyString".}: TStringDesc


