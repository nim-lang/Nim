//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit ecmasgen;

// This is the EMCAScript (also known as JavaScript) code generator.
// **Invariant: each expression only occurs once in the generated
// code!**

interface

{$include 'config.inc'}

uses
  nsystem, ast, astalgo, strutils, nhashes, trees, platform, magicsys,
  extccomp, options, nversion, nimsets, msgs, crc, bitsets, idents,
  lists, types, nos, ntime, ropes, nmath, passes, ccgutils, wordrecg, rnimsyn,
  rodread;

function ecmasgenPass(): TPass;

implementation

type
  TEcmasGen = object(TPassContext)
    filename: string;
    module: PSym;
  end;
  BModule = ^TEcmasGen;

  TEcmasTypeKind = (
    etyNone,         // no type
    etyNull,         // null type
    etyProc,         // proc type
    etyBool,         // bool type
    etyInt,          // Ecmascript's int
    etyFloat,        // Ecmascript's float
    etyString,       // Ecmascript's string
    etyObject,       // Ecmascript's reference to an object
    etyBaseIndex     // base + index needed
  );

  TCompRes = record
    kind: TEcmasTypeKind;
    com: PRope; // computation part
                // address if this is a (address, index)-tuple
    res: PRope; // result part; index if this is a (address, index)-tuple
  end;

  TBlock = record
    id: int;  // the ID of the label; positive means that it
              // has been used (i.e. the label should be emitted)
    nestedTryStmts: int; // how many try statements is it nested into
  end;

  TGlobals = record
    typeInfo, code: PRope;
    typeInfoGenerated: TIntSet;
  end;
  PGlobals = ^TGlobals;

  TProc = record
    procDef: PNode;
    prc: PSym;
    data: PRope;
    options: TOptions;
    module: BModule;
    globals: PGlobals;
    BeforeRetNeeded: bool;
    nestedTryStmts: int;
    unique: int;
    blocks: array of TBlock;
  end;

function newGlobals(): PGlobals;
begin
  new(result);
{@ignore} fillChar(result^, sizeof(result^), 0); {@emit}
  IntSetInit(result.typeInfoGenerated);
end;

procedure initCompRes(var r: TCompRes);
begin
  r.com := nil; r.res := nil; r.kind := etyNone;
end;

procedure initProc(var p: TProc; globals: PGlobals; module: BModule;
                   procDef: PNode; options: TOptions);
begin
{@ignore}
  fillChar(p, sizeof(p), 0);
{@emit
  p.blocks := @[];}
  p.options := options;
  p.module := module;
  p.procDef := procDef;
  p.globals := globals;
  if procDef <> nil then p.prc := procDef.sons[namePos].sym;
end;

const
  MappedToObject = {@set}[tyObject, tyArray, tyArrayConstr, tyTuple,
                          tyOpenArray, tySet, tyVar, tyRef, tyPtr];

function mapType(typ: PType): TEcmasTypeKind;
begin
  case skipGeneric(typ).kind of
    tyVar, tyRef, tyPtr: begin
      if typ.sons[0].kind in mappedToObject then
        result := etyObject
      else
        result := etyBaseIndex
    end;
    tyPointer: begin
      // treat a tyPointer like a typed pointer to an array of bytes
      result := etyInt;
    end;
    tyRange: result := mapType(typ.sons[0]);
    tyInt..tyInt64, tyEnum, tyAnyEnum, tyChar:
      result := etyInt;
    tyBool: result := etyBool;
    tyFloat..tyFloat128: result := etyFloat;
    tySet: begin
      result := etyObject // map a set to a table
    end;
    tyString, tySequence:
      result := etyInt; // little hack to get the right semantics
    tyObject, tyArray, tyArrayConstr, tyTuple, tyOpenArray:
      result := etyObject;
    tyNil: result := etyNull;
    tyGenericInst, tyGenericParam, tyGeneric, tyNone, tyForward, tyEmpty:
      result := etyNone;
    tyProc: result := etyProc;
    tyCString: result := etyString;
  end
end;

function mangle(const name: string): string;
var
  i: int;
begin
  result := '';
  for i := strStart to length(name) + strStart-1 do begin
    case name[i] of
      'A'..'Z': addChar(result, chr(ord(name[i]) - ord('A') + ord('a')));
      '_': begin end;
      'a'..'z', '0'..'9': addChar(result, name[i]);
      else result := result +{&} 'X' +{&} toHex(ord(name[i]), 2);
    end
  end
end;

function mangleName(s: PSym): PRope;
begin
  result := s.loc.r;
  if result = nil then begin
    result := toRope(mangle(s.name.s));
    app(result, '_'+'');
    app(result, toRope(s.id));
    s.loc.r := result;
  end
end;

// ----------------------- type information ----------------------------------

function genTypeInfo(var p: TProc; typ: PType): PRope; forward;

function genObjectFields(var p: TProc; typ: PType; n: PNode): PRope;
var
  s, u: PRope;
  len, i, j: int;
  field: PSym;
  b: PNode;
begin
  result := nil;
  case n.kind of
    nkRecList: begin
      len := sonsLen(n);
      if len = 1 then  // generates more compact code!
        result := genObjectFields(p, typ, n.sons[0])
      else begin
        s := nil;
        for i := 0 to len-1 do begin
          if i > 0 then app(s, ', ' + tnl);
          app(s, genObjectFields(p, typ, n.sons[i]));
        end;
        result := ropef('{kind: 2, len: $1, offset: 0, ' +
                        'typ: null, name: null, sons: [$2]}', [toRope(len), s]);
      end
    end;
    nkSym: begin
      field := n.sym;
      s := genTypeInfo(p, field.typ);
      result := ropef('{kind: 1, offset: "$1", len: 0, ' +
                      'typ: $2, name: $3, sons: null}', [
                      mangleName(field), s, makeCString(field.name.s)]);
    end;
    nkRecCase: begin
      len := sonsLen(n);
      if (n.sons[0].kind <> nkSym) then
        InternalError(n.info, 'genObjectFields');
      field := n.sons[0].sym;
      s := genTypeInfo(p, field.typ);
      for i := 1 to len-1 do begin
        b := n.sons[i]; // branch
        u := nil;
        case b.kind of
          nkOfBranch: begin
            if sonsLen(b) < 2 then
              internalError(b.info, 'genObjectFields; nkOfBranch broken');
            for j := 0 to sonsLen(b)-2 do begin
              if u <> nil then app(u, ', ');
              if b.sons[j].kind = nkRange then begin
                appf(u, '[$1, $2]', [toRope(getOrdValue(b.sons[j].sons[0])),
                                     toRope(getOrdValue(b.sons[j].sons[1]))]);
              end
              else
                app(u, toRope(getOrdValue(b.sons[j])))
            end
          end;
          nkElse: u := toRope(lengthOrd(field.typ));
          else internalError(n.info, 'genObjectFields(nkRecCase)');
        end;
        if result <> nil then app(result, ', ' + tnl);
        appf(result, '[SetConstr($1), $2]',
             [u, genObjectFields(p, typ, lastSon(b))]);
      end;
      result := ropef('{kind: 3, offset: "$1", len: $3, ' +
                      'typ: $2, name: $4, sons: [$5]}', [mangleName(field), s,
                      toRope(lengthOrd(field.typ)),
                      makeCString(field.name.s),
                      result]);
    end;
    else internalError(n.info, 'genObjectFields');
  end
end;

procedure genObjectInfo(var p: TProc; typ: PType; name: PRope);
var
  s: PRope;
begin
  s := ropef('var $1 = {size: 0, kind: $2, base: null, node: null, ' +
             'finalizer: null};$n', [name, toRope(ord(typ.kind))]);
  prepend(p.globals.typeInfo, s);

  appf(p.globals.typeInfo, 'var NNI$1 = $2;$n',
      [toRope(typ.id), genObjectFields(p, typ, typ.n)]);
  appf(p.globals.typeInfo, '$1.node = NNI$2;$n', [name, toRope(typ.id)]);
  if (typ.kind = tyObject) and (typ.sons[0] <> nil) then begin
    appf(p.globals.typeInfo, '$1.base = $2;$n',
        [name, genTypeInfo(p, typ.sons[0])]);
  end
end;

procedure genEnumInfo(var p: TProc; typ: PType; name: PRope);
var
  s, n: PRope;
  len, i: int;
  field: PSym;
begin
  len := sonsLen(typ.n);
  s := nil;
  for i := 0 to len-1 do begin
    if (typ.n.sons[i].kind <> nkSym) then
      InternalError(typ.n.info, 'genEnumInfo');
    field := typ.n.sons[i].sym;
    if i > 0 then app(s, ', '+tnl);
    appf(s, '{kind: 1, offset: $1, typ: $2, name: $3, len: 0, sons: null}',
            [toRope(field.position), name, makeCString(field.name.s)]);
  end;
  n := ropef('var NNI$1 = {kind: 2, offset: 0, typ: null, ' +
             'name: null, len: $2, sons: [$3]};$n',
             [toRope(typ.id), toRope(len), s]);

  s := ropef('var $1 = {size: 0, kind: $2, base: null, node: null, ' +
             'finalizer: null};$n', [name, toRope(ord(typ.kind))]);
  prepend(p.globals.typeInfo, s);

  app(p.globals.typeInfo, n);
  appf(p.globals.typeInfo, '$1.node = NNI$2;$n', [name, toRope(typ.id)]);
  if typ.sons[0] <> nil then begin
    appf(p.globals.typeInfo, '$1.base = $2;$n',
        [name, genTypeInfo(p, typ.sons[0])]);
  end;
