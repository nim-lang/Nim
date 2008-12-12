//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
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
  nsystem, ast, astalgo, strutils, hashes, trees, platform, magicsys,
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
    cfsData,           // section for C constant data
    cfsVars,           // section for C variable declarations
    cfsProcHeaders,    // section for C procs prototypes
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
    debugDeclared: TIntSet;  // for debugging purposes
    headerFiles: TLinkedList; // needed headers to include
    typeInfoMarker: TIntSet; // needed for generating type information
    initProc: BProc;         // code for init procedure
    typeStack: TTypeSeq;     // used for type generation
    dataCache: TNodeTable;
    typeNodes, nimTypes: int;// used for type info generation
    typeNodesName, nimTypesName: PRope;    // used for type info generation
  end;

var
  mainModProcs, mainModInit: PRope; // parts of the main module
  gMapping: PRope;  // the generated mapping file (if requested)
  gProcProfile: Natural; // proc profile counter


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
  result := not (skipVarGeneric(typ).kind in [tyTuple, tyObject, tyArray,
                                            tyArrayConstr, tySet, tySequence])
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

function beEqualTypes(a, b: PType): bool;
begin
  // returns whether two type are equal for the backend
  result := sameType(skipGenericRange(a), skipGenericRange(b))
end;

procedure getTemp(p: BProc; t: PType; var result: TLoc);
begin
  inc(p.labels);
  result.r := con('LOC', toRope(p.labels));
  appf(p.s[cpsLocals], '$1 $2;$n', [getTypeDesc(p.module, t), result.r]);
  result.k := locTemp;
  result.a := -1;
  result.t := getUniqueType(t);
  result.s := OnStack;
  result.flags := {@set}[];
end;

// -------------------------- Variable manager ----------------------------

procedure declareGlobalVar(m: BModule; s: PSym);
begin
  if not IntSetContainsOrIncl(m.declaredThings, s.id) then begin
    app(m.s[cfsVars], getTypeDesc(m, s.loc.t));
    if sfRegister in s.flags then
      app(m.s[cfsVars], ' register');
    if sfVolatile in s.flags then
      app(m.s[cfsVars], ' volatile');
    if sfThreadVar in s.flags then
      app(m.s[cfsVars], ' NIM_THREADVAR');
    appf(m.s[cfsVars], ' $1;$n', [s.loc.r])
  end
end;

procedure assignLocalVar(p: BProc; s: PSym);
begin
  //assert(s.loc.k == locNone) // not yet assigned
  // this need not be fullfilled for inline procs; they are regenerated
  // for each module that uses them!
  fillLoc(s.loc, locLocalVar, s.typ, mangleName(s), OnStack);
  app(p.s[cpsLocals], getTypeDesc(p.module, s.loc.t));
  if sfRegister in s.flags then
    app(p.s[cpsLocals], ' register');
  if (sfVolatile in s.flags) or (p.nestedTryStmts > 0) then
    app(p.s[cpsLocals], ' volatile');

  appf(p.s[cpsLocals], ' $1;$n', [s.loc.r]);
  // if debugging we need a new slot for the local variable:
  if [optStackTrace, optEndb] * p.Options = [optStackTrace, optEndb] then begin
    appf(p.s[cpsInit],
      'F.s[$1].name = $2; F.s[$1].address = (void*)&$3; F.s[$1].typ = $4;$n',
      [toRope(p.frameLen), makeCString(normalize(s.name.s)), s.loc.r,
      genTypeInfo(p.module, s.loc.t)]);
    inc(p.frameLen);
  end
end;

procedure assignGlobalVar(m: BModule; s: PSym);
begin
  fillLoc(s.loc, locGlobalVar, s.typ, mangleName(s), OnHeap);
  useHeader(m, s);
  if lfNoDecl in s.loc.flags then exit;
  if sfImportc in s.flags then app(m.s[cfsVars], 'extern ');
  declareGlobalVar(m, s);
  if [optStackTrace, optEndb] * m.module.options =
     [optStackTrace, optEndb] then begin
    useMagic(m, 'dbgRegisterGlobal');
    appf(m.s[cfsDebugInit],
      'dbgRegisterGlobal($1, &$2, $3);$n',
      [makeCString(normalize(s.owner.name.s + '.' +{&} s.name.s)), s.loc.r,
      genTypeInfo(m, s.typ)])
  end;
