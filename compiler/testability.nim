template tests*(body: stmt) {.immediate.} =
  when defined(selftest):
    when not defined(unittest): import unittest
    body

