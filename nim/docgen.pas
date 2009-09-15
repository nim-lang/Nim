//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit docgen;

// This is the documentation generator. It is currently pretty simple: No
// semantic checking is done for the code. Cross-references are generated
// by knowing how the anchors are going to be named.

interface

{$include 'config.inc'}

uses
  nsystem, charsets, ast, astalgo, strutils, nhashes, options, nversion, msgs,
  nos, ropes, idents, wordrecg, nmath, pnimsyn, rnimsyn, scanner, rst, ntime,
  highlite;

procedure CommandDoc(const filename: string);
procedure CommandRst2Html(const filename: string);
procedure CommandRst2TeX(const filename: string);

implementation

type
  TTocEntry = record
    n: PRstNode;
    refname, header: PRope;
  end;
  TSections = array [TSymKind] of PRope;
  TMetaEnum = (metaNone, metaTitle, metaSubtitle, metaAuthor, metaVersion);
  TDocumentor = record  // contains a module's documentation
    filename: string;   // filename of the source file; without extension
    basedir: string;    // base directory (where to put the documentation)
    modDesc: PRope;     // module description
    dependsOn: PRope;   // dependencies
    id: int;            // for generating IDs
    splitAfter: int;    // split too long entries in the TOC
    tocPart: array of TTocEntry;
    hasToc: bool;
    toc, section: TSections;
    indexFile, theIndex: PRstNode;
    indexValFilename: string;
    indent, verbatim: int;        // for code generation
    meta: array [TMetaEnum] of PRope;
  end;
  PDoc = ^TDocumentor;

var
  splitter: string = '<wbr />';

function findIndexNode(n: PRstNode): PRstNode;
var
  i: int;
begin
  if n = nil then
    result := nil
  else if n.kind = rnIndex then begin
    result := n.sons[2];
    if result = nil then begin
      result := newRstNode(rnDefList);
      n.sons[2] := result
    end
    else if result.kind = rnInner then
      result := result.sons[0]
  end
  else begin
    result := nil;
    for i := 0 to rsonsLen(n)-1 do begin
      result := findIndexNode(n.sons[i]);
      if result <> nil then exit
    end
  end
end;

procedure initIndexFile(d: PDoc);
var
  h: PRstNode;
  dummyHasToc: bool;
begin
  if gIndexFile = '' then exit;
  gIndexFile := appendFileExt(gIndexFile, 'txt');
  d.indexValFilename := changeFileExt(extractFilename(d.filename), HtmlExt);
  if ExistsFile(gIndexFile) then begin
    d.indexFile := rstParse(readFile(gIndexFile), false, gIndexFile, 0, 1,
                            dummyHasToc);
    d.theIndex := findIndexNode(d.indexFile);
    if (d.theIndex = nil) or (d.theIndex.kind <> rnDefList) then
      rawMessage(errXisNoValidIndexFile, gIndexFile);
    clearIndex(d.theIndex, d.indexValFilename);
  end
  else begin
    d.indexFile := newRstNode(rnInner);
    h := newRstNode(rnOverline);
    h.level := 1;
    addSon(h, newRstNode(rnLeaf, 'Index'));
    addSon(d.indexFile, h);
    h := newRstNode(rnIndex);
    addSon(h, nil); // no argument
    addSon(h, nil); // no options
    d.theIndex := newRstNode(rnDefList);
    addSon(h, d.theIndex);
    addSon(d.indexFile, h);
  end
end;

function newDocumentor(const filename: string): PDoc;
var
  s: string;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit
  result.tocPart := @[];
}
  result.filename := filename;
  result.id := 100;
  result.splitAfter := 20;
  s := getConfigVar('split.item.toc');
  if s <> '' then
    result.splitAfter := parseInt(s);
end;

function getVarIdx(const varnames: array of string; const id: string): int;
var
  i: int;
begin
  for i := 0 to high(varnames) do
    if cmpIgnoreStyle(varnames[i], id) = 0 then begin
      result := i; exit
    end;
  result := -1
end;

function ropeFormatNamedVars(const frmt: TFormatStr;
                             const varnames: array of string;
                             const varvalues: array of PRope): PRope;
var
  i, j, L, start, idx, num: int;
  id: string;
