
import threads

var
  thr: array [0..4, TThread]
  L: TLock
  
proc threadFunc(c: pointer) {.procvar.} = 
  for i in 0..9: 
    Aquire(L)
    echo i
    Release(L)

InitLock(L)

for i in 0..high(thr):
  createThread(thr[i], threadFunc)
for i in 0..high(thr):
  joinThread(thr[i])


