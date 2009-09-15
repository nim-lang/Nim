//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit cgen;

// This is the new C code generator; much cleaner and faster
// than the old one. It also generates better code.

interface

{$include 'config.inc'}

uses
  nsystem, ast, astalgo, strutils, nhashes, trees, platform, magicsys,
  extccomp, options, nversion, nimsets, msgs, crc, bitsets, idents,
  lists, types, ccgutils, nos, ntime, ropes, nmath, passes, rodread,
  wordrecg, rnimsyn, treetab;
  
function cgenPass(): TPass;

implementation

type
  TLabel = PRope;      // for the C generator a label is just a rope

  TCFileSection = (    // the sections a generated C file consists of
    cfsHeaders,        // section for C include file headers
    cfsForwardTypes,   // section for C forward typedefs
    cfsTypes,          // section for C typedefs
    cfsSeqTypes,       // section for sequence types only
                       // this is needed for strange type generation
                       // reasons
    cfsFieldInfo,      // section for field information
    cfsTypeInfo,       // section for type information
    cfsProcHeaders,    // section for C procs prototypes
    cfsData,           // section for C constant data
    cfsVars,           // section for C variable declarations
    cfsProcs,          // section for C procs that are not inline
    cfsTypeInit1,      // section 1 for declarations of type information
    cfsTypeInit2,      // section 2 for initialization of type information
    cfsTypeInit3,      // section 3 for init of type information
    cfsDebugInit,      // section for initialization of debug information
    cfsDynLibInit,     // section for initialization of dynamic library binding
    cfsDynLibDeinit    // section for deinitialization of dynamic libraries
  );

  TCTypeKind = (       // describes the type kind of a C type
    ctVoid,
    ctChar,
    ctBool,
    ctUInt, ctUInt8, ctUInt16, ctUInt32, ctUInt64,
    ctInt, ctInt8, ctInt16, ctInt32, ctInt64,
    ctFloat, ctFloat32, ctFloat64, ctFloat128,
    ctArray,
    ctStruct,
    ctPtr,
    ctNimStr,
    ctNimSeq,
    ctProc,
    ctCString
  );

  TCFileSections = array [TCFileSection] of PRope;
    // TCFileSections represents a generated C file
  TCProcSection = (    // the sections a generated C proc consists of
    cpsLocals,         // section of local variables for C proc
    cpsInit,           // section for initialization of variables for C proc
    cpsStmts           // section of local statements for C proc
  );

  TCProcSections = array [TCProcSection] of PRope;
    // TCProcSections represents a generated C proc

  BModule = ^TCGen;
  BProc = ^TCProc;

  TBlock = record
    id: int;  // the ID of the label; positive means that it
              // has been used (i.e. the label should be emitted)
    nestedTryStmts: int; // how many try statements is it nested into
  end;

  TCProc = record            // represents C proc that is currently generated
    s: TCProcSections;       // the procs sections; short name for readability
    prc: PSym;               // the Nimrod proc that this C proc belongs to
    BeforeRetNeeded: bool;   // true iff 'BeforeRet' label for proc is needed
    nestedTryStmts: Natural; // in how many nested try statements we are
                             // (the vars must be volatile then)
    labels: Natural;         // for generating unique labels in the C proc
    blocks: array of TBlock; // nested blocks
    options: TOptions;       // options that should be used for code
                             // generation; this is the same as prc.options
                             // unless prc == nil
    frameLen: int;           // current length of frame descriptor
    sendClosure: PType;      // closure record type that we pass
    receiveClosure: PType;   // closure record type that we get
    module: BModule;         // used to prevent excessive parameter passing
  end;
  TTypeSeq = array of PType;
  TCGen = object(TPassContext) // represents a C source file
    module: PSym;
    filename: string;
    s: TCFileSections;       // sections of the C file
    cfilename: string;       // filename of the module (including path,
                             // without extension)
    typeCache: TIdTable;     // cache the generated types
    forwTypeCache: TIdTable; // cache for forward declarations of types
    declaredThings: TIntSet; // things we have declared in this .c file
    declaredProtos: TIntSet; // prototypes we have declared in this .c file
    headerFiles: TLinkedList; // needed headers to include
    typeInfoMarker: TIntSet; // needed for generating type information
    initProc: BProc;         // code for init procedure
    typeStack: TTypeSeq;     // used for type generation
    dataCache: TNodeTable;
    forwardedProcs: TSymSeq; // keep forwarded procs here
    typeNodes, nimTypes: int;// used for type info generation
    typeNodesName, nimTypesName: PRope; // used for type info generation
    labels: natural;         // for generating unique module-scope names
  end;

var
  mainModProcs, mainModInit: PRope; // parts of the main module
  gMapping: PRope;  // the generated mapping file (if requested)
  gProcProfile: Natural; // proc profile counter
  gGeneratedSyms: TIntSet; // set of ID's of generated symbols
  gPendingModules: array of BModule = {@ignore} nil {@emit @[]};
    // list of modules that are not finished with code generation
  gForwardedProcsCounter: int = 0;
  gmti: BModule; // generated type info: no need to initialize: defaults fit

function ropeff(const cformat, llvmformat: string; 
                const args: array of PRope): PRope;
begin
  if gCmd = cmdCompileToLLVM then 
    result := ropef(llvmformat, args)
  else
    result := ropef(cformat, args)
end;

procedure appff(var dest: PRope; const cformat, llvmformat: string; 
                const args: array of PRope);
begin
  if gCmd = cmdCompileToLLVM then 
    appf(dest, llvmformat, args)
  else
    appf(dest, cformat, args);
end;

procedure addForwardedProc(m: BModule; prc: PSym);
var
  L: int;
begin
  L := length(m.forwardedProcs);
  setLength(m.forwardedProcs, L+1);
  m.forwardedProcs[L] := prc;
  inc(gForwardedProcsCounter);
end;

procedure addPendingModule(m: BModule);
var
  L, i: int;
begin
  for i := 0 to high(gPendingModules) do
    if gPendingModules[i] = m then
      InternalError('module already pending: ' + m.module.name.s);
  L := length(gPendingModules);
  setLength(gPendingModules, L+1);
  gPendingModules[L] := m;
end;

function findPendingModule(m: BModule; s: PSym): BModule;
var
  ms: PSym;
  i: int;
begin
  ms := getModule(s);
  if ms.id = m.module.id then begin
    result := m; exit
  end;
  for i := 0 to high(gPendingModules) do begin
    result := gPendingModules[i];
    if result.module.id = ms.id then exit;
  end;
  InternalError(s.info, 'no pending module found for: ' + s.name.s);
end;

procedure initLoc(var result: TLoc; k: TLocKind; typ: PType; s: TStorageLoc);
begin
  result.k := k;
  result.s := s;
  result.t := GetUniqueType(typ);
  result.r := nil;
  result.a := -1;
  result.flags := {@set}[]
end;

procedure fillLoc(var a: TLoc; k: TLocKind; typ: PType; r: PRope;
                  s: TStorageLoc);
begin
  // fills the loc if it is not already initialized
  if a.k = locNone then begin
    a.k := k;
    a.t := getUniqueType(typ);
    a.a := -1;
    a.s := s;
    if a.r = nil then a.r := r;
  end
end;

function newProc(prc: PSym; module: BModule): BProc;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.prc := prc;
  result.module := module;
  if prc <> nil then
    result.options := prc.options
  else
    result.options := gOptions;
{@ignore}
  setLength(result.blocks, 0);
{@emit
  result.blocks := @[];}
end;

function isSimpleConst(typ: PType): bool;
begin
  result := not (skipTypes(typ, abstractVar).kind in [tyTuple, tyObject, 
    tyArray, tyArrayConstr, tySet, tySequence])
end;

procedure useHeader(m: BModule; sym: PSym);
begin
  if lfHeader in sym.loc.Flags then begin
    assert(sym.annex <> nil);
    {@discard} lists.IncludeStr(m.headerFiles, sym.annex.path)
  end
end;

procedure UseMagic(m: BModule; const name: string); forward;

{$include 'ccgtypes.pas'}

// ------------------------------ Manager of temporaries ------------------

procedure getTemp(p: BProc; t: PType; var result: TLoc);
begin
  inc(p.labels);
  if gCmd = cmdCompileToLLVM then 
    result.r := con('%LOC', toRope(p.labels))
  else begin
    result.r := con('LOC', toRope(p.labels));
    appf(p.s[cpsLocals], '$1 $2;$n', [getTypeDesc(p.module, t), result.r]);
  end;
  result.k := locTemp;
  result.a := -1;
  result.t := getUniqueType(t);
  result.s := OnStack;
  result.flags := {@set}[];
end;

// -------------------------- Variable manager ----------------------------

function cstringLit(p: BProc; var r: PRope; const s: string): PRope; overload;
begin
  if gCmd = cmdCompileToLLVM then begin
    inc(p.module.labels);
    inc(p.labels);
    result := ropef('%LOC$1', [toRope(p.labels)]);
    appf(p.module.s[cfsData], '@C$1 = private constant [$2 x i8] $3$n', [
         toRope(p.module.labels), toRope(length(s)), makeLLVMString(s)]);
    appf(r, '$1 = getelementptr [$2 x i8]* @C$3, %NI 0, %NI 0$n', 
        [result, toRope(length(s)), toRope(p.module.labels)]);
  end
  else
    result := makeCString(s)
end;

function cstringLit(m: BModule; var r: PRope; const s: string): PRope; overload;
begin
  if gCmd = cmdCompileToLLVM then begin
    inc(m.labels, 2);
    result := ropef('%MOC$1', [toRope(m.labels-1)]);
    appf(m.s[cfsData], '@MOC$1 = private constant [$2 x i8] $3$n', [
         toRope(m.labels), toRope(length(s)), makeLLVMString(s)]);
    appf(r, '$1 = getelementptr [$2 x i8]* @MOC$3, %NI 0, %NI 0$n', 
        [result, toRope(length(s)), toRope(m.labels)]);
  end
  else
    result := makeCString(s)
end;

procedure allocParam(p: BProc; s: PSym);
var
  tmp: PRope;
begin
  assert(s.kind = skParam);
  if not (lfParamCopy in s.loc.flags) then begin
    inc(p.labels);
    tmp := con('%LOC', toRope(p.labels));
    include(s.loc.flags, lfParamCopy);
    include(s.loc.flags, lfIndirect);
    appf(p.s[cpsInit], 
        '$1 = alloca $3$n' +
        'store $3 $2, $3* $1$n', [tmp, s.loc.r, getTypeDesc(p.module, s.loc.t)]);
    s.loc.r := tmp
  end;
end;

procedure localDebugInfo(p: BProc; s: PSym); 
var
  name, a: PRope;
begin
  if [optStackTrace, optEndb] * p.options <> [optStackTrace, optEndb] then exit;
  if gCmd = cmdCompileToLLVM then begin
    // "address" is the 0th field
    // "typ" is the 1rst field
    // "name" is the 2nd field
    name := cstringLit(p, p.s[cpsInit], normalize(s.name.s));
    if (s.kind = skParam) and not ccgIntroducedPtr(s) then allocParam(p, s);
    inc(p.labels, 3);
    appf(p.s[cpsInit], 
        '%LOC$6 = getelementptr %TF* %F, %NI 0, $1, %NI 0$n' +
        '%LOC$7 = getelementptr %TF* %F, %NI 0, $1, %NI 1$n' +
        '%LOC$8 = getelementptr %TF* %F, %NI 0, $1, %NI 2$n' +
        'store i8* $2, i8** %LOC$6$n' +
        'store $3* $4, $3** %LOC$7$n' +
        'store i8* $5, i8** %LOC$8$n', 
        [toRope(p.frameLen), s.loc.r, getTypeDesc(p.module, 'TNimType'),
         genTypeInfo(p.module, s.loc.t), name, toRope(p.labels), 
         toRope(p.labels-1), toRope(p.labels-2)])
  end
  else begin
    a := con('&'+'', s.loc.r);
    if (s.kind = skParam) and ccgIntroducedPtr(s) then a := s.loc.r;
    appf(p.s[cpsInit],
      'F.s[$1].address = (void*)$3; F.s[$1].typ = $4; F.s[$1].name = $2;$n',
      [toRope(p.frameLen), makeCString(normalize(s.name.s)), a,
      genTypeInfo(p.module, s.loc.t)]);
  end;
  inc(p.frameLen);
end;

procedure assignLocalVar(p: BProc; s: PSym);
begin
  //assert(s.loc.k == locNone) // not yet assigned
  // this need not be fullfilled for inline procs; they are regenerated
  // for each module that uses them!
  if s.loc.k = locNone then
    fillLoc(s.loc, locLocalVar, s.typ, mangleName(s), OnStack);
  if gCmd = cmdCompileToLLVM then begin
    appf(p.s[cpsLocals], '$1 = alloca $2$n', 
         [s.loc.r, getTypeDesc(p.module, s.loc.t)]);
    include(s.loc.flags, lfIndirect);
  end
  else begin
    app(p.s[cpsLocals], getTypeDesc(p.module, s.loc.t));
    if sfRegister in s.flags then
      app(p.s[cpsLocals], ' register');
    if (sfVolatile in s.flags) or (p.nestedTryStmts > 0) then
      app(p.s[cpsLocals], ' volatile');

    appf(p.s[cpsLocals], ' $1;$n', [s.loc.r]);
  end;
  // if debugging we need a new slot for the local variable:
  localDebugInfo(p, s);
end;

procedure assignGlobalVar(p: BProc; s: PSym);
begin
  if s.loc.k = locNone then
    fillLoc(s.loc, locGlobalVar, s.typ, mangleName(s), OnHeap);
  if gCmd = cmdCompileToLLVM then begin
    appf(p.module.s[cfsVars], '$1 = linkonce global $2 zeroinitializer$n', 
         [s.loc.r, getTypeDesc(p.module, s.loc.t)]);
    include(s.loc.flags, lfIndirect);
  end
  else begin
    useHeader(p.module, s);
    if lfNoDecl in s.loc.flags then exit;
    if sfImportc in s.flags then app(p.module.s[cfsVars], 'extern ');
    app(p.module.s[cfsVars], getTypeDesc(p.module, s.loc.t));
    if sfRegister in s.flags then app(p.module.s[cfsVars], ' register');
    if sfVolatile in s.flags then app(p.module.s[cfsVars], ' volatile');
    if sfThreadVar in s.flags then app(p.module.s[cfsVars], ' NIM_THREADVAR');
    appf(p.module.s[cfsVars], ' $1;$n', [s.loc.r]);
  end;
  if [optStackTrace, optEndb] * p.module.module.options =
     [optStackTrace, optEndb] then begin
    useMagic(p.module, 'dbgRegisterGlobal');
    appff(p.module.s[cfsDebugInit], 
      'dbgRegisterGlobal($1, &$2, $3);$n',
      'call void @dbgRegisterGlobal(i8* $1, i8* $2, $4* $3)$n',
      [cstringLit(p, p.module.s[cfsDebugInit], 
                  normalize(s.owner.name.s + '.' +{&} s.name.s)),
       s.loc.r,
       genTypeInfo(p.module, s.typ),
       getTypeDesc(p.module, 'TNimType')]);
  end;
end;

function iff(cond: bool; the, els: PRope): PRope;
begin
  if cond then result := the else result := els
end;

procedure assignParam(p: BProc; s: PSym);
begin
  assert(s.loc.r <> nil);
  if (sfAddrTaken in s.flags) and (gCmd = cmdCompileToLLVM) then 
    allocParam(p, s);
  localDebugInfo(p, s);
end;

procedure fillProcLoc(sym: PSym);
begin
  if sym.loc.k = locNone then
    fillLoc(sym.loc, locProc, sym.typ, mangleName(sym), OnStack);
end;

// -------------------------- label manager -------------------------------

// note that a label is a location too
function getLabel(p: BProc): TLabel;
begin
  inc(p.labels);
  result := con('LA', toRope(p.labels))
end;

procedure fixLabel(p: BProc; labl: TLabel);
begin
  appf(p.s[cpsStmts], '$1: ;$n', [labl])
end;

procedure genVarPrototype(m: BModule; sym: PSym); forward;
procedure genConstPrototype(m: BModule; sym: PSym); forward;
procedure genProc(m: BModule; prc: PSym); forward;
procedure genStmts(p: BProc; t: PNode); forward;
procedure genProcPrototype(m: BModule; sym: PSym); forward;

{$include 'ccgexprs.pas'}
{$include 'ccgstmts.pas'}

// ----------------------------- dynamic library handling -----------------

// We don't finalize dynamic libs as this does the OS for us.

procedure libCandidates(const s: string; var dest: TStringSeq);
var
  prefix, suffix: string;
  le, ri, i, L: int;
  temp: TStringSeq;
begin
  le := strutils.find(s, '(');
  ri := strutils.find(s, ')');
  if (le >= strStart) and (ri > le) then begin
    prefix := ncopy(s, strStart, le-1);
    suffix := ncopy(s, ri+1);
    temp := split(ncopy(s, le+1, ri-1), {@set}['|']);
    for i := 0 to high(temp) do 
      libCandidates(prefix +{&} temp[i] +{&} suffix, dest);
  end
  else begin
    {@ignore} 
    L := length(dest);
    setLength(dest, L+1);
    dest[L] := s;
    {@emit add(dest, s);}
  end
end;

procedure loadDynamicLib(m: BModule; lib: PLib);
var
  tmp, loadlib: PRope;
  s: TStringSeq;
  i: int;
begin
  assert(lib <> nil);
  if not lib.generated then begin
    lib.generated := true;
    tmp := getGlobalTempName();
    assert(lib.name = nil);
    lib.name := tmp;
    // BUGFIX: useMagic has awful side-effects
    appff(m.s[cfsVars], 'static void* $1;$n', 
                        '$1 = linkonce global i8* zeroinitializer$n', [tmp]);
    {@ignore} s := nil; {@emit s := @[];}
    libCandidates(lib.path, s);
    loadlib := nil;
    for i := 0 to high(s) do begin
      inc(m.labels);
      if i > 0 then app(loadlib, '||');
      appff(loadlib,
          '($1 = nimLoadLibrary((NimStringDesc*) &$2))$n',
          '%MOC$4 = call i8* @nimLoadLibrary($3 $2)$n' +
          'store i8* %MOC$4, i8** $1$n',
          [tmp, getStrLit(m, s[i]), getTypeDesc(m, getSysType(tyString)),
           toRope(m.labels)]);
    end;
    appff(m.s[cfsDynLibInit], 
         'if (!($1)) nimLoadLibraryError((NimStringDesc*) &$2);$n', 
         'XXX too implement',
         [loadlib, getStrLit(m, lib.path)]);
    //appf(m.s[cfsDynLibDeinit],
    //  'if ($1 != NIM_NIL) nimUnloadLibrary($1);$n', [tmp]);
    useMagic(m, 'nimLoadLibrary');
    useMagic(m, 'nimUnloadLibrary');
    useMagic(m, 'NimStringDesc');
    useMagic(m, 'nimLoadLibraryError');
  end;
  if lib.name = nil then InternalError('loadDynamicLib');
end;

procedure SymInDynamicLib(m: BModule; sym: PSym);
var
  lib: PLib;
  extname, tmp: PRope;
begin
  lib := sym.annex;
  extname := sym.loc.r;
  loadDynamicLib(m, lib);
  useMagic(m, 'nimGetProcAddr');
  if gCmd = cmdCompileToLLVM then include(sym.loc.flags, lfIndirect);

  tmp := ropeff('Dl_$1', '@Dl_$1', [toRope(sym.id)]);
  sym.loc.r := tmp; // from now on we only need the internal name
  sym.typ.sym := nil; // generate a new name
  inc(m.labels, 2);
  appff(m.s[cfsDynLibInit], 
    '$1 = ($2) nimGetProcAddr($3, $4);$n',
    '%MOC$5 = load i8* $3$n' +
    '%MOC$6 = call $2 @nimGetProcAddr(i8* %MOC$5, i8* $4)$n' +
    'store $2 %MOC$6, $2* $1$n',
    [tmp, getTypeDesc(m, sym.typ), lib.name, 
    cstringLit(m, m.s[cfsDynLibInit], ropeToStr(extname)),
    toRope(m.labels), toRope(m.labels-1)]);

  appff(m.s[cfsVars], 
    '$2 $1;$n', 
    '$1 = linkonce global $2 zeroinitializer$n',
    [sym.loc.r, getTypeDesc(m, sym.loc.t)]);
end;

// ----------------------------- sections ---------------------------------

procedure UseMagic(m: BModule; const name: string);
var
  sym: PSym;
begin
  sym := magicsys.getCompilerProc(name);
  if sym <> nil then 
    case sym.kind of
      skProc, skConverter: genProc(m, sym);
      skVar: genVarPrototype(m, sym);
      skType: {@discard} getTypeDesc(m, sym.typ);
      else InternalError('useMagic: ' + name)
    end
  else if not (sfSystemModule in m.module.flags) then
    rawMessage(errSystemNeeds, name); // don't be too picky here
end;

procedure generateHeaders(m: BModule);
var
  it: PStrEntry;
begin
  app(m.s[cfsHeaders], '#include "nimbase.h"' +{&} tnl +{&} tnl);
  it := PStrEntry(m.headerFiles.head);
  while it <> nil do begin
    if not (it.data[strStart] in ['"', '<']) then
      appf(m.s[cfsHeaders],
        '#include "$1"$n', [toRope(it.data)])
    else
      appf(m.s[cfsHeaders], '#include $1$n', [toRope(it.data)]);
    it := PStrEntry(it.Next)
  end
end;

procedure getFrameDecl(p: BProc);
var
  slots: PRope;
begin
  if p.frameLen > 0 then begin
    useMagic(p.module, 'TVarSlot');
    slots := ropeff('  TVarSlot s[$1];$n',
                    ', [$1 x %TVarSlot]', [toRope(p.frameLen)])
  end
  else
    slots := nil;
  appff(p.s[cpsLocals], 
    'volatile struct {TFrame* prev;' +
    'NCSTRING procname;NI line;NCSTRING filename;' +
    'NI len;$n$1} F;$n', 
    '%TF = type {%TFrame*, i8*, %NI, %NI$1}$n' + 
    '%F = alloca %TF$n',
    [slots]);
  inc(p.labels);
  prepend(p.s[cpsInit], ropeff('F.len = $1;$n',
      '%LOC$2 = getelementptr %TF %F, %NI 4$n' +
      'store %NI $1, %NI* %LOC$2$n',
      [toRope(p.frameLen), toRope(p.labels)]))
end;

function retIsNotVoid(s: PSym): bool;
begin
  result := (s.typ.sons[0] <> nil) and not isInvalidReturnType(s.typ.sons[0])
end;

function initFrame(p: BProc; procname, filename: PRope): PRope;
begin
  inc(p.labels, 5);
  result := ropeff(
    'F.procname = $1;$n' +
    'F.prev = framePtr;$n' +
    'F.filename = $2;$n' +
    'F.line = 0;$n' +
    'framePtr = (TFrame*)&F;$n',
    
    '%LOC$3 = getelementptr %TF %F, %NI 1$n' +
    '%LOC$4 = getelementptr %TF %F, %NI 0$n' +
    '%LOC$5 = getelementptr %TF %F, %NI 3$n' +
    '%LOC$6 = getelementptr %TF %F, %NI 2$n' +
    
    'store i8* $1, i8** %LOC$3$n' +
    'store %TFrame* @framePtr, %TFrame** %LOC$4$n' +
    'store i8* $2, i8** %LOC$5$n' +
    'store %NI 0, %NI* %LOC$6$n' +
    
    '%LOC$7 = bitcast %TF* %F to %TFrame*$n' +
    'store %TFrame* %LOC$7, %TFrame** @framePtr$n',
    [procname, filename, toRope(p.labels), toRope(p.labels-1), 
     toRope(p.labels-2), toRope(p.labels-3), toRope(p.labels-4)]);
end;

function deinitFrame(p: BProc): PRope;
begin
  inc(p.labels, 3);
  result := ropeff('framePtr = framePtr->prev;$n',
    
                   '%LOC$1 = load %TFrame* @framePtr$n' +
                   '%LOC$2 = getelementptr %TFrame* %LOC$1, %NI 0$n' +
                   '%LOC$3 = load %TFrame** %LOC$2$n' +
                   'store %TFrame* $LOC$3, %TFrame** @framePtr', [
                   toRope(p.labels), toRope(p.labels-1), toRope(p.labels-2)])
end;

procedure genProcAux(m: BModule; prc: PSym);
var
  p: BProc;
  generatedProc, header, returnStmt, procname, filename: PRope;
  i: int;
  res, param: PSym;
begin
  p := newProc(prc, m);
  header := genProcHeader(m, prc);
  returnStmt := nil;
  assert(prc.ast <> nil);

  if not (sfPure in prc.flags) and (prc.typ.sons[0] <> nil) then begin
    res := prc.ast.sons[resultPos].sym; // get result symbol
    if not isInvalidReturnType(prc.typ.sons[0]) then begin
      // declare the result symbol:
      assignLocalVar(p, res);
      assert(res.loc.r <> nil);
      returnStmt := ropeff('return $1;$n', 'ret $1$n', [rdLoc(res.loc)]);
    end
    else begin
      fillResult(res);
      assignParam(p, res);
      if skipTypes(res.typ, abstractInst).kind = tyArray then begin
        include(res.loc.flags, lfIndirect);
        res.loc.s := OnUnknown;
      end;
    end;
    initVariable(p, res);
    genObjectInit(p, res.typ, res.loc, true);
  end;
  for i := 1 to sonsLen(prc.typ.n)-1 do begin
    param := prc.typ.n.sons[i].sym;
    assignParam(p, param)
  end;

  genStmts(p, prc.ast.sons[codePos]); // modifies p.locals, p.init, etc.
  if sfPure in prc.flags then
    generatedProc := ropeff('$1 {$n$2$3$4}$n', 'define $1 {$n$2$3$4}$n',
      [header, p.s[cpsLocals], p.s[cpsInit], p.s[cpsStmts]])
  else begin
    generatedProc := ropeff('$1 {$n', 'define $1 {$n', [header]);
    if optStackTrace in prc.options then begin
      getFrameDecl(p);
      app(generatedProc, p.s[cpsLocals]);
      procname := CStringLit(p, generatedProc, 
                             prc.owner.name.s +{&} '.' +{&} prc.name.s);
      filename := CStringLit(p, generatedProc, toFilename(prc.info));
      app(generatedProc, initFrame(p, procname, filename));
    end
    else
      app(generatedProc, p.s[cpsLocals]);
    if (optProfiler in prc.options) and (gCmd <> cmdCompileToLLVM) then begin
      if gProcProfile >= 64*1024 then // XXX: hard coded value!
        InternalError(prc.info, 'too many procedures for profiling');
      useMagic(m, 'profileData');
      app(p.s[cpsLocals], 'ticks NIM_profilingStart;'+tnl);
      if prc.loc.a < 0 then begin
        appf(m.s[cfsDebugInit], 'profileData[$1].procname = $2;$n',
            [toRope(gProcProfile),
             makeCString(prc.owner.name.s +{&} '.' +{&} prc.name.s)]);
        prc.loc.a := gProcProfile;
        inc(gProcProfile);
      end;
      prepend(p.s[cpsInit], toRope('NIM_profilingStart = getticks();' + tnl));
    end;
    app(generatedProc, p.s[cpsInit]);
    app(generatedProc, p.s[cpsStmts]);
    if p.beforeRetNeeded then
      app(generatedProc, 'BeforeRet: ;' + tnl);
    if optStackTrace in prc.options then
      app(generatedProc, deinitFrame(p));
    if (optProfiler in prc.options) and (gCmd <> cmdCompileToLLVM) then 
      appf(generatedProc,
        'profileData[$1].total += elapsed(getticks(), NIM_profilingStart);$n',
        [toRope(prc.loc.a)]);
    app(generatedProc, returnStmt);
    app(generatedProc, '}' + tnl);
  end;
  app(m.s[cfsProcs], generatedProc);
end;

procedure genProcPrototype(m: BModule; sym: PSym);
begin
  useHeader(m, sym);
  if (lfNoDecl in sym.loc.Flags) then exit;
  if lfDynamicLib in sym.loc.Flags then begin
    if (sym.owner.id <> m.module.id) and
        not intSetContainsOrIncl(m.declaredThings, sym.id) then begin
      appff(m.s[cfsVars], 'extern $1 Dl_$2;$n',
           '@Dl_$2 = linkonce global $1 zeroinitializer$n',
           [getTypeDesc(m, sym.loc.t), toRope(sym.id)]);
      if gCmd = cmdCompileToLLVM then include(sym.loc.flags, lfIndirect);
    end
  end
  else begin
    if not IntSetContainsOrIncl(m.declaredProtos, sym.id) then
      appf(m.s[cfsProcHeaders], '$1;$n', [genProcHeader(m, sym)]);
  end
end;

procedure genProcNoForward(m: BModule; prc: PSym);
begin
  fillProcLoc(prc);
  useHeader(m, prc);
  genProcPrototype(m, prc);
  if (lfNoDecl in prc.loc.Flags) then exit;  
  if prc.typ.callConv = ccInline then begin
    // We add inline procs to the calling module to enable C based inlining.
    // This also means that a check with ``gGeneratedSyms`` is wrong, we need
    // a check for ``m.declaredThings``.
    if not intSetContainsOrIncl(m.declaredThings, prc.id) then 
      genProcAux(m, prc);
  end
  else if lfDynamicLib in prc.loc.flags then begin
    if not IntSetContainsOrIncl(gGeneratedSyms, prc.id) then
      SymInDynamicLib(findPendingModule(m, prc), prc);
  end
  else if not (sfImportc in prc.flags) then begin
    if not IntSetContainsOrIncl(gGeneratedSyms, prc.id) then 
      genProcAux(findPendingModule(m, prc), prc);
  end
end;

procedure genProc(m: BModule; prc: PSym);
begin
  if sfBorrow in prc.flags then exit;
  fillProcLoc(prc);
  if [sfForward, sfFromGeneric] * prc.flags <> [] then 
    addForwardedProc(m, prc)
  else
    genProcNoForward(m, prc)
end;

procedure genVarPrototype(m: BModule; sym: PSym);
begin
  assert(sfGlobal in sym.flags);
  useHeader(m, sym);
  fillLoc(sym.loc, locGlobalVar, sym.typ, mangleName(sym), OnHeap);
  if (lfNoDecl in sym.loc.Flags) or
      intSetContainsOrIncl(m.declaredThings, sym.id) then
    exit;
  if sym.owner.id <> m.module.id then begin
    // else we already have the symbol generated!
    assert(sym.loc.r <> nil);
    if gCmd = cmdCompileToLLVM then begin
      include(sym.loc.flags, lfIndirect);
      appf(m.s[cfsVars], '$1 = linkonce global $2 zeroinitializer$n', 
           [sym.loc.r, getTypeDesc(m, sym.loc.t)]);
    end
    else begin
      app(m.s[cfsVars], 'extern ');
      app(m.s[cfsVars], getTypeDesc(m, sym.loc.t));
      if sfRegister in sym.flags then
        app(m.s[cfsVars], ' register');
      if sfVolatile in sym.flags then
        app(m.s[cfsVars], ' volatile');
      if sfThreadVar in sym.flags then
        app(m.s[cfsVars], ' NIM_THREADVAR');
      appf(m.s[cfsVars], ' $1;$n', [sym.loc.r])
    end
  end
end;

procedure genConstPrototype(m: BModule; sym: PSym);
begin
  useHeader(m, sym);
  if sym.loc.k = locNone then
    fillLoc(sym.loc, locData, sym.typ, mangleName(sym), OnUnknown);
  if (lfNoDecl in sym.loc.Flags) or
      intSetContainsOrIncl(m.declaredThings, sym.id) then
    exit;
  if sym.owner.id <> m.module.id then begin
    // else we already have the symbol generated!
    assert(sym.loc.r <> nil);
    appff(m.s[cfsData], 
      'extern NIM_CONST $1 $2;$n',
      '$1 = linkonce constant $2 zeroinitializer',
      [getTypeDesc(m, sym.loc.t), sym.loc.r])
  end
end;

function getFileHeader(const cfilenoext: string): PRope;
begin
  if optCompileOnly in gGlobalOptions then
    result := ropeff(
      '/* Generated by the Nimrod Compiler v$1 */$n' +
      '/*   (c) 2009 Andreas Rumpf */$n',
      '; Generated by the Nimrod Compiler v$1$n' +
      ';   (c) 2009 Andreas Rumpf$n',
      [toRope(versionAsString)])
  else
    result := ropeff(
      '/* Generated by the Nimrod Compiler v$1 */$n' +
      '/*   (c) 2009 Andreas Rumpf */$n' +
      '/* Compiled for: $2, $3, $4 */$n' +
      '/* Command for C compiler:$n   $5 */$n',
      '; Generated by the Nimrod Compiler v$1$n' +
      ';   (c) 2009 Andreas Rumpf$n' +
      '; Compiled for: $2, $3, $4$n' +
      '; Command for LLVM compiler:$n   $5$n',
      [toRope(versionAsString), toRope(platform.OS[targetOS].name),
      toRope(platform.CPU[targetCPU].name),
      toRope(extccomp.CC[extccomp.ccompiler].name),
      toRope(getCompileCFileCmd(cfilenoext))]);
  case platform.CPU[targetCPU].intSize of
    16: appff(result, '$ntypedef short int NI;$n' +
                      'typedef unsigned short int NU;$n',
                      '$n%NI = type i16$n', []);
    32: appff(result, '$ntypedef long int NI;$n' +
                      'typedef unsigned long int NU;$n',
                      '$n%NI = type i32$n', []);
    64: appff(result, '$ntypedef long long int NI;$n' +
                      'typedef unsigned long long int NU;$n',
                      '$n%NI = type i64$n', []);
    else begin end
  end
end;

