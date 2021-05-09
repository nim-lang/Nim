import std/strutils

from std/os import fileExists

import std/typetraits as typetraits2
from std/setutils import complement





proc fn1() = discard
proc fn2*() = discard


let fn4 = 0
let fn5* = 0


const fn7 = 0
const fn8* = 0

type T1 = object
