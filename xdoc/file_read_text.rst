Reading Text from a File
========================

* there are 9 different variations showing reading a text file
* this is not an exhaustive list of how to read a text file
* each reading of the input file is timed
* each file reading is approximately ordered from slower to faster
* if the examples were to manipulate strings within the loop, then the overall times would be much slower
* Garbage collection and OS load will add variability to the timing (this is NOT a benchmark)
* Provide some suitably sized (text) file called junkdata.txt when trying this example
* compile with -d:release (the file reading is slower otherwise)
  

.. code-block:: nim
  
  import strutils, times, os, parsecsv, streams, memfiles
  
  let
    fname = "junkdata.txt"  

  const
    FGETSZ = 2500    
    
  var
    t0, t1 = cpuTime()
    F: File
    line = ""
    cntL = 0
    cntC = 0
  
  var fgetStr: cstring = newString(FGETSZ+1)
  
  proc fgets(c: cstring, n: cint, f: File): cstring  {.importc: "fgets", header: "<stdio.h>".}
  
  iterator fgetsLine(f: File): string =
    while not isNil(fgets(fgetStr, FGETSZ, f)):
      yield $fgetStr
  
  proc fgetsAll(f: File): string =
    result = ""
    for x in f.fgetsLine():
      result.add(x)
    
  proc prepare() =
    t0 = cpuTime()
    cntL = 0
    cntC = 0
    
  proc finalise(msg: string) =
    t1 = cpuTime()
    let s = (msg & repeat(' ',25))[0..25]
    echo s,($(t1-t0) & "00")[0..4], "  Lines: ", cntL, " chars: ",cntC
  
  # -- MAIN ---
  proc main() =
    # Check file exists
    if not open(F, fname):
      echo "Unable to find ", fname
      quit()
    close(F)
  
    # using fgets() from stdlib of C  (reading all file data into a single string)
    #
    # This is slower than the next fgets() example because of string handling
    #
    prepare()
    if open(F, fname):
      let s = F.fgetsAll
      cntL = s.countLines
      cntC = s.len
      close(F)
    finalise("fgets all: ")
      
    # using fgets() from stdlib of C
    # 
    # This shows how to make C library calls
    # Safety-wise, it is best to use Nim's system lib procs
    #
    prepare()
    if open(F, fname):
      for s in F.fgetsLine:
        inc cntL
        cntC += s.len - 1   # exclude nl char
      close(F)
    finalise("fgets iterator: ")
    
    # Reading line-by-line using the readLine() iterator from the Nim system lib
    #
    # Compare this readLine() with the iterator lines()
    #
    prepare()
    if open(F, fname):
      while F.readLine(line):
        inc cntL
        cntC += line.len
      close(F)
    finalise("readLine: ")
  
    # using the lines() iterator from the Nim system lib
    #
    prepare()
    if open(F, fname):
      for line in F.lines:
        inc cntL
        cntC += line.len
      close(F)
    finalise("lines: ")
  
    # using the Nim parseCsv lib
    #
    # If you needed to manipulate string portions of each line, 
    # then this may be a quicker approach, 
    # because it provides the line already split 
    # by delimeter (if required)
    #
    prepare()
    var s = newFileStream(fname, fmRead)
    if s != nil: 
      var x: CsvParser
      open(x, s, fname)
      while x.readRow():
        inc cntL
        for z in x.row:
          cntC += z.len
      close(x)
    finalise("parsecsv: ")
  
    # using readAll() and splitLines() from Nim system lib
    #
    # This would not be appropriate for large files due to
    # memory usage in reading ALL the file into a string
    # but for small files works well
    #
    prepare()
    if open(F, fname):
      let x = F.readAll
      for line in x.splitLines:
        inc cntL
        cntC += line.len
      close(F)
      dec cntL
    finalise("readAll splitLines: ")
    
    # using readAll() and splitLines() from Nim system lib
    #
    # This is a minor improvement on string handling compared
    # to the previous example (if you don't need access to the 
    # full text from the file)
    #
    prepare()
    if open(F, fname):
      for line in F.readAll().splitLines:
        inc cntL
        cntC += line.len
      close(F)
      dec cntL
    finalise("readAll().splitLines: ")
    
    # using readAll() and countLines() from Nim system and strutils lib
    #
    # This avoids manipulating the file on a per-line basis
    # and is probably not a practical example for most cases,
    # but does highlight that you may make performance gains if
    # you optimise your code for a specific situation
    #
    prepare()
    if open(F, fname):
      let x = F.readAll
      cntL = x.countLines
      cntC = x.len() - (cntL * "\n".len)
      close(F)
    finalise("readAll countlines: ")
  
    # using memfiles() and lines() from the Nim memfiles lib
    #
    # This is faster because the file is read into a buffer in chunks
    #
    prepare()
    var file = memfiles.open(fname, fmRead)
    for line in memfiles.lines(file):
      inc cntL
      cntC += line.len
    close(file)
    finalise("memfiles lines: ")
      
  main()
  