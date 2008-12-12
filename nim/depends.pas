//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit depends;

// This module implements a dependency file generator.

interface

{$include 'config.inc'}

uses
  nsystem, nos, options, ast, astalgo, msgs, ropes, idents, passes, importer;

function genDependPass(): TPass;
procedure generateDot(const project: string);

implementation

type
  TGen = object(TPassContext)
    module: PSym;
    filename: string;
  end;
  PGen = ^TGen;

var
  gDotGraph: PRope; // the generated DOT file; we need a global variable

procedure addDependencyAux(const importing, imported: string);
begin
  appf(gDotGraph, '$1 -> $2;$n', [toRope(importing),
                                  toRope(imported)]);
  //    s1 -> s2_4 [label="[0-9]"];
end;

function addDotDependency(c: PPassContext; n: PNode): PNode;
var
  i: int;
  g: PGen;
  imported: string;
begin
  result := n;
  if n = nil then exit;
  g := PGen(c);
  case n.kind of
    nkImportStmt: begin
      for i := 0 to sonsLen(n)-1 do begin
        imported := getFileTrunk(getModuleFile(n.sons[i]));
        addDependencyAux(g.module.name.s, imported);
      end
    end;
    nkFromStmt: begin
      imported := getFileTrunk(getModuleFile(n.sons[0]));
      addDependencyAux(g.module.name.s, imported);
    end;
    nkStmtList, nkBlockStmt, nkStmtListExpr, nkBlockExpr: begin
      for i := 0 to sonsLen(n)-1 do {@discard} addDotDependency(c, n.sons[i]);
    end
    else begin end
  end
end;

procedure generateDot(const project: string);
begin
  writeRope(
    ropef('digraph $1 {$n$2}$n', [
      toRope(changeFileExt(extractFileName(project), '')), gDotGraph]),
    changeFileExt(project, 'dot') );
end;

function myOpen(module: PSym; const filename: string): PPassContext;
var
  g: PGen;
begin
  new(g);
{@ignore}
  fillChar(g^, sizeof(g^), 0);
{@emit}
  g.module := module;
  g.filename := filename;
  result := g;
end;

function gendependPass(): TPass;
begin
  initPass(result);
  result.open := myOpen;
  result.process := addDotDependency;
end;

end.
