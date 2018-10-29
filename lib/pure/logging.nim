#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple logger. It has been designed to be as simple
## as possible to avoid bloat, if this library does not fulfill your needs,
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
## $datetime     $dateT$time
## $app          ``os.getAppFilename()``
## $appname      base name of $app
## $appdir       directory name of $app
## $levelid      first letter of log level
## $levelname    log level name
## ============  =======================
##
##
## The following example demonstrates logging to three different handlers
## simultaneously:
##
## .. code-block:: nim
##
##    var L = newConsoleLogger()
##    var fL = newFileLogger("test.log", fmtStr = verboseFmtStr)
##    var rL = newRollingFileLogger("rolling.log", fmtStr = verboseFmtStr)
##    addHandler(L)
##    addHandler(fL)
##    addHandler(rL)
##    info("920410:52 accepted")
##    warn("4 8 15 16 23 4-- Error")
##    error("922044:16 SYSTEM FAILURE")
##    fatal("SYSTEM FAILURE SYSTEM FAILURE")
##
## **Warning:** The global list of handlers is a thread var, this means that
## the handlers must be re-added in each thread.
## **Warning:** When logging on disk or console, only error and fatal messages
## are flushed out immediately. Use flushFile() where needed.

import strutils, times
when not defined(js):
  import os

type
  Level* = enum  ## logging level
    lvlAll,       ## all levels active
    lvlDebug,     ## debug level (and any above) active
    lvlInfo,      ## info level (and any above) active
    lvlNotice,    ## info notice (and any above) active
    lvlWarn,      ## warn level (and any above) active
    lvlError,     ## error level (and any above) active
    lvlFatal,     ## fatal level (and any above) active
    lvlNone       ## no levels active

const
  LevelNames*: array[Level, string] = [
    "DEBUG", "DEBUG", "INFO", "NOTICE", "WARN", "ERROR", "FATAL", "NONE"
  ]

  defaultFmtStr* = "$levelname " ## default format string
  verboseFmtStr* = "$levelid, [$datetime] -- $appname: "

type
  Logger* = ref object of RootObj ## abstract logger; the base type of all loggers
    levelThreshold*: Level    ## only messages of level >= levelThreshold
                              ## should be processed
    fmtStr*: string ## = defaultFmtStr by default, see substituteLog for $date etc.

  ConsoleLogger* = ref object of Logger ## logger that writes the messages to the
                                        ## console
    useStderr*: bool ## will send logs into Stderr if set 

when not defined(js):
  type
    FileLogger* = ref object of Logger ## logger that writes the messages to a file
      file*: File  ## the wrapped file.

    RollingFileLogger* = ref object of FileLogger ## logger that writes the
                                                  ## messages to a file and
                                                  ## performs log rotation
      maxLines: int # maximum number of lines
      curLine : int
      baseName: string # initial filename
      baseMode: FileMode # initial file mode
      logFiles: int # how many log files already created, e.g. basename.1, basename.2...
      bufSize: int # size of output buffer (-1: use system defaults, 0: unbuffered, >0: fixed buffer size)

var
  level {.threadvar.}: Level   ## global log filter
  handlers {.threadvar.}: seq[Logger] ## handlers with their own log levels

proc substituteLog*(frmt: string, level: Level, args: varargs[string, `$`]): string =
  ## Format a log message using the ``frmt`` format string, ``level`` and varargs.
  ## See the module documentation for the format string syntax.
  var msgLen = 0
  for arg in args:
    msgLen += arg.len
  result = newStringOfCap(frmt.len + msgLen + 20)
  var i = 0
  while i < frmt.len:
    if frmt[i] != '$':
      result.add(frmt[i])
      inc(i)
    else:
      inc(i)
      var v = ""
      let app = when defined(js): "" else: getAppFilename()
      while frmt[i] in IdentChars:
        v.add(toLowerAscii(frmt[i]))
        inc(i)
      case v
      of "date": result.add(getDateStr())
      of "time": result.add(getClockStr())
      of "datetime": result.add(getDateStr() & "T" & getClockStr())
      of "app":  result.add(app)
      of "appdir":
        when not defined(js): result.add(app.splitFile.dir)
      of "appname":
        when not defined(js): result.add(app.splitFile.name)
      of "levelid": result.add(LevelNames[level][0])
      of "levelname": result.add(LevelNames[level])
      else: discard
  for arg in args:
    result.add(arg)

