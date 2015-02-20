#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module allows you to monitor files or directories for changes using
## asyncio.
##
## Windows support is not yet implemented.
##
## **Note:** This module uses ``inotify`` on Linux (Other Unixes are not yet
## supported). ``inotify`` was merged into the 2.6.13 Linux kernel, this
## module will therefore not work with any Linux kernel prior to that, unless
## it has been patched to support inotify.

when defined(linux) or defined(nimdoc):
  from posix import read
else:
  {.error: "Your platform is not supported.".}

import inotify, os, asyncio, tables

type
  FSMonitor* = ref FSMonitorObj
  FSMonitorObj = object of RootObj
    fd: cint
    handleEvent: proc (m: FSMonitor, ev: MonitorEvent) {.closure.}
    targets: Table[cint, string]
  
  MonitorEventType* = enum ## Monitor event type
    MonitorAccess,       ## File was accessed.
    MonitorAttrib,       ## Metadata changed.
    MonitorCloseWrite,   ## Writtable file was closed.
    MonitorCloseNoWrite, ## Unwrittable file closed.
    MonitorCreate,       ## Subfile was created.
    MonitorDelete,       ## Subfile was deleted.
    MonitorDeleteSelf,   ## Watched file/directory was itself deleted.
    MonitorModify,       ## File was modified.
    MonitorMoveSelf,     ## Self was moved.
    MonitorMoved,        ## File was moved.
    MonitorOpen,         ## File was opened.
    MonitorAll           ## Filter for all event types.
  
  MonitorEvent* = object
    case kind*: MonitorEventType  ## Type of the event.
    of MonitorMoveSelf, MonitorMoved:
      oldPath*: string          ## Old absolute location
      newPath*: string          ## New absolute location
    else:
      fullname*: string         ## Absolute filename of the file/directory affected.
    name*: string             ## Non absolute filepath of the file/directory
                              ## affected relative to the directory watched.
                              ## "" if this event refers to the file/directory
                              ## watched.
    wd*: cint                 ## Watch descriptor.

{.deprecated: [PFSMonitor: FSMonitor, TFSMonitor: FSMonitorObj,
  TMonitorEventType: MonitorEventType, TMonitorEvent: MonitorEvent].}

const
  MaxEvents = 100

proc newMonitor*(): FSMonitor =
  ## Creates a new file system monitor.
  new(result)
  result.targets = initTable[cint, string]()
  result.fd = inotifyInit()
  if result.fd < 0:
    raiseOSError(osLastError())

proc add*(monitor: FSMonitor, target: string,
               filters = {MonitorAll}): cint {.discardable.} =
  ## Adds ``target`` which may be a directory or a file to the list of
  ## watched paths of ``monitor``.
  ## You can specify the events to report using the ``filters`` parameter.
  
  var INFilter = -1
  for f in filters:
    case f
    of MonitorAccess: INFilter = INFilter and IN_ACCESS
    of MonitorAttrib: INFilter = INFilter and IN_ATTRIB
    of MonitorCloseWrite: INFilter = INFilter and IN_CLOSE_WRITE
    of MonitorCloseNoWrite: INFilter = INFilter and IN_CLOSE_NO_WRITE
    of MonitorCreate: INFilter = INFilter and IN_CREATE
    of MonitorDelete: INFilter = INFilter and IN_DELETE
    of MonitorDeleteSelf: INFilter = INFilter and IN_DELETE_SELF
    of MonitorModify: INFilter = INFilter and IN_MODIFY
    of MonitorMoveSelf: INFilter = INFilter and IN_MOVE_SELF
    of MonitorMoved: INFilter = INFilter and IN_MOVED_FROM and IN_MOVED_TO
    of MonitorOpen: INFilter = INFilter and IN_OPEN
    of MonitorAll: INFilter = INFilter and IN_ALL_EVENTS
  
  result = inotifyAddWatch(monitor.fd, target, INFilter.uint32)
  if result < 0:
    raiseOSError(osLastError())
  monitor.targets.add(result, target)

proc del*(monitor: FSMonitor, wd: cint) =
  ## Removes watched directory or file as specified by ``wd`` from ``monitor``.
  ##
  ## If ``wd`` is not a part of ``monitor`` an EOS error is raised.
  if inotifyRmWatch(monitor.fd, wd) < 0:
    raiseOSError(osLastError())