procedure genMainProc(m: BModule);
const
  CommonMainBody =
    '  setStackBottom(dummy);$n' +
    '  nim__datInit();$n' +
    '  systemInit();$n' +
    '$1' +
    '$2';
  CommonMainBodyLLVM = 
    '  %MOC$3 = bitcast [8 x %NI]* %dummy to i8*$n' +
    '  call void @setStackBottom(i8* %MOC$3)$n' +
    '  call void @nim__datInit()$n' +
    '  call void systemInit()$n' +
    '$1' +
    '$2';    
  PosixNimMain =
    'int cmdCount;$n' +
    'char** cmdLine;$n' +
    'char** gEnv;$n' +
    'N_CDECL(void, NimMain)(void) {$n' +
    '  int dummy[8];$n' +{&}
    CommonMainBody +{&}
    '}$n';
  PosixCMain = 
    'int main(int argc, char** args, char** env) {$n' +
    '  cmdLine = args;$n' +
    '  cmdCount = argc;$n' +
    '  gEnv = env;$n' +
    '  NimMain();$n' +
    '  return 0;$n' +
    '}$n';
  PosixNimMainLLVM =
    '@cmdCount = linkonce i32$n' +
    '@cmdLine = linkonce i8**$n' +
    '@gEnv = linkonce i8**$n' +
    'define void @NimMain(void) {$n' +
    '  %dummy = alloca [8 x %NI]$n' +{&}
    CommonMainBodyLLVM +{&}
    '}$n';
  PosixCMainLLVM = 
    'define i32 @main(i32 %argc, i8** %args, i8** %env) {$n' +
    '  store i8** %args, i8*** @cmdLine$n' +
    '  store i32 %argc, i32* @cmdCount$n' +
    '  store i8** %env, i8*** @gEnv$n' +
    '  call void @NimMain()$n' +
    '  ret i32 0$n' +
    '}$n';    
  WinNimMain = 
    'N_CDECL(void, NimMain)(void) {$n' +
    '  int dummy[8];$n' +{&}
    CommonMainBody +{&}
    '}$n';
  WinCMain =
    'N_STDCALL(int, WinMain)(HINSTANCE hCurInstance, $n' +
    '                        HINSTANCE hPrevInstance, $n' +
    '                        LPSTR lpCmdLine, int nCmdShow) {$n' +
    '  NimMain();$n' +
    '  return 0;$n' +
    '}$n';
  WinNimMainLLVM = 
    'define void @NimMain(void) {$n' +
    '  %dummy = alloca [8 x %NI]$n' +{&}
    CommonMainBodyLLVM +{&}
    '}$n';
  WinCMainLLVM =
    'define stdcall i32 @WinMain(i32 %hCurInstance, $n' +
    '                            i32 %hPrevInstance, $n' +
    '                            i8* %lpCmdLine, i32 %nCmdShow) {$n' +
    '  call void @NimMain()$n' +
    '  ret i32 0$n' +
    '}$n';
  WinNimDllMain = WinNimMain;
  WinCDllMain =
    'BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fwdreason, $n' +
    '                    LPVOID lpvReserved) {$n' +
    '  NimMain();$n' +
    '  return 1;$n' +
    '}$n';
  WinNimDllMainLLVM = WinNimMainLLVM;
  WinCDllMainLLVM =
    'define stdcall i32 @DllMain(i32 %hinstDLL, i32 %fwdreason, $n' +
    '                            i8* %lpvReserved) {$n' +
    '  call void @NimMain()$n' +
    '  ret i32 1$n' +
    '}$n';
var
  nimMain, otherMain: TFormatStr;
begin
  useMagic(m, 'setStackBottom');
  if (platform.targetOS = osWindows) and
      (gGlobalOptions * [optGenGuiApp, optGenDynLib] <> []) then begin
    if optGenGuiApp in gGlobalOptions then begin
      if gCmd = cmdCompileToLLVM then begin
        nimMain := WinNimMainLLVM; 
        otherMain := WinCMainLLVM
      end
      else begin
        nimMain := WinNimMain;
        otherMain := WinCMain;
      end
    end
    else begin
      if gCmd = cmdCompileToLLVM then begin
        nimMain := WinNimDllMainLLVM;
        otherMain := WinCDllMainLLVM;
      end
      else begin
        nimMain := WinNimDllMain;
        otherMain := WinCDllMain;
      end
    end;
    {@discard} lists.IncludeStr(m.headerFiles, '<windows.h>')
  end
  else begin 
    if gCmd = cmdCompileToLLVM then begin 
      nimMain := PosixNimMainLLVM;
      otherMain := PosixCMainLLVM;
    end
    else begin
      nimMain := PosixNimMain;
      otherMain := PosixCMain;
    end
  end;
  if gBreakpoints <> nil then useMagic(m, 'dbgRegisterBreakpoint');
  inc(m.labels);
  appf(m.s[cfsProcs], nimMain, [gBreakpoints, mainModInit, toRope(m.labels)]);
  if not (optNoMain in gGlobalOptions) then 
    appf(m.s[cfsProcs], otherMain, []);
end;

function getInitName(m: PSym): PRope;
begin
  result := ropeff('$1Init', '@$1Init', [toRope(m.name.s)]);
end;

procedure registerModuleToMain(m: PSym);
var
  initname: PRope;
begin
  initname := getInitName(m);
  appff(mainModProcs, 'N_NOINLINE(void, $1)(void);$n',
                      'declare void $1() noinline$n', [initname]);
  if not (sfSystemModule in m.flags) then
    appff(mainModInit, '$1();$n', 'call void ()* $1$n', [initname]);
end;

procedure genInitCode(m: BModule);
var
  initname, prc, procname, filename: PRope;
begin
  if optProfiler in m.initProc.options then begin
    // This does not really belong here, but there is no good place for this
    // code. I don't want to put this to the proc generation as the
    // ``IncludeStr`` call is quite slow.
    {@discard} lists.IncludeStr(m.headerFiles, '<cycle.h>');
  end;
  initname := getInitName(m.module);
  prc := ropeff('N_NOINLINE(void, $1)(void) {$n',
                'define void $1() noinline {$n', [initname]);
  if m.typeNodes > 0 then begin
    useMagic(m, 'TNimNode');
    appff(m.s[cfsTypeInit1], 'static TNimNode $1[$2];$n',
         '$1 = private alloca [$2 x @TNimNode]$n', 
         [m.typeNodesName, toRope(m.typeNodes)]);
  end;
  if m.nimTypes > 0 then begin
    useMagic(m, 'TNimType');
    appff(m.s[cfsTypeInit1], 'static TNimType $1[$2];$n', 
         '$1 = private alloca [$2 x @TNimType]$n',
         [m.nimTypesName, toRope(m.nimTypes)]);
  end;
  if optStackTrace in m.initProc.options then begin
    getFrameDecl(m.initProc);
    app(prc, m.initProc.s[cpsLocals]);
    app(prc, m.s[cfsTypeInit1]);
    
    procname := CStringLit(m.initProc, prc, 'module ' +{&} m.module.name.s);
    filename := CStringLit(m.initProc, prc, toFilename(m.module.info));
    app(prc, initFrame(m.initProc, procname, filename));
  end
  else begin
    app(prc, m.initProc.s[cpsLocals]);
    app(prc, m.s[cfsTypeInit1]);
  end;
  app(prc, m.s[cfsTypeInit2]);
  app(prc, m.s[cfsTypeInit3]);
  app(prc, m.s[cfsDebugInit]);
  app(prc, m.s[cfsDynLibInit]);
  app(prc, m.initProc.s[cpsInit]);
  app(prc, m.initProc.s[cpsStmts]);
  if optStackTrace in m.initProc.options then
    app(prc, deinitFrame(m.initProc));
  app(prc, '}' +{&} tnl +{&} tnl);
  app(m.s[cfsProcs], prc)