end;

function iff(cond: bool; the, els: PRope): PRope;
begin
  if cond then result := the else result := els
end;

procedure assignParam(p: BProc; s: PSym);
begin
  assert(s.loc.r <> nil);
  if [optStackTrace, optEndb] * p.options = [optStackTrace, optEndb] then begin
    appf(p.s[cpsInit],
      'F.s[$1].name = $2; F.s[$1].address = (void*)$3; ' +
      'F.s[$1].typ = $4;$n',
      [toRope(p.frameLen), makeCString(normalize(s.name.s)),
      iff(ccgIntroducedPtr(s), s.loc.r, con('&'+'', s.loc.r)),
      genTypeInfo(p.module, s.loc.t)]);
    inc(p.frameLen)
  end
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

procedure genProcPrototype(m: BModule; sym: PSym); forward;
procedure genVarPrototype(m: BModule; sym: PSym); forward;
procedure genConstPrototype(m: BModule; sym: PSym); forward;
procedure genProc(m: BModule; prc: PSym); forward;
procedure genStmts(p: BProc; t: PNode); forward;

{$include 'ccgexprs.pas'}
{$include 'ccgstmts.pas'}

// ----------------------------- dynamic library handling -----------------

// We don't finalize dynamic libs as this does the OS for us.

procedure loadDynamicLib(m: BModule; lib: PLib);
var
  tmp: PRope;
begin
  assert(lib <> nil);
  if not lib.generated then begin
    lib.generated := true;
    useMagic(m, 'nimLoadLibrary');
    useMagic(m, 'nimUnloadLibrary');
    useMagic(m, 'NimStringDesc');
    tmp := getTempName();
    appf(m.s[cfsVars], 'static void* $1;$n', [tmp]);
    appf(m.s[cfsDynLibInit],
      '$1 = nimLoadLibrary((NimStringDesc*) &$2);$n',
      [tmp, getStrLit(m, lib.path)]);
    appf(m.s[cfsDynLibDeinit],
      'if ($1 != NIM_NIL) nimUnloadLibrary($1);$n', [tmp]);
    assert(lib.name = nil);
    lib.name := tmp
  end
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
  tmp := ropef('Dl_$1', [toRope(sym.id)]);
  sym.loc.r := tmp; // from now on we only need the internal name
  sym.typ.sym := nil; // generate a new name
  appf(m.s[cfsDynLibInit],
    '$1 = ($2) nimGetProcAddr($3, $4);$n',
    [tmp, getTypeDesc(m, sym.typ), lib.name,
    makeCString(ropeToStr(extname))]);
  declareGlobalVar(m, sym)
end;

// ----------------------------- sections ---------------------------------

procedure UseMagic(m: BModule; const name: string);
var
  sym: PSym;
begin
  if (sfSystemModule in m.module.flags) then exit;
  // we don't know the magic symbols in the system module, but they will be
  // there anyway, because that is the way the code generator works
  sym := magicsys.getCompilerProc(name);
  case sym.kind of
    skProc, skConverter: genProcPrototype(m, sym);
    skVar: genVarPrototype(m, sym);
    skType: {@discard} getTypeDesc(m, sym.typ);
    else InternalError('useMagic: ' + name)
  end
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
    slots := ropef('  TVarSlot s[$1];$n', [toRope(p.frameLen)])
  end
  else
    slots := nil;
  appf(p.s[cpsLocals], 'volatile struct {TFrame* prev;' +
    'NCSTRING procname;NI line;NCSTRING filename;' +
    'NI len;$n$1} F;$n', [slots]);
  prepend(p.s[cpsInit], ropef('F.len = $1;$n', [toRope(p.frameLen)]))
end;

function retIsNotVoid(s: PSym): bool;
begin
  result := (s.typ.sons[0] <> nil) and not isInvalidReturnType(s.typ.sons[0])
end;

procedure genProc(m: BModule; prc: PSym);
var
  p: BProc;
  generatedProc, header, returnStmt: PRope;
  i, profileId: int;
  res, param: PSym;
begin
  useHeader(m, prc);
  fillLoc(prc.loc, locProc, prc.typ, mangleName(prc), OnStack);
  if (lfNoDecl in prc.loc.Flags) then exit;
  if lfDynamicLib in prc.loc.flags then
    SymInDynamicLib(m, prc)
  else if not (sfImportc in prc.flags) then begin
    // we have a real proc here:
    p := newProc(prc, m);
    header := genProcHeader(m, prc);
    if (sfCompilerProc in prc.flags)
    and (sfSystemModule in m.module.flags)
    and not IntSetContains(m.declaredThings, prc.id) then
      appf(m.s[cfsProcHeaders], '$1;$n', [header]);
    intSetIncl(m.declaredThings, prc.id);
    returnStmt := nil;
    assert(prc.ast <> nil);

    if not (sfPure in prc.flags) and (prc.typ.sons[0] <> nil) then begin
      res := prc.ast.sons[resultPos].sym; // get result symbol
      if not isInvalidReturnType(prc.typ.sons[0]) then begin
        // declare the result symbol:
        assignLocalVar(p, res);
        assert(res.loc.r <> nil);
        returnStmt := ropef('return $1;$n', [rdLoc(res.loc)]);
      end
      else begin
        fillResult(res);
        assignParam(p, res);
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
      generatedProc := ropef('$1 {$n$2$3$4}$n',
        [header, p.s[cpsLocals], p.s[cpsInit], p.s[cpsStmts]])
    else begin
      generatedProc := con(header, '{' + tnl);
      if optStackTrace in prc.options then begin
        getFrameDecl(p);
        prepend(p.s[cpsInit], ropef(
          'F.procname = $1;$n' +
          'F.prev = framePtr;$n' +
          'F.filename = $2;$n' +
          'F.line = 0;$n' +
          'framePtr = (TFrame*)&F;$n',
          [makeCString(prc.owner.name.s +{&} '.' +{&} prc.name.s),
          makeCString(toFilename(prc.info))]));
      end;
      if optProfiler in prc.options then begin
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
      app(generatedProc, con(p.s));
      if p.beforeRetNeeded then
        app(generatedProc, 'BeforeRet: ;' + tnl);
      if optStackTrace in prc.options then
        app(generatedProc, 'framePtr = framePtr->prev;' + tnl);
      if optProfiler in prc.options then
        appf(generatedProc,
          'profileData[$1].total += elapsed(getticks(), NIM_profilingStart);$n',
          [toRope(prc.loc.a)]);
      app(generatedProc, returnStmt);
      app(generatedProc, '}' + tnl);
    end;
    app(m.s[cfsProcs], generatedProc);
  end
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
end;

procedure genConstPrototype(m: BModule; sym: PSym);
begin
  useHeader(m, sym);
  fillLoc(sym.loc, locData, sym.typ, mangleName(sym), OnUnknown);
  if (lfNoDecl in sym.loc.Flags) or
      intSetContainsOrIncl(m.declaredThings, sym.id) then
    exit;
  if sym.owner.id <> m.module.id then begin
    // else we already have the symbol generated!
    assert(sym.loc.r <> nil);
    app(m.s[cfsData], 'extern ');
    appf(m.s[cfsData], 'NIM_CONST $1 $2;$n',
      [getTypeDesc(m, sym.loc.t), sym.loc.r])
  end
end;