end;

function genTypeInfo(var p: TProc; typ: PType): PRope;
var
  t: PType;
  s: PRope;
begin
  t := typ;
  if t.kind = tyGenericInst then t := lastSon(t);
  result := ropef('NTI$1', [toRope(t.id)]);
  if IntSetContainsOrIncl(p.globals.TypeInfoGenerated, t.id) then exit;
  case t.kind of
    tyPointer, tyProc, tyBool, tyChar, tyCString, tyString,
    tyInt..tyFloat128: begin
      s := ropef(
        'var $1 = {size: 0, kind: $2, base: null, node: null, finalizer: null};$n',
        [result, toRope(ord(t.kind))]);
      prepend(p.globals.typeInfo, s);
    end;
    tyVar, tyRef, tyPtr, tySequence, tyRange, tySet: begin
      s := ropef(
        'var $1 = {size: 0, kind: $2, base: null, node: null, finalizer: null};$n',
        [result, toRope(ord(t.kind))]);
      prepend(p.globals.typeInfo, s);
      appf(p.globals.typeInfo, '$1.base = $2;$n',
          [result, genTypeInfo(p, typ.sons[0])]);
    end;
    tyArrayConstr, tyArray: begin
      s := ropef(
        'var $1 = {size: 0, kind: $2, base: null, node: null, finalizer: null};$n',
        [result, toRope(ord(t.kind))]);
      prepend(p.globals.typeInfo, s);
      appf(p.globals.typeInfo, '$1.base = $2;$n',
          [result, genTypeInfo(p, typ.sons[1])]);
    end;
    tyEnum: genEnumInfo(p, t, result);
    tyObject, tyTuple: genObjectInfo(p, t, result);
    else InternalError('genTypeInfo(' + typekindToStr[t.kind] + ')');
  end
end;

// ---------------------------------------------------------------------------

procedure gen(var p: TProc; n: PNode; var r: TCompRes); forward;
procedure genStmt(var p: TProc; n: PNode; var r: TCompRes); forward;

procedure useMagic(var p: TProc; const ident: string);
begin
  // to implement
end;

function mergeExpr(a, b: PRope): PRope; overload;
begin
  if (a <> nil) then begin
    if b <> nil then result := ropef('($1, $2)', [a, b])
    else result := a
  end
  else result := b
end;

function mergeExpr(const r: TCompRes): PRope; overload;
begin
  result := mergeExpr(r.com, r.res);
end;

function mergeStmt(const r: TCompRes): PRope;
begin
  if r.res = nil then result := r.com
  else if r.com = nil then result := r.res
  else result := ropef('$1$2', [r.com, r.res])
end;

procedure genAnd(var p: TProc; a, b: PNode; var r: TCompRes);
var
  x, y: TCompRes;
begin
  gen(p, a, x);
  gen(p, b, y);
  r.res := ropef('($1 && $2)', [mergeExpr(x), mergeExpr(y)])
end;

procedure genOr(var p: TProc; a, b: PNode; var r: TCompRes);
var
  x, y: TCompRes;
begin
  gen(p, a, x);
  gen(p, b, y);
  r.res := ropef('($1 || $2)', [mergeExpr(x), mergeExpr(y)])
end;

type
  TMagicFrmt = array [0..3] of string;

const
  // magic checked op; magic unchecked op; checked op; unchecked op
  ops: array [mAddi..mStrToStr] of TMagicFrmt = (
    ('addInt', '',   'addInt($1, $2)',    '($1 + $2)'), // AddI
    ('subInt', '',   'subInt($1, $2)',    '($1 - $2)'), // SubI
    ('mulInt', '',   'mulInt($1, $2)',    '($1 * $2)'), // MulI
    ('divInt', '',   'divInt($1, $2)',    'Math.floor($1 / $2)'), // DivI
    ('modInt', '',   'modInt($1, $2)',    'Math.floor($1 % $2)'), // ModI
    ('addInt64', '',   'addInt64($1, $2)',  '($1 + $2)'), // AddI64
    ('subInt64', '',   'subInt64($1, $2)',  '($1 - $2)'), // SubI64
    ('mulInt64', '',   'mulInt64($1, $2)',  '($1 * $2)'), // MulI64
    ('divInt64', '',   'divInt64($1, $2)',  'Math.floor($1 / $2)'), // DivI64
    ('modInt64', '',   'modInt64($1, $2)',  'Math.floor($1 % $2)'), // ModI64
    ('',   '',   '($1 >>> $2)',       '($1 >>> $2)'), // ShrI
    ('',   '',   '($1 << $2)',        '($1 << $2)'), // ShlI
    ('',   '',   '($1 & $2)',         '($1 & $2)'), // BitandI
    ('',   '',   '($1 | $2)',         '($1 | $2)'), // BitorI
    ('',   '',   '($1 ^ $2)',         '($1 ^ $2)'), // BitxorI
    ('nimMin', 'nimMin', 'nimMin($1, $2)',    'nimMin($1, $2)'), // MinI
    ('nimMax', 'nimMax', 'nimMax($1, $2)',    'nimMax($1, $2)'), // MaxI
    ('',   '',   '($1 >>> $2)',       '($1 >>> $2)'), // ShrI64
    ('',   '',   '($1 << $2)',        '($1 << $2)'), // ShlI64
    ('',   '',   '($1 & $2)',         '($1 & $2)'), // BitandI64
    ('',   '',   '($1 | $2)',         '($1 | $2)'), // BitorI64
    ('',   '',   '($1 ^ $2)',         '($1 ^ $2)'), // BitxorI64
    ('nimMin', 'nimMin', 'nimMin($1, $2)',    'nimMin($1, $2)'), // MinI64
    ('nimMax', 'nimMax', 'nimMax($1, $2)',    'nimMax($1, $2)'), // MaxI64
    ('',   '',   '($1 + $2)',         '($1 + $2)'), // AddF64
    ('',   '',   '($1 - $2)',         '($1 - $2)'), // SubF64
    ('',   '',   '($1 * $2)',         '($1 * $2)'), // MulF64
    ('',   '',   '($1 / $2)',         '($1 / $2)'), // DivF64
    ('nimMin', 'nimMin', 'nimMin($1, $2)',    'nimMin($1, $2)'), // MinF64
    ('nimMax', 'nimMax', 'nimMax($1, $2)',    'nimMax($1, $2)'), // MaxF64
    ('AddU', 'AddU', 'AddU($1, $2)',      'AddU($1, $2)'), // AddU
    ('SubU', 'SubU', 'SubU($1, $2)',      'SubU($1, $2)'), // SubU
    ('MulU', 'MulU', 'MulU($1, $2)',      'MulU($1, $2)'), // MulU
    ('DivU', 'DivU', 'DivU($1, $2)',      'DivU($1, $2)'), // DivU
    ('ModU', 'ModU', 'ModU($1, $2)',      'ModU($1, $2)'), // ModU
    ('AddU64', 'AddU64', 'AddU64($1, $2)',    'AddU64($1, $2)'), // AddU64
    ('SubU64', 'SubU64', 'SubU64($1, $2)',    'SubU64($1, $2)'), // SubU64
    ('MulU64', 'MulU64', 'MulU64($1, $2)',    'MulU64($1, $2)'), // MulU64
    ('DivU64', 'DivU64', 'DivU64($1, $2)',    'DivU64($1, $2)'), // DivU64
    ('ModU64', 'ModU64', 'ModU64($1, $2)',    'ModU64($1, $2)'), // ModU64
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqI
    ('',   '',   '($1 <= $2)',        '($1 <= $2)'), // LeI
    ('',   '',   '($1 < $2)',         '($1 < $2)'), // LtI
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqI64
    ('',   '',   '($1 <= $2)',        '($1 <= $2)'), // LeI64
    ('',   '',   '($1 < $2)',         '($1 < $2)'), // LtI64
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqF64
    ('',   '',   '($1 <= $2)',        '($1 <= $2)'), // LeF64
    ('',   '',   '($1 < $2)',         '($1 < $2)'), // LtF64
    ('LeU', 'LeU', 'LeU($1, $2)',       'LeU($1, $2)'), // LeU
    ('LtU', 'LtU', 'LtU($1, $2)',       'LtU($1, $2)'), // LtU
    ('LeU64', 'LeU64', 'LeU64($1, $2)',     'LeU64($1, $2)'), // LeU64
    ('LtU64', 'LtU64', 'LtU64($1, $2)',     'LtU64($1, $2)'), // LtU64
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqEnum
    ('',   '',   '($1 <= $2)',        '($1 <= $2)'), // LeEnum
    ('',   '',   '($1 < $2)',         '($1 < $2)'), // LtEnum
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqCh
    ('',   '',   '($1 <= $2)',        '($1 <= $2)'), // LeCh
    ('',   '',   '($1 < $2)',         '($1 < $2)'), // LtCh
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqB
    ('',   '',   '($1 <= $2)',        '($1 <= $2)'), // LeB
    ('',   '',   '($1 < $2)',         '($1 < $2)'), // LtB
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqRef
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqProc
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqUntracedRef
    ('',   '',   '($1 <= $2)',        '($1 <= $2)'), // LePtr
    ('',   '',   '($1 < $2)',         '($1 < $2)'), // LtPtr
    ('',   '',   '($1 == $2)',        '($1 == $2)'), // EqCString
    ('',   '',   '($1 != $2)',        '($1 != $2)'), // Xor
    ('NegInt', '',   'NegInt($1)',        '-($1)'), // UnaryMinusI
    ('NegInt64', '',   'NegInt64($1)',      '-($1)'), // UnaryMinusI64
    ('AbsInt', '',   'AbsInt($1)',        'Math.abs($1)'), // AbsI
    ('AbsInt64', '', 'AbsInt64($1)',      'Math.abs($1)'), // AbsI64
    ('',   '',   '!($1)',             '!($1)'), // Not
    ('',   '',   '+($1)',             '+($1)'), // UnaryPlusI
    ('',   '',   '~($1)',             '~($1)'), // BitnotI
    ('',   '',   '+($1)',             '+($1)'), // UnaryPlusI64
    ('',   '',   '~($1)',             '~($1)'), // BitnotI64
    ('',   '',   '+($1)',             '+($1)'), // UnaryPlusF64
    ('',   '',   '-($1)',             '-($1)'), // UnaryMinusF64
    ('',   '',   'Math.abs($1)',      'Math.abs($1)'), // AbsF64

    ('Ze8ToI', 'Ze8ToI', 'Ze8ToI($1)', 'Ze8ToI($1)'),  // mZe8ToI
    ('Ze8ToI64', 'Ze8ToI64', 'Ze8ToI64($1)', 'Ze8ToI64($1)'),  // mZe8ToI64
    ('Ze16ToI', 'Ze16ToI', 'Ze16ToI($1)', 'Ze16ToI($1)'),  // mZe16ToI
    ('Ze16ToI64', 'Ze16ToI64', 'Ze16ToI64($1)', 'Ze16ToI64($1)'),  // mZe16ToI64
    ('Ze32ToI64', 'Ze32ToI64', 'Ze32ToI64($1)', 'Ze32ToI64($1)'),  // mZe32ToI64
    ('ZeIToI64', 'ZeIToI64', 'ZeIToI64($1)', 'ZeIToI64($1)'),  // mZeIToI64

    ('ToU8', 'ToU8', 'ToU8($1)',          'ToU8($1)'), // ToU8
    ('ToU16', 'ToU16', 'ToU16($1)',         'ToU16($1)'), // ToU16
    ('ToU32', 'ToU32', 'ToU32($1)',         'ToU32($1)'), // ToU32
    ('',   '',   '$1',                '$1'), // ToFloat
    ('',   '',   '$1',                '$1'), // ToBiggestFloat
    ('',   '',   'Math.floor($1)',    'Math.floor($1)'), // ToInt
    ('',   '',   'Math.floor($1)',    'Math.floor($1)'), // ToBiggestInt

    ('nimCharToStr', 'nimCharToStr', 'nimCharToStr($1)', 'nimCharToStr($1)'),
    ('nimBoolToStr', 'nimBoolToStr', 'nimBoolToStr($1)', 'nimBoolToStr($1)'),
    ('cstrToNimStr', 'cstrToNimStr', 'cstrToNimStr(($1)+"")', 'cstrToNimStr(($1)+"")'),
    ('cstrToNimStr', 'cstrToNimStr', 'cstrToNimStr(($1)+"")', 'cstrToNimStr(($1)+"")'),
    ('cstrToNimStr', 'cstrToNimStr', 'cstrToNimStr(($1)+"")', 'cstrToNimStr(($1)+"")'),
    ('cstrToNimStr', 'cstrToNimStr', 'cstrToNimStr($1)', 'cstrToNimStr($1)'),
    ('', '', '$1', '$1')
  );

