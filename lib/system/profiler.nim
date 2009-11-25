#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements the Nimrod profiler. The profiler needs support by the
# code generator. 

type
  TProfileData {.compilerproc, final.} = object
    procname: cstring
    total: float

var
  profileData {.compilerproc.}: array [0..64*1024-1, TProfileData]

proc sortProfile(a: var array[0..64*1024-1, TProfileData], N: int) = 
  # we use shellsort here; fast enough and simple
  var h = 1
  while true: 
    h = 3 * h + 1
    if h > N: break 
  while true: 
    h = h div 3
    for i in countup(h, N - 1): 
      var v = a[i]
      var j = i
      while a[j-h].total <= v.total: 
        a[j] = a[j-h]
        j = j-h
        if j < h: break 
      a[j] = v
    if h == 1: break

proc writeProfile() {.noconv.} =
  const filename = "profile_results"
  var i = 0
  var f: TFile
  var j = 1
  while open(f, filename & $j & ".txt"):
    close(f)
    inc(j)
  if open(f, filename & $j & ".txt", fmWrite):
    var N = 0
    # we have to compute the actual length of the array:
    while profileData[N].procname != nil: inc(N)
    sortProfile(profileData, N)
    writeln(f, "total running time of each proc" &
               " (interpret these numbers relatively)")
    while profileData[i].procname != nil:
      write(f, profileData[i].procname)
      write(f, ": ")
      writeln(f, profileData[i].total)
      inc(i)
    close(f)

addQuitProc(writeProfile)