procedure genProcPrototype(m: BModule; sym: PSym);
begin
  useHeader(m, sym);
  fillLoc(sym.loc, locProc, sym.typ, mangleName(sym), OnStack);
  if lfDynamicLib in sym.loc.Flags then begin
    // it is a proc variable!
    if (sym.owner.id <> m.module.id) and
        not intSetContainsOrIncl(m.declaredThings, sym.id) then begin
      app(m.s[cfsVars], 'extern ');
      // BUGFIX: declareGlobalVar() inlined, because of intSetContainsOrIncl
      // check
      app(m.s[cfsVars], getTypeDesc(m, sym.loc.t));
      appf(m.s[cfsVars], ' $1;$n', [sym.loc.r])
    end
  end
  else begin
    // it is a proc:
    if (lfNoDecl in sym.loc.Flags) then exit;
    if intSetContainsOrIncl(m.declaredThings, sym.id) then exit;
    appf(m.s[cfsProcHeaders], '$1;$n', [genProcHeader(m, sym)]);
    if (sym.typ.callConv = ccInline)
    and (sym.owner.id <> m.module.id) then
      genProc(m, sym) // generate the code again!
  end
end;

function getFileHeader(const cfilenoext: string): PRope;
begin
  if optCompileOnly in gGlobalOptions then
    result := ropef(
      '/* Generated by the Nimrod Compiler v$1 */$n' +
      '/*   (c) 2008 Andreas Rumpf */$n',
      [toRope(versionAsString)])
  else
    result := ropef(
      '/* Generated by the Nimrod Compiler v$1 */$n' +
      '/*   (c) 2008 Andreas Rumpf */$n' +
      '/* Compiled for: $2, $3, $4 */$n' +
      '/* Command for C compiler:$n   $5 */$n',
      [toRope(versionAsString), toRope(platform.OS[targetOS].name),
      toRope(platform.CPU[targetCPU].name),
      toRope(extccomp.CC[extccomp.ccompiler].name),
      toRope(getCompileCFileCmd(cfilenoext))]);
  case platform.CPU[targetCPU].intSize of
    16: appf(result, '$ntypedef short int NI;$n' +
                     'typedef unsigned short int NU;$n', []);
    32: appf(result, '$ntypedef long int NI;$n' +
                     'typedef unsigned long int NU;$n', []);
    64: appf(result, '$ntypedef long long int NI;$n' +
                     'typedef unsigned long long int NU;$n', []);
    else begin end
  end
end;

procedure genMainProc(m: BModule);
const
  CommonMainBody =
    '  setStackBottom(dummy);$n' +
    '  systemInit();$n' +
    '$1' +
    '$2';
  PosixMain =
    'NI cmdCount;$n' +
    'char** cmdLine;$n' +
    'char** gEnv;$n' +
    'int main(int argc, char** args, char** env) {$n' +
    '  int dummy[8];$n' +
    '  cmdLine = args;$n' +
    '  cmdCount = (NI)argc;$n' +
    '  gEnv = env;$n' +{&}
    CommonMainBody +{&}
    '  return 0;$n' +
    '}$n';
  WinMain =
    'N_STDCALL(int, WinMain)(HINSTANCE hCurInstance, $n' +
    '                        HINSTANCE hPrevInstance, $n' +
    '                        LPSTR lpCmdLine, int nCmdShow) {$n' +
    '  int dummy[8];$n' +{&}
    CommonMainBody +{&}
    '  return 0;$n' +
    '}$n';
  WinDllMain =
    'BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fwdreason, $n' +
    '                    LPVOID lpvReserved) {$n' +
    '  int dummy[8];$n' +{&}
    CommonMainBody +{&}
    '  return 1;$n' +
    '}$n';
var
  frmt: TFormatStr;
begin
  useMagic(m, 'setStackBottom');
  if (platform.targetOS = osWindows) and
      (gGlobalOptions * [optGenGuiApp, optGenDynLib] <> []) then begin
    if optGenGuiApp in gGlobalOptions then
      frmt := WinMain
    else
      frmt := WinDllMain;
    {@discard} lists.IncludeStr(m.headerFiles, '<windows.h>')
  end
  else
    frmt := PosixMain;
  if gBreakpoints <> nil then
    useMagic(m, 'dbgRegisterBreakpoint');
  appf(m.s[cfsProcs], frmt, [gBreakpoints, mainModInit])
end;

function getInitName(m: PSym): PRope;
begin
  result := con(m.name.s, toRope('Init'));
end;