procedure binaryExpr(var p: TProc; n: PNode; var r: TCompRes;
                     const magic, frmt: string);
var
  x, y: TCompRes;
begin
  if magic <> '' then useMagic(p, magic);
  gen(p, n.sons[1], x);
  gen(p, n.sons[2], y);
  r.res := ropef(frmt, [x.res, y.res]);
  r.com := mergeExpr(x.com, y.com);
end;

procedure binaryStmt(var p: TProc; n: PNode; var r: TCompRes;
                     const magic, frmt: string);
var
  x, y: TCompRes;
begin
  if magic <> '' then useMagic(p, magic);
  gen(p, n.sons[1], x);
  gen(p, n.sons[2], y);
  if x.com <> nil then appf(r.com, '$1;$n', [x.com]);
  if y.com <> nil then appf(r.com, '$1;$n', [y.com]);
  appf(r.com, frmt, [x.res, y.res]);
end;

procedure unaryExpr(var p: TProc; n: PNode; var r: TCompRes;
                    const magic, frmt: string);
begin
  if magic <> '' then useMagic(p, magic);
  gen(p, n.sons[1], r);
  r.res := ropef(frmt, [r.res]);
end;

procedure arith(var p: TProc; n: PNode; var r: TCompRes; op: TMagic);
var
  x, y: TCompRes;
  i: int;
begin
  if optOverflowCheck in p.options then i := 0 else i := 1;
  useMagic(p, ops[op][i]);
  if sonsLen(n) > 2 then begin
    gen(p, n.sons[1], x);
    gen(p, n.sons[2], y);
    r.res := ropef(ops[op][i+2], [x.res, y.res]);
    r.com := mergeExpr(x.com, y.com);
  end
  else begin
    gen(p, n.sons[1], r);
    r.res := ropef(ops[op][i+2], [r.res])
  end
end;

procedure genLineDir(var p: TProc; n: PNode; var r: TCompRes);
var
  line: int;
begin
  line := toLinenumber(n.info);
  if optLineDir in p.Options then // pretty useless, but better than nothing
    appf(r.com, '// line $2 "$1"$n',
      [toRope(toFilename(n.info)), toRope(line)]);
  if ([optStackTrace, optEndb] * p.Options = [optStackTrace, optEndb]) and
      ((p.prc = nil) or not (sfPure in p.prc.flags)) then begin
    useMagic(p, 'endb');
    appf(r.com, 'endb($1);$n', [toRope(line)])
  end
  else if ([optLineTrace, optStackTrace] * p.Options =
        [optLineTrace, optStackTrace]) and ((p.prc = nil) or
      not (sfPure in p.prc.flags)) then
    appf(r.com, 'F.line = $1;$n', [toRope(line)])
end;

procedure finishTryStmt(var p: TProc; var r: TCompRes; howMany: int);
var
  i: int;
begin
  for i := 1 to howMany do
    app(r.com, 'excHandler = excHandler.prev;' + tnl);
end;

procedure genWhileStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  cond, stmt: TCompRes;
  len, labl: int;
begin
  genLineDir(p, n, r);
  inc(p.unique);
  len := length(p.blocks);
  setLength(p.blocks, len+1);
  p.blocks[len].id := -p.unique;
  p.blocks[len].nestedTryStmts := p.nestedTryStmts;
  labl := p.unique;
  gen(p, n.sons[0], cond);
  genStmt(p, n.sons[1], stmt);
  if p.blocks[len].id > 0 then
    appf(r.com, 'L$3: while ($1) {$n$2}$n',
      [mergeExpr(cond), mergeStmt(stmt), toRope(labl)])
  else
    appf(r.com, 'while ($1) {$n$2}$n',
      [mergeExpr(cond), mergeStmt(stmt)]);
  setLength(p.blocks, len);
end;

procedure genTryStmt(var p: TProc; n: PNode; var r: TCompRes);
  // code to generate:
(*
  var sp = {prev: excHandler, exc: null};
  excHandler = sp;
  try {
    stmts;
  } catch (e) {
    if (e.typ && e.typ == NTI433 || e.typ == NTI2321) {
      stmts;
    } else if (e.typ && e.typ == NTI32342) {
      stmts;
    } else {
      stmts;
    }
  } finally {
    stmts;
    excHandler = excHandler.prev;
  }
*)
var
  i, j, len, blen: int;
  safePoint, orExpr, epart: PRope;
  a: TCompRes;
