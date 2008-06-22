//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit backends;

// This module only contains the PBackend type declaration/interface, each
// backend has to adhere to.

interface

{$include 'config.inc'}

uses
  nsystem, idents, ropes, msgs, ast;

type
  PBackend = ^TBackend;

  TBackendEvent = (eNone, eAfterModule);
  TEventMask = set of TBackendEvent;
  TBackend = object(NObject)
    eventMask: TEventMask;
    module: PSym;
    filename: string;
    backendCreator: function (oldBackend: PBackend; module: PSym;
                              const filename: string): PBackend;
    afterModuleEvent: procedure (b: PBackend; module: PNode);
      // triggered AFTER a whole module has been checked for semantics
  end;

function backendCreator(b: PBackend; module: PSym;
                        const filename: string): PBackend;
function newBackend(module: PSym; const filename: string): PBackend;

implementation

function newBackend(module: PSym; const filename: string): PBackend;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.backendCreator := backendCreator;
  result.module := module;
  result.filename := filename;
end;

function backendCreator(b: PBackend; module: PSym;
                        const filename: string): PBackend;
begin
  result := newBackend(module, filename);
end;

end.
