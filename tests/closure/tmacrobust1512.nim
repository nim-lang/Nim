discard """
output: ""
"""

import macros, strutils

# https://github.com/nim-lang/Nim/issues/1512

proc macrobust0(input: string): string =
  var output = ""
  proc p1(a:string) =
    output.add(a)

  proc p2(a:string) = p1(a)
  proc p3(a:string) = p2(a)
  proc p4(a:string) = p3(a)
  proc p5(a:string) = p4(a)
  proc p6(a:string) = p5(a)
  proc p7(a:string) = p6(a)
  proc p8(a:string) = p7(a)
  proc p9(a:string) = p8(a)
  proc p10(a:string) = p9(a)
  proc p11(a:string) = p10(a)
  proc p12(a:string) = p11(a)
  proc p13(a:string) = p12(a)
  proc p14(a:string) = p13(a)
  proc p15(a:string) = p14(a)
  proc p16(a:string) = p15(a)
  proc p17(a:string) = p16(a)
  proc p18(a:string) = p17(a)
  proc p19(a:string) = p18(a)
  proc p20(a:string) = p19(a)

  for a in input.split():
    p20(a)
    p19(a)
    p18(a)
    p17(a)
    p16(a)
    p15(a)
    p14(a)
    p13(a)
    p12(a)
    p11(a)
    p10(a)
    p9(a)
    p8(a)
    p7(a)
    p6(a)
    p5(a)
    p4(a)
    p3(a)
    p2(a)
    p1(a)

  result = output

macro macrobust(input: static[string]): untyped =
  var output = ""
  proc p1(a:string) =
    output.add(a)

  proc p2(a:string) = p1(a)
  proc p3(a:string) = p2(a)
  proc p4(a:string) = p3(a)
  proc p5(a:string) = p4(a)
  proc p6(a:string) = p5(a)
  proc p7(a:string) = p6(a)
  proc p8(a:string) = p7(a)
  proc p9(a:string) = p8(a)
  proc p10(a:string) = p9(a)
  proc p11(a:string) = p10(a)
  proc p12(a:string) = p11(a)
  proc p13(a:string) = p12(a)
  proc p14(a:string) = p13(a)
  proc p15(a:string) = p14(a)
  proc p16(a:string) = p15(a)
  proc p17(a:string) = p16(a)
  proc p18(a:string) = p17(a)
  proc p19(a:string) = p18(a)
  proc p20(a:string) = p19(a)

  for a in input.split():
    p20(a)
    p19(a)
    p18(a)
    p17(a)
    p16(a)
    p15(a)
    p14(a)
    p13(a)
    p12(a)
    p11(a)
    p10(a)
    p9(a)
    p8(a)
    p7(a)
    p6(a)
    p5(a)
    p4(a)
    p3(a)
    p2(a)
    p1(a)

  result = newLit(output)

const input = """
  fdsasadfsdfa sadfsdafsdaf
  dsfsdafdsfadsfa fsdaasdfasdf
  fsdafsadfsad asdfasdfasdf
  fdsasdfasdfa sadfsadfsadf
  sadfasdfsdaf sadfsdafsdaf dsfasdaf
  sadfsdafsadf fdsasdafsadf fdsasadfsdaf
  sdfasadfsdafdfsa sadfsadfsdaf
  sdafsdaffsda sdfasadfsadf
  fsdasdafsdfa sdfasdfafsda
  sdfasdafsadf sdfasdafsdaf sdfasdafsdaf
"""

let str1 = macrobust(input)
let str2 = macrobust0(input)

doAssert str1 == str2
