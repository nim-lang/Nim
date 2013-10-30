#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple logger. It is based on the following design:
## * Runtime log formating is a bug: Sooner or later every log file is parsed.
## * Keep it simple: If this library does not fullfill your needs, write your
##   own. Trying to support every logging feature just leads to bloat.
##
## Format is::
##
##   DEBUG|INFO|... (2009-11-02 00:00:00)? (Component: )? Message
##
##

import strutils, os, times

type
  TLevel* = enum  ## logging level
    lvlAll,       ## all levels active
    lvlDebug,     ## debug level (and any above) active
    lvlInfo,      ## info level (and any above) active
    lvlWarn,      ## warn level (and any above) active
    lvlError,     ## error level (and any above) active
    lvlFatal,     ## fatal level (and any above) active
    lvlNone

const
  LevelNames*: array [TLevel, string] = [
    "DEBUG", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "NONE"
  ]

  defaultFmtStr = "" ## default string between log level and message per logger
  verboseFmtStr = "$date $time "

type
  TLogger* = object of TObject ## abstract logger; the base type of all loggers
    levelThreshold*: TLevel    ## only messages of level >= levelThreshold
                               ## should be processed
    fmtStr: string ## = defaultFmtStr by default, see substituteLog for $date etc.

  TConsoleLogger* = object of TLogger ## logger that writes the messages to the
                                      ## console

  TFileLogger* = object of TLogger ## logger that writes the messages to a file
    f: TFile

  # TODO: implement rolling log, will produce filename.1, filename.2 etc.
  TRollingFileLogger* = object of TFileLogger ## logger that writes the
                                              ## message to a file
    maxLines: int # maximum number of lines
    curLine : int
    baseName: string # initial filename
    logFiles: int # how many log files already created, e.g. basename.1, basename.2...




proc substituteLog*(frmt: string): string =
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



method log*(L: ref TLogger, level: TLevel,
            frmt: string, args: varargs[string, `$`]) =
  ## override this method in custom loggers. Default implementation does
  ## nothing.
  nil

method log*(L: ref TConsoleLogger, level: TLevel,
            frmt: string, args: varargs[string, `$`]) =
    Writeln(stdout, LevelNames[level], " ", substituteLog(L.fmtStr), frmt % args)

method log*(L: ref TFileLogger, level: TLevel,
            frmt: string, args: varargs[string, `$`]) =
    Writeln(L.f, LevelNames[level], " ", substituteLog(L.fmtStr), frmt % args)

proc defaultFilename*(): string =
  ## returns the default filename for a logger
  var (path, name, ext) = splitFile(getAppFilename())
  result = changeFileExt(path / name & "_" & getDateStr(), "log")




proc newConsoleLogger*(levelThreshold = lvlAll) : ref TConsoleLogger =
  new result
  result.fmtStr = defaultFmtStr
  result.levelThreshold = levelThreshold

proc newFileLogger*(filename = defaultFilename(),
                    mode: TFileMode = fmAppend,
                    levelThreshold = lvlAll): ref TFileLogger =
  new(result)
  result.levelThreshold = levelThreshold
  result.f = open(filename, mode)
  result.fmtStr = defaultFmtStr

# ------

proc readLogLines(logger : ref TRollingFileLogger) = nil
  #f.readLine # TODO read all lines, update curLine


proc newRollingFileLogger*(filename = defaultFilename(),
                           mode: TFileMode = fmReadWrite,
                           levelThreshold = lvlAll,
                           maxLines = 1000): ref TRollingFileLogger =
  new(result)
  result.levelThreshold = levelThreshold
  result.fmtStr = defaultFmtStr
  result.maxLines = maxLines
  result.f = open(filename, mode)
  result.curLine = 0

  # TODO count all number files
  # count lines in existing filename file
  # if >= maxLines then rename to next numbered file and create new file

  #if mode in {fmReadWrite, fmReadWriteExisting}:
  #  readLogLines(result)



method log*(L: ref TRollingFileLogger, level: TLevel,
            frmt: string, args: varargs[string, `$`]) =
  # TODO
  # if more than maxlines, then set cursor to zero

  Writeln(L.f, LevelNames[level], " ", frmt % args)

# --------

var
  level* = lvlAll  ## global log filter
  handlers*: seq[ref TLogger] = @[] ## handlers with their own log levels

proc logLoop(level: TLevel, frmt: string, args: varargs[string, `$`]) =
  for logger in items(handlers):
    if level >= logger.levelThreshold:
      log(logger, level, frmt, args)

template log*(level: TLevel, frmt: string, args: varargs[string, `$`]) =
  ## logs a message of the given level
  bind logLoop
  bind `%`
  bind logging.Level

  if level >= logging.Level:
    logLoop(level, frmt, args)

template debug*(frmt: string, args: varargs[string, `$`]) =
  ## logs a debug message
  log(lvlDebug, frmt, args)

template info*(frmt: string, args: varargs[string, `$`]) =
  ## logs an info message
  log(lvlInfo, frmt, args)

template warn*(frmt: string, args: varargs[string, `$`]) =
  ## logs a warning message
  log(lvlWarn, frmt, args)

template error*(frmt: string, args: varargs[string, `$`]) =
  ## logs an error message
  log(lvlError, frmt, args)

template fatal*(frmt: string, args: varargs[string, `$`]) =
  ## logs a fatal error message
  log(lvlFatal, frmt, args)


# --------------

when isMainModule:
  var L = newConsoleLogger()
  var fL = newFileLogger("test.log")
  fL.fmtStr = verboseFmtStr
  handlers.add(L)
  handlers.add(fL)
  info("hello", [])


