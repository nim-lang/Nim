discard """
$nimsuggest --tester $file
>use $1
def;;skEnum;;tuse_enum.Red;;Colour;;$file;;10;;4;;"";;100
use;;skEnum;;tuse_enum.Red;;Colour;;$file;;14;;8;;"";;100
"""

type
  Colour = enum
    Red
    Green
    Blue

discard #[!]#Red

