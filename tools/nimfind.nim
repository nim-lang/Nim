#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nimfind is a tool that helps to give editors IDE like capabilities.

when not defined(nimcore):
  {.error: "nimcore MUST be defined for Nim's core tooling".}
when not defined(nimfind):
  {.error: "nimfind MUST be defined for Nim's nimfind tool".}

const Usage = """
Nimfind - Tool to find declarations or usages for Nim symbols
Usage:
  nimfind [options] file.nim:line:col

Options:
  --help, -h              show this help
  --rebuild               rebuild the index
  --project:file.nim      use file.nim as the entry point

In addition, all command line options of Nim that do not affect code generation
are supported.
"""

import strutils, os, parseopt

import "../compiler" / [options, commands, modules, sem,
  passes, passaux, msgs, ast,
  idents, modulegraphs, lineinfos, cmdlinehelper,
  pathutils]

import db_sqlite

proc createDb(db: DbConn) =
  db.exec(sql"""
  create table if not exists filenames(
    id integer primary key,
    fullpath varchar(8000) not null
  );
  """)
  db.exec sql"create index if not exists FilenameIx on filenames(fullpath);"

  # every sym can have potentially 2 different definitions due to forward
  # declarations.
  db.exec(sql"""
  create table if not exists syms(
    id integer primary key,
    nimid integer not null,
    name varchar(256) not null,
    defline integer not null,
    defcol integer not null,
    deffile integer not null,
    deflineB integer not null default 0,
    defcolB integer not null default 0,
    deffileB integer not null default 0,
    foreign key (deffile) references filenames(id),
    foreign key (deffileB) references filenames(id)
  );
  """)

  db.exec(sql"""
  create table if not exists usages(
    id integer primary key,
    nimid integer not null,
    line integer not null,
    col integer not null,
    colB integer not null,
    file integer not null,
    foreign key (file) references filenames(id),
    foreign key (nimid) references syms(nimid)
  );
  """)
  db.exec sql"create index if not exists UsagesIx on usages(file, line);"

proc toDbFileId*(db: DbConn; conf: ConfigRef; fileIdx: FileIndex): int =
  if fileIdx == FileIndex(-1): return -1
  let fullpath = toFullPath(conf, fileIdx)
  let row = db.getRow(sql"select id from filenames where fullpath = ?", fullpath)
  let id = row[0]
  if id.len == 0:
    result = int db.insertID(sql"insert into filenames(fullpath) values (?)",
      fullpath)
  else:
    result = parseInt(id)

type
  FinderRef = ref object of RootObj
    db: DbConn

proc writeDef(graph: ModuleGraph; s: PSym; info: TLineInfo) =
  let f = FinderRef(graph.backend)
  f.db.exec(sql"""insert into syms(nimid, name, defline, defcol, deffile) values (?, ?, ?, ?, ?)""",
    s.id, s.name.s, info.line, info.col,
    toDbFileId(f.db, graph.config, info.fileIndex))

proc writeDefResolveForward(graph: ModuleGraph; s: PSym; info: TLineInfo) =
  let f = FinderRef(graph.backend)
  f.db.exec(sql"""update syms set deflineB = ?, defcolB = ?, deffileB = ?
    where nimid = ?""", info.line, info.col,
    toDbFileId(f.db, graph.config, info.fileIndex), s.id)

proc writeUsage(graph: ModuleGraph; s: PSym; info: TLineInfo) =
  let f = FinderRef(graph.backend)
  f.db.exec(sql"""insert into usages(nimid, line, col, colB, file) values (?, ?, ?, ?, ?)""",
    s.id, info.line, info.col, info.col + s.name.s.len - 1,
    toDbFileId(f.db, graph.config, info.fileIndex))

