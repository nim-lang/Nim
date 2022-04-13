discard """
  action: "compile"
"""
import options, mregression

type
  MyEnum = enum
    Success

template t =
  echo some(Success)

t()
