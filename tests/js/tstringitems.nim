discard """
  output: '''Hello
Hello
c
d
e'''
"""

block: # bug #2581
  const someVars = [ "Hello" ]
  var someVars2 = [ "Hello" ]

  proc getSomeVar: string =
      for i in someVars:
          if i == "Hello":
              result = i
              break

  proc getSomeVar2: string =
      for i in someVars2:
          if i == "Hello":
              result = i
              break

  echo getSomeVar()
  echo getSomeVar2()

block: # Test compile-time binary data generation, invalid unicode
  proc signatureMaker(): string {. compiletime .} =
    const signatureBytes = [137, 80, 78, 71, 13, 10, 26, 10]
    result = ""
    for c in signatureBytes: result.add chr(c)

  const cSig = signatureMaker()

  var rSig = newString(8)
  rSig[0] = chr(137)
  rSig[1] = chr(80)
  rSig[2] = chr(78)
  rSig[3] = chr(71)
  rSig[4] = chr(13)
  rSig[5] = chr(10)
  rSig[6] = chr(26)
  rSig[7] = chr(10)

  doAssert(rSig == cSig)

block: # Test unicode strings
  const constStr = "Привет!"
  var jsStr : cstring
  {.emit: """`jsStr` = "Привет!";""".}

  doAssert($jsStr == constStr)
  var runtimeStr = "При"
  runtimeStr &= "вет!"

  doAssert(runtimeStr == constStr)

block: # Conversions from/to cstring
  proc stringSaysHelloInRussian(s: cstring): bool =
    {.emit: """`result` = (`s` === "Привет!");""".}

  doAssert(stringSaysHelloInRussian("Привет!"))

  const constStr = "Привет!"
  doAssert(stringSaysHelloInRussian(constStr))

  var rtStr = "Привет!"
  doAssert(stringSaysHelloInRussian(rtStr))

block: # String case of
  const constStr = "Привет!"
  var s = "Привет!"

  case s
  of constStr: discard
  else: doAssert(false)

  case s
  of "Привет!": discard
  else: doAssert(false)

block: # String cmp
  var a, b: string
  doAssert(cmp(a, b) == 0)
  doAssert(cmp("foo", "foo") == 0)
  doAssert(cmp("foobar", "foo") == 3)
  doAssert(cmp("foo", "foobar") == -3)
  doAssert(cmp("fooz", "foog") == 19)
  doAssert(cmp("foog", "fooz") == -19)

proc main(x: openArray[char]) =
  for c in x: echo c

main(toOpenArray(['a', 'b', 'c', 'd', 'e'], 2, 4))