proc getEvent(m: FSMonitor, fd: cint): seq[MonitorEvent] =
  result = @[]
  let size = (sizeof(TINotifyEvent)+2000)*MaxEvents
  var buffer = newString(size)

  let le = read(fd, addr(buffer[0]), size)

  var movedFrom = initTable[cint, tuple[wd: cint, old: string]]()

  var i = 0
  while i < le:
    var event = cast[ptr TINotifyEvent](addr(buffer[i]))
    var mev: MonitorEvent
    mev.wd = event.wd
    if event.len.int != 0:
      let cstr = event.name.addr.cstring
      mev.name = $cstr
    else:
      mev.name = ""
    
    if (event.mask.int and IN_MOVED_FROM) != 0: 
      # Moved from event, add to m's collection
      movedFrom.add(event.cookie.cint, (mev.wd, mev.name))
      inc(i, sizeof(TINotifyEvent) + event.len.int)
      continue
    elif (event.mask.int and IN_MOVED_TO) != 0: 
      mev.kind = MonitorMoved
      assert movedFrom.hasKey(event.cookie.cint)
      # Find the MovedFrom event.
      mev.oldPath = movedFrom[event.cookie.cint].old
      mev.newPath = "" # Set later
      # Delete it from the Table
      movedFrom.del(event.cookie.cint)
    elif (event.mask.int and IN_ACCESS) != 0: mev.kind = MonitorAccess
    elif (event.mask.int and IN_ATTRIB) != 0: mev.kind = MonitorAttrib
    elif (event.mask.int and IN_CLOSE_WRITE) != 0: 
      mev.kind = MonitorCloseWrite
    elif (event.mask.int and IN_CLOSE_NOWRITE) != 0: 
      mev.kind = MonitorCloseNoWrite
    elif (event.mask.int and IN_CREATE) != 0: mev.kind = MonitorCreate
    elif (event.mask.int and IN_DELETE) != 0: 
      mev.kind = MonitorDelete
    elif (event.mask.int and IN_DELETE_SELF) != 0: 
      mev.kind = MonitorDeleteSelf
    elif (event.mask.int and IN_MODIFY) != 0: mev.kind = MonitorModify
    elif (event.mask.int and IN_MOVE_SELF) != 0: 
      mev.kind = MonitorMoveSelf
    elif (event.mask.int and IN_OPEN) != 0: mev.kind = MonitorOpen
    
    if mev.kind != MonitorMoved:
      mev.fullname = ""
    
    result.add(mev)
    inc(i, sizeof(TINotifyEvent) + event.len.int)

  # If movedFrom events have not been matched with a moveTo. File has
  # been moved to an unwatched location, emit a MonitorDelete.
  for cookie, t in pairs(movedFrom):
    var mev: MonitorEvent
    mev.kind = MonitorDelete
    mev.wd = t.wd
    mev.name = t.old
    result.add(mev)

proc FSMonitorRead(h: RootRef) =
  var events = FSMonitor(h).getEvent(FSMonitor(h).fd)
  #var newEv: MonitorEvent
  for ev in events:
    var target = FSMonitor(h).targets[ev.wd]
    var newEv = ev
    if newEv.kind == MonitorMoved:
      newEv.oldPath = target / newEv.oldPath
      newEv.newPath = target / newEv.name
    else:
      newEv.fullName = target / newEv.name
    FSMonitor(h).handleEvent(FSMonitor(h), newEv)

proc toDelegate(m: FSMonitor): Delegate =
  result = newDelegate()
  result.deleVal = m
  result.fd = (type(result.fd))(m.fd)
  result.mode = fmRead
  result.handleRead = FSMonitorRead
  result.open = true

proc register*(d: Dispatcher, monitor: FSMonitor,
               handleEvent: proc (m: FSMonitor, ev: MonitorEvent) {.closure.}) =
  ## Registers ``monitor`` with dispatcher ``d``.
  monitor.handleEvent = handleEvent
  var deleg = toDelegate(monitor)
  d.register(deleg)

when isMainModule:
  proc main =
    var disp = newDispatcher()
    var monitor = newMonitor()
    echo monitor.add("/home/dom/inotifytests/")
    disp.register(monitor,
      proc (m: FSMonitor, ev: MonitorEvent) =
        echo("Got event: ", ev.kind)
        if ev.kind == MonitorMoved:
          echo("From ", ev.oldPath, " to ", ev.newPath)
          echo("Name is ", ev.name)
        else:
          echo("Name ", ev.name, " fullname ", ev.fullName))
        
    while true:
      if not disp.poll(): break
  main()
