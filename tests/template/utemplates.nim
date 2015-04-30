import unittest

template t(a: int): expr = "int"
template t(a: string): expr = "string"

test "templates can be overloaded":
  check t(10) == "int"
  check t("test") == "string"

test "previous definitions can be further overloaded or hidden in local scopes":
  template t(a: bool): expr = "bool"

  check t(true) == "bool"
  check t(10) == "int"

  template t(a: int): expr = "inner int"
  check t(10) == "inner int"
  check t("test") == "string"

test "templates can be redefined multiple times":
  template customAssert(cond: bool, msg: string): stmt {.immediate, dirty.} =
    if not cond: fail(msg)

  template assertion_failed(body: stmt) {.immediate, dirty.} =
    template fail(msg: string): stmt = body

  assertion_failed: check msg == "first fail path"
  customAssert false, "first fail path"

  assertion_failed: check msg == "second fail path"
  customAssert false, "second fail path"

