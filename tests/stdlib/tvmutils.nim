discard """
  joinable: false
  nimout: '''
0
1
2
tvmutils.nim(28, 13) [opcLdImmInt]     if i == 4:
tvmutils.nim(28, 10) [opcEqInt]     if i == 4:
tvmutils.nim(28, 10) [opcFJmp]     if i == 4:
tvmutils.nim(28, 13) [opcLdImmInt]     if i == 4:
tvmutils.nim(28, 10) [opcEqInt]     if i == 4:
tvmutils.nim(28, 10) [opcFJmp]     if i == 4:
tvmutils.nim(29, 7) [opcLdConst]       vmTrace(false)
tvmutils.nim(29, 15) [opcLdImmInt]       vmTrace(false)
tvmutils.nim(29, 14) [opcIndCall]       vmTrace(false)
5
6
'''
"""
# line 20 (only showing a subset of nimout to avoid making the test rigid)
import std/vmutils

proc main() =
  for i in 0..<7:
    echo i
    if i == 2:
      vmTrace(true)
    if i == 4:
      vmTrace(false)

static: main()
