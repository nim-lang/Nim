import unittest

template t(a: int): string = "int"
template t(a: string): string = "string"

block: # templates can be overloaded
  check t(10) == "int"
  check t("test") == "string"

block: # previous definitions can be further overloaded or hidden in local scopes
  template t(a: bool): string = "bool"

  check t(true) == "bool"
  check t(10) == "int"

  template t(a: int): string = "inner int"
  check t(10) == "inner int"
  check t("test") == "string"

block: # templates can be redefined multiple times
  template customAssert(cond: bool, msg: string): typed {.dirty.} =
    if not cond: fail(msg)

  template assertionFailed(body: untyped) {.dirty.} =
    template fail(msg: string): typed =
      body

  assertionFailed:
    check(msg == "first fail path")

  customAssert false, "first fail path"

  assertionFailed:
    check(msg == "second fail path")

  customAssert false, "second fail path"