proc performSearch(conf: ConfigRef; dbfile: AbsoluteFile) =
  var db = open(connection=string dbfile, user="nim", password="",
                database="nim")
  let pos = conf.m.trackPos
  let fid = toDbFileId(db, conf, pos.fileIndex)
  let known = toFullPath(conf, pos.fileIndex)
  let nimids = db.getRow(sql"""select distinct nimid from usages where line = ? and file = ? and ? between col and colB""",
      pos.line, fid, pos.col)
  if nimids.len > 0:
    var idSet = ""
    for id in nimids:
      if idSet.len > 0: idSet.add ", "
      idSet.add id
    var outputLater = ""
    for r in db.rows(sql"""select line, col, filenames.fullpath from usages
                          inner join filenames on filenames.id = file
                          where nimid in (?)""", idSet):
      let line = parseInt(r[0])
      let col = parseInt(r[1])
      let file = r[2]
      if file == known and line == pos.line.int:
        # output the line we already know last:
        outputLater.add file & ":" & $line & ":" & $(col+1) & "\n"
      else:
        echo file, ":", line, ":", col+1
    if outputLater.len > 0: stdout.write outputLater
  close(db)

proc setupDb(g: ModuleGraph; dbfile: AbsoluteFile) =
  var f = FinderRef()
  removeFile(dbfile)
  f.db = open(connection=string dbfile, user="nim", password="",
            database="nim")
  createDb(f.db)
  f.db.exec(sql"pragma journal_mode=off")
  # This MUST be turned off, otherwise it's way too slow even for testing purposes:
  f.db.exec(sql"pragma SYNCHRONOUS=off")
  f.db.exec(sql"pragma LOCKING_MODE=exclusive")
  g.backend = f

proc mainCommand(graph: ModuleGraph) =
  let conf = graph.config
  let dbfile = getNimcacheDir(conf) / RelativeFile"nimfind.db"
  if not fileExists(dbfile) or optForceFullMake in conf.globalOptions:
    clearPasses(graph)
    registerPass graph, verbosePass
    registerPass graph, semPass
    conf.cmd = cmdIdeTools
    wantMainModule(conf)
    setupDb(graph, dbfile)

    graph.onDefinition = writeUsage # writeDef
    graph.onDefinitionResolveForward = writeUsage # writeDefResolveForward
    graph.onUsage = writeUsage

    if not fileExists(conf.projectFull):
      quit "cannot find file: " & conf.projectFull.string
    add(conf.searchPaths, conf.libpath)
    # do not stop after the first error:
    conf.errorMax = high(int)
    try:
      compileProject(graph)
    finally:
      close(FinderRef(graph.backend).db)
  performSearch(conf, dbfile)

proc processCmdLine*(pass: TCmdLinePass, cmd: string; conf: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      case p.key.normalize
      of "help", "h":
        stdout.writeLine(Usage)
        quit()
      of "project":
        conf.projectName = p.val
      of "rebuild":
        incl conf.globalOptions, optForceFullMake
      else: processSwitch(pass, p, conf)
    of cmdArgument:
      let info = p.key.split(':')
      if info.len == 3:
        let (dir, file, ext) = info[0].splitFile()
        conf.projectName = findProjectNimFile(conf, dir)
        if conf.projectName.len == 0: conf.projectName = info[0]
        try:
          conf.m.trackPos = newLineInfo(conf, AbsoluteFile info[0],
                                        parseInt(info[1]), parseInt(info[2])-1)
        except ValueError:
          quit "invalid command line"
      else:
        quit "invalid command line"

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    suggestMode: true,
    processCmdLine: processCmdLine,
    mainCommand: mainCommand
  )
  self.initDefinesProg(conf, "nimfind")

  if paramCount() == 0:
    stdout.writeLine(Usage)
    return

  self.processCmdLineAndProjectPath(conf)

  # Find Nim's prefix dir.
  let binaryPath = findExe("nim")
  if binaryPath == "":
    raise newException(IOError,
        "Cannot find Nim standard library: Nim compiler not in PATH")
  conf.prefixDir = AbsoluteDir binaryPath.splitPath().head.parentDir()
  if not dirExists(conf.prefixDir / RelativeDir"lib"):
    conf.prefixDir = AbsoluteDir""

  discard self.loadConfigsAndRunMainCommand(cache, conf)

handleCmdLine(newIdentCache(), newConfigRef())
