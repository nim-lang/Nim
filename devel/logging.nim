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

type
  TLevel* = enum  ## logging level
    lvlAll,       ## all levels active
    lvlDebug,     ## debug level (and any above) active
    lvlInfo,      ## info level (and any above) active
    lvlWarn,      ## warn level (and any above) active
    lvlError,     ## error level (and any above) active
    lvlFatal      ## fatal level (and any above) active

const
  LevelNames*: array [TLevel, string] = [
    "DEBUG", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
  ]

type
  TLogger* = object of TObject ## abstract logger; the base type of all loggers
    levelThreshold*: TLevel    ## only messages of level >= levelThreshold 
                               ## should be processed
  TConsoleLogger* = object of TLogger ## logger that writes the messages to the
                                      ## console
  
  TFileLogger* = object of TLogger ## logger that writes the messages to a file
    f: TFile
    
  TRollingFileLogger* = object of TFileLogger ## logger that writes the 
                                              ## message to a file
    maxlines: int # maximum number of lines
    lines: seq[string]

method log*(L: ref TLogger, level: TLevel,
            frmt: string, args: openArray[string]) =
  ## override this method in custom loggers. Default implementation does
  ## nothing.
  nil
  
method log*(L: ref TConsoleLogger, level: TLevel,
            frmt: string, args: openArray[string]) = 
  Writeln(stdout, LevelNames[level], " ", frmt % args)

method log*(L: ref TFileLogger, level: TLevel, 
            frmt: string, args: openArray[string]) = 
  Writeln(L.f, LevelNames[level], " ", frmt % args)

proc defaultFilename*(): string = 
  ## returns the default filename for a logger
  var (path, name, ext) = splitFile(getAppFilename())
  result = changeFileExt(path / name & "_" & getDateStr(), "log")

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
      

proc newFileLogger*(filename = defaultFilename(), 
                    mode: TFileMode = fmAppend,
                    levelThreshold = lvlNone): ref TFileLogger = 
  new(result)
  result.levelThreshold = levelThreshold
  result.f = open(filename, mode)

proc newRollingFileLogger*(filename = defaultFilename(), 
                           mode: TFileMode = fmAppend,
                           levelThreshold = lvlNone,
                           maxLines = 1000): ref TFileLogger = 
  new(result)
  result.levelThreshold = levelThreshold
  result.maxLines = maxLines
  result.f = open(filename, mode)

var
  level* = lvlNone
  handlers*: seq[ref TLogger] = @[]

proc logLoop(level: TLevel, msg: string) =
  for logger in items(handlers): 
    if level >= logger.levelThreshold:
      log(logger, level, msg)

template log*(level: TLevel, msg: string) =
  ## logs a message of the given level
  bind logLoop
  if level >= logging.Level:
    logLoop(level, frmt, args)

template debug*(msg: string) =
  ## logs a debug message
  log(lvlDebug, msg)

template info*(msg: string) = 
  ## logs an info message
  log(lvlInfo, msg)

template warn*(msg: string) = 
  ## logs a warning message
  log(lvlWarn, msg)

template error*(msg: string) = 
  ## logs an error message
  log(lvlError, msg)
  
template fatal*(msg: string) =  
  ## logs a fatal error message
  log(lvlFatal, msg)

