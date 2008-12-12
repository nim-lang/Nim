//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit passaux;

// implements some little helper passes
{$include 'config.inc'}

interface

uses
  nsystem, strutils, ast, passes, msgs, options;

function verbosePass: TPass;
function cleanupPass: TPass;

implementation

function verboseOpen(s: PSym; const filename: string): PPassContext;
begin
  //MessageOut('compiling ' + s.name.s);
  result := nil; // we don't need a context
  if gVerbosity > 0 then 
    rawMessage(hintProcessing, s.name.s);
end;

function verboseProcess(context: PPassContext; n: PNode): PNode;
begin
  result := n;
  if context <> nil then InternalError('logpass: context is not nil');
  if gVerbosity = 3 then
    liMessage(n.info, hintProcessing, toString(ast.gid));
end;

function verbosePass: TPass;
begin
  initPass(result);
  result.open := verboseOpen;
  result.process := verboseProcess;
end;

function cleanUp(c: PPassContext; n: PNode): PNode;
var
  i: int;
  s: PSym;
begin
  result := n;
  case n.kind of
    nkStmtList: begin
      for i := 0 to sonsLen(n)-1 do {@discard} cleanup(c, n.sons[i]);
    end;
    nkProcDef: begin
      if (n.sons[namePos].kind = nkSym) then begin
        s := n.sons[namePos].sym;
        if not astNeeded(s) then s.ast.sons[codePos] := nil; // free the memory
      end
    end
    else begin end;
  end
end;

function cleanupPass: TPass;
begin
  initPass(result);
  result.process := cleanUp;
  result.close := cleanUp;
end;

end.
