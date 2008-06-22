var
  x: array [0..2, int]

x = [0, 1, 2]

type
  TStringDesc = record
    len, space: int # len and space without counting the terminating zero
    data: array [0..0, char] # for the '\0' character

var
  emptyString {.export: "emptyString".}: TStringDesc = (
    len: 0, space: 0, data: ['\0']
  )

