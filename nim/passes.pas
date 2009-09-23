//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit passes;

// This module implements the passes functionality. A pass must implement the
// `TPass` interface.

interface

{$include 'config.inc'}

uses
  nsystem, charsets, strutils,
  lists, options, ast, astalgo, llstream,
  msgs, platform, nos, condsyms, idents, rnimsyn, types,
  extccomp, nmath, magicsys, nversion, nimsets, pnimsyn, ntime, rodread;

type
  TPassContext = object(NObject) // the pass's context
  end;
  PPassContext = ^TPassContext;

  TPass = record {@tuple} // a pass is a tuple of procedure vars
    open: function (module: PSym; const filename: string): PPassContext;
    openCached: function (module: PSym; const filename: string;
                          rd: PRodReader): PPassContext;
    close: function (p: PPassContext; n: PNode): PNode;
    process: function (p: PPassContext; topLevelStmt: PNode): PNode;
  end;

// ``TPass.close`` may produce additional nodes. These are passed to the other
// close procedures. This mechanism is needed for the instantiation of
// generics.
 
procedure registerPass(const p: TPass);

procedure initPass(var p: TPass);

// This implements a memory preserving scheme: Top level statements are
// processed in a pipeline. The compiler never looks at a whole module
// any longer. However, this is simple to change, as new passes may perform
// whole program optimizations. For now, we avoid it to save a lot of memory.

procedure processModule(module: PSym; const filename: string;
                        stream: PLLStream; rd: PRodReader);


function astNeeded(s: PSym): bool;
  // The ``rodwrite`` module uses this to determine if the body of a proc
  // needs to be stored. The passes manager frees s.sons[codePos] when
  // appropriate to free the procedure body's memory. This is important
  // to keep memory usage down.

// the semantic checker needs these:
var
  gImportModule: function (const filename: string): PSym;
  gIncludeFile: function (const filename: string): PNode;
  gIncludeTmplFile: function (const filename: string): PNode;

implementation

function astNeeded(s: PSym): bool;
begin
  if (s.kind in [skMethod, skProc])
  and ([sfCompilerProc, sfCompileTime] * s.flags = [])
  and (s.typ.callConv <> ccInline)
  and (s.ast.sons[genericParamsPos] = nil) then
    result := false
  else
    result := true
end;

const
  maxPasses = 10;
  
type
  TPassContextArray = array [0..maxPasses-1] of PPassContext;
var
  gPasses: array [0..maxPasses-1] of TPass;
  gPassesLen: int;

procedure registerPass(const p: TPass);
begin
  gPasses[gPassesLen] := p;
  inc(gPassesLen);
end;

procedure openPasses(var a: TPassContextArray; module: PSym;
                     const filename: string);
var
  i: int;
begin
  for i := 0 to gPassesLen-1 do
    if assigned(gPasses[i].open) then
      a[i] := gPasses[i].open(module, filename)
    else
      a[i] := nil
end;

procedure openPassesCached(var a: TPassContextArray; module: PSym;
                           const filename: string; rd: PRodReader);
var
  i: int;
begin
  for i := 0 to gPassesLen-1 do
    if assigned(gPasses[i].openCached) then
      a[i] := gPasses[i].openCached(module, filename, rd)
    else
      a[i] := nil
end;

procedure closePasses(var a: TPassContextArray);
var
  i: int;
  m: PNode;
begin
  m := nil;
  for i := 0 to gPassesLen-1 do begin
    if assigned(gPasses[i].close) then m := gPasses[i].close(a[i], m);
    a[i] := nil; // free the memory here
  end
end;

procedure processTopLevelStmt(n: PNode; var a: TPassContextArray);
var
  i: int;
  m: PNode;
begin
  // this implements the code transformation pipeline
  m := n;
  for i := 0 to gPassesLen-1 do
    if assigned(gPasses[i].process) then m := gPasses[i].process(a[i], m);
end;

procedure processTopLevelStmtCached(n: PNode; var a: TPassContextArray);
var
  i: int;
  m: PNode;
begin
  // this implements the code transformation pipeline
  m := n;
  for i := 0 to gPassesLen-1 do
    if assigned(gPasses[i].openCached) then m := gPasses[i].process(a[i], m);
end;

procedure closePassesCached(var a: TPassContextArray);
var
  i: int;
  m: PNode;
begin
  m := nil;
  for i := 0 to gPassesLen-1 do begin
    if assigned(gPasses[i].openCached) and assigned(gPasses[i].close) then 
      m := gPasses[i].close(a[i], m);
    a[i] := nil; // free the memory here
  end
end;

procedure processModule(module: PSym; const filename: string;
                        stream: PLLStream; rd: PRodReader);
var
  p: TParser;
  n: PNode;
  a: TPassContextArray;
  s: PLLStream;
  i: int;
begin
  if rd = nil then begin
    openPasses(a, module, filename);
    if stream = nil then begin
      s := LLStreamOpen(filename, fmRead);
      if s = nil then begin
        rawMessage(errCannotOpenFile, filename);
        exit
      end;
    end
    else
      s := stream;
    while true do begin
      openParser(p, filename, s); 
      while true do begin
        n := parseTopLevelStmt(p);
        if n = nil then break;
        processTopLevelStmt(n, a)
      end;
      closeParser(p);
      if s.kind <> llsStdIn then break;
    end;
    closePasses(a);
    // id synchronization point for more consistent code generation:
    IDsynchronizationPoint(1000);
  end
  else begin
    openPassesCached(a, module, filename, rd);
    n := loadInitSection(rd);
    //MessageOut('init section' + renderTree(n));
    for i := 0 to sonsLen(n)-1 do processTopLevelStmtCached(n.sons[i], a);
    closePassesCached(a);
  end;
end;

procedure initPass(var p: TPass);
begin
  p.open := nil;
  p.openCached := nil;
  p.close := nil;
  p.process := nil;
end;

end.