begin
  i := strStart;
  L := length(frmt);
  result := nil;
  num := 0;
  while i <= L + StrStart - 1 do begin
    if frmt[i] = '$' then begin
      inc(i);                 // skip '$'
      case frmt[i] of
        '#': begin
          app(result, varvalues[num]);
          inc(num);
          inc(i);
        end;
        '$': begin
          app(result, '$'+'');
          inc(i)
        end;
        '0'..'9': begin
          j := 0;
          while true do begin
            j := (j * 10) + Ord(frmt[i]) - ord('0');
            inc(i);
            if (i > L+StrStart-1) or not (frmt[i] in ['0'..'9']) then break
          end;
          if j > high(varvalues) + 1 then
            internalError('ropeFormatNamedVars');
          num := j;
          app(result, varvalues[j - 1])
        end;
        'A'..'Z', 'a'..'z', #128..#255: begin
          id := '';
          while true do begin
            addChar(id, frmt[i]);
            inc(i);
            if not (frmt[i] in ['A'..'Z', '_', 'a'..'z', #128..#255]) then break
          end;
          // search for the variable:
          idx := getVarIdx(varnames, id);
          if idx >= 0 then app(result, varvalues[idx])
          else rawMessage(errUnkownSubstitionVar, id)
        end;
        '{': begin
          id := '';
          inc(i);
          while frmt[i] <> '}' do begin
            if frmt[i] = #0 then rawMessage(errTokenExpected, '}'+'');
            addChar(id, frmt[i]);
            inc(i);
          end;
          inc(i); // skip }
          // search for the variable:
          idx := getVarIdx(varnames, id);
          if idx >= 0 then app(result, varvalues[idx])
          else rawMessage(errUnkownSubstitionVar, id)
        end
        else
          InternalError('ropeFormatNamedVars')
      end
    end;
    start := i;
    while (i <= L + StrStart - 1) do begin
      if (frmt[i] <> '$') then
        inc(i)
      else
        break
    end;
    if i - 1 >= start then
      app(result, ncopy(frmt, start, i - 1))
  end
end;

// -------------------- dispatcher -------------------------------------------

procedure addXmlChar(var dest: string; c: Char);
begin
  case c of
    '&': add(dest, '&amp;');
    '<': add(dest, '&lt;');
    '>': add(dest, '&gt;');
    '"': add(dest, '&quot;');
    else addChar(dest, c)
  end
end;

procedure addRtfChar(var dest: string; c: Char);
begin
  case c of
    '{': add(dest, '\{');
    '}': add(dest, '\}');
    '\': add(dest, '\\');
    else addChar(dest, c)
  end
end;

procedure addTexChar(var dest: string; c: Char);
begin
  case c of
    '_': add(dest, '\_');
    '{': add(dest, '\symbol{123}');
    '}': add(dest, '\symbol{125}');
    '[': add(dest, '\symbol{91}');
    ']': add(dest, '\symbol{93}');
    '\': add(dest, '\symbol{92}');
    '$': add(dest, '\$');
    '&': add(dest, '\&');
    '#': add(dest, '\#');
    '%': add(dest, '\%');
    '~': add(dest, '\symbol{126}');
    '@': add(dest, '\symbol{64}');
    '^': add(dest, '\symbol{94}');
    '`': add(dest, '\symbol{96}');
    else addChar(dest, c)
  end
end;

procedure escChar(var dest: string; c: Char);
begin
  if gCmd <> cmdRst2Tex then addXmlChar(dest, c)
  else addTexChar(dest, c);
end;

function nextSplitPoint(const s: string; start: int): int;
begin
  result := start;
  while result < length(s)+strStart do begin
    case s[result] of
      '_': exit;
      'a'..'z': begin
        if result+1 < length(s)+strStart then
          if s[result+1] in ['A'..'Z'] then exit;
      end;
      else begin end;
    end;
    inc(result);
  end;
  dec(result); // last valid index
end;

function esc(const s: string; splitAfter: int = -1): string;
var
  i, j, k, partLen: int;
begin
  result := '';
  if splitAfter >= 0 then begin
    partLen := 0;
    j := strStart;
    while j < length(s)+strStart do begin
      k := nextSplitPoint(s, j);
      if (splitter <> ' '+'') or (partLen + k - j + 1 > splitAfter) then begin
        partLen := 0;
        add(result, splitter);
      end;
      for i := j to k do escChar(result, s[i]);
      inc(partLen, k - j + 1);
      j := k+1;
    end;
  end
  else begin
    for i := strStart to length(s)+strStart-1 do escChar(result, s[i])
  end
end;

function disp(const xml, tex: string): string;
begin  
  if gCmd <> cmdRst2Tex then
    result := xml
  else
    result := tex
end;

function dispF(const xml, tex: string; const args: array of PRope): PRope;
begin
  if gCmd <> cmdRst2Tex then
    result := ropef(xml, args)
  else
    result := ropef(tex, args)
end;

procedure dispA(var dest: PRope; const xml, tex: string;
                const args: array of PRope);
begin
  if gCmd <> cmdRst2Tex then
    appf(dest, xml, args)
  else
    appf(dest, tex, args)
end;

// ---------------------------------------------------------------------------

function renderRstToOut(d: PDoc; n: PRstNode): PRope; forward;

function renderAux(d: PDoc; n: PRstNode; const outer: string = '$1'): PRope;
var
  i: int;
begin
  result := nil;
  for i := 0 to rsonsLen(n)-1 do
    app(result, renderRstToOut(d, n.sons[i]));
  result := ropef(outer, [result]);
end;

procedure setIndexForSourceTerm(d: PDoc; name: PRstNode; id: int);
var
  a, h: PRstNode;
begin
  if d.theIndex = nil then exit;
  h := newRstNode(rnHyperlink);
  a := newRstNode(rnLeaf, d.indexValFilename +{&} disp('#'+'', '')
                  +{&} toString(id));
  addSon(h, a);
  addSon(h, a);
  a := newRstNode(rnIdx);
  addSon(a, name);
  setIndexPair(d.theIndex, a, h);
end;

function renderIndexTerm(d: PDoc; n: PRstNode): PRope;
var
  a, h: PRstNode;
begin
  inc(d.id);
  result := dispF('<em id="$1">$2</em>',
                  '$2\label{$1}', [toRope(d.id), renderAux(d, n)]);
  h := newRstNode(rnHyperlink);
  a := newRstNode(rnLeaf, d.indexValFilename +{&} disp('#'+'', '')
                  +{&} toString(d.id));
  addSon(h, a);
  addSon(h, a);
  setIndexPair(d.theIndex, n, h);
end;

function genComment(d: PDoc; n: PNode): PRope;
var
  dummyHasToc: bool;
begin
  if (n.comment <> snil) and startsWith(n.comment, '##') then
    result := renderRstToOut(d, rstParse(n.comment, true, toFilename(n.info),
                                          toLineNumber(n.info),
                                          toColumn(n.info), dummyHasToc))
  else
    result := nil;
end;

function genRecComment(d: PDoc; n: PNode): PRope;
var
  i: int;
begin
  if n = nil then begin result := nil; exit end;
  result := genComment(d, n);
  if result = nil then begin
    if not (n.kind in [nkEmpty..nkNilLit]) then
      for i := 0 to sonsLen(n)-1 do begin
        result := genRecComment(d, n.sons[i]);
        if result <> nil then exit
      end
  end
  else
    n.comment := snil
end;

function isVisible(n: PNode): bool;
var
  v: PIdent;
begin
  result := false;
  if n.kind = nkPostfix then begin
    if (sonsLen(n) = 2) and (n.sons[0].kind = nkIdent) then begin
      v := n.sons[0].ident;
      result := (v.id = ord(wStar)) or (v.id = ord(wMinus));
    end
  end
  else if n.kind = nkSym then
    result := sfInInterface in n.sym.flags
  else if n.kind = nkPragmaExpr then
    result := isVisible(n.sons[0]);
end;

function getName(n: PNode; splitAfter: int = -1): string;
begin
  case n.kind of
    nkPostfix: result := getName(n.sons[1], splitAfter);
    nkPragmaExpr: result := getName(n.sons[0], splitAfter);
    nkSym: result := esc(n.sym.name.s, splitAfter);
    nkIdent: result := esc(n.ident.s, splitAfter);
    nkAccQuoted:
      result := esc('`'+'') +{&} getName(n.sons[0], splitAfter) +{&}
                esc('`'+'');
    else begin
      internalError(n.info, 'getName()');
      result := ''
    end
  end
end;

function getRstName(n: PNode): PRstNode;
begin
  case n.kind of
    nkPostfix: result := getRstName(n.sons[1]);
    nkPragmaExpr: result := getRstName(n.sons[0]);
    nkSym: result := newRstNode(rnLeaf, n.sym.name.s);
    nkIdent: result := newRstNode(rnLeaf, n.ident.s);
    nkAccQuoted: result := getRstName(n.sons[0]);
    else begin
      internalError(n.info, 'getRstName()');
      result := nil
    end
  end
end;

procedure genItem(d: PDoc; n, nameNode: PNode; k: TSymKind);
var
  r: TSrcGen;
  kind: TTokType;
  literal: string;
  name, result, comm: PRope;
begin
  if not isVisible(nameNode) then exit;
  name := toRope(getName(nameNode));
  result := nil;
  literal := '';
  kind := tkEof;
{@ignore}
  fillChar(r, sizeof(r), 0);
{@emit}
  comm := genRecComment(d, n); // call this here for the side-effect!
  initTokRender(r, n, {@set}[renderNoPragmas, renderNoBody, renderNoComments,
                             renderDocComments]);
  while true do begin
    getNextTok(r, kind, literal);
    case kind of
      tkEof: break;
      tkComment:
        dispA(result, '<span class="Comment">$1</span>',
                      '\spanComment{$1}',
                      [toRope(esc(literal))]);
      tokKeywordLow..tokKeywordHigh:
        dispA(result, '<span class="Keyword">$1</span>',
                      '\spanKeyword{$1}',
                      [toRope(literal)]);
      tkOpr, tkHat:
        dispA(result, '<span class="Operator">$1</span>',
                      '\spanOperator{$1}',
                      [toRope(esc(literal))]);
      tkStrLit..tkTripleStrLit:
        dispA(result, '<span class="StringLit">$1</span>',
                      '\spanStringLit{$1}',
                      [toRope(esc(literal))]);
      tkCharLit:
        dispA(result, '<span class="CharLit">$1</span>',
                      '\spanCharLit{$1}',
                      [toRope(esc(literal))]);
      tkIntLit..tkInt64Lit:
        dispA(result, '<span class="DecNumber">$1</span>',
                      '\spanDecNumber{$1}',
                      [toRope(esc(literal))]);
      tkFloatLit..tkFloat64Lit:
        dispA(result, '<span class="FloatNumber">$1</span>',
                      '\spanFloatNumber{$1}',
                      [toRope(esc(literal))]);
      tkSymbol:
        dispA(result, '<span class="Identifier">$1</span>',
                      '\spanIdentifier{$1}',
                      [toRope(esc(literal))]);
      tkInd, tkSad, tkDed, tkSpaces: begin
        app(result, literal)
      end;
      tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe, tkCurlyRi,
      tkBracketDotLe, tkBracketDotRi, tkCurlyDotLe, tkCurlyDotRi,
      tkParDotLe, tkParDotRi, tkComma, tkSemiColon, tkColon,
      tkEquals, tkDot, tkDotDot, tkAccent:
        dispA(result, '<span class="Other">$1</span>',
                      '\spanOther{$1}',
                      [toRope(esc(literal))]);
      else InternalError(n.info, 'docgen.genThing(' + toktypeToStr[kind] + ')');
    end
  end;
  inc(d.id);
  app(d.section[k], ropeFormatNamedVars(getConfigVar('doc.item'),
      ['name', 'header', 'desc', 'itemID'],
      [name, result, comm, toRope(d.id)]));
  app(d.toc[k], ropeFormatNamedVars(getConfigVar('doc.item.toc'),
      ['name', 'header', 'desc', 'itemID'],
      [toRope(getName(nameNode, d.splitAfter)), result, comm, toRope(d.id)]));
  setIndexForSourceTerm(d, getRstName(nameNode), d.id);
end;

function renderHeadline(d: PDoc; n: PRstNode): PRope;
var
  i, len: int;
  refname: PRope;
begin
  result := nil;
  for i := 0 to rsonsLen(n)-1 do
    app(result, renderRstToOut(d, n.sons[i]));
  refname := toRope(rstnodeToRefname(n));
  if d.hasToc then begin
    len := length(d.tocPart);
    setLength(d.tocPart, len+1);
    d.tocPart[len].refname := refname;
    d.tocPart[len].n := n;
    d.tocPart[len].header := result;
    result := dispF(
      '<h$1><a class="toc-backref" id="$2" href="#$2_toc">$3</a></h$1>',
      '\rsth$4{$3}\label{$2}$n',
      [toRope(n.level), d.tocPart[len].refname, result,
       toRope(chr(n.level-1+ord('A'))+'')]);
  end
  else
    result := dispF('<h$1 id="$2">$3</h$1>',
                    '\rsth$4{$3}\label{$2}$n',
                    [toRope(n.level), refname, result,
                     toRope(chr(n.level-1+ord('A'))+'')]);
end;

function renderOverline(d: PDoc; n: PRstNode): PRope;
var
  i: int;
  t: PRope;
begin
  t := nil;
  for i := 0 to rsonsLen(n)-1 do
    app(t, renderRstToOut(d, n.sons[i]));
  result := nil;
  if d.meta[metaTitle] = nil then d.meta[metaTitle] := t
  else if d.meta[metaSubtitle] = nil then d.meta[metaSubtitle] := t
  else
    result := dispF('<h$1 id="$2"><center>$3</center></h$1>',
                    '\rstov$4{$3}\label{$2}$n',
                    [toRope(n.level), toRope(rstnodeToRefname(n)), t,
                     toRope(chr(n.level-1+ord('A'))+'')]);
end;

function renderRstToRst(d: PDoc; n: PRstNode): PRope; forward;

function renderRstSons(d: PDoc; n: PRstNode): PRope;
var
  i: int;
begin
  result := nil;
  for i := 0 to rsonsLen(n)-1 do app(result, renderRstToRst(d, n.sons[i]));
end;

function renderRstToRst(d: PDoc; n: PRstNode): PRope;
// this is needed for the index generation; it may also be useful for
// debugging, but most code is already debugged...
const
  lvlToChar: array [0..8] of char = ('!', '=', '-', '~', '`',
                                     '<', '*', '|', '+');
var
  L: int;
  ind: PRope;
begin
  result := nil;
  if n = nil then exit;
  ind := toRope(repeatChar(d.indent));
  case n.kind of
    rnInner: result := renderRstSons(d, n);
    rnHeadline: begin
      result := renderRstSons(d, n);
      L := ropeLen(result);
      result := ropef('$n$1$2$n$1$3', [ind, result,
                      toRope(repeatChar(L, lvlToChar[n.level]))]);
    end;
    rnOverline: begin
      result := renderRstSons(d, n);
      L := ropeLen(result);
      result := ropef('$n$1$3$n$1$2$n$1$3', [ind, result,
                      toRope(repeatChar(L, lvlToChar[n.level]))]);
    end;
    rnTransition:
      result := ropef('$n$n$1$2$n$n',
                     [ind, toRope(repeatChar(78-d.indent, '-'))]);
    rnParagraph: begin
      result := renderRstSons(d, n);
      result := ropef('$n$n$1$2', [ind, result]);
    end;
    rnBulletItem: begin
      inc(d.indent, 2);
      result := renderRstSons(d, n);
      if result <> nil then result := ropef('$n$1* $2', [ind, result]);
      dec(d.indent, 2);
    end;
    rnEnumItem: begin
      inc(d.indent, 4);
      result := renderRstSons(d, n);
      if result <> nil then result := ropef('$n$1(#) $2', [ind, result]);
      dec(d.indent, 4);
    end;
    rnOptionList, rnFieldList, rnDefList, rnDefItem, rnLineBlock, rnFieldName,
    rnFieldBody, rnStandaloneHyperlink, rnBulletList, rnEnumList:
      result := renderRstSons(d, n);
    rnDefName: begin
      result := renderRstSons(d, n);
      result := ropef('$n$n$1$2', [ind, result]);
    end;
    rnDefBody: begin
      inc(d.indent, 2);
      result := renderRstSons(d, n);
      if n.sons[0].kind <> rnBulletList then
        result := ropef('$n$1  $2', [ind, result]);
      dec(d.indent, 2);
    end;
    rnField: begin
      result := renderRstToRst(d, n.sons[0]);
      L := max(ropeLen(result)+3, 30);
      inc(d.indent, L);
      result := ropef('$n$1:$2:$3$4', [
        ind, result, toRope(repeatChar(L-ropeLen(result)-2)),
        renderRstToRst(d, n.sons[1])]);
      dec(d.indent, L);
    end;
    rnLineBlockItem: begin
      result := renderRstSons(d, n);
      result := ropef('$n$1| $2', [ind, result]);
    end;
    rnBlockQuote: begin
      inc(d.indent, 2);
      result := renderRstSons(d, n);
      dec(d.indent, 2);
    end;
    rnRef: begin
      result := renderRstSons(d, n);
      result := ropef('`$1`_', [result]);
    end;
    rnHyperlink: begin
      result := ropef('`$1 <$2>`_', [renderRstToRst(d, n.sons[0]),
                                     renderRstToRst(d, n.sons[1])]);
    end;
    rnGeneralRole: begin
      result := renderRstToRst(d, n.sons[0]);
      result := ropef('`$1`:$2:', [result, renderRstToRst(d, n.sons[1])]);
    end;
    rnSub: begin
      result := renderRstSons(d, n);
      result := ropef('`$1`:sub:', [result]);
    end;
    rnSup: begin
      result := renderRstSons(d, n);
      result := ropef('`$1`:sup:', [result]);
    end;
    rnIdx: begin
      result := renderRstSons(d, n);
      result := ropef('`$1`:idx:', [result]);
    end;
    rnEmphasis: begin
      result := renderRstSons(d, n);
      result := ropef('*$1*', [result]);
    end;
    rnStrongEmphasis: begin
      result := renderRstSons(d, n);
      result := ropef('**$1**', [result]);
    end;
    rnInterpretedText: begin
      result := renderRstSons(d, n);
      result := ropef('`$1`', [result]);
    end;
    rnInlineLiteral: begin
      inc(d.verbatim);
      result := renderRstSons(d, n);
      result := ropef('``$1``', [result]);
      dec(d.verbatim);
    end;
    rnLeaf: begin
      if (d.verbatim = 0) and (n.text = '\'+'') then
        result := toRope('\\') // XXX: escape more special characters!
      else
        result := toRope(n.text);
    end;
    rnIndex: begin
      inc(d.indent, 3);
      if n.sons[2] <> nil then
        result := renderRstSons(d, n.sons[2]);
      dec(d.indent, 3);
      result := ropef('$n$n$1.. index::$n$2', [ind, result]);
    end;
    rnContents: begin
      result := ropef('$n$n$1.. contents::', [ind]);
    end;
    else rawMessage(errCannotRenderX, rstnodeKindToStr[n.kind]);
  end;
end;

function renderTocEntry(d: PDoc; const e: TTocEntry): PRope;
begin
  result := dispF(
    '<li><a class="reference" id="$1_toc" href="#$1">$2</a></li>$n',
    '\item\label{$1_toc} $2\ref{$1}$n',
    [e.refname, e.header]);
end;

function renderTocEntries(d: PDoc; var j: int; lvl: int): PRope;
var
  a: int;
begin
  result := nil;
  while (j <= high(d.tocPart)) do begin
    a := abs(d.tocPart[j].n.level);
    if (a = lvl) then begin
      app(result, renderTocEntry(d, d.tocPart[j]));
      inc(j);
    end
    else if (a > lvl) then
      app(result, renderTocEntries(d, j, a))
    else
      break
  end;
  if lvl > 1 then
    result := dispF('<ul class="simple">$1</ul>',
                    '\begin{enumerate}$1\end{enumerate}', [result]);
end;

function fieldAux(const s: string): PRope;
begin
  result := toRope(strip(s))
end;

function renderImage(d: PDoc; n: PRstNode): PRope;
var
  s, scale: string;
  options: PRope;
begin
  options := nil;
  s := getFieldValue(n, 'scale');
  if s <> '' then dispA(options, ' scale="$1"', ' scale=$1', [fieldAux(scale)]);
  
  s := getFieldValue(n, 'height');
  if s <> '' then dispA(options, ' height="$1"', ' height=$1', [fieldAux(s)]);
  
  s := getFieldValue(n, 'width');
  if s <> '' then dispA(options, ' width="$1"', ' width=$1', [fieldAux(s)]);
  
  s := getFieldValue(n, 'alt');
  if s <> '' then dispA(options, ' alt="$1"', '', [fieldAux(s)]);
  s := getFieldValue(n, 'align');
  if s <> '' then dispA(options, ' align="$1"', '', [fieldAux(s)]);
    
  if options <> nil then options := dispF('$1', '[$1]', [options]);
  result := dispF('<img src="$1"$2 />',
    '\includegraphics$2{$1}', [toRope(getArgument(n)), options]);
  if rsonsLen(n) >= 3 then app(result, renderRstToOut(d, n.sons[2]))
end;

function renderCodeBlock(d: PDoc; n: PRstNode): PRope;
var
  m: PRstNode;
  g: TGeneralTokenizer;
  langstr: string;
  lang: TSourceLanguage;
begin
  result := nil;
  if n.sons[2] = nil then exit;
  m := n.sons[2].sons[0];
  if (m.kind <> rnLeaf) then InternalError('renderCodeBlock');
  langstr := strip(getArgument(n));
  if langstr = '' then lang := langNimrod // default language
  else lang := getSourceLanguage(langstr);
  if lang = langNone then begin
    rawMessage(warnLanguageXNotSupported, langstr);
    result := toRope(m.text)
  end
  else begin
    initGeneralTokenizer(g, m.text);
    while true do begin
      getNextToken(g, lang);
      case g.kind of
        gtEof: break;
        gtNone, gtWhitespace: begin
          app(result, ncopy(m.text, g.start+strStart,
                            g.len+g.start-1+strStart))
        end
        else
          dispA(result,
                '<span class="$2">$1</span>',
                '\span$2{$1}',
                [toRope(esc(ncopy(m.text, g.start+strStart,
                                  g.len+g.start-1+strStart))),
                 toRope(tokenClassToStr[g.kind])]);
      end;
    end;
    deinitGeneralTokenizer(g);
  end;
  if result <> nil then
    result := dispF('<pre>$1</pre>', '\begin{rstpre}$n$1$n\end{rstpre}$n',
                    [result])
end;

function renderContainer(d: PDoc; n: PRstNode): PRope;
var
  arg: PRope;
begin
  result := renderRstToOut(d, n.sons[2]);
  arg := toRope(strip(getArgument(n)));
  if arg = nil then result := dispF('<div>$1</div>', '$1', [result])
  else result := dispF('<div class="$1">$2</div>', '$2', [arg, result])  
end;

function texColumns(n: PRstNode): string;
var
  i: int;
begin
  result := '';
  for i := 1 to rsonsLen(n) do add(result, '|X');
end;

function renderField(d: PDoc; n: PRstNode): PRope;
var
  fieldname: string;
  fieldval: PRope;
  b: bool;
begin
  b := false;
  if gCmd = cmdRst2Tex then begin
    fieldname := addNodes(n.sons[0]);
    fieldval := toRope(esc(strip(addNodes(n.sons[1]))));
    if cmpIgnoreStyle(fieldname, 'author') = 0 then begin
      if d.meta[metaAuthor] = nil then begin
        d.meta[metaAuthor] := fieldval;
        b := true
      end
    end
    else if cmpIgnoreStyle(fieldName, 'version') = 0 then begin
      if d.meta[metaVersion] = nil then begin
        d.meta[metaVersion] := fieldval;
        b := true
      end
    end
  end;
  if b then result := nil
  else result := renderAux(d, n, disp('<tr>$1</tr>$n', '$1'));
end;

function renderRstToOut(d: PDoc; n: PRstNode): PRope;
var
  i: int;
begin
  if n = nil then begin result := nil; exit end;
  case n.kind of
    rnInner: result := renderAux(d, n);
    rnHeadline: result := renderHeadline(d, n);
    rnOverline: result := renderOverline(d, n);
    rnTransition:
      result := renderAux(d, n, disp('<hr />'+nl, '\hrule'+nl));
    rnParagraph:
      result := renderAux(d, n, disp('<p>$1</p>'+nl, '$1$n$n'));
    rnBulletList:
      result := renderAux(d, n, disp('<ul class="simple">$1</ul>'+nl,
                                '\begin{itemize}$1\end{itemize}'+nl));
    rnBulletItem, rnEnumItem:
      result := renderAux(d, n, disp('<li>$1</li>'+nl, '\item $1'+nl));
    rnEnumList:
      result := renderAux(d, n, disp('<ol class="simple">$1</ol>'+nl,
                                     '\begin{enumerate}$1\end{enumerate}'+nl));
    rnDefList: 
      result := renderAux(d, n, disp('<dl class="docutils">$1</dl>'+nl,
                        '\begin{description}$1\end{description}'+nl));
    rnDefItem: 
      result := renderAux(d, n);
    rnDefName:
      result := renderAux(d, n, disp('<dt>$1</dt>'+nl, '\item[$1] '));
    rnDefBody:
      result := renderAux(d, n, disp('<dd>$1</dd>'+nl, '$1'+nl));
    rnFieldList: begin
      result := nil;
      for i := 0 to rsonsLen(n)-1 do app(result, renderRstToOut(d, n.sons[i]));
      if result <> nil then
        result := dispf('<table class="docinfo" frame="void" rules="none">' +
                        '<col class="docinfo-name" />' +
                        '<col class="docinfo-content" />' +
                        '<tbody valign="top">$1' +
                        '</tbody></table>',
                        '\begin{description}$1\end{description}'+nl, [result]);
    end;
    rnField: result := renderField(d, n);
    rnFieldName:
      result := renderAux(d, n, disp(
                  '<th class="docinfo-name">$1:</th>', '\item[$1:]'));
    rnFieldBody:
      result := renderAux(d, n, disp('<td>$1</td>', ' $1$n'));
    rnIndex:
      result := renderRstToOut(d, n.sons[2]);

    rnOptionList:
      result := renderAux(d, n, disp('<table frame="void">$1</table>',
                    '\begin{description}$n$1\end{description}'+nl));
    rnOptionListItem:
      result := renderAux(d, n, disp('<tr>$1</tr>$n', '$1'));
    rnOptionGroup:
      result := renderAux(d, n, disp('<th align="left">$1</th>', '\item[$1]'));
    rnDescription:
      result := renderAux(d, n, disp('<td align="left">$1</td>$n', ' $1$n'));
    rnOption,
    rnOptionString,
    rnOptionArgument: InternalError('renderRstToOut');

    rnLiteralBlock: 
      result := renderAux(d, n, disp('<pre>$1</pre>$n',
                                     '\begin{rstpre}$n$1$n\end{rstpre}$n'));
    rnQuotedLiteralBlock: InternalError('renderRstToOut');

    rnLineBlock: result := renderAux(d, n, disp('<p>$1</p>', '$1$n$n'));
    rnLineBlockItem: result := renderAux(d, n, disp('$1<br />', '$1\\$n'));

    rnBlockQuote:
      result := renderAux(d, n, disp('<blockquote><p>$1</p></blockquote>$n',
                                     '\begin{quote}$1\end{quote}$n'));

    rnTable, rnGridTable: begin
      result := renderAux(d, n,
                          disp('<table border="1" class="docutils">$1</table>',
                               '\begin{table}\begin{rsttab}{' +{&}
                               texColumns(n) +{&}
                               '|}$n\hline$n$1\end{rsttab}\end{table}'));
    end;
    rnTableRow: begin
      if rsonsLen(n) >= 1 then begin
        result := renderRstToOut(d, n.sons[0]);
        for i := 1 to rsonsLen(n)-1 do
          dispa(result, '$1', ' & $1', [renderRstToOut(d, n.sons[i])]);
        result := dispf('<tr>$1</tr>$n', '$1\\$n\hline$n', [result]);
      end
      else
        result := nil;
    end;
    rnTableDataCell: result := renderAux(d, n, disp('<td>$1</td>', '$1'));
    rnTableHeaderCell:
      result := renderAux(d, n, disp('<th>$1</th>', '\textbf{$1}'));

    rnLabel: InternalError('renderRstToOut'); // used for footnotes and other
    rnFootnote: InternalError('renderRstToOut'); // a footnote

    rnCitation: InternalError('renderRstToOut');    // similar to footnote
    rnRef: 
      result := dispF('<a class="reference external" href="#$2">$1</a>',
                      '$1\ref{$2}',
                      [renderAux(d, n), toRope(rstnodeToRefname(n))]);
    rnStandaloneHyperlink:
      result := renderAux(d, n, disp(
                    '<a class="reference external" href="$1">$1</a>',
                    '\href{$1}{$1}'));
    rnHyperlink: 
      result := dispF('<a class="reference external" href="$2">$1</a>',
                      '\href{$2}{$1}',
                      [renderRstToOut(d, n.sons[0]),
                       renderRstToOut(d, n.sons[1])]);
    rnDirArg, rnRaw: result := renderAux(d, n);
    rnImage, rnFigure: result := renderImage(d, n);
    rnCodeBlock: result := renderCodeBlock(d, n);
    rnContainer: result := renderContainer(d, n);
    rnSubstitutionReferences, rnSubstitutionDef:
      result := renderAux(d, n, disp('|$1|', '|$1|'));
    rnDirective: result := renderAux(d, n, '');

    // Inline markup:
    rnGeneralRole: 
      result := dispF('<span class="$2">$1</span>',
                      '\span$2{$1}',
                      [renderRstToOut(d, n.sons[0]),
                       renderRstToOut(d, n.sons[1])]);
    rnSub: result := renderAux(d, n, disp('<sub>$1</sub>', '\rstsub{$1}'));
    rnSup: result := renderAux(d, n, disp('<sup>$1</sup>', '\rstsup{$1}'));
    rnEmphasis: result := renderAux(d, n, disp('<em>$1</em>', '\emph{$1}'));
    rnStrongEmphasis:
      result := renderAux(d, n, disp('<strong>$1</strong>', '\textbf{$1}'));
    rnInterpretedText:
      result := renderAux(d, n, disp('<cite>$1</cite>', '\emph{$1}'));
    rnIdx: begin
      if d.theIndex = nil then
        result := renderAux(d, n, disp('<em>$1</em>', '\emph{$1}'))
      else
        result := renderIndexTerm(d, n);
    end;
    rnInlineLiteral:
      result := renderAux(d, n, disp(
        '<tt class="docutils literal"><span class="pre">$1</span></tt>',
        '\texttt{$1}'));
    rnLeaf: result := toRope(esc(n.text));
    rnContents: d.hasToc := true;
    rnTitle: d.meta[metaTitle] := renderRstToOut(d, n.sons[0]);
    else InternalError('renderRstToOut');
  end
end;

procedure generateDoc(d: PDoc; n: PNode);
var
  i: int;
begin
  if n = nil then exit;
  case n.kind of
    nkCommentStmt:  app(d.modDesc, genComment(d, n));
    nkProcDef:      genItem(d, n, n.sons[namePos], skProc);
    nkIteratorDef:  genItem(d, n, n.sons[namePos], skIterator);
    nkMacroDef:     genItem(d, n, n.sons[namePos], skMacro);
    nkTemplateDef:  genItem(d, n, n.sons[namePos], skTemplate);
    nkConverterDef: genItem(d, n, n.sons[namePos], skConverter);
    nkVarSection: begin
      for i := 0 to sonsLen(n)-1 do
        if n.sons[i].kind <> nkCommentStmt then
          genItem(d, n.sons[i], n.sons[i].sons[0], skVar);
    end;
    nkConstSection: begin
      for i := 0 to sonsLen(n)-1 do
        if n.sons[i].kind <> nkCommentStmt then
          genItem(d, n.sons[i], n.sons[i].sons[0], skConst);
    end;
    nkTypeSection: begin
      for i := 0 to sonsLen(n)-1 do
        if n.sons[i].kind <> nkCommentStmt then
          genItem(d, n.sons[i], n.sons[i].sons[0], skType);
    end;
    nkStmtList: begin
      for i := 0 to sonsLen(n)-1 do generateDoc(d, n.sons[i]);
    end;
    nkWhenStmt: begin
      // generate documentation for the first branch only:
      generateDoc(d, lastSon(n.sons[0]));
    end
    else begin end
  end
end;

procedure genSection(d: PDoc; kind: TSymKind);
var
  title: PRope;
begin
  if d.section[kind] = nil then exit;
  title := toRope(ncopy(symKindToStr[kind], strStart+2) + 's');
  d.section[kind] := ropeFormatNamedVars(getConfigVar('doc.section'),
    ['sectionid', 'sectionTitle', 'sectionTitleID', 'content'],
    [toRope(ord(kind)), title, toRope(ord(kind)+50), d.section[kind]]);
  d.toc[kind] := ropeFormatNamedVars(getConfigVar('doc.section.toc'),
    ['sectionid', 'sectionTitle', 'sectionTitleID', 'content'],
    [toRope(ord(kind)), title, toRope(ord(kind)+50), d.toc[kind]]);
end;

function genOutFile(d: PDoc): PRope;
var
  code, toc, title, content: PRope;
  bodyname: string;
  i: TSymKind;
  j: int;
begin
  j := 0;
  toc := renderTocEntries(d, j, 1);
  code := nil;
  content := nil;
  title := nil;
  for i := low(TSymKind) to high(TSymKind) do begin
    genSection(d, i);
    app(toc, d.toc[i]);
  end;
  if toc <> nil then
    toc := ropeFormatNamedVars(getConfigVar('doc.toc'), ['content'], [toc]);
  for i := low(TSymKind) to high(TSymKind) do app(code, d.section[i]);
  if d.meta[metaTitle] <> nil then
    title := d.meta[metaTitle]
  else
    title := toRope('Module ' + extractFilename(changeFileExt(d.filename, '')));
  if d.hasToc then
    bodyname := 'doc.body_toc'
  else
    bodyname := 'doc.body_no_toc';
  content := ropeFormatNamedVars(getConfigVar(bodyname),
    ['title', 'tableofcontents', 'moduledesc', 'date', 'time', 'content'],
    [title, toc, d.modDesc, toRope(getDateStr()), toRope(getClockStr()), code]);
  if not (optCompileOnly in gGlobalOptions) then
    code := ropeFormatNamedVars(getConfigVar('doc.file'),
      ['title', 'tableofcontents', 'moduledesc', 'date', 'time',
       'content', 'author', 'version'],
      [title, toc, d.modDesc, toRope(getDateStr()), toRope(getClockStr()),
       content, d.meta[metaAuthor], d.meta[metaVersion]])
  else
    code := content;
  result := code;
end;

procedure generateIndex(d: PDoc);
begin
  if d.theIndex <> nil then begin
    sortIndex(d.theIndex);
    writeRope(renderRstToRst(d, d.indexFile), gIndexFile);
  end
end;

procedure CommandDoc(const filename: string);
var
  ast: PNode;
  d: PDoc;
begin
  ast := parseFile(appendFileExt(filename, nimExt));
  if ast = nil then exit;
  d := newDocumentor(filename);
  initIndexFile(d);
  d.hasToc := true;
  generateDoc(d, ast);
  writeRope(genOutFile(d), getOutFile(filename, HtmlExt));
  generateIndex(d);
end;

procedure CommandRstAux(const filename, outExt: string);
var
  filen: string;
  d: PDoc;
  rst: PRstNode;
  code: PRope;
begin
  filen := appendFileExt(filename, 'txt');
  d := newDocumentor(filen);
  initIndexFile(d);
  rst := rstParse(readFile(filen), false, filen, 0, 1, d.hasToc);
  d.modDesc := renderRstToOut(d, rst);
  code := genOutFile(d);
  writeRope(code, getOutFile(filename, outExt));
  generateIndex(d);
end;

procedure CommandRst2Html(const filename: string);
begin
  CommandRstAux(filename, HtmlExt);
end;

procedure CommandRst2TeX(const filename: string);
begin
  splitter := '\-';
  CommandRstAux(filename, TexExt);
end;

end.
