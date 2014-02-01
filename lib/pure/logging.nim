#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple logger. It has been designed to be as simple
## as possible to avoid bloat, if this library does not fullfill your needs,
## write your own.
## 
## Format strings support the following variables which must be prefixed with
## the dollar operator (``$``):
##
## ============  =======================
##   Operator     Output
## ============  =======================
## $date         Current date
## $time         Current time
## $app          ``os.getAppFilename()``
## ============  =======================
## 
##
## The following example demonstrates logging to three different handlers
## simultaneously:
##
## .. code-block:: nimrod
##     
##    var L = newConsoleLogger()
##    var fL = newFileLogger("test.log", fmtStr = verboseFmtStr)
##    var rL = newRollingFileLogger("rolling.log", fmtStr = verboseFmtStr)
##    handlers.add(L)
##    handlers.add(fL)
##    handlers.add(rL)
##    info("920410:52 accepted")
##    warn("4 8 15 16 23 4-- Error")
##    error("922044:16 SYSTEM FAILURE")
##    fatal("SYSTEM FAILURE SYSTEM FAILURE")

import strutils, os, times

type
  TLevel* = enum  ## logging level
    lvlAll,       ## all levels active
    lvlDebug,     ## debug level (and any above) active
    lvlInfo,      ## info level (and any above) active
    lvlWarn,      ## warn level (and any above) active
    lvlError,     ## error level (and any above) active
    lvlFatal,     ## fatal level (and any above) active
    lvlNone       ## no levels active

const
  LevelNames*: array [TLevel, string] = [
    "DEBUG", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "NONE"
  ]

  defaultFmtStr* = "" ## default string between log level and message per logger
  verboseFmtStr* = "$date $time "

type
  PLogger* = ref object of PObject ## abstract logger; the base type of all loggers
    levelThreshold*: TLevel    ## only messages of level >= levelThreshold 
                               ## should be processed
    fmtStr: string ## = defaultFmtStr by default, see substituteLog for $date etc.
    
  PConsoleLogger* = ref object of PLogger ## logger that writes the messages to the
                                      ## console
  
  PFileLogger* = ref object of PLogger ## logger that writes the messages to a file
    f: TFile
  
  PRollingFileLogger* = ref object of PFileLogger ## logger that writes the 
                                                  ## messages to a file and
                                                  ## performs log rotation
    maxLines: int # maximum number of lines    
    curLine : int
    baseName: string # initial filename
    baseMode: TFileMode # initial file mode
    logFiles: int # how many log files already created, e.g. basename.1, basename.2...

proc substituteLog(frmt: string): string = 
  ## converts $date to the current date
  ## converts $time to the current time
  ## converts $app to getAppFilename()
  ## converts 
  result = newStringOfCap(frmt.len + 20)
  var i = 0
  while i < frmt.len: 
    if frmt[i] != '$': 
      result.add(frmt[i])
      inc(i)
    else:
      inc(i)
      var v = ""
      var app = getAppFilename()
      while frmt[i] in IdentChars: 
        v.add(toLower(frmt[i]))
        inc(i)
      case v
      of "date": result.add(getDateStr())
      of "time": result.add(getClockStr())
      of "app":  result.add(app)
      of "appdir": result.add(app.splitFile.dir)
      of "appname": result.add(app.splitFile.name)

method log*(logger: PLogger, level: TLevel,
            frmt: string, args: varargs[string, `$`]) =
  ## Override this method in custom loggers. Default implementation does
  ## nothing.
  nil
  
method log*(logger: PConsoleLogger, level: TLevel,
            frmt: string, args: varargs[string, `$`]) =
  ## Logs to the console using ``logger`` only.
  if level >= logger.levelThreshold:
    writeln(stdout, LevelNames[level], " ", substituteLog(logger.fmtStr),
            frmt % args)

method log*(logger: PFileLogger, level: TLevel, 
            frmt: string, args: varargs[string, `$`]) =
  ## Logs to a file using ``logger`` only.
  if level >= logger.levelThreshold:
    writeln(logger.f, LevelNames[level], " ",
            substituteLog(logger.fmtStr), frmt % args)

proc defaultFilename*(): string = 
  ## Returns the default filename for a logger.
  var (path, name, ext) = splitFile(getAppFilename())
  result = changeFileExt(path / name, "log")

proc newConsoleLogger*(levelThreshold = lvlAll, fmtStr = defaultFmtStr): PConsoleLogger =
  ## Creates a new console logger. This logger logs to the console.
  new result
  result.fmtStr = fmtStr
  result.levelThreshold = levelThreshold