method log*(logger: Logger, level: Level, args: varargs[string, `$`]) {.
            raises: [Exception], gcsafe,
            tags: [TimeEffect, WriteIOEffect, ReadIOEffect], base.} =
  ## Override this method in custom loggers. Default implementation does
  ## nothing.
  discard

method log*(logger: ConsoleLogger, level: Level, args: varargs[string, `$`]) =
  ## Logs to the console using ``logger`` only.
  if level >= logging.level and level >= logger.levelThreshold:
    let ln = substituteLog(logger.fmtStr, level, args)
    when defined(js):
      let cln: cstring = ln
      {.emit: "console.log(`cln`);".}
    else:
      try:
        var handle = stdout
        if logger.useStderr:
          handle = stderr 
        writeLine(handle, ln)
        if level in {lvlError, lvlFatal}: flushFile(handle)
      except IOError:
        discard

proc newConsoleLogger*(levelThreshold = lvlAll, fmtStr = defaultFmtStr, useStderr=false): ConsoleLogger =
  ## Creates a new console logger. This logger logs to the console.
  new result
  result.fmtStr = fmtStr
  result.levelThreshold = levelThreshold
  result.useStderr = useStderr

when not defined(js):
  method log*(logger: FileLogger, level: Level, args: varargs[string, `$`]) =
    ## Logs to a file using ``logger`` only.
    if level >= logging.level and level >= logger.levelThreshold:
      writeLine(logger.file, substituteLog(logger.fmtStr, level, args))
      if level in {lvlError, lvlFatal}: flushFile(logger.file)

  proc defaultFilename*(): string =
    ## Returns the default filename for a logger.
    var (path, name, _) = splitFile(getAppFilename())
    result = changeFileExt(path / name, "log")

  proc newFileLogger*(file: File,
                      levelThreshold = lvlAll,
                      fmtStr = defaultFmtStr): FileLogger =
    ## Creates a new file logger. This logger logs to ``file``.
    new(result)
    result.file = file
    result.levelThreshold = levelThreshold
    result.fmtStr = fmtStr

  proc newFileLogger*(filename = defaultFilename(),
                      mode: FileMode = fmAppend,
                      levelThreshold = lvlAll,
                      fmtStr = defaultFmtStr,
                      bufSize: int = -1): FileLogger =
    ## Creates a new file logger. This logger logs to a file, specified
    ## by ``fileName``.
    ## Use ``bufSize`` as size of the output buffer when writing the file
    ## (-1: use system defaults, 0: unbuffered, >0: fixed buffer size).
    let file = open(filename, mode, bufSize = bufSize)
    newFileLogger(file, levelThreshold, fmtStr)

  # ------

  proc countLogLines(logger: RollingFileLogger): int =
    result = 0
    let fp = open(logger.baseName, fmRead)
    for line in fp.lines():
      result.inc()
    fp.close()

  proc countFiles(filename: string): int =
    # Example: file.log.1
    result = 0
    var (dir, name, ext) = splitFile(filename)
    if dir == "":
      dir = "."
    for kind, path in walkDir(dir):
      if kind == pcFile:
        let llfn = name & ext & ExtSep
        if path.extractFilename.startsWith(llfn):
          let numS = path.extractFilename[llfn.len .. ^1]
          try:
            let num = parseInt(numS)
            if num > result:
              result = num
          except ValueError: discard

  proc newRollingFileLogger*(filename = defaultFilename(),
                            mode: FileMode = fmReadWrite,
                            levelThreshold = lvlAll,
                            fmtStr = defaultFmtStr,
                            maxLines = 1000,
                            bufSize: int = -1): RollingFileLogger =
    ## Creates a new rolling file logger. Once a file reaches ``maxLines`` lines
    ## a new log file will be started and the old will be renamed.
    ## Use ``bufSize`` as size of the output buffer when writing the file
    ## (-1: use system defaults, 0: unbuffered, >0: fixed buffer size).
    new(result)
    result.levelThreshold = levelThreshold
    result.fmtStr = fmtStr
    result.maxLines = maxLines
    result.bufSize = bufSize
    result.file = open(filename, mode, bufSize=result.bufSize)
    result.curLine = 0
    result.baseName = filename
    result.baseMode = mode

    result.logFiles = countFiles(filename)

    if mode == fmAppend:
      # We need to get a line count because we will be appending to the file.
      result.curLine = countLogLines(result)

  proc rotate(logger: RollingFileLogger) =
    let (dir, name, ext) = splitFile(logger.baseName)
    for i in countdown(logger.logFiles, 0):
      let srcSuff = if i != 0: ExtSep & $i else: ""
      moveFile(dir / (name & ext & srcSuff),
              dir / (name & ext & ExtSep & $(i+1)))

  method log*(logger: RollingFileLogger, level: Level, args: varargs[string, `$`]) =
    ## Logs to a file using rolling ``logger`` only.
    if level >= logging.level and level >= logger.levelThreshold:
      if logger.curLine >= logger.maxLines:
        logger.file.close()
        rotate(logger)
        logger.logFiles.inc
        logger.curLine = 0
        logger.file = open(logger.baseName, logger.baseMode, bufSize = logger.bufSize)

      writeLine(logger.file, substituteLog(logger.fmtStr, level, args))
      if level in {lvlError, lvlFatal}: flushFile(logger.file)
      logger.curLine.inc

