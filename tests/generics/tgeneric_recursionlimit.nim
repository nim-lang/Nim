discard """
  action: "compile"
"""

# https://github.com/nim-lang/Nim/issues/20348

type
  Payload[T] = object
    payload: T
  Carrier[T] = object
    val: T

type
  Payload0*[T] = object
    payload: Payload[T]
  Payload1*[T] = object
    payload: Payload[T]
  Payload2*[T] = object
    payload: Payload[T]
  Payload3*[T] = object
    payload: Payload[T]
  Payload4*[T] = object
    payload: Payload[T]
  Payload5*[T] = object
    payload: Payload[T]
  Payload6*[T] = object
    payload: Payload[T]
  Payload7*[T] = object
    payload: Payload[T]
  Payload8*[T] = object
    payload: Payload[T]
  Payload9*[T] = object
    payload: Payload[T]
  Payload10*[T] = object
    payload: Payload[T]
  Payload11*[T] = object
    payload: Payload[T]
  Payload12*[T] = object
    payload: Payload[T]
  Payload13*[T] = object
    payload: Payload[T]
  Payload14*[T] = object
    payload: Payload[T]
  Payload15*[T] = object
    payload: Payload[T]
  Payload16*[T] = object
    payload: Payload[T]
  Payload17*[T] = object
    payload: Payload[T]
  Payload18*[T] = object
    payload: Payload[T]
  Payload19*[T] = object
    payload: Payload[T]
  Payload20*[T] = object
    payload: Payload[T]
  Payload21*[T] = object
    payload: Payload[T]
  Payload22*[T] = object
    payload: Payload[T]
  Payload23*[T] = object
    payload: Payload[T]
  Payload24*[T] = object
    payload: Payload[T]
  Payload25*[T] = object
    payload: Payload[T]
  Payload26*[T] = object
    payload: Payload[T]
  Payload27*[T] = object
    payload: Payload[T]
  Payload28*[T] = object
    payload: Payload[T]
  Payload29*[T] = object
    payload: Payload[T]
  Payload30*[T] = object
    payload: Payload[T]
  Payload31*[T] = object
    payload: Payload[T]
  Payload32*[T] = object
    payload: Payload[T]
  Payload33*[T] = object
    payload: Payload[T]

type
  Carriers*[T] = object
    c0*: Carrier[Payload0[T]]
    c1*: Carrier[Payload1[T]]
    c2*: Carrier[Payload2[T]]
    c3*: Carrier[Payload3[T]]
    c4*: Carrier[Payload4[T]]
    c5*: Carrier[Payload5[T]]
    c6*: Carrier[Payload6[T]]
    c7*: Carrier[Payload7[T]]
    c8*: Carrier[Payload8[T]]
    c9*: Carrier[Payload9[T]]
    c10*: Carrier[Payload10[T]]
    c11*: Carrier[Payload11[T]]
    c12*: Carrier[Payload12[T]]
    c13*: Carrier[Payload13[T]]
    c14*: Carrier[Payload14[T]]
    c15*: Carrier[Payload15[T]]
    c16*: Carrier[Payload16[T]]
    c17*: Carrier[Payload17[T]]
    c18*: Carrier[Payload18[T]]
    c19*: Carrier[Payload19[T]]
    c20*: Carrier[Payload20[T]]
    c21*: Carrier[Payload21[T]]
    c22*: Carrier[Payload22[T]]
    c23*: Carrier[Payload23[T]]
    c24*: Carrier[Payload24[T]]
    c25*: Carrier[Payload25[T]]
    c26*: Carrier[Payload26[T]]
    c27*: Carrier[Payload27[T]]
    c28*: Carrier[Payload28[T]]
    c29*: Carrier[Payload29[T]]
    c30*: Carrier[Payload30[T]]
    c31*: Carrier[Payload31[T]]
    c32*: Carrier[Payload32[T]]
    c33*: Carrier[Payload33[T]]

var carriers : Carriers[int]

static:
  assert $(typeof(carriers.c33.val)) == "Payload33[system.int]"