begin
  genLineDir(p, n, r);
  inc(p.unique);
  safePoint := ropef('Tmp$1', [toRope(p.unique)]);
  appf(r.com, 'var $1 = {prev: excHandler, exc: null};$n' +
              'excHandler = $1;$n', [safePoint]);
  if optStackTrace in p.Options then
    app(r.com, 'framePtr = F;' + tnl);
  app(r.com, 'try {' + tnl);
  len := sonsLen(n);
  inc(p.nestedTryStmts);
  genStmt(p, n.sons[0], a);
  app(r.com, mergeStmt(a));
  i := 1;
  epart := nil;
  while (i < len) and (n.sons[i].kind = nkExceptBranch) do begin
    blen := sonsLen(n.sons[i]);
    if blen = 1 then begin
      // general except section:
      if i > 1 then app(epart, 'else {' + tnl);
      genStmt(p, n.sons[i].sons[0], a);
      app(epart, mergeStmt(a));
      if i > 1 then app(epart, '}' + tnl);
    end
    else begin
      orExpr := nil;
      for j := 0 to blen-2 do begin
        if (n.sons[i].sons[j].kind <> nkType) then
          InternalError(n.info, 'genTryStmt');
        if orExpr <> nil then app(orExpr, '||');
        appf(orExpr, '($1.exc.m_type == $2)',
          [safePoint, genTypeInfo(p, n.sons[i].sons[j].typ)])
      end;
      if i > 1 then app(epart, 'else ');
      appf(epart, 'if ($1.exc && $2) {$n', [safePoint, orExpr]);
      genStmt(p, n.sons[i].sons[blen - 1], a);
      appf(epart, '$1}$n', [mergeStmt(a)]);
    end;
    inc(i)
  end;
  if epart <> nil then
    appf(r.com, '} catch (EXC) {$n$1', [epart]);
  finishTryStmt(p, r, p.nestedTryStmts);
  dec(p.nestedTryStmts);
  app(r.com, '} finally {' + tnl + 'excHandler = excHandler.prev;' +{&} tnl);
  if (i < len) and (n.sons[i].kind = nkFinally) then begin
    genStmt(p, n.sons[i].sons[0], a);
    app(r.com, mergeStmt(a));
  end;
  app(r.com, '}' + tnl);
end;

procedure genRaiseStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
  typ: PType;
begin
  genLineDir(p, n, r);
  if n.sons[0] <> nil then begin
    gen(p, n.sons[0], a);
    if a.com <> nil then appf(r.com, '$1;$n', [a.com]);
    typ := skipPtrsGeneric(n.sons[0].typ);
    useMagic(p, 'raiseException');
    appf(r.com, 'raiseException($1, $2);$n',
      [a.res, makeCString(typ.sym.name.s)]);
  end
  else begin
    useMagic(p, 'reraiseException');
    app(r.com, 'reraiseException();' + tnl);
  end
end;

procedure genCaseStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  cond, stmt: TCompRes;
  i, j: int;
  it, e, v: PNode;
  stringSwitch: bool;
begin
  genLineDir(p, n, r);
  gen(p, n.sons[0], cond);
  if cond.com <> nil then
    appf(r.com, '$1;$n', [cond.com]);
  stringSwitch := skipVarGeneric(n.sons[0].typ).kind = tyString;
  if stringSwitch then begin
    useMagic(p, 'toEcmaStr');
    appf(r.com, 'switch (toEcmaStr($1)) {$n', [cond.res])
  end
  else
    appf(r.com, 'switch ($1) {$n', [cond.res]);
  for i := 1 to sonsLen(n)-1 do begin
    it := n.sons[i];
    case it.kind of
      nkOfBranch: begin
        for j := 0 to sonsLen(it)-2 do begin
          e := it.sons[j];
          if e.kind = nkRange then begin
            v := copyNode(e.sons[0]);
            while (v.intVal <= e.sons[1].intVal) do begin
              gen(p, v, cond);
              if cond.com <> nil then
                internalError(v.info, 'ecmasgen.genCaseStmt');
              appf(r.com, 'case $1: ', [cond.res]);
              Inc(v.intVal)
            end
          end
          else begin
            gen(p, e, cond);
            if cond.com <> nil then
              internalError(e.info, 'ecmasgen.genCaseStmt');
            if stringSwitch then begin
              case e.kind of
                nkStrLit..nkTripleStrLit:
                  appf(r.com, 'case $1: ', [makeCString(e.strVal)]);
                else InternalError(e.info, 'ecmasgen.genCaseStmt: 2');
              end
            end
            else
              appf(r.com, 'case $1: ', [cond.res]);
          end
        end;
        genStmt(p, lastSon(it), stmt);
        appf(r.com, '$n$1break;$n', [mergeStmt(stmt)]);
      end;
      nkElse: begin
        genStmt(p, it.sons[0], stmt);
        appf(r.com, 'default: $n$1break;$n', [mergeStmt(stmt)]);
      end
      else internalError(it.info, 'ecmasgen.genCaseStmt')
    end
  end;
  appf(r.com, '}$n', []);
end;

procedure genStmtListExpr(var p: TProc; n: PNode; var r: TCompRes); forward;

procedure genBlock(var p: TProc; n: PNode; var r: TCompRes);
var
  idx, labl: int;
  sym: PSym;
begin
  inc(p.unique);
  idx := length(p.blocks);
  if n.sons[0] <> nil then begin // named block?
    if (n.sons[0].kind <> nkSym) then InternalError(n.info, 'genBlock');
    sym := n.sons[0].sym;
    sym.loc.k := locOther;
    sym.loc.a := idx
  end;
  setLength(p.blocks, idx+1);
  p.blocks[idx].id := -p.unique; // negative because it isn't used yet
  p.blocks[idx].nestedTryStmts := p.nestedTryStmts;
  labl := p.unique;
  if n.kind = nkBlockExpr then genStmtListExpr(p, n.sons[1], r)
  else genStmt(p, n.sons[1], r);
  if p.blocks[idx].id > 0 then begin // label has been used:
    r.com := ropef('L$1: do {$n$2} while(false);$n',
                   [toRope(labl), r.com]);
  end;
  setLength(p.blocks, idx)
end;

procedure genBreakStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  idx: int;
  sym: PSym;
begin
  genLineDir(p, n, r);
  idx := length(p.blocks)-1;
  if n.sons[0] <> nil then begin // named break?
    assert(n.sons[0].kind = nkSym);
    sym := n.sons[0].sym;
    assert(sym.loc.k = locOther);
    idx := sym.loc.a
  end;
  p.blocks[idx].id := abs(p.blocks[idx].id); // label is used
  finishTryStmt(p, r, p.nestedTryStmts - p.blocks[idx].nestedTryStmts);
  appf(r.com, 'break L$1;$n', [toRope(p.blocks[idx].id)])
end;

procedure genAsmStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  i: int;
begin
  genLineDir(p, n, r);
  assert(n.kind = nkAsmStmt);
  for i := 0 to sonsLen(n)-1 do begin
    case n.sons[i].Kind of
      nkStrLit..nkTripleStrLit: app(r.com, n.sons[i].strVal);
      nkSym: app(r.com, mangleName(n.sons[i].sym));
      else InternalError(n.sons[i].info, 'ecmasgen: genAsmStmt()')
    end
  end
end;

procedure genIfStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  i, toClose: int;
  cond, stmt: TCompRes;
  it: PNode;
begin
  toClose := 0;
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    if sonsLen(it) <> 1 then begin
      gen(p, it.sons[0], cond);
      genStmt(p, it.sons[1], stmt);
      if i > 0 then begin appf(r.com, 'else {$n', []); inc(toClose) end;
      if cond.com <> nil then appf(r.com, '$1;$n', [cond.com]);
      appf(r.com, 'if ($1) {$n$2}', [cond.res, mergeStmt(stmt)]);
    end
    else begin
      // else part:
      genStmt(p, it.sons[0], stmt);
      appf(r.com, 'else {$n$1}$n', [mergeStmt(stmt)]);
    end
  end;
  app(r.com, repeatChar(toClose, '}')+{&}tnl);
end;

procedure genIfExpr(var p: TProc; n: PNode; var r: TCompRes);
var
  i, toClose: int;
  cond, stmt: TCompRes;
  it: PNode;
begin
  toClose := 0;
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    if sonsLen(it) <> 1 then begin
      gen(p, it.sons[0], cond);
      gen(p, it.sons[1], stmt);
      if i > 0 then begin app(r.res, ': ('); inc(toClose); end;
      r.com := mergeExpr(r.com, cond.com);
      r.com := mergeExpr(r.com, stmt.com);
      appf(r.res, '($1) ? ($2)', [cond.res, stmt.res]);
    end
    else begin
      // else part:
      gen(p, it.sons[0], stmt);
      r.com := mergeExpr(r.com, stmt.com);
      appf(r.res, ': ($1)', [stmt.res]);
    end
  end;
  app(r.res, repeatChar(toClose, ')'));
end;

function generateHeader(var p: TProc; typ: PType): PRope;
var
  i: int;
  param: PSym;
  name: PRope;
begin
  result := nil;
  for i := 1 to sonsLen(typ.n)-1 do begin
    if result <> nil then app(result, ', ');
    assert(typ.n.sons[i].kind = nkSym);
    param := typ.n.sons[i].sym;
    name := mangleName(param);
    app(result, name);
    if mapType(param.typ) = etyBaseIndex then begin
      app(result, ', ');
      app(result, name);
      app(result, '_Idx');
    end
  end
end;

