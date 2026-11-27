discard """
  exitcode: 1
  outputsub: "Error: unhandled exception: boom [ValueError]"
"""

# An exception that nothing catches must be reported. With the C++ backend the
# report is written by a `std::terminate` handler, which read the current
# exception from the program's own copy of the exception state instead of
# nimrtl's, and crashed.

proc fail() =
  raise newException(ValueError, "boom")

fail()
