#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Basic type definitions the module graph needs in order to support
## incremental compilations.

const nimIncremental* = defined(nimIncremental)

import options, lineinfos

when nimIncremental:
  import ast, msgs, intsets, btrees, db_sqlite, std / sha1
  from strutils import parseInt

  type
    Writer* = object
      sstack*: seq[PSym]          # a stack of symbols to process
      tstack*: seq[PType]         # a stack of types to process
      tmarks*, smarks*: IntSet
      forwardedSyms*: seq[PSym]

    Reader* = object
      syms*: BTree[int, PSym]
      types*: BTree[int, PType]

    IncrementalCtx* = object
      db*: DbConn
      w*: Writer
      r*: Reader
      configChanged*: bool

  proc init*(incr: var IncrementalCtx) =
    incr.w.sstack = @[]
    incr.w.tstack = @[]
    incr.w.tmarks = initIntSet()
    incr.w.smarks = initIntSet()
    incr.w.forwardedSyms = @[]
    incr.r.syms = initBTree[int, PSym]()
    incr.r.types = initBTree[int, PType]()


  proc hashFileCached*(conf: ConfigRef; fileIdx: FileIndex; fullpath: string): string =
    result = msgs.getHash(conf, fileIdx)
    if result.len == 0:
      result = $secureHashFile(fullpath)
      msgs.setHash(conf, fileIdx, result)

  proc toDbFileId*(incr: var IncrementalCtx; conf: ConfigRef; fileIdx: FileIndex): int =
    if fileIdx == FileIndex(-1): return -1
    let fullpath = toFullPath(conf, fileIdx)
    let row = incr.db.getRow(sql"select id, fullhash from filenames where fullpath = ?",
      fullpath)
    let id = row[0]
    let fullhash = hashFileCached(conf, fileIdx, fullpath)
    if id.len == 0:
      result = int incr.db.insertID(sql"insert into filenames(fullpath, fullhash) values (?, ?)",
        fullpath, fullhash)
    else:
      if row[1] != fullhash:
        incr.db.exec(sql"update filenames set fullhash = ? where fullpath = ?", fullhash, fullpath)
      result = parseInt(id)

  proc fromDbFileId*(incr: var IncrementalCtx; conf: ConfigRef; dbId: int): FileIndex =
    if dbId == -1: return FileIndex(-1)
    let fullpath = incr.db.getValue(sql"select fullpath from filenames where id = ?", dbId)
    doAssert fullpath.len > 0, "cannot find file name for DB ID " & $dbId
    result = fileInfoIdx(conf, fullpath)


  proc addModuleDep*(incr: var IncrementalCtx; conf: ConfigRef;
                     module, fileIdx: FileIndex;
                     isIncludeFile: bool) =
    if conf.symbolFiles != v2Sf: return

    let a = toDbFileId(incr, conf, module)
    let b = toDbFileId(incr, conf, fileIdx)

    incr.db.exec(sql"insert into deps(module, dependency, isIncludeFile) values (?, ?, ?)",
      a, b, ord(isIncludeFile))

  # --------------- Database model ---------------------------------------------

  proc createDb*(db: DbConn) =
    db.exec(sql"""
      create table if not exists controlblock(
        idgen integer not null
      );
    """)

    db.exec(sql"""
      create table if not exists config(
        config varchar(8000) not null
      );
    """)

    db.exec(sql"""
      create table if not exists filenames(
        id integer primary key,
        fullpath varchar(8000) not null,
        fullHash varchar(256) not null
      );
    """)
    db.exec sql"create index if not exists FilenameIx on filenames(fullpath);"

    db.exec(sql"""
      create table if not exists modules(
        id integer primary key,
        nimid integer not null,
        fullpath varchar(8000) not null,
        interfHash varchar(256) not null,
        fullHash varchar(256) not null,

        created timestamp not null default (DATETIME('now'))
      );""")
    db.exec(sql"""create unique index if not exists SymNameIx on modules(fullpath);""")

    db.exec(sql"""
      create table if not exists deps(
        id integer primary key,
        module integer not null,
        dependency integer not null,
        isIncludeFile integer not null,
        foreign key (module) references filenames(id),
        foreign key (dependency) references filenames(id)
      );""")
    db.exec(sql"""create index if not exists DepsIx on deps(module);""")

    db.exec(sql"""
      create table if not exists types(
        id integer primary key,
        nimid integer not null,
        module integer not null,
        data blob not null,
        foreign key (module) references module(id)
      );
    """)
    db.exec sql"create index TypeByModuleIdx on types(module);"
    db.exec sql"create index TypeByNimIdIdx on types(nimid);"

    db.exec(sql"""
      create table if not exists syms(
        id integer primary key,
        nimid integer not null,
        module integer not null,
        name varchar(256) not null,
        data blob not null,
        exported int not null,
        foreign key (module) references module(id)
      );
    """)
    db.exec sql"create index if not exists SymNameIx on syms(name);"
    db.exec sql"create index SymByNameAndModuleIdx on syms(name, module);"
    db.exec sql"create index SymByModuleIdx on syms(module);"
    db.exec sql"create index SymByNimIdIdx on syms(nimid);"


    db.exec(sql"""
      create table if not exists toplevelstmts(
        id integer primary key,
        position integer not null,
        module integer not null,
        data blob not null,
        foreign key (module) references module(id)
      );
    """)
    db.exec sql"create index TopLevelStmtByModuleIdx on toplevelstmts(module);"
    db.exec sql"create index TopLevelStmtByPositionIdx on toplevelstmts(position);"

    db.exec(sql"""
      create table if not exists statics(
        id integer primary key,
        module integer not null,
        data blob not null,
        foreign key (module) references module(id)
      );
    """)
    db.exec sql"create index StaticsByModuleIdx on toplevelstmts(module);"
    db.exec sql"insert into controlblock(idgen) values (0)"


else:
  type
    IncrementalCtx* = object

  template init*(incr: IncrementalCtx) = discard

  template addModuleDep*(incr: var IncrementalCtx; conf: ConfigRef;
                     module, fileIdx: FileIndex;
                     isIncludeFile: bool) =
    discard
