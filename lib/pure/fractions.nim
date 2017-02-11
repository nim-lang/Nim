#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Adel Qalieh
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##   A man is like a fraction whose numerator is what he is and whose
##   denominator is what he thinks of himself. The larger the denominator, the
##   smaller the fraction. -- Leo Tolstoy
## 
## Rational number arithmetic for Nim.

import math
import unittest

proc gcd*(a, b): int =
  ## Greatest common divisor
  var
    a = a
    b = b
  while b != 0:
    a = a mod b
    swap a, b
  return a

type
  Fraction* = object of RootObj
    numerator*: int
    denominator*: int

proc newFraction(numerator: int, denominator: int): Fraction =
  let g:int = gcd(numerator, denominator)
  result.numerator = numerator div g
  result.denominator = denominator div g

proc `+` (a, b: Fraction): Fraction =
  return newFraction(a.numerator * b.denominator +
                     b.numerator * a.denominator,
                     a.denominator * b.denominator)

proc `-` (a, b: Fraction): Fraction =
  return newFraction(a.numerator * b.denominator -
                     b.numerator * a.denominator,
                     a.denominator * b.denominator)

proc `*` (a, b: Fraction): Fraction =
  return newFraction(a.numerator * b.numerator, a.denominator * b.denominator)

proc `/` (a, b: Fraction): Fraction =
  return newFraction(a.numerator * b.denominator, a.denominator * b.numerator)

proc floor(a: Fraction): Fraction =
  return newFraction(a.numerator div a.denominator, 1)

proc `div` (a, b: Fraction): Fraction =
  return floor(a / b)

proc `mod` (a, b: Fraction): Fraction =
  return a - b * (a div b)