const
  nodeKindsNeedNoCopy = {@set}[nkCharLit..nkInt64Lit, nkStrLit..nkTripleStrLit,
                               nkFloatLit..nkFloat64Lit,
                               nkCurly, nkPar, 
                               nkStringToCString, nkCStringToString,
                               nkCall, nkHiddenCallConv];

function needsNoCopy(y: PNode): bool;
begin
  result := (y.kind in nodeKindsNeedNoCopy)
      or (skipGeneric(y.typ).kind in [tyRef, tyPtr, tyVar])
end;

procedure genAsgnAux(var p: TProc; x, y: PNode; var r: TCompRes;
                     noCopyNeeded: bool);
var
  a, b: TCompRes;
begin
  gen(p, x, a);
  gen(p, y, b);
  case mapType(x.typ) of
    etyObject: begin
      if a.com <> nil then appf(r.com, '$1;$n', [a.com]);
      if b.com <> nil then appf(r.com, '$1;$n', [b.com]);
      if needsNoCopy(y) or noCopyNeeded then
        appf(r.com, '$1 = $2;$n', [a.res, b.res])
      else begin
        useMagic(p, 'NimCopy');
        appf(r.com, '$1 = NimCopy($2, $3);$n',
            [a.res, b.res, genTypeInfo(p, y.typ)]);
      end
    end;
    etyBaseIndex: begin
      if (a.kind <> etyBaseIndex) or (b.kind <> etyBaseIndex) then
        internalError(x.info, 'genAsgn');
      appf(r.com, '$1 = $2; $3 = $4;$n', [a.com, b.com, a.res, b.res]);
    end
    else begin
      if a.com <> nil then appf(r.com, '$1;$n', [a.com]);
      if b.com <> nil then appf(r.com, '$1;$n', [b.com]);
      appf(r.com, '$1 = $2;$n', [a.res, b.res]);
    end
  end
end;

procedure genAsgn(var p: TProc; n: PNode; var r: TCompRes);
begin
  genLineDir(p, n, r);
  genAsgnAux(p, n.sons[0], n.sons[1], r, false);
end;

procedure genFastAsgn(var p: TProc; n: PNode; var r: TCompRes);
begin
  genLineDir(p, n, r);
  genAsgnAux(p, n.sons[0], n.sons[1], r, true);
end;

procedure genSwap(var p: TProc; n: PNode; var r: TCompRes);
var
  a, b: TCompRes;
  tmp, tmp2: PRope;
begin
  gen(p, n.sons[1], a);
  gen(p, n.sons[2], b);
  inc(p.unique);
  tmp := ropef('Tmp$1', [toRope(p.unique)]);
  case mapType(n.sons[1].typ) of
    etyBaseIndex: begin
      inc(p.unique);
      tmp2 := ropef('Tmp$1', [toRope(p.unique)]);
      if (a.kind <> etyBaseIndex) or (b.kind <> etyBaseIndex) then
        internalError(n.info, 'genSwap');
      appf(r.com, 'var $1 = $2; $2 = $3; $3 = $1;$n', [tmp, a.com, b.com]);
      appf(r.com, 'var $1 = $2; $2 = $3; $3 = $1', [tmp2, a.res, b.res]);
    end
    else begin
      if a.com <> nil then appf(r.com, '$1;$n', [a.com]);
      if b.com <> nil then appf(r.com, '$1;$n', [b.com]);
      appf(r.com, 'var $1 = $2; $2 = $3; $3 = $1', [tmp, a.res, b.res]);
    end
  end
end;

