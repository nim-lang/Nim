import times, os

var start = epochTime()
os.sleep(1000)
let diff = abs(epochTime() - start - 1.0)
doAssert diff < 0.005