proc newFileLogger*(filename = defaultFilename(), 
                    mode: TFileMode = fmAppend,
                    levelThreshold = lvlAll,
                    fmtStr = defaultFmtStr): PFileLogger = 
  ## Creates a new file logger. This logger logs to a file.
  new(result)
  result.levelThreshold = levelThreshold
  result.f = open(filename, mode)
  result.fmtStr = fmtStr

# ------

proc countLogLines(logger: PRollingFileLogger): int =
  result = 0
  for line in logger.f.lines():
    result.inc()

proc countFiles(filename: string): int =
  # Example: file.log.1
  result = 0
  let (dir, name, ext) = splitFile(filename)
  for kind, path in walkDir(dir):
    if kind == pcFile:
      let llfn = name & ext & ExtSep
      if path.extractFilename.startsWith(llfn):
        let numS = path.extractFilename[llfn.len .. -1]
        try:
          let num = parseInt(numS)
          if num > result:
            result = num
        except EInvalidValue: discard

proc newRollingFileLogger*(filename = defaultFilename(), 
                           mode: TFileMode = fmReadWrite,
                           levelThreshold = lvlAll,
                           fmtStr = defaultFmtStr,
                           maxLines = 1000): PRollingFileLogger =
  ## Creates a new rolling file logger. Once a file reaches ``maxLines`` lines
  ## a new log file will be started and the old will be renamed.
  new(result)
  result.levelThreshold = levelThreshold
  result.fmtStr = defaultFmtStr
  result.maxLines = maxLines
  result.f = open(filename, mode)
  result.curLine = 0
  result.baseName = filename
  result.baseMode = mode
  
  result.logFiles = countFiles(filename)
  
  if mode == fmAppend:
    # We need to get a line count because we will be appending to the file.
    result.curLine = countLogLines(result)

proc rotate(logger: PRollingFileLogger) =
  let (dir, name, ext) = splitFile(logger.baseName)
  for i in countdown(logger.logFiles, 0):
    let srcSuff = if i != 0: ExtSep & $i else: ""
    moveFile(dir / (name & ext & srcSuff),
             dir / (name & ext & ExtSep & $(i+1)))

method log*(logger: PRollingFileLogger, level: TLevel, 
            frmt: string, args: varargs[string, `$`]) =
  ## Logs to a file using rolling ``logger`` only.
  if level >= logger.levelThreshold:
    if logger.curLine >= logger.maxLines:
      logger.f.close()
      rotate(logger)
      logger.logFiles.inc
      logger.curLine = 0
      logger.f = open(logger.baseName, logger.baseMode)
    
    writeln(logger.f, LevelNames[level], " ", frmt % args)
    logger.curLine.inc

# --------

var
  level* = lvlAll  ## global log filter
  handlers*: seq[PLogger] = @[] ## handlers with their own log levels

proc logLoop(level: TLevel, frmt: string, args: varargs[string, `$`]) =
  for logger in items(handlers): 
    if level >= logger.levelThreshold:
      log(logger, level, frmt, args)

template log*(level: TLevel, frmt: string, args: varargs[string, `$`]) =
  ## Logs a message to all registered handlers at the given level.
  bind logLoop
  bind `%`
  bind logging.Level
  
  if level >= logging.Level:
    logLoop(level, frmt, args)

template debug*(frmt: string, args: varargs[string, `$`]) =
  ## Logs a debug message to all registered handlers.
  log(lvlDebug, frmt, args)

template info*(frmt: string, args: varargs[string, `$`]) = 
  ## Logs an info message to all registered handlers.
  log(lvlInfo, frmt, args)

template warn*(frmt: string, args: varargs[string, `$`]) = 
  ## Logs a warning message to all registered handlers.
  log(lvlWarn, frmt, args)

template error*(frmt: string, args: varargs[string, `$`]) = 
  ## Logs an error message to all registered handlers.
  log(lvlError, frmt, args)
  
template fatal*(frmt: string, args: varargs[string, `$`]) =  
  ## Logs a fatal error message to all registered handlers.
  log(lvlFatal, frmt, args)


# --------------

when isMainModule:
  var L = newConsoleLogger()
  var fL = newFileLogger("test.log", fmtStr = verboseFmtStr)
  var rL = newRollingFileLogger("rolling.log", fmtStr = verboseFmtStr)
  handlers.add(L)
  handlers.add(fL)
  handlers.add(rL)
  for i in 0 .. 25:
    info("hello" & $i, [])
  

