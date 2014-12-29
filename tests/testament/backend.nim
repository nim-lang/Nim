#
#
#              The Nim Tester
#        (c) Copyright 2014 Andreas Rumpf
#
#    Look at license.txt for more info.
#    All rights reserved.

import strutils, db_sqlite, os, osproc

var db: TDbConn

proc createDb() =
  db.exec(sql"""
    create table if not exists Machine(
      id integer primary key,
      name varchar(100) not null,
      os varchar(20) not null,
      cpu varchar(20) not null
    );""")

  db.exec(sql"""
    create table if not exists [Commit](
      id integer primary key,
      hash varchar(256) not null,
      branch varchar(50) not null
    );""")

  db.exec(sql"""
    create table if not exists TestResult(
      id integer primary key,
      name varchar(100) not null,
      category varchar(100) not null,
      target varchar(20) not null,
      action varchar(10) not null,
      result varchar(30) not null,
      [commit] int not null,
      machine int not null,
      expected varchar(10000) not null,
      given varchar(10000) not null,
      created timestamp not null default (DATETIME('now')),

      foreign key ([commit]) references [commit](id),
      foreign key (machine) references machine(id)
    );""")

  #db.exec(sql"""
  #  --create unique index if not exists TsstNameIx on TestResult(name);
  #  """, [])

type
  MachineId* = distinct int64
  CommitId = distinct int64

proc `$`*(id: MachineId): string {.borrow.}
proc `$`(id: CommitId): string {.borrow.}

var
  thisMachine: MachineId
  thisCommit: CommitId

proc `()`(cmd: string{lit}): string = cmd.execProcess.string.strip

proc getMachine*(db: TDbConn): MachineId =
  var name = "hostname"()
  if name.len == 0:
    name = when defined(posix): getenv"HOSTNAME".string
           else: getenv"COMPUTERNAME".string
  if name.len == 0:
    quit "cannot determine the machine name"

  let id = db.getValue(sql"select id from Machine where name = ?", name)
  if id.len > 0:
    result = id.parseInt.MachineId
  else:
    result = db.insertId(sql"insert into Machine(name, os, cpu) values (?,?,?)",
                         name, system.hostOS, system.hostCPU).MachineId

proc getCommit(db: TDbConn): CommitId =
  const commLen = "commit ".len
  let hash = "git log -n 1"()[commLen..commLen+10]
  let branch = "git symbolic-ref --short HEAD"()
  if hash.len == 0 or branch.len == 0: quit "cannot determine git HEAD"
  
  let id = db.getValue(sql"select id from [Commit] where hash = ? and branch = ?",
                       hash, branch)
  if id.len > 0:
    result = id.parseInt.CommitId
  else:
    result = db.insertId(sql"insert into [Commit](hash, branch) values (?, ?)", 
                         hash, branch).CommitId

proc writeTestResult*(name, category, target, 
                      action, result, expected, given: string) =
  let id = db.getValue(sql"""select id from TestResult 
                             where name = ? and category = ? and target = ? and
                                machine = ? and [commit] = ?""", 
                                name, category, target,
                                thisMachine, thisCommit)
  if id.len > 0:
    db.exec(sql"""update TestResult
                  set action = ?, result = ?, expected = ?, given = ? 
                  where id = ?""", action, result, expected, given, id)
  else:
    db.exec(sql"""insert into TestResult(name, category, target, 
                                         action, 
                                         result, expected, given,
                                         [commit], machine)
                  values (?,?,?,?,?,?,?,?,?) """, name, category, target, 
                                        action,
                                        result, expected, given, 
                                        thisCommit, thisMachine)

proc open*() =
  db = open(connection="testament.db", user="testament", password="",
            database="testament")
  createDb()
  thisMachine = getMachine(db)
  thisCommit = getCommit(db)

proc close*() = close(db)
