discard """
  targets: "c cpp"
"""
import std/atomics

block testSize: # issue 12726
  type
    Node = ptr object
      # works
      next: Atomic[pointer]
      f:AtomicFlag
    MyChannel = object
      # type not defined completely
      back: Atomic[ptr int]
      f: AtomicFlag
  static:
    doAssert sizeof(Node) == sizeof(pointer)
    doAssert sizeof(MyChannel) == sizeof(pointer) * 2