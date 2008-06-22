//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit lists;

// This unit implements a generic doubled linked list.

interface

{@ignore}
uses
  nsystem;
{@emit}

{$include 'config.inc'}

type
  PListEntry = ^TListEntry;
  TListEntry = object(nobject)
    prev, next: PListEntry;
  end;

  TStrEntry = object(TListEntry)
    data: string;
  end;
  PStrEntry = ^TStrEntry;

  TLinkedList = object
    head, tail: PListEntry;
    Counter: int;
  end;

  // for the "find" operation:
  TCompareProc = function (entry: PListEntry; closure: Pointer): Boolean;

procedure InitLinkedList(var list: TLinkedList);
procedure Append(var list: TLinkedList; entry: PListEntry);
procedure Prepend(var list: TLinkedList; entry: PListEntry);
procedure Remove(var list: TLinkedList; entry: PListEntry);
procedure InsertBefore(var list: TLinkedList; pos, entry: PListEntry);

function Find(const list: TLinkedList; fn: TCompareProc;
  closure: Pointer): PListEntry;

procedure AppendStr(var list: TLinkedList; const data: string);
function IncludeStr(var list: TLinkedList; const data: string): boolean;
procedure PrependStr(var list: TLinkedList; const data: string);

implementation

procedure InitLinkedList(var list: TLinkedList);
begin
  list.Counter := 0;
  list.head := nil;
  list.tail := nil;
end;

procedure Append(var list: TLinkedList; entry: PListEntry);
begin
  Inc(list.counter);
  entry.next := nil;
  entry.prev := list.tail;
  if list.tail <> nil then begin
    assert(list.tail.next = nil);
    list.tail.next := entry
  end;
  list.tail := entry;
  if list.head = nil then
    list.head := entry;
end;

function newStrEntry(const data: string): PStrEntry;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.data := data
end;

procedure AppendStr(var list: TLinkedList; const data: string);
begin
  append(list, newStrEntry(data));
end;

procedure PrependStr(var list: TLinkedList; const data: string);
begin
  prepend(list, newStrEntry(data));
end;

function IncludeStr(var list: TLinkedList; const data: string): boolean;
var
  it: PListEntry;
begin
  it := list.head;
  while it <> nil do begin
    if PStrEntry(it).data = data then begin
      result := true; exit // already in list
    end;
    it := it.next;
  end;
  AppendStr(list, data); // else: add to list
  result := false
end;

procedure InsertBefore(var list: TLinkedList; pos, entry: PListEntry);
begin
  assert(pos <> nil);
  if pos = list.head then
    prepend(list, entry)
  else begin
    Inc(list.counter);
    entry.next := pos;
    entry.prev := pos.prev;
    if pos.prev <> nil then
      pos.prev.next := entry;
    pos.prev := entry;
  end
end;

procedure Prepend(var list: TLinkedList; entry: PListEntry);
begin
  Inc(list.counter);
  entry.prev := nil;
  entry.next := list.head;
  if list.head <> nil then begin
    assert(list.head.prev = nil);
    list.head.prev := entry
  end;
  list.head := entry;
  if list.tail = nil then
    list.tail := entry
end;

procedure Remove(var list: TLinkedList; entry: PListEntry);
begin
  Dec(list.counter);
  if entry = list.tail then begin
    list.tail := entry.prev
  end;
  if entry = list.head then begin
    list.head := entry.next;
  end;
  if entry.next <> nil then
    entry.next.prev := entry.prev;
  if entry.prev <> nil then
    entry.prev.next := entry.next;
end;

function Find(const list: TLinkedList; fn: TCompareProc;
  closure: Pointer): PListEntry;
begin
  result := list.head;
  while result <> nil do begin
    if fn(result, closure) then exit;
    result := result.next
  end
end;

end.
