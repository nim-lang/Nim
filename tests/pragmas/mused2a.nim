import std/strutils
import std/sugar
from std/os import fileExists
import std/enumutils as enumutils2
import std/typetraits as typetraits2
from std/setutils import complement

{.used: strutils.}
{.used: enumutils2.}
{.used: complement.}

proc fn1() = discard
proc fn2*() = discard
proc fn3() = discard

let fn4 = 0
let fn5* = 0
let fn6 = 0

const fn7 = 0
const fn8* = 0
const fn9 = 0
type T1 = object
type T2 = object

{.used: fn3.}
{.used: fn6.}
{.used: fn9.}
{.used: T2.}
