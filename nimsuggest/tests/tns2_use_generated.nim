# Code that a generic or a macro produces has the positions of their own
# source: the `fieldPairs` loop variable, the `quote do:`. `use` leaves those
# out, as the name is not written there and a rename must not edit them.

import mns2genlib

type Conf = object
  flag: bool

proc read(c: Conf): bool = c.flag

var conf = Conf()
setFlag(conf)
echo countFields(conf), read(conf)

discard """
$nimsuggest2 $file
>use $file:8:3
def;;skField;;tns2_use_generated.Conf.flag;;bool;;$file;;8;;2;;""
use;;skField;;tns2_use_generated.Conf.flag;;bool;;$file;;10;;29;;""
"""