end;

function genModule(m: BModule; const cfilenoext: string): PRope;
var
  i: TCFileSection;
begin
  result := getFileHeader(cfilenoext);
  generateHeaders(m);
  for i := low(TCFileSection) to cfsProcs do app(result, m.s[i])
end;

function rawNewModule(module: PSym; const filename: string): BModule;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  InitLinkedList(result.headerFiles);
  intSetInit(result.declaredThings);
  intSetInit(result.declaredProtos);
  result.cfilename := filename;
  result.filename := filename;
  initIdTable(result.typeCache);
  initIdTable(result.forwTypeCache);
  result.module := module;
  intSetInit(result.typeInfoMarker);
  result.initProc := newProc(nil, result);
  result.initProc.options := gOptions;
  initNodeTable(result.dataCache);
{@emit result.typeStack := @[];}
{@emit result.forwardedProcs := @[];}
  result.typeNodesName := getTempName();
  result.nimTypesName := getTempName();
end;

function newModule(module: PSym; const filename: string): BModule;
begin
  result := rawNewModule(module, filename);
  if (optDeadCodeElim in gGlobalOptions) then begin
    if (sfDeadCodeElim in module.flags) then
      InternalError('added pending module twice: ' + filename);
    addPendingModule(result)
  end;
end;

procedure registerTypeInfoModule();
const
  moduleName = 'nim__dat';
var
  s: PSym;
begin
  s := NewSym(skModule, getIdent(moduleName), nil);
  gmti := rawNewModule(s, joinPath(options.projectPath, moduleName)+'.nim');
  addPendingModule(gmti);
  appff(mainModProcs, 'N_NOINLINE(void, $1)(void);$n',
                      'declare void $1() noinline$n', [getInitName(s)]);
end;

function myOpen(module: PSym; const filename: string): PPassContext;
begin
  if gmti = nil then registerTypeInfoModule();
  result := newModule(module, filename);
end;

function myOpenCached(module: PSym; const filename: string;
                      rd: PRodReader): PPassContext;
var
  cfile, cfilenoext, objFile: string;
begin
  if gmti = nil then registerTypeInfoModule();
  //MessageOut('cgen.myOpenCached has been called ' + filename);
  cfile := changeFileExt(completeCFilePath(filename), cExt);
  cfilenoext := changeFileExt(cfile, '');
  addFileToLink(cfilenoext);
  registerModuleToMain(module);
  // XXX: this cannot be right here, initalization has to be appended during
  // the ``myClose`` call
  result := nil;
end;

function shouldRecompile(code: PRope; const cfile, cfilenoext: string): bool;
var
  objFile: string;
begin
  result := true;
  if not (optForceFullMake in gGlobalOptions) then begin
    objFile := toObjFile(cfilenoext);
    if writeRopeIfNotEqual(code, cfile) then exit;
    if ExistsFile(objFile) and nos.FileNewer(objFile, cfile) then
      result := false
  end
  else
    writeRope(code, cfile);
end;

function myProcess(b: PPassContext; n: PNode): PNode;
var
  m: BModule;
begin
  result := n;
  if b = nil then exit;
  m := BModule(b);
  m.initProc.options := gOptions;
  genStmts(m.initProc, n);
end;

procedure finishModule(m: BModule);
var
  i: int;
  prc: PSym;
begin
  i := 0;
  while i <= high(m.forwardedProcs) do begin
    // Note: ``genProc`` may add to ``m.forwardedProcs``, so we cannot use
    // a for loop here
    prc := m.forwardedProcs[i];
    if sfForward in prc.flags then InternalError(prc.info, 'still forwarded');
    genProcNoForward(m, prc);
    inc(i);
  end;
  assert(gForwardedProcsCounter >= i);
  dec(gForwardedProcsCounter, i);
  setLength(m.forwardedProcs, 0);
end;

procedure writeModule(m: BModule);
var
  cfile, cfilenoext: string;
  code: PRope;
begin
  // generate code for the init statements of the module:
  genInitCode(m);
  finishTypeDescriptions(m);
  
  cfile := completeCFilePath(m.cfilename);
  cfilenoext := changeFileExt(cfile, '');
  if sfMainModule in m.module.flags then begin
    // generate main file:
    app(m.s[cfsProcHeaders], mainModProcs);
  end;
  code := genModule(m, cfilenoext);
  if shouldRecompile(code, changeFileExt(cfile, cExt), cfilenoext) then begin
    addFileToCompile(cfilenoext);
  end;
  addFileToLink(cfilenoext);
end;

function myClose(b: PPassContext; n: PNode): PNode;
var
  m: BModule;
  i: int;
begin
  result := n;
  if b = nil then exit;
  m := BModule(b);
  if n <> nil then begin
    m.initProc.options := gOptions;
    genStmts(m.initProc, n);
  end;
  registerModuleToMain(m.module);
  if not (optDeadCodeElim in gGlobalOptions) and 
      not (sfDeadCodeElim in m.module.flags) then
    finishModule(m);
  if sfMainModule in m.module.flags then begin
    genMainProc(m);
    // we need to process the transitive closure because recursive module
    // deps are allowed (and the system module is processed in the wrong
    // order anyway)
    while gForwardedProcsCounter > 0 do
      for i := 0 to high(gPendingModules) do
        finishModule(gPendingModules[i]);
    for i := 0 to high(gPendingModules) do writeModule(gPendingModules[i]);
    setLength(gPendingModules, 0);
  end;
  if not (optDeadCodeElim in gGlobalOptions) and 
      not (sfDeadCodeElim in m.module.flags) then
    writeModule(m);
  if sfMainModule in m.module.flags then 
    writeMapping(gMapping);  
end;

function cgenPass(): TPass;
begin
  initPass(result);
  result.open := myOpen;
  result.openCached := myOpenCached;
  result.process := myProcess;
  result.close := myClose;
end;

initialization
  InitIiTable(gToTypeInfoId);
  IntSetInit(gGeneratedSyms);
end.