procedure genFieldAddr(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
  f: PSym;
begin
  r.kind := etyBaseIndex;
  gen(p, n.sons[0], a);
  if n.sons[1].kind <> nkSym then
    InternalError(n.sons[1].info, 'genFieldAddr');
  f := n.sons[1].sym;
  if f.loc.r = nil then f.loc.r := mangleName(f);
  r.res := makeCString(ropeToStr(f.loc.r));
  r.com := mergeExpr(a);
end;

procedure genFieldAccess(var p: TProc; n: PNode; var r: TCompRes);
var
  f: PSym;
begin
  r.kind := etyNone;
  gen(p, n.sons[0], r);
  if n.sons[1].kind <> nkSym then
    InternalError(n.sons[1].info, 'genFieldAddr');
  f := n.sons[1].sym;
  if f.loc.r = nil then f.loc.r := mangleName(f);
  r.res := ropef('$1.$2', [r.res, f.loc.r]);
end;

procedure genCheckedFieldAddr(var p: TProc; n: PNode; var r: TCompRes);
begin
  genFieldAddr(p, n.sons[0], r); // XXX
end;

procedure genCheckedFieldAccess(var p: TProc; n: PNode; var r: TCompRes);
begin
  genFieldAccess(p, n.sons[0], r); // XXX
end;

procedure genArrayAddr(var p: TProc; n: PNode; var r: TCompRes);
var
  a, b: TCompRes;
  first: biggestInt;
  typ: PType;
begin
  r.kind := etyBaseIndex;
  gen(p, n.sons[0], a);
  gen(p, n.sons[1], b);
  r.com := mergeExpr(a);
  typ := skipPtrsGeneric(n.sons[0].typ);
  if typ.kind in [tyArray, tyArrayConstr] then first := FirstOrd(typ.sons[0])
  else first := 0;
  if (optBoundsCheck in p.options) and not isConstExpr(n.sons[1]) then begin
    useMagic(p, 'chckIndx');
    b.res := ropef('chckIndx($1, $2, $3.length)-$2',
                  [b.res, toRope(first), a.res]);
    // XXX: BUG: a.res evaluated twice!
  end
  else if first <> 0 then begin
    b.res := ropef('($1)-$2', [b.res, toRope(first)]);
  end;
  r.res := mergeExpr(b);
end;

procedure genArrayAccess(var p: TProc; n: PNode; var r: TCompRes);
begin
  genArrayAddr(p, n, r);
  r.kind := etyNone;
  r.res := ropef('$1[$2]', [r.com, r.res]);
  r.com := nil;
end;

(*
type
  TMyList = record
    x: seq[ptr ptr int]
    L: int
    next: ptr TMyList

proc myAdd(head: var ptr TMyList, item: ptr TMyList) =
  item.next = head
  head = item

proc changeInt(i: var int) = inc(i)

proc f(p: ptr TMyList, x: ptr ptr int) =
  add p.x, x
  p.next = nil
  changeInt(p.L)

*)

procedure genAddr(var p: TProc; n: PNode; var r: TCompRes);
var
  s: PSym;
begin
  case n.sons[0].kind of
    nkSym: begin
      s := n.sons[0].sym;
      if s.loc.r = nil then InternalError(n.info, 'genAddr: 3');
      case s.kind of
        skVar: begin
          if mapType(n.typ) = etyObject then begin
            // make addr() a no-op:
            r.kind := etyNone;
            r.res := s.loc.r;
            r.com := nil;
          end
          else if sfGlobal in s.flags then begin
            // globals are always indirect accessible
            r.kind := etyBaseIndex;
            r.com := toRope('Globals');
            r.res := makeCString(ropeToStr(s.loc.r));
          end
          else if sfAddrTaken in s.flags then begin
            r.kind := etyBaseIndex;
            r.com := s.loc.r;
            r.res := toRope('0'+'');
          end
          else InternalError(n.info, 'genAddr: 4');
        end;
        else InternalError(n.info, 'genAddr: 2');
      end;
    end;
    nkCheckedFieldExpr: genCheckedFieldAddr(p, n, r);
    nkDotExpr, nkQualified: genFieldAddr(p, n, r);
    nkBracketExpr: genArrayAddr(p, n, r);
    else InternalError(n.info, 'genAddr');
  end
end;

procedure genSym(var p: TProc; n: PNode; var r: TCompRes);
var
  s: PSym;
  k: TEcmasTypeKind;
begin
  s := n.sym;
  if s.loc.r = nil then
    InternalError(n.info, 'symbol has no generated name: ' + s.name.s);
  case s.kind of
    skVar, skParam, skTemp: begin
      k := mapType(s.typ);
      if k = etyBaseIndex then begin
        r.kind := etyBaseIndex;
        if [sfAddrTaken, sfGlobal] * s.flags <> [] then begin
          r.com := ropef('$1[0]', [s.loc.r]);
          r.res := ropef('$1[1]', [s.loc.r]);
        end
        else begin
          r.com := s.loc.r;
          r.res := con(s.loc.r, '_Idx');
        end
      end
      else if (k <> etyObject) and (sfAddrTaken in s.flags) then
        r.res := ropef('$1[0]', [s.loc.r])
      else
        r.res := s.loc.r
    end
    else r.res := s.loc.r;
  end
end;

procedure genDeref(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
begin
  if mapType(n.sons[0].typ) = etyObject then
    gen(p, n.sons[0], r)
  else begin
    gen(p, n.sons[0], a);
    if a.kind <> etyBaseIndex then InternalError(n.info, 'genDeref');
    r.res := ropef('$1[$2]', [a.com, a.res])
  end
end;

procedure genCall(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
  i: int;
begin
  gen(p, n.sons[0], r);
  app(r.res, '('+'');
  for i := 1 to sonsLen(n)-1 do begin
    if i > 1 then app(r.res, ', ');
    gen(p, n.sons[i], a);
    if a.kind = etyBaseIndex then begin
      app(r.res, a.com);
      app(r.res, ', ');
      app(r.res, a.res);
    end
    else
      app(r.res, mergeExpr(a));
  end;
  app(r.res, ')'+'');
end;

function putToSeq(const s: string; indirect: bool): PRope;
begin
  result := toRope(s);
  if indirect then result := ropef('[$1]', [result])
end;

function createVar(var p: TProc; typ: PType;
                   indirect: bool): PRope; forward;

function createRecordVarAux(var p: TProc; rec: PNode; var c: int): PRope;
var
  i: int;
begin
  result := nil;
  case rec.kind of
    nkRecList: begin
      for i := 0 to sonsLen(rec)-1 do
        app(result, createRecordVarAux(p, rec.sons[i], c))
    end;
    nkRecCase: begin
      app(result, createRecordVarAux(p, rec.sons[0], c));
      for i := 1 to sonsLen(rec)-1 do
        app(result, createRecordVarAux(p, lastSon(rec.sons[i]), c));
    end;
    nkSym: begin
      if c > 0 then app(result, ', ');
      app(result, mangleName(rec.sym));
      app(result, ': ');
      app(result, createVar(p, rec.sym.typ, false));
      inc(c);
    end;
    else InternalError(rec.info, 'createRecordVarAux')
  end
end;

function createVar(var p: TProc; typ: PType; indirect: bool): PRope;
var
  i, len, c: int;
  t, e: PType;
begin
  t := skipGeneric(typ);
  case t.kind of
    tyInt..tyInt64, tyEnum, tyAnyEnum, tyChar: begin
      result := putToSeq('0'+'', indirect)
    end;
    tyFloat..tyFloat128: result := putToSeq('0.0', indirect);
    tyRange: result := createVar(p, typ.sons[0], indirect);
    tySet: result := toRope('{}');
    tyBool: result := putToSeq('false', indirect);
    tyArray, tyArrayConstr: begin
      len := int(lengthOrd(t));
      e := elemType(t);
      if len > 32 then begin
        useMagic(p, 'ArrayConstr');
        result := ropef('ArrayConstr($1, $2, $3)',
                        [toRope(len), createVar(p, e, false),
                        genTypeInfo(p, e)])
      end
      else begin
        result := toRope('['+'');
        i := 0;
        while i < len do begin
          if i > 0 then app(result, ', ');
          app(result, createVar(p, e, false));
          inc(i);
        end;
        app(result, ']'+'');
      end
    end;
    tyTuple: begin
      result := toRope('{'+'');
      c := 0;
      app(result, createRecordVarAux(p, t.n, c));
      app(result, '}'+'');
    end;
    tyObject: begin
      result := toRope('{'+'');
      c := 0;
      if not (tfFinal in t.flags) or (t.sons[0] <> nil) then begin
        inc(c);
        appf(result, 'm_type: $1', [genTypeInfo(p, t)]);
      end;
      while t <> nil do begin
        app(result, createRecordVarAux(p, t.n, c));
        t := t.sons[0];
      end;
      app(result, '}'+'');
    end;
    tyVar, tyPtr, tyRef: begin
      if mapType(t) = etyBaseIndex then
        result := putToSeq('[null, 0]', indirect)
      else
        result := putToSeq('null', indirect);
    end;
    tySequence, tyString, tyCString, tyPointer: begin
      result := putToSeq('null', indirect);
    end
    else begin
      internalError('createVar: ' + typekindtoStr[t.kind]);
      result := nil;
    end
  end
end;

function isIndirect(v: PSym): bool;
begin
  result := (sfAddrTaken in v.flags) and (mapType(v.typ) <> etyObject);
end;

procedure genVarInit(var p: TProc; v: PSym; n: PNode; var r: TCompRes);
var
  a: TCompRes;
  s: PRope;
begin
  if n = nil then begin
    appf(r.com, 'var $1 = $2;$n',
        [mangleName(v), createVar(p, v.typ, isIndirect(v))])
  end
  else begin
    {@discard} mangleName(v);
    gen(p, n, a);
    case mapType(v.typ) of
      etyObject: begin
        if a.com <> nil then appf(r.com, '$1;$n', [a.com]);
        if needsNoCopy(n) then s := a.res
        else begin
          useMagic(p, 'NimCopy');
          s := ropef('NimCopy($1, $2)', [a.res, genTypeInfo(p, n.typ)]);
        end
      end;
      etyBaseIndex: begin
        if (a.kind <> etyBaseIndex) then InternalError(n.info, 'genVarInit');
        if [sfAddrTaken, sfGlobal] * v.flags <> [] then
          appf(r.com, 'var $1 = [$2, $3];$n', [v.loc.r, a.com, a.res])
        else
          appf(r.com, 'var $1 = $2; var $1_Idx = $3;$n',
               [v.loc.r, a.com, a.res]);
        exit
      end
      else begin
        if a.com <> nil then appf(r.com, '$1;$n', [a.com]);
        s := a.res;
      end
    end;
    if isIndirect(v) then
      appf(r.com, 'var $1 = [$2];$n', [v.loc.r, s])
    else
      appf(r.com, 'var $1 = $2;$n', [v.loc.r, s])
  end;
end;

procedure genVarStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  i: int;
  v: PSym;
  a: PNode;
begin
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    assert(a.kind = nkIdentDefs);
    assert(a.sons[0].kind = nkSym);
    v := a.sons[0].sym;
    if lfNoDecl in v.loc.flags then continue;
    genLineDir(p, a, r);
    genVarInit(p, v, a.sons[2], r);
  end
end;

procedure genConstStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  c: PSym;
  i: int;
begin
  genLineDir(p, n, r);
  for i := 0 to sonsLen(n)-1 do begin
    if n.sons[i].kind = nkCommentStmt then continue;
    assert(n.sons[i].kind = nkConstDef);
    c := n.sons[i].sons[0].sym;
    if (c.ast <> nil) and (c.typ.kind in ConstantDataTypes) and
           not (lfNoDecl in c.loc.flags) then begin
      genLineDir(p, n.sons[i], r);
      genVarInit(p, c, c.ast, r);
    end
  end
end;

procedure genNew(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
  t: Ptype;
begin
  gen(p, n.sons[1], a);
  t := skipVarGeneric(n.sons[1].typ).sons[0];
  if a.com <> nil then appf(r.com, '$1;$n', [a.com]);
  appf(r.com, '$1 = $2;$n', [a.res, createVar(p, t, true)]);
end;

procedure genOrd(var p: TProc; n: PNode; var r: TCompRes);
begin
  case skipVarGeneric(n.sons[1].typ).kind of
    tyEnum, tyAnyEnum, tyInt..tyInt64, tyChar: gen(p, n.sons[1], r);
    tyBool: unaryExpr(p, n, r, '', '($1 ? 1:0)');
    else InternalError(n.info, 'genOrd');
  end
end;

procedure genConStrStr(var p: TProc; n: PNode; var r: TCompRes);
var
  a, b: TCompRes;
begin
  gen(p, n.sons[1], a);
  gen(p, n.sons[2], b);
  r.com := mergeExpr(a.com, b.com);
  if skipVarGenericRange(n.sons[1].typ).kind = tyChar then
    a.res := ropef('[$1, 0]', [a.res]);
  if skipVarGenericRange(n.sons[2].typ).kind = tyChar then
    b.res := ropef('[$1, 0]', [b.res]);
  r.res := ropef('($1.slice(0,-1)).concat($2)', [a.res, b.res]);
end;

procedure genMagic(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
  line, filen: PRope;
  op: TMagic;
begin
  op := n.sons[0].sym.magic;
  case op of
    mOr: genOr(p, n.sons[1], n.sons[2], r);
    mAnd: genAnd(p, n.sons[1], n.sons[2], r);
    mAddi..mStrToStr: arith(p, n, r, op);
    //mRepr: genRepr(p, n, r);
    mSwap: genSwap(p, n, r);
    mPred: begin // XXX: range checking?
      if not (optOverflowCheck in p.Options) then
        binaryExpr(p, n, r, '', '$1 - $2')
      else
        binaryExpr(p, n, r, 'subInt', 'subInt($1, $2)')
    end;
    mSucc: begin // XXX: range checking?
      if not (optOverflowCheck in p.Options) then
        binaryExpr(p, n, r, '', '$1 - $2')
      else
        binaryExpr(p, n, r, 'addInt', 'addInt($1, $2)')
    end;
    mAppendStrCh: binaryStmt(p, n, r, 'addChar', '$1 = addChar($1, $2)');
    mAppendStrStr:
      binaryStmt(p, n, r, '', '$1 = ($1.slice(0,-1)).concat($2)');
      // XXX: make a copy of $2, because of EMCAScript's sucking semantics
    mAppendSeqElem: binaryStmt(p, n, r, '', '$1.push($2)');
    mConStrStr: genConStrStr(p, n, r);
    mEqStr: binaryExpr(p, n, r, 'eqStrings', 'eqStrings($1, $2)');
    mLeStr: binaryExpr(p, n, r, 'cmpStrings', '(cmpStrings($1, $2) <= 0)');
    mLtStr: binaryExpr(p, n, r, 'cmpStrings', '(cmpStrings($1, $2) < 0)');
    mIsNil: unaryExpr(p, n, r, '', '$1 == null');
    mAssert: begin
      if (optAssert in p.Options) then begin
        useMagic(p, 'internalAssert');
        gen(p, n.sons[1], a);
        line := toRope(toLinenumber(n.info));
        filen := makeCString(ToFilename(n.info));
        appf(r.com, 'if (!($3)) internalAssert($1, $2)',
                      [filen, line, mergeExpr(a)])
      end
    end;
    mNew, mNewFinalize: genNew(p, n, r);
    mSizeOf: r.res := toRope(getSize(n.sons[1].typ));
    mChr: gen(p, n.sons[1], r); // nothing to do
    mOrd: genOrd(p, n, r);
    mLengthStr: unaryExpr(p, n, r, '', '($1.length-1)');
    mLengthSeq, mLengthOpenArray, mLengthArray:
      unaryExpr(p, n, r, '', '$1.length');
    mHigh: begin
      if skipVarGeneric(n.sons[0].typ).kind = tyString then
        unaryExpr(p, n, r, '', '($1.length-2)')
      else
        unaryExpr(p, n, r, '', '($1.length-1)');
    end;
    mInc: begin
      if not (optOverflowCheck in p.Options) then
        binaryStmt(p, n, r, '', '$1 += $2')
      else
        binaryStmt(p, n, r, 'addInt', '$1 = addInt($1, $2)')
    end;
    ast.mDec: begin
      if not (optOverflowCheck in p.Options) then
        binaryStmt(p, n, r, '', '$1 -= $2')
      else
        binaryStmt(p, n, r, 'subInt', '$1 = subInt($1, $2)')
    end;
    mSetLengthStr: binaryStmt(p, n, r, '', '$1.length = ($2)-1');
    mSetLengthSeq: binaryStmt(p, n, r, '', '$1.length = $2');
    mCard: unaryExpr(p, n, r, 'SetCard', 'SetCard($1)');
    mLtSet: binaryExpr(p, n, r, 'SetLt', 'SetLt($1, $2)');
    mLeSet: binaryExpr(p, n, r, 'SetLe', 'SetLe($1, $2)');
    mEqSet: binaryExpr(p, n, r, 'SetEq', 'SetEq($1, $2)');
    mMulSet: binaryExpr(p, n, r, 'SetMul', 'SetMul($1, $2)');
    mPlusSet: binaryExpr(p, n, r, 'SetPlus', 'SetPlus($1, $2)');
    mMinusSet: binaryExpr(p, n, r, 'SetMinus', 'SetMinus($1, $2)');
    mIncl: binaryStmt(p, n, r, '', '$1[$2] = true');
    mExcl: binaryStmt(p, n, r, '', 'delete $1[$2]');
    mInSet: binaryExpr(p, n, r, '', '($1[$2] != undefined)');
    mNLen..mNError:
      liMessage(n.info, errCannotGenerateCodeForX, n.sons[0].sym.name.s);
    else genCall(p, n, r);
    //else internalError(e.info, 'genMagic: ' + magicToStr[op]);
  end
end;

procedure genSetConstr(var p: TProc; n: PNode; var r: TCompRes);
var
  a, b: TCompRes;
  i: int;
  it: PNode;
begin
  useMagic(p, 'SetConstr');
  r.res := toRope('SetConstr(');
  for i := 0 to sonsLen(n)-1 do begin
    if i > 0 then app(r.res, ', ');
    it := n.sons[i];
    if it.kind = nkRange then begin
      gen(p, it.sons[0], a);
      gen(p, it.sons[1], b);
      r.com := mergeExpr(r.com, mergeExpr(a.com, b.com));
      appf(r.res, '[$1, $2]', [a.res, b.res]);
    end
    else begin
      gen(p, it, a);
      r.com := mergeExpr(r.com, a.com);
      app(r.res, a.res);
    end
  end;
  app(r.res, ')'+'');
end;

procedure genArrayConstr(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
  i: int;
begin
  r.res := toRope('['+'');
  for i := 0 to sonsLen(n)-1 do begin
    if i > 0 then app(r.res, ', ');
    gen(p, n.sons[i], a);
    r.com := mergeExpr(r.com, a.com);
    app(r.res, a.res);
  end;
  app(r.res, ']'+'');
end;

procedure genRecordConstr(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
  i, len: int;
begin
  i := 0;
  len := sonsLen(n);
  r.res := toRope('{'+'');
  while i < len do begin
    if i > 0 then app(r.res, ', ');
    if (n.sons[i].kind <> nkSym) then
      internalError(n.sons[i].info, 'genRecordConstr');
    gen(p, n.sons[i+1], a);
    r.com := mergeExpr(r.com, a.com);
    appf(r.res, '$1: $2', [mangleName(n.sons[i].sym), a.res]);
    inc(i, 2)
  end
end;

procedure genConv(var p: TProc; n: PNode; var r: TCompRes);
var
  src, dest: PType;
begin
  dest := skipVarGenericRange(n.typ);
  src := skipVarGenericRange(n.sons[1].typ);
  gen(p, n.sons[1], r);
  if (dest.kind <> src.kind) and (src.kind = tyBool) then
    r.res := ropef('(($1)? 1:0)', [r.res])
end;

procedure upConv(var p: TProc; n: PNode; var r: TCompRes);
begin
  gen(p, n.sons[0], r); // XXX
end;

procedure genRangeChck(var p: TProc; n: PNode; var r: TCompRes;
                       const magic: string);
var
  a, b: TCompRes;
begin
  gen(p, n.sons[0], r);
  if optRangeCheck in p.options then begin
    gen(p, n.sons[1], a);
    gen(p, n.sons[2], b);
    r.com := mergeExpr(r.com, mergeExpr(a.com, b.com));
    useMagic(p, 'chckRange');
    r.res := ropef('chckRange($1, $2, $3)', [r.res, a.res, b.res]);
  end
end;

procedure convStrToCStr(var p: TProc; n: PNode; var r: TCompRes);
begin
  // we do an optimization here as this is likely to slow down
  // much of the code otherwise:
  if n.sons[0].kind = nkCStringToString then
    gen(p, n.sons[0].sons[0], r)
  else begin
    gen(p, n.sons[0], r);
    if r.res = nil then InternalError(n.info, 'convStrToCStr');
    useMagic(p, 'toEcmaStr');
    r.res := ropef('toEcmaStr($1)', [r.res]);
  end;
end;

procedure convCStrToStr(var p: TProc; n: PNode; var r: TCompRes);
begin
  // we do an optimization here as this is likely to slow down
  // much of the code otherwise:
  if n.sons[0].kind = nkStringToCString then
    gen(p, n.sons[0].sons[0], r)
  else begin
    gen(p, n.sons[0], r);
    if r.res = nil then InternalError(n.info, 'convCStrToStr');
    useMagic(p, 'cstrToNimstr');
    r.res := ropef('cstrToNimstr($1)', [r.res]);
  end;
end;

procedure genReturnStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  a: TCompRes;
begin
  if p.procDef = nil then InternalError(n.info, 'genReturnStmt');
  p.BeforeRetNeeded := true;
  if (n.sons[0] <> nil) then begin
    genStmt(p, n.sons[0], a);
    if a.com <> nil then appf(r.com, '$1;$n', mergeStmt(a));
  end
  else genLineDir(p, n, r);
  finishTryStmt(p, r, p.nestedTryStmts);
  app(r.com, 'break BeforeRet;' + tnl);
end;

function genProcBody(var p: TProc; prc: PSym; const r: TCompRes): PRope;
begin
  if optStackTrace in prc.options then begin
    result := ropef(
      'var F = {procname: $1, prev: framePtr, filename: $2, line: 0};$n' +
      'framePtr = F;$n',
      [makeCString(prc.owner.name.s +{&} '.' +{&} prc.name.s),
      makeCString(toFilename(prc.info))]);
  end
  else
    result := nil;
  if p.beforeRetNeeded then
    appf(result, 'BeforeRet: do {$n$1} while (false); $n', [mergeStmt(r)])
  else
    app(result, mergeStmt(r));
  if prc.typ.callConv = ccSysCall then begin
    result := ropef('try {$n$1} catch (e) {$n'+
                    ' alert("Unhandled exception:\n" + e.message + "\n"$n}',
                    [result]);
  end;
  if optStackTrace in prc.options then
    app(result, 'framePtr = framePtr.prev;' + tnl);
end;

procedure genProc(var oldProc: TProc; n: PNode; var r: TCompRes);
var
  p: TProc;
  prc, resultSym: PSym;
  name, returnStmt, resultAsgn, header: PRope;
  a: TCompRes;
begin
  prc := n.sons[namePos].sym;
  initProc(p, oldProc.globals, oldProc.module, n, prc.options);
  returnStmt := nil;
  resultAsgn := nil;
  name := mangleName(prc);
  header := generateHeader(p, prc.typ);
  if (prc.typ.sons[0] <> nil) and not (sfPure in prc.flags) then begin
    resultSym := n.sons[resultPos].sym;
    resultAsgn := ropef('var $1 = $2;$n', [mangleName(resultSym),
      createVar(p, resultSym.typ, isIndirect(resultSym))]);
    gen(p, n.sons[resultPos], a);
    if a.com <> nil then appf(returnStmt, '$1;$n', [a.com]);
    returnStmt := ropef('return $1;$n', [a.res]);
  end;
  genStmt(p, n.sons[codePos], r);
  r.com := ropef('function $1($2) {$n$3$4$5}$n',
           [name, header, resultAsgn, genProcBody(p, prc, r), returnStmt]);
  r.res := nil;
end;

procedure genStmtListExpr(var p: TProc; n: PNode; var r: TCompRes);
var
  i: int;
  a: TCompRes;
begin
  // watch out this trick: ``function () { stmtList; return expr; }()``
  r.res := toRope('function () {');
  for i := 0 to sonsLen(n)-2 do begin
    genStmt(p, n.sons[i], a);
    app(r.res, mergeStmt(a));
  end;
  gen(p, lastSon(n), a);
  if a.com <> nil then appf(r.res, '$1;$n', [a.com]);
  appf(r.res, 'return $1; }()', [a.res]);
end;

procedure genStmt(var p: TProc; n: PNode; var r: TCompRes);
var
  prc: PSym;
  i: int;
  a: TCompRes;
begin
  r.kind := etyNone;
  r.com := nil;
  r.res := nil;
  case n.kind of
    nkNilLit: begin end;
    nkStmtList: begin
      for i := 0 to sonsLen(n)-1 do begin
        genStmt(p, n.sons[i], a);
        app(r.com, mergeStmt(a));
      end
    end;
    nkBlockStmt:   genBlock(p, n, r);
    nkIfStmt:      genIfStmt(p, n, r);
    nkWhileStmt:   genWhileStmt(p, n, r);
    nkVarSection:  genVarStmt(p, n, r);
    nkConstSection: genConstStmt(p, n, r);
    nkForStmt:     internalError(n.info, 'for statement not eliminated');
    nkCaseStmt:    genCaseStmt(p, n, r);
    nkReturnStmt:  genReturnStmt(p, n, r);
    nkBreakStmt:   genBreakStmt(p, n, r);
    nkAsgn:        genAsgn(p, n, r);
    nkFastAsgn:    genFastAsgn(p, n, r);
    nkDiscardStmt: begin
      genLineDir(p, n, r);
      gen(p, n.sons[0], r);
      app(r.res, ';'+ tnl);
    end;
    nkAsmStmt: genAsmStmt(p, n, r);
    nkTryStmt: genTryStmt(p, n, r);
    nkRaiseStmt: genRaiseStmt(p, n, r);
    nkTypeSection, nkCommentStmt, nkIteratorDef,
    nkIncludeStmt, nkImportStmt,
    nkFromStmt, nkTemplateDef, nkMacroDef, nkPragma: begin end;
    nkProcDef, nkConverterDef: begin
      if (n.sons[genericParamsPos] = nil) then begin
        prc := n.sons[namePos].sym;
        if (n.sons[codePos] <> nil) and not (lfNoDecl in prc.loc.flags) then
          genProc(p, n, r)
        else
          {@discard} mangleName(prc);
      end
    end;
    else begin
      genLineDir(p, n, r);
      gen(p, n, r);
      app(r.res, ';'+ tnl);
    end
  end
end;

procedure gen(var p: TProc; n: PNode; var r: TCompRes);
var
  f: BiggestFloat;
begin
  r.kind := etyNone;
  r.com := nil;
  r.res := nil;
  case n.kind of
    nkSym: genSym(p, n, r);
    nkCharLit..nkInt64Lit: begin
      r.res := toRope(n.intVal);
    end;
    nkNilLit: begin
      if mapType(n.typ) = etyBaseIndex then begin
        r.kind := etyBaseIndex;
        r.com := toRope('null');
        r.res := toRope('0'+'');
      end
      else
        r.res := toRope('null');
    end;
    nkStrLit..nkTripleStrLit: begin
      if skipVarGenericRange(n.typ).kind = tyString then begin
        useMagic(p, 'cstrToNimstr');
        r.res := ropef('cstrToNimstr($1)', [makeCString(n.strVal)])
      end
      else
        r.res := makeCString(n.strVal)
    end;
    nkFloatLit..nkFloat64Lit: begin
      f := n.floatVal;
      if f <> f then
        r.res := toRope('NaN')
      else if f = 0.0 then
        r.res := toRopeF(f)
      else if f = 0.5 * f then
        if f > 0.0 then r.res := toRope('Infinity')
        else r.res := toRope('-Infinity')
      else
        r.res := toRopeF(f);
    end;
    nkBlockExpr: genBlock(p, n, r);
    nkIfExpr: genIfExpr(p, n, r);
    nkCall, nkHiddenCallConv: begin
      if (n.sons[0].kind = nkSym) and (n.sons[0].sym.magic <> mNone) then
        genMagic(p, n, r)
      else
        genCall(p, n, r)
    end;
    nkCurly: genSetConstr(p, n, r);
    nkBracket: genArrayConstr(p, n, r);
    nkPar: genRecordConstr(p, n, r);
    nkHiddenStdConv, nkHiddenSubConv, nkConv: genConv(p, n, r);
    nkAddr, nkHiddenAddr: genAddr(p, n, r);
    nkDerefExpr, nkHiddenDeref: genDeref(p, n, r);
    nkBracketExpr: genArrayAccess(p, n, r);
    nkDotExpr: genFieldAccess(p, n, r);
    nkCheckedFieldExpr: genCheckedFieldAccess(p, n, r);
    nkObjDownConv: gen(p, n.sons[0], r);
    nkObjUpConv: upConv(p, n, r);
    nkChckRangeF: genRangeChck(p, n, r, 'chckRangeF');
    nkChckRange64: genRangeChck(p, n, r, 'chckRange64');
    nkChckRange: genRangeChck(p, n, r, 'chckRange');
    nkStringToCString: convStrToCStr(p, n, r);
    nkCStringToString: convCStrToStr(p, n, r);
    nkPassAsOpenArray: gen(p, n.sons[0], r);
    nkStmtListExpr: genStmtListExpr(p, n, r);
    else
      InternalError(n.info, 'gen: unknown node type: ' + nodekindToStr[n.kind])
  end
end;

// ------------------------------------------------------------------------

var
  globals: PGlobals;

function newModule(module: PSym; const filename: string): BModule;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.filename := filename;
  result.module := module;
  if globals = nil then globals := newGlobals();
end;

function genHeader(): PRope;
begin
  result := ropef(
    '/* Generated by the Nimrod Compiler v$1 */$n' +
    '/*   (c) 2008 Andreas Rumpf */$n$n' +
    '$nvar Globals = this;$n' +
    'var framePtr = null;$n' +
    'var excHandler = null;$n',
    [toRope(versionAsString)])
end;

procedure genModule(var p: TProc; n: PNode; var r: TCompRes);
begin
  genStmt(p, n, r);
  if optStackTrace in p.options then begin
    r.com := ropef(
      'var F = {procname: $1, prev: framePtr, filename: $2, line: 0};$n' +
      'framePtr = F;$n' +
      '$3' +
      'framePtr = framePtr.prev;$n',
      [makeCString('module ' + p.module.module.name.s),
      makeCString(toFilename(p.module.module.info)), r.com])
  end
end;

function myProcess(b: PPassContext; n: PNode): PNode;
var
  m: BModule;
  p: TProc;
  r: TCompRes;
begin
  result := n;
  m := BModule(b);
  if m.module = nil then InternalError(n.info, 'myProcess');
  initProc(p, globals, m, nil, m.module.options);
  genModule(p, n, r);
  app(p.globals.code, p.data);
  app(p.globals.code, mergeStmt(r));
end;

function myClose(b: PPassContext; n: PNode): PNode;
var
  m: BModule;
  code: PRope;
  outfile: string;
begin
  result := myProcess(b, n);
  m := BModule(b);
  if sfMainModule in m.module.flags then begin
    // write the file:
    code := con(globals.typeInfo, globals.code);
    outfile := changeFileExt(completeCFilePath(m.filename), 'js');
    {@discard} writeRopeIfNotEqual(con(genHeader(), code), outfile);
  end
end;

function myOpenCached(s: PSym; const filename: string;
                      rd: PRodReader): PPassContext;
begin
  InternalError('symbol files are not possible with the Ecmas code generator');
  result := nil;
end;

function myOpen(s: PSym; const filename: string): PPassContext;
begin
  result := newModule(s, filename);
end;

function ecmasgenPass(): TPass;
begin
  InitPass(result);
  result.open := myOpen;
  result.close := myClose;
  result.openCached := myOpenCached;
  result.process := myProcess;
end;

end.
