#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Memory tracking support for Nim.

when not defined(memTracker) and not isMainModule:
  {.error: "Memory tracking support is turned off!".}

{.push memtracker: off.}
# we import the low level wrapper and are careful not to use Nim's
# memory manager for anything here.
import sqlite3

var
  dbHandle: PSqlite3
  insertStmt {.threadvar.}: Pstmt

const insertQuery = "INSERT INTO tracking(op, address, size, file, line) values (?, ?, ?, ?, ?)"

template sbind(x: int; value) =
  when value is cstring:
    let ret = insertStmt.bindText(x, value, value.len.int32, SQLITE_TRANSIENT)
    if ret != SQLITE_OK:
      quit "could not bind value"
  else:
    let ret = insertStmt.bindInt64(x, value)
    if ret != SQLITE_OK:
      quit "could not bind value"

when defined(memTracker):
  proc logEntries(log: TrackLog) {.nimcall, locks: 0, tags: [], gcsafe.} =
    if insertStmt.isNil:
      if prepare_v2(dbHandle, insertQuery,
          insertQuery.len, insertStmt, nil) != SQLITE_OK:
        quit "could not bind query to insertStmt " & $sqlite3.errmsg(dbHandle)
    for i in 0..log.count-1:
      var success = false
      let e = log.data[i]
      discard sqlite3.reset(insertStmt)
      discard clearBindings(insertStmt)
      sbind 1, e.op
      sbind(2, cast[int](e.address))
      sbind 3, e.size
      sbind 4, e.file
      sbind 5, e.line
      if step(insertStmt) == SQLITE_DONE:
        success = true
      if not success:
        quit "could not write to database! " & $sqlite3.errmsg(dbHandle)

proc execQuery(q: string) =
  var s: Pstmt
  if prepare_v2(dbHandle, q, q.len.int32, s, nil) == SQLITE_OK:
    discard step(s)
    if finalize(s) != SQLITE_OK:
      quit "could not finalize " & $sqlite3.errmsg(dbHandle)
  else:
    quit "could not prepare statement " & $sqlite3.errmsg(dbHandle)

proc setupDb() =
  execQuery """create table if not exists tracking(
       id integer primary key,
       op varchar not null,
       address integer not null,
       size integer not null,
       file varchar not null,
       line integer not null
     )"""
  execQuery "delete from tracking"

if sqlite3.open("memtrack.db", dbHandle) == SQLITE_OK:
  setupDb()
  const query = "INSERT INTO tracking(op, address, size, file, line) values (?, ?, ?, ?, ?)"
  if prepare_v2(dbHandle, insertQuery,
      insertQuery.len, insertStmt, nil) == SQLITE_OK:
    when defined(memTracker):
      setTrackLogger logEntries
  else:
    quit "could not prepare statement B " & $sqlite3.errmsg(dbHandle)
else:
  quit "could not setup sqlite " & $sqlite3.errmsg(dbHandle)
{.pop.}