# --------

proc logLoop(level: Level, args: varargs[string, `$`]) =
  for logger in items(handlers):
    if level >= logger.levelThreshold:
      log(logger, level, args)

template log*(level: Level, args: varargs[string, `$`]) =
  ## Logs a message to all registered handlers at the given level.
  bind logLoop
  bind `%`
  bind logging.level

  if level >= logging.level:
    logLoop(level, args)

template debug*(args: varargs[string, `$`]) =
  ## Logs a debug message to all registered handlers.
  ##
  ## Messages that are useful to the application developer only and are usually
  ## turned off in release.
  log(lvlDebug, args)

template info*(args: varargs[string, `$`]) =
  ## Logs an info message to all registered handlers.
  ##
  ## Messages that are generated during the normal operation of an application
  ## and are of no particular importance. Useful to aggregate for potential
  ## later analysis.
  log(lvlInfo, args)

template notice*(args: varargs[string, `$`]) =
  ## Logs an notice message to all registered handlers.
  ##
  ## Semantically very similar to `info`, but meant to be messages you want to
  ## be actively notified about (depending on your application).
  ## These could be, for example, grouped by hour and mailed out.
  log(lvlNotice, args)

template warn*(args: varargs[string, `$`]) =
  ## Logs a warning message to all registered handlers.
  ##
  ## A non-error message that may indicate a potential problem rising or
  ## impacted performance.
  log(lvlWarn, args)

template error*(args: varargs[string, `$`]) =
  ## Logs an error message to all registered handlers.
  ##
  ## A application-level error condition. For example, some user input generated
  ## an exception. The application will continue to run, but functionality or
  ## data was impacted, possibly visible to users.
  log(lvlError, args)

template fatal*(args: varargs[string, `$`]) =
  ## Logs a fatal error message to all registered handlers.
  ##
  ## A application-level fatal condition. FATAL usually means that the application
  ## cannot go on and will exit (but this logging event will not do that for you).
  log(lvlFatal, args)

proc addHandler*(handler: Logger) =
  ## Adds ``handler`` to the list of handlers.
  handlers.add(handler)

proc getHandlers*(): seq[Logger] =
  ## Returns a list of all the registered handlers.
  return handlers

proc setLogFilter*(lvl: Level) =
  ## Sets the global log filter.
  level = lvl

proc getLogFilter*(): Level =
  ## Gets the global log filter.
  return level

# --------------

when not defined(testing) and isMainModule:
  var L = newConsoleLogger()
  when not defined(js):
    var fL = newFileLogger("test.log", fmtStr = verboseFmtStr)
    var rL = newRollingFileLogger("rolling.log", fmtStr = verboseFmtStr)
    addHandler(fL)
    addHandler(rL)
  addHandler(L)
  for i in 0 .. 25:
    info("hello", i)

  var nilString: string
  info "hello ", nilString
