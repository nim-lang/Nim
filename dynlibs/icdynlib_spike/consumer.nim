import producer_dynlib

doAssert answer(41) == 42
doAssert answer(20, 22) == 42
doAssert identity(nil) == nil
notify(42)
