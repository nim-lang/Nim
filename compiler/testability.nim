template tests*(body: stmt) {.immediate.} =
  when defined(selftest):
    when not declared(unittest): import unittest
    body