procedure registerModuleToMain(m: PSym);
var
  initname: PRope;
begin
  initname := getInitName(m);
  appf(mainModProcs, 'N_NOINLINE(void, $1)(void);$n',
      [initname]);
  if not (sfSystemModule in m.flags) then
    appf(mainModInit, '$1();$n', [initname]);
end;

procedure genInitCode(m: BModule);
var
  initname, prc: PRope;
begin
  if optProfiler in m.initProc.options then begin
    // This does not really belong here, but there is no good place for this
    // code. I don't want to put this to the proc generation as the
    // ``IncludeStr`` call is quite slow.
    {@discard} lists.IncludeStr(m.headerFiles, '<cycle.h>');
  end;
  initname := getInitName(m.module);
  registerModuleToMain(m.module);
  prc := ropef('N_NOINLINE(void, $1)(void) {$n', [initname]);
  if m.typeNodes > 0 then 
    appf(m.s[cfsTypeInit1], 'static TNimNode $1[$2];$n', 
         [m.typeNodesName, toRope(m.typeNodes)]);  
  if m.nimTypes > 0 then 
    appf(m.s[cfsTypeInit1], 'static TNimType $1[$2];$n', 
         [m.nimTypesName, toRope(m.nimTypes)]);
  if optStackTrace in m.initProc.options then begin
    getFrameDecl(m.initProc);
    app(prc, m.initProc.s[cpsLocals]);
    app(prc, m.s[cfsTypeInit1]);
    appf(prc,
      'F.len = 0;$n' + // IMPORTANT: else the debugger crashes!
      'F.procname = $1;$n' +
      'F.prev = framePtr;$n' +
      'F.filename = $2;$n' +
      'F.line = 0;$n' +
      'framePtr = (TFrame*)&F;$n',
      [makeCString('module ' + m.module.name.s),
      makeCString(toFilename(m.module.info))])
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
    app(prc, 'framePtr = framePtr->prev;' + tnl);
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

function newModule(module: PSym; const filename: string): BModule;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  InitLinkedList(result.headerFiles);
  intSetInit(result.declaredThings);
  intSetInit(result.debugDeclared);
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
  result.typeNodesName := getTempName();
  result.nimTypesName := getTempName();
end;

function myOpen(module: PSym; const filename: string): PPassContext;
begin
  result := newModule(module, filename);
end;

function myOpenCached(module: PSym; const filename: string;
                      rd: PRodReader): PPassContext;
var
  cfile, cfilenoext, objFile: string;
begin
  //MessageOut('cgen.myOpenCached has been called ' + filename);
  cfile := changeFileExt(completeCFilePath(filename), cExt);
  cfilenoext := changeFileExt(cfile, '');
  (*
  objFile := toObjFile(cfilenoext);
  if ExistsFile(objFile) and nos.FileNewer(objFile, cfile) then begin
  end
  else begin
    addFileToCompile(cfilenoext); // is to compile
  end; *)
  addFileToLink(cfilenoext);
  registerModuleToMain(module);
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

function myClose(b: PPassContext; n: PNode): PNode;
var
  cfile, cfilenoext: string;
  m: BModule;
  code: PRope;
begin
  result := n;
  if b = nil then exit;
  m := BModule(b);
  if n <> nil then begin
    m.initProc.options := gOptions;
    genStmts(m.initProc, n);
  end;
  // generate code for the init statements of the module:
  genInitCode(m);
  finishTypeDescriptions(m);
  cfile := completeCFilePath(m.cfilename);
  cfilenoext := changeFileExt(cfile, '');
  if sfMainModule in m.module.flags then begin
    // generate main file:
    app(m.s[cfsProcHeaders], mainModProcs);
    genMainProc(m);
  end;
  code := genModule(m, cfilenoext);
  if shouldRecompile(code, changeFileExt(cfile, cExt), cfilenoext) then begin
    addFileToCompile(cfilenoext); // is to compile
  end;
  addFileToLink(cfilenoext);
  if sfMainModule in m.module.flags then writeMapping(cfile, gMapping);
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
end.
