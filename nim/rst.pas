//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit rst;

// This module implements a *reStructuredText* parser. Currently, only a
// subset is provided. Later, there will be additions.

interface

{$include 'config.inc'}

uses
  nsystem, nos, msgs, strutils, platform, nhashes, ropes, charsets, options;

type
  TRstNodeKind = (
    rnInner,       // an inner node or a root
    rnHeadline,    // a headline
    rnOverline,    // an over- and underlined headline
    rnTransition,  // a transition (the ------------- <hr> thingie)
    rnParagraph,   // a paragraph

    rnBulletList,  // a bullet list
    rnBulletItem,  // a bullet item
    rnEnumList,    // an enumerated list
    rnEnumItem,    // an enumerated item

    rnDefList,     // a definition list
    rnDefItem,     // an item of a definition list consisting of ...
    rnDefName,     // ... a name part ...
    rnDefBody,     // ... and a body part ...

    rnFieldList,   // a field list
    rnField,       // a field item
    rnFieldName,   // consisting of a field name ...
    rnFieldBody,   // ... and a field body

    rnOptionList,
    rnOptionListItem,
    rnOptionGroup,
    rnOption,
    rnOptionString,
    rnOptionArgument,
    rnDescription,

    rnLiteralBlock,
    rnQuotedLiteralBlock,

    rnLineBlock,   // the | thingie
    rnLineBlockItem, // sons of the | thing

    rnBlockQuote,  // text just indented

    rnTable,
    rnGridTable,
    rnTableRow,
    rnTableHeaderCell,
    rnTableDataCell,

    rnLabel,       // used for footnotes and other things
    rnFootnote,    // a footnote

    rnCitation,    // similar to footnote

    rnStandaloneHyperlink,
    rnHyperlink,
    rnRef,
    rnDirective,   // a directive
    rnDirArg,
    rnRaw,
    rnTitle,
    rnContents,
    rnImage,
    rnFigure,
    rnCodeBlock,
    rnContainer,   // ``container`` directive
    rnIndex,       // index directve:
                   // .. index::
                   //   key
                   //     * `file#id <file#id>`_
                   //     * `file#id <file#id>'_

    rnSubstitutionDef,  // a definition of a substitution

    rnGeneralRole,
    // Inline markup:
    rnSub,
    rnSup,
    rnIdx,
    rnEmphasis,         // "*"
    rnStrongEmphasis,   // "**"
    rnInterpretedText,  // "`"
    rnInlineLiteral,    // "``"
    rnSubstitutionReferences, // "|"

    rnLeaf              // a leaf; the node's text field contains the leaf val
  );
const
  rstnodekindToStr: array [TRstNodeKind] of string = (
    'Inner', 'Headline', 'Overline', 'Transition', 'Paragraph',
    'BulletList', 'BulletItem', 'EnumList', 'EnumItem', 'DefList', 'DefItem',
    'DefName', 'DefBody', 'FieldList', 'Field', 'FieldName', 'FieldBody',
    'OptionList', 'OptionListItem', 'OptionGroup', 'Option', 'OptionString',
    'OptionArgument', 'Description', 'LiteralBlock', 'QuotedLiteralBlock',
    'LineBlock', 'LineBlockItem', 'BlockQuote', 'Table', 'GridTable',
    'TableRow', 'TableHeaderCell', 'TableDataCell', 'Label', 'Footnote',
    'Citation', 'StandaloneHyperlink', 'Hyperlink', 'Ref', 'Directive',
    'DirArg', 'Raw', 'Title', 'Contents', 'Image', 'Figure', 'CodeBlock',
    'Container', 'Index', 'SubstitutionDef', 'GeneralRole', 
    'Sub', 'Sup', 'Idx', 'Emphasis', 'StrongEmphasis', 'InterpretedText', 
    'InlineLiteral', 'SubstitutionReferences', 'Leaf'
  );

type
  // the syntax tree of RST:
  PRSTNode = ^TRstNode;
  TRstNodeSeq = array of PRstNode;
  TRSTNode = record
    kind: TRstNodeKind;
    text: string;      // valid for leafs in the AST; and the title of
                       // the document or the section
    level: int;        // valid for some node kinds
    sons: TRstNodeSeq; // the node's sons
  end {@acyclic};


function rstParse(const text: string; // the text to be parsed
                  skipPounds: bool;
                  const filename: string; // for error messages
                  line, column: int;
                  var hasToc: bool): PRstNode;
function rsonsLen(n: PRstNode): int;
function newRstNode(kind: TRstNodeKind): PRstNode; overload;
function newRstNode(kind: TRstNodeKind; const s: string): PRstNode; overload;
procedure addSon(father, son: PRstNode);

function rstnodeToRefname(n: PRstNode): string;

function addNodes(n: PRstNode): string;

function getFieldValue(n: PRstNode; const fieldname: string): string;
function getArgument(n: PRstNode): string;

// index handling:
procedure setIndexPair(index, key, val: PRstNode);
procedure sortIndex(a: PRstNode);
procedure clearIndex(index: PRstNode; const filename: string);


implementation

// ----------------------------- scanner part --------------------------------

const
  SymChars: TCharSet = ['a'..'z', 'A'..'Z', '0'..'9', #128..#255];

type
  TTokType = (tkEof, tkIndent, tkWhite, tkWord, tkAdornment, tkPunct, tkOther);
  TToken = record            // a RST token
    kind: TTokType;          // the type of the token
    ival: int;               // the indentation or parsed integer value
    symbol: string;          // the parsed symbol as string
    line, col: int;          // line and column of the token
  end;
  TTokenSeq = array of TToken;
  TLexer = object(NObject)
    buf: PChar;
    bufpos: int;
    line, col, baseIndent: int;
    skipPounds: bool;
  end;

procedure getThing(var L: TLexer; var tok: TToken; const s: TCharSet);
var
  pos: int;
begin
  tok.kind := tkWord;
  tok.line := L.line;
  tok.col := L.col;
  pos := L.bufpos;
  while True do begin
    addChar(tok.symbol, L.buf[pos]);
    inc(pos);
    if not (L.buf[pos] in s) then break
  end;
  inc(L.col, pos - L.bufpos);
  L.bufpos := pos;
end;

procedure getAdornment(var L: TLexer; var tok: TToken);
var
  pos: int;
  c: char;
begin
  tok.kind := tkAdornment;
  tok.line := L.line;
  tok.col := L.col;
  pos := L.bufpos;
  c := L.buf[pos];
  while True do begin
    addChar(tok.symbol, L.buf[pos]);
    inc(pos);
    if L.buf[pos] <> c then break
  end;
  inc(L.col, pos - L.bufpos);
  L.bufpos := pos
end;

function getIndentAux(var L: TLexer; start: int): int;
var
  buf: PChar;
  pos: int;
begin
  pos := start;
  buf := L.buf;
  // skip the newline (but include it in the token!)
  if buf[pos] = #13 then begin
    if buf[pos+1] = #10 then inc(pos, 2) else inc(pos);
  end
  else if buf[pos] = #10 then inc(pos);
  if L.skipPounds then begin
    if buf[pos] = '#' then inc(pos);
    if buf[pos] = '#' then inc(pos);
  end;
  result := 0;
  while True do begin
    case buf[pos] of
      ' ', #11, #12: begin
        inc(pos);
        inc(result);
      end;
      #9: begin
        inc(pos);
        result := result - (result mod 8) + 8;
      end;
      else break; // EndOfFile also leaves the loop
    end;
  end;
  if buf[pos] = #0 then result := 0
  else if (buf[pos] = #10) or (buf[pos] = #13) then begin
    // look at the next line for proper indentation:
    result := getIndentAux(L, pos);
  end;
  L.bufpos := pos; // no need to set back buf
end;

procedure getIndent(var L: TLexer; var tok: TToken);
begin
  inc(L.line);
  tok.line := L.line;
  tok.col := 0;
  tok.kind := tkIndent;
  // skip the newline (but include it in the token!)
  tok.ival := getIndentAux(L, L.bufpos);
  L.col := tok.ival;
  tok.ival := max(tok.ival - L.baseIndent, 0);
  tok.symbol := nl +{&} repeatChar(tok.ival);
end;

procedure rawGetTok(var L: TLexer; var tok: TToken);
var
  c: Char;
begin
  tok.symbol := '';
  tok.ival := 0;
  c := L.buf[L.bufpos];
  case c of
    'a'..'z', 'A'..'Z', #128..#255, '0'..'9': getThing(L, tok, SymChars);
    ' ', #9, #11, #12: begin
      getThing(L, tok, {@set}[' ', #9]);
      tok.kind := tkWhite;
      if L.buf[L.bufpos] in [#13, #10] then
        rawGetTok(L, tok); // ignore spaces before \n
    end;
    #13, #10: getIndent(L, tok);
    '!', '"', '#', '$', '%', '&', '''',
    '(', ')', '*', '+', ',', '-', '.', '/',
    ':', ';', '<', '=', '>', '?', '@', '[', '\', ']',
    '^', '_', '`', '{', '|', '}', '~': begin
      getAdornment(L, tok);
      if length(tok.symbol) <= 3 then tok.kind := tkPunct;
    end;
    else begin
      tok.line := L.line;
      tok.col := L.col;
      if c = #0 then
        tok.kind := tkEof
      else begin
        tok.kind := tkOther;
        addChar(tok.symbol, c);
        inc(L.bufpos);
        inc(L.col);
      end
    end
  end;
  tok.col := max(tok.col - L.baseIndent, 0);
end;

procedure getTokens(const buffer: string; skipPounds: bool;
                    var tokens: TTokenSeq);
var
  L: TLexer;
  len: int;
begin
{@ignore}
  fillChar(L, sizeof(L), 0);
{@emit}
  len := length(tokens);
  L.buf := PChar(buffer);
  L.line := 1;
  L.skipPounds := skipPounds;
  if skipPounds then begin
    if L.buf[L.bufpos] = '#' then inc(L.bufpos);
    if L.buf[L.bufpos] = '#' then inc(L.bufpos);
    L.baseIndent := 0;
    while L.buf[L.bufpos] = ' ' do begin
      inc(L.bufpos);
      inc(L.baseIndent);
    end
  end;
  while true do begin
    inc(len);
    setLength(tokens, len);
    rawGetTok(L, tokens[len-1]);
    if tokens[len-1].kind = tkEof then break;
  end;
  if tokens[0].kind = tkWhite then begin // BUGFIX
    tokens[0].ival := length(tokens[0].symbol);
    tokens[0].kind := tkIndent
  end
end;

// --------------------------------------------------------------------------

procedure addSon(father, son: PRstNode);
var
  L: int;
begin
  L := length(father.sons);
  setLength(father.sons, L+1);
  father.sons[L] := son;
end;

procedure addSonIfNotNil(father, son: PRstNode);
begin
  if son <> nil then addSon(father, son);
end;

function rsonsLen(n: PRstNode): int;
begin
  result := length(n.sons)
end;

function newRstNode(kind: TRstNodeKind): PRstNode; overload;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit
  result.sons := @[];
}
  result.kind := kind;
end;

function newRstNode(kind: TRstNodeKind; const s: string): PRstNode; overload;
begin
  result := newRstNode(kind);
  result.text := s;
end;

// ---------------------------------------------------------------------------
type
  TLevelMap = array [Char] of int;
  TSubstitution = record
    key: string;
    value: PRstNode;
  end;
  TSharedState = record
    uLevel, oLevel: int; // counters for the section levels
    subs: array of TSubstitution; // substitutions
    refs: array of TSubstitution; // references
    underlineToLevel: TLevelMap;
    // Saves for each possible title adornment character its level in the
    // current document. This is for single underline adornments.
    overlineToLevel: TLevelMap;
    // Saves for each possible title adornment character its level in the
    // current document. This is for over-underline adornments.
  end;
  PSharedState = ^TSharedState;
  TRstParser = object(NObject)
    idx: int;
    tok: TTokenSeq;
    s: PSharedState;
    indentStack: array of int;
    filename: string;
    line, col: int;
    hasToc: bool;
  end;

function newSharedState(): PSharedState;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  {@emit
  result.subs := @[];}
  {@emit
  result.refs := @[];}
end;

function tokInfo(const p: TRstParser; const tok: TToken): TLineInfo;
begin
  result := newLineInfo(p.filename, p.line+tok.line, p.col+tok.col);
end;

procedure rstMessage(const p: TRstParser; msgKind: TMsgKind;
                     const arg: string); overload;
begin
  liMessage(tokInfo(p, p.tok[p.idx]), msgKind, arg);
end;

procedure rstMessage(const p: TRstParser; msgKind: TMsgKind); overload;
begin
  liMessage(tokInfo(p, p.tok[p.idx]), msgKind, p.tok[p.idx].symbol);
end;

function currInd(const p: TRstParser): int;
begin
  result := p.indentStack[high(p.indentStack)];
end;

procedure pushInd(var p: TRstParser; ind: int);
var
  len: int;
begin
  len := length(p.indentStack);
  setLength(p.indentStack, len+1);
  p.indentStack[len] := ind;
end;

procedure popInd(var p: TRstParser);
begin
  if length(p.indentStack) > 1 then
    setLength(p.indentStack, length(p.indentStack)-1);
end;

procedure initParser(var p: TRstParser; sharedState: PSharedState);
begin
  {@ignore}
  fillChar(p, sizeof(p), 0);
  p.tok := nil;
  p.indentStack := nil;
  pushInd(p, 0);
  {@emit
  p.indentStack := @[0];}
  {@emit
  p.tok := @[];}
  p.idx := 0;
  p.filename := '';
  p.hasToc := false;
  p.col := 0;
  p.line := 1;
  p.s := sharedState;
end;

// ---------------------------------------------------------------

procedure addNodesAux(n: PRstNode; var result: string);
var
  i: int;
begin
  if n.kind = rnLeaf then
    add(result, n.text)
  else begin
    for i := 0 to rsonsLen(n)-1 do
      addNodesAux(n.sons[i], result)
  end
end;

function addNodes(n: PRstNode): string;
begin
  result := '';
  addNodesAux(n, result);
end;

procedure rstnodeToRefnameAux(n: PRstNode; var r: string; var b: bool);
var
  i: int;
begin
  if n.kind = rnLeaf then begin
    for i := strStart to length(n.text)+strStart-1 do begin
      case n.text[i] of
        '0'..'9': begin
          if b then begin addChar(r, '-'); b := false; end;
          // BUGFIX: HTML id's cannot start with a digit
          if length(r) = 0 then addChar(r, 'Z');
          addChar(r, n.text[i])
        end;
        'a'..'z': begin
          if b then begin addChar(r, '-'); b := false; end;
          addChar(r, n.text[i])
        end;
        'A'..'Z': begin
          if b then begin addChar(r, '-'); b := false; end;
          addChar(r, chr(ord(n.text[i]) - ord('A') + ord('a')));
        end;
        else if (length(r) > 0) then b := true;
      end
    end
  end
  else begin
    for i := 0 to rsonsLen(n)-1 do rstnodeToRefnameAux(n.sons[i], r, b)
  end
end;

function rstnodeToRefname(n: PRstNode): string;
var
  b: bool;
begin
  result := '';
  b := false;
  rstnodeToRefnameAux(n, result, b);
end;

function findSub(var p: TRstParser; n: PRstNode): int;
var
  key: string;
  i: int;
begin
  key := addNodes(n);
  // the spec says: if no exact match, try one without case distinction:
  for i := 0 to high(p.s.subs) do
    if key = p.s.subs[i].key then begin
      result := i; exit
    end;
  for i := 0 to high(p.s.subs) do
    if cmpIgnoreStyle(key, p.s.subs[i].key) = 0 then begin
      result := i; exit
    end;
  result := -1
end;

procedure setSub(var p: TRstParser; const key: string; value: PRstNode);
var
  i, len: int;
begin
  len := length(p.s.subs);
  for i := 0 to len-1 do
    if key = p.s.subs[i].key then begin
      p.s.subs[i].value := value; exit
    end;
  setLength(p.s.subs, len+1);
  p.s.subs[len].key := key;
  p.s.subs[len].value := value;
end;

procedure setRef(var p: TRstParser; const key: string; value: PRstNode);
var
  i, len: int;
begin
  len := length(p.s.refs);
  for i := 0 to len-1 do
    if key = p.s.refs[i].key then begin
      p.s.refs[i].value := value;
      rstMessage(p, warnRedefinitionOfLabel, key);
      exit
    end;
  setLength(p.s.refs, len+1);
  p.s.refs[len].key := key;
  p.s.refs[len].value := value;
end;

function findRef(var p: TRstParser; const key: string): PRstNode;
var
  i: int;
begin
  for i := 0 to high(p.s.refs) do
    if key = p.s.refs[i].key then begin
      result := p.s.refs[i].value; exit
    end;
  result := nil
end;

function cmpNodes(a, b: PRstNode): int;
var
  x, y: PRstNode;
begin
  assert(a.kind = rnDefItem);
  assert(b.kind = rnDefItem);
  x := a.sons[0];
  y := b.sons[0];
  result := cmpIgnoreStyle(addNodes(x), addNodes(y))
end;

procedure sortIndex(a: PRstNode);
// we use shellsort here; fast and simple
var
  N, i, j, h: int;
  v: PRstNode;
begin
  assert(a.kind = rnDefList);
  N := rsonsLen(a);
  h := 1; repeat h := 3*h+1; until h > N;
  repeat
    h := h div 3;
    for i := h to N-1 do begin
      v := a.sons[i]; j := i;
      while cmpNodes(a.sons[j-h], v) >= 0 do begin
        a.sons[j] := a.sons[j-h]; j := j - h;
        if j < h then break
      end;
      a.sons[j] := v;
    end;
  until h = 1
end;

function eqRstNodes(a, b: PRstNode): bool;
var
  i: int;
begin
  result := false;
  if a.kind <> b.kind then exit;
  if a.kind = rnLeaf then
    result := a.text = b.text
  else begin
    if rsonsLen(a) <> rsonsLen(b) then exit;
    for i := 0 to rsonsLen(a)-1 do
      if not eqRstNodes(a.sons[i], b.sons[i]) then exit;
    result := true
  end
end;

function matchesHyperlink(h: PRstNode; const filename: string): bool;
var
  s: string;
begin
  if h.kind = rnInner then begin
    assert(rsonsLen(h) = 1);
    result := matchesHyperlink(h.sons[0], filename)
  end
  else if h.kind = rnHyperlink then begin
    s := addNodes(h.sons[1]);
    if startsWith(s, filename) and (s[length(filename)+strStart] = '#') then
      result := true
    else
      result := false
  end
  else // this may happen in broken indexes!
    result := false
end;

procedure clearIndex(index: PRstNode; const filename: string);
var
  i, j, k, items, lastItem: int;
  val: PRstNode;
begin
  assert(index.kind = rnDefList);
  for i := 0 to rsonsLen(index)-1 do begin
    assert(index.sons[i].sons[1].kind = rnDefBody);
    val := index.sons[i].sons[1].sons[0];
    if val.kind = rnInner then val := val.sons[0];
    if val.kind = rnBulletList then begin
      items := rsonsLen(val);
      lastItem := -1; // save the last valid item index
      for j := 0 to rsonsLen(val)-1 do begin
        if val.sons[j] = nil then
          dec(items)
        else if matchesHyperlink(val.sons[j].sons[0], filename) then begin
          val.sons[j] := nil;
          dec(items)
        end
        else lastItem := j
      end;
      if items = 1 then // remove bullet list:
        index.sons[i].sons[1].sons[0] := val.sons[lastItem].sons[0]
      else if items = 0 then
        index.sons[i] := nil
    end
    else if matchesHyperlink(val, filename) then
      index.sons[i] := nil
  end;
  // remove nil nodes:
  k := 0;
  for i := 0 to rsonsLen(index)-1 do begin
    if index.sons[i] <> nil then begin
      if k <> i then index.sons[k] := index.sons[i];
      inc(k)
    end
  end;
  setLength(index.sons, k);
end;

procedure setIndexPair(index, key, val: PRstNode);
var
  i: int;
  e, a, b: PRstNode;
begin
  // writeln(rstnodekindToStr[key.kind], ': ', rstnodekindToStr[val.kind]);
  assert(index.kind = rnDefList);
  assert(key.kind <> rnDefName);
  a := newRstNode(rnDefName);
  addSon(a, key);

  for i := 0 to rsonsLen(index)-1 do begin
    if eqRstNodes(index.sons[i].sons[0], a) then begin
      assert(index.sons[i].sons[1].kind = rnDefBody);
      e := index.sons[i].sons[1].sons[0];
      if e.kind <> rnBulletList then begin
        e := newRstNode(rnBulletList);
        b := newRstNode(rnBulletItem);
        addSon(b, index.sons[i].sons[1].sons[0]);
        addSon(e, b);
        index.sons[i].sons[1].sons[0] := e;
      end;
      b := newRstNode(rnBulletItem);
      addSon(b, val);
      addSon(e, b);

      exit // key already exists
    end
  end;
  e := newRstNode(rnDefItem);
  assert(val.kind <> rnDefBody);
  b := newRstNode(rnDefBody);
  addSon(b, val);
  addSon(e, a);
  addSon(e, b);
  addSon(index, e);
end;

// ---------------------------------------------------------------------------

function newLeaf(var p: TRstParser): PRstNode;
begin
  result := newRstNode(rnLeaf, p.tok[p.idx].symbol)
end;

function getReferenceName(var p: TRstParser; const endStr: string): PRstNode;
var
  res: PRstNode;
begin
  res := newRstNode(rnInner);
  while true do begin
    case p.tok[p.idx].kind of
      tkWord, tkOther, tkWhite: addSon(res, newLeaf(p));
      tkPunct:
        if p.tok[p.idx].symbol = endStr then begin inc(p.idx); break end
        else addSon(res, newLeaf(p));
      else begin
        rstMessage(p, errXexpected, endStr);
        break
      end
    end;
    inc(p.idx);
  end;
  result := res;
end;

function untilEol(var p: TRstParser): PRstNode;
begin
  result := newRstNode(rnInner);
  while not (p.tok[p.idx].kind in [tkIndent, tkEof]) do begin
    addSon(result, newLeaf(p)); inc(p.idx);
  end
end;

procedure expect(var p: TRstParser; const tok: string);
begin
  if p.tok[p.idx].symbol = tok then inc(p.idx)
  else rstMessage(p, errXexpected, tok)
end;

(*
  From the specification:

  The inline markup start-string and end-string recognition rules are as
  follows. If any of the conditions are not met, the start-string or end-string
  will not be recognized or processed.

   1. Inline markup start-strings must start a text block or be immediately
      preceded by whitespace or one of:  ' " ( [ { < - / :
   2. Inline markup start-strings must be immediately followed by
      non-whitespace.
   3. Inline markup end-strings must be immediately preceded by non-whitespace.
   4. Inline markup end-strings must end a text block or be immediately
      followed by whitespace or one of: ' " ) ] } > - / : . , ; ! ? \
   5. If an inline markup start-string is immediately preceded by a single or
      double quote, "(", "[", "{", or "<", it must not be immediately followed
      by the corresponding single or double quote, ")", "]", "}", or ">".
   6. An inline markup end-string must be separated by at least one character
      from the start-string.
   7. An unescaped backslash preceding a start-string or end-string will
      disable markup recognition, except for the end-string of inline literals.
      See Escaping Mechanism above for details.
*)
function isInlineMarkupEnd(const p: TRstParser; const markup: string): bool;
begin
  result := p.tok[p.idx].symbol = markup;
  if not result then exit;
  // Rule 3:
  result := not (p.tok[p.idx-1].kind in [tkIndent, tkWhite]);
  if not result then exit;
  // Rule 4:
  result := (p.tok[p.idx+1].kind in [tkIndent, tkWhite, tkEof])
    or (p.tok[p.idx+1].symbol[strStart] in ['''', '"', ')', ']', '}', '>',
                                            '-', '/', '\', ':', '.', ',',
                                            ';', '!', '?', '_']);
  if not result then exit;
  // Rule 7:
  if p.idx > 0 then begin
    if (markup <> '``') and (p.tok[p.idx-1].symbol = '\'+'') then begin
      result := false
    end
  end
end;

function isInlineMarkupStart(const p: TRstParser; const markup: string): bool;
var
  c, d: Char;
begin
  result := p.tok[p.idx].symbol = markup;
  if not result then exit;
  // Rule 1:
  result := (p.idx = 0) or (p.tok[p.idx-1].kind in [tkIndent, tkWhite])
    or (p.tok[p.idx-1].symbol[strStart] in ['''', '"', '(', '[', '{', '<',
                                            '-', '/', ':', '_']);
  if not result then exit;
  // Rule 2:
  result := not (p.tok[p.idx+1].kind in [tkIndent, tkWhite, tkEof]);
  if not result then exit;
  // Rule 5 & 7:
  if p.idx > 0 then begin
    if p.tok[p.idx-1].symbol = '\'+'' then
      result := false
    else begin
      c := p.tok[p.idx-1].symbol[strStart];
      case c of
        '''', '"': d := c;
        '(': d := ')';
        '[': d := ']';
        '{': d := '}';
        '<': d := '>';
        else d := #0;
      end;
      if d <> #0 then
        result := p.tok[p.idx+1].symbol[strStart] <> d;
    end
  end
end;

procedure parseBackslash(var p: TRstParser; father: PRstNode);
begin
  assert(p.tok[p.idx].kind = tkPunct);
  if p.tok[p.idx].symbol = '\\' then begin
    addSon(father, newRstNode(rnLeaf, '\'+''));
    inc(p.idx);
  end
  else if p.tok[p.idx].symbol = '\'+'' then begin
    // XXX: Unicode?
    inc(p.idx);
    if p.tok[p.idx].kind <> tkWhite then addSon(father, newLeaf(p));
    inc(p.idx);
  end
  else begin
    addSon(father, newLeaf(p));
    inc(p.idx)
  end
end;

function match(const p: TRstParser; start: int; const expr: string): bool;
// regular expressions are:
// special char     exact match
// 'w'              tkWord
// ' '              tkWhite
// 'a'              tkAdornment
// 'i'              tkIndent
// 'p'              tkPunct
// 'T'              always true
// 'E'              whitespace, indent or eof
// 'e'              tkWord or '#' (for enumeration lists)
var
  i, j, last, len: int;
  c: char;
begin
  i := strStart;
  j := start;
  last := length(expr)+strStart-1;
  while i <= last do begin
    case expr[i] of
      'w': result := p.tok[j].kind = tkWord;
      ' ': result := p.tok[j].kind = tkWhite;
      'i': result := p.tok[j].kind = tkIndent;
      'p': result := p.tok[j].kind = tkPunct;
      'a': result := p.tok[j].kind = tkAdornment;
      'o': result := p.tok[j].kind = tkOther;
      'T': result := true;
      'E': result := p.tok[j].kind in [tkEof, tkWhite, tkIndent];
      'e': begin
        result := (p.tok[j].kind = tkWord) or (p.tok[j].symbol = '#'+'');
        if result then
          case p.tok[j].symbol[strStart] of
            'a'..'z', 'A'..'Z': result := length(p.tok[j].symbol) = 1;
            '0'..'9': result := allCharsInSet(p.tok[j].symbol, ['0'..'9']);
            else begin end
          end
      end
      else begin
        c := expr[i];
        len := 0;
        while (i <= last) and (expr[i] = c) do begin inc(i); inc(len) end;
        dec(i);
        result := (p.tok[j].kind in [tkPunct, tkAdornment])
          and (length(p.tok[j].symbol) = len)
          and (p.tok[j].symbol[strStart] = c);
      end
    end;
    if not result then exit;
    inc(j);
    inc(i)
  end;
  result := true
end;

procedure fixupEmbeddedRef(n, a, b: PRstNode);
var
  i, sep, incr: int;
begin
  sep := -1;
  for i := rsonsLen(n)-2 downto 0 do
    if n.sons[i].text = '<'+'' then begin sep := i; break end;
  if (sep > 0) and (n.sons[sep-1].text[strStart] = ' ') then incr := 2
  else incr := 1;
  for i := 0 to sep-incr do addSon(a, n.sons[i]);
  for i := sep+1 to rsonsLen(n)-2 do addSon(b, n.sons[i]);
end;

function parsePostfix(var p: TRstParser; n: PRstNode): PRstNode;
var
  a, b: PRstNode;
begin
  result := n;
  if isInlineMarkupEnd(p, '_'+'') then begin
    inc(p.idx);
    if (p.tok[p.idx-2].symbol ='`'+'')
    and (p.tok[p.idx-3].symbol = '>'+'') then begin
      a := newRstNode(rnInner);
      b := newRstNode(rnInner);
      fixupEmbeddedRef(n, a, b);
      if rsonsLen(a) = 0 then begin
        result := newRstNode(rnStandaloneHyperlink);
        addSon(result, b);
      end
      else begin
        result := newRstNode(rnHyperlink);
        addSon(result, a);
        addSon(result, b);
        setRef(p, rstnodeToRefname(a), b);
      end
    end
    else if n.kind = rnInterpretedText then
      n.kind := rnRef
    else begin
      result := newRstNode(rnRef);
      addSon(result, n);
    end;
  end
  else if match(p, p.idx, ':w:') then begin
    // a role:
    if p.tok[p.idx+1].symbol = 'idx' then
      n.kind := rnIdx
    else if p.tok[p.idx+1].symbol = 'literal' then
      n.kind := rnInlineLiteral
    else if p.tok[p.idx+1].symbol = 'strong' then
      n.kind := rnStrongEmphasis
    else if p.tok[p.idx+1].symbol = 'emphasis' then
      n.kind := rnEmphasis
    else if (p.tok[p.idx+1].symbol = 'sub')
         or (p.tok[p.idx+1].symbol = 'subscript') then
      n.kind := rnSub
    else if (p.tok[p.idx+1].symbol = 'sup')
         or (p.tok[p.idx+1].symbol = 'supscript') then
      n.kind := rnSup
    else begin
      result := newRstNode(rnGeneralRole);
      n.kind := rnInner;
      addSon(result, n);
      addSon(result, newRstNode(rnLeaf, p.tok[p.idx+1].symbol));
    end;
    inc(p.idx, 3)
  end
end;

function isURL(const p: TRstParser; i: int): bool;
begin
  result := (p.tok[i+1].symbol = ':'+'') and (p.tok[i+2].symbol = '//')
    and (p.tok[i+3].kind = tkWord) and (p.tok[i+4].symbol = '.'+'')
end;

procedure parseURL(var p: TRstParser; father: PRstNode);
var
  n: PRstNode;
begin
  //if p.tok[p.idx].symbol[strStart] = '<' then begin
  if isURL(p, p.idx) then begin
    n := newRstNode(rnStandaloneHyperlink);
    while true do begin
      case p.tok[p.idx].kind of
        tkWord, tkAdornment, tkOther: begin end;
        tkPunct: begin
          if not (p.tok[p.idx+1].kind in [tkWord, tkAdornment, tkOther, tkPunct])
          then break
        end
        else break
      end;
      addSon(n, newLeaf(p));
      inc(p.idx);
    end;
    addSon(father, n);
  end
  else begin
    n := newLeaf(p);
    inc(p.idx);
    if p.tok[p.idx].symbol = '_'+'' then n := parsePostfix(p, n);
    addSon(father, n);
  end
end;

procedure parseUntil(var p: TRstParser; father: PRstNode;
                     const postfix: string; interpretBackslash: bool);
begin
  while true do begin
    case p.tok[p.idx].kind of
      tkPunct: begin
        if isInlineMarkupEnd(p, postfix) then begin
          inc(p.idx);
          break;
        end
        else if interpretBackslash then
          parseBackslash(p, father)
        else begin
          addSon(father, newLeaf(p));
          inc(p.idx);
        end
      end;
      tkAdornment, tkWord, tkOther: begin
        addSon(father, newLeaf(p));
        inc(p.idx);
      end;
      tkIndent: begin
        addSon(father, newRstNode(rnLeaf, ' '+''));
        inc(p.idx);
        if p.tok[p.idx].kind = tkIndent then begin
          rstMessage(p, errXExpected, postfix);
          break
        end
      end;
      tkWhite: begin
        addSon(father, newRstNode(rnLeaf, ' '+''));
        inc(p.idx);
      end
      else
        rstMessage(p, errXExpected, postfix);
    end
  end
end;

procedure parseInline(var p: TRstParser; father: PRstNode);
var
  n: PRstNode;
begin
  case p.tok[p.idx].kind of
    tkPunct: begin
      if isInlineMarkupStart(p, '**') then begin
        inc(p.idx);
        n := newRstNode(rnStrongEmphasis);
        parseUntil(p, n, '**', true);
        addSon(father, n);
      end
      else if isInlineMarkupStart(p, '*'+'') then begin
        inc(p.idx);
        n := newRstNode(rnEmphasis);
        parseUntil(p, n, '*'+'', true);
        addSon(father, n);
      end
      else if isInlineMarkupStart(p, '``') then begin
        inc(p.idx);
        n := newRstNode(rnInlineLiteral);
        parseUntil(p, n, '``', false);
        addSon(father, n);
      end
      else if isInlineMarkupStart(p, '`'+'') then begin
        inc(p.idx);
        n := newRstNode(rnInterpretedText);
        parseUntil(p, n, '`'+'', true);
        n := parsePostfix(p, n);
        addSon(father, n);
      end
      else if isInlineMarkupStart(p, '|'+'') then begin
        inc(p.idx);
        n := newRstNode(rnSubstitutionReferences);
        parseUntil(p, n, '|'+'', false);
        addSon(father, n);
      end
      else begin
        parseBackslash(p, father);
      end;
    end;
    tkWord: parseURL(p, father);
    tkAdornment, tkOther, tkWhite: begin
      addSon(father, newLeaf(p));
      inc(p.idx);
    end
    else assert(false);
  end
end;

function getDirective(var p: TRstParser): string;
var
  j: int;
begin
  if (p.tok[p.idx].kind = tkWhite) and (p.tok[p.idx+1].kind = tkWord) then begin
    j := p.idx;
    inc(p.idx);
    result := p.tok[p.idx].symbol;
    inc(p.idx);
    while p.tok[p.idx].kind in [tkWord, tkPunct, tkAdornment, tkOther] do begin
      if p.tok[p.idx].symbol = '::' then break;
      add(result, p.tok[p.idx].symbol);
      inc(p.idx);
    end;
    if (p.tok[p.idx].kind = tkWhite) then inc(p.idx);
    if p.tok[p.idx].symbol = '::' then begin
      inc(p.idx);
      if (p.tok[p.idx].kind = tkWhite) then inc(p.idx);
    end
    else begin
      p.idx := j; // set back
      result := '' // error
    end
  end
  else
    result := '';
end;

function parseComment(var p: TRstParser): PRstNode;
var
  indent: int;
begin
  case p.tok[p.idx].kind of
    tkIndent, tkEof: begin
      if p.tok[p.idx+1].kind = tkIndent then begin
        inc(p.idx);
        // empty comment
      end
      else begin
        indent := p.tok[p.idx].ival;
        while True do begin
          case p.tok[p.idx].kind of
            tkEof: break;
            tkIndent: begin
              if (p.tok[p.idx].ival < indent) then break;
            end
            else begin end
          end;
          inc(p.idx)
        end
      end
    end
    else
      while not (p.tok[p.idx].kind in [tkIndent, tkEof]) do inc(p.idx);
  end;
  result := nil;
end;

type
  TDirKind = ( // must be ordered alphabetically!
    dkNone, dkAuthor, dkAuthors, dkCodeBlock, dkContainer,
    dkContents, dkFigure, dkImage, dkInclude, dkIndex, dkRaw, dkTitle
  );
const
  DirIds: array [0..11] of string = (
    '', 'author', 'authors', 'code-block', 'container',
    'contents', 'figure', 'image', 'include', 'index', 'raw', 'title'
  );

function getDirKind(const s: string): TDirKind;
var
  i: int;
begin
  i := binaryStrSearch(DirIds, s);
  if i >= 0 then result := TDirKind(i)
  else result := dkNone
end;

procedure parseLine(var p: TRstParser; father: PRstNode);
begin
  while True do begin
    case p.tok[p.idx].kind of
      tkWhite, tkWord, tkOther, tkPunct: parseInline(p, father);
      else break;
    end
  end
end;

procedure parseSection(var p: TRstParser; result: PRstNode); forward;

function parseField(var p: TRstParser): PRstNode;
var
  col, indent: int;
  fieldname, fieldbody: PRstNode;
begin
  result := newRstNode(rnField);
  col := p.tok[p.idx].col;
  inc(p.idx); // skip :
  fieldname := newRstNode(rnFieldname);
  parseUntil(p, fieldname, ':'+'', false);
  fieldbody := newRstNode(rnFieldbody);

  if p.tok[p.idx].kind <> tkIndent then
    parseLine(p, fieldbody);
  if p.tok[p.idx].kind = tkIndent then begin
    indent := p.tok[p.idx].ival;
    if indent > col then begin
      pushInd(p, indent);
      parseSection(p, fieldbody);
      popInd(p);
    end
  end;
  addSon(result, fieldname);
  addSon(result, fieldbody);
end;

function parseFields(var p: TRstParser): PRstNode;
var
  col: int;
begin
  result := nil;
  if (p.tok[p.idx].kind = tkIndent)
  and (p.tok[p.idx+1].symbol = ':'+'') then begin
    col := p.tok[p.idx].ival; // BUGFIX!
    result := newRstNode(rnFieldList);
    inc(p.idx);
    while true do begin
      addSon(result, parseField(p));
      if (p.tok[p.idx].kind = tkIndent) and (p.tok[p.idx].ival = col)
      and (p.tok[p.idx+1].symbol = ':'+'') then inc(p.idx)
      else break
    end
  end
end;

function getFieldValue(n: PRstNode; const fieldname: string): string;
var
  i: int;
  f: PRstNode;
begin
  result := '';
  if n.sons[1] = nil then exit;
  if (n.sons[1].kind <> rnFieldList) then
    InternalError('getFieldValue (2): ' + rstnodeKindToStr[n.sons[1].kind]);
  for i := 0 to rsonsLen(n.sons[1])-1 do begin
    f := n.sons[1].sons[i];
    if cmpIgnoreStyle(addNodes(f.sons[0]), fieldname) = 0 then begin
      result := addNodes(f.sons[1]);
      if result = '' then result := #1#1; // indicates that the field exists
      exit
    end
  end
end;

function getArgument(n: PRstNode): string;
begin
  if n.sons[0] = nil then result := ''
  else result := addNodes(n.sons[0]);
end;

function parseDotDot(var p: TRstParser): PRstNode; forward;

function parseLiteralBlock(var p: TRstParser): PRstNode;
var
  indent: int;
  n: PRstNode;
begin
  result := newRstNode(rnLiteralBlock);
  n := newRstNode(rnLeaf, '');
  if p.tok[p.idx].kind = tkIndent then begin
    indent := p.tok[p.idx].ival;
    inc(p.idx);
    while True do begin
      case p.tok[p.idx].kind of
        tkEof: break;
        tkIndent: begin
          if (p.tok[p.idx].ival < indent) then begin
            break;
          end
          else begin
            add(n.text, nl);
            add(n.text, repeatChar(p.tok[p.idx].ival - indent));
            inc(p.idx)
          end
        end
        else begin
          add(n.text, p.tok[p.idx].symbol);
          inc(p.idx)
        end
      end
    end
  end
  else begin
    while not (p.tok[p.idx].kind in [tkIndent, tkEof]) do begin
      add(n.text, p.tok[p.idx].symbol);
      inc(p.idx)
    end
  end;
  addSon(result, n);
end;

function getLevel(var map: TLevelMap; var lvl: int; c: Char): int;
begin
  if map[c] = 0 then begin
    inc(lvl);
    map[c] := lvl;
  end;
  result := map[c]
end;

function tokenAfterNewline(const p: TRstParser): int;
begin
  result := p.idx;
  while true do
    case p.tok[result].kind of
      tkEof: break;
      tkIndent: begin inc(result); break end;
      else inc(result)
    end
end;

// ---------------------------------------------------------------------------

function isLineBlock(const p: TRstParser): bool;
var
  j: int;
begin
  j := tokenAfterNewline(p);
  result := (p.tok[p.idx].col = p.tok[j].col) and (p.tok[j].symbol = '|'+'')
    or (p.tok[j].col > p.tok[p.idx].col)
end;

function predNL(const p: TRstParser): bool;
begin
  result := true;
  if (p.idx > 0) then
    result := (p.tok[p.idx-1].kind = tkIndent)
         and (p.tok[p.idx-1].ival = currInd(p))
end;

function isDefList(const p: TRstParser): bool;
var
  j: int;
begin
  j := tokenAfterNewline(p);
  result := (p.tok[p.idx].col < p.tok[j].col)
    and (p.tok[j].kind in [tkWord, tkOther, tkPunct])
    and (p.tok[j-2].symbol <> '::');
end;

function whichSection(const p: TRstParser): TRstNodeKind;
begin
  case p.tok[p.idx].kind of
    tkAdornment: begin
      if match(p, p.idx+1, 'ii') then result := rnTransition
      else if match(p, p.idx+1, ' a') then result := rnTable
      else if match(p, p.idx+1, 'i'+'') then result := rnOverline
      else result := rnLeaf
    end;
    tkPunct: begin
      if match(p, tokenAfterNewLine(p), 'ai') then
        result := rnHeadline
      else if p.tok[p.idx].symbol = '::' then
        result := rnLiteralBlock
      else if predNL(p)
          and ((p.tok[p.idx].symbol = '+'+'') or
          (p.tok[p.idx].symbol = '*'+'') or
          (p.tok[p.idx].symbol = '-'+''))
          and (p.tok[p.idx+1].kind = tkWhite) then
        result := rnBulletList
      else if (p.tok[p.idx].symbol = '|'+'') and isLineBlock(p) then
        result := rnLineBlock
      else if (p.tok[p.idx].symbol = '..') and predNL(p) then
        result := rnDirective
      else if (p.tok[p.idx].symbol = ':'+'') and predNL(p) then
        result := rnFieldList
      else if match(p, p.idx, '(e) ') then
        result := rnEnumList
      else if match(p, p.idx, '+a+') then begin
        result := rnGridTable;
        rstMessage(p, errGridTableNotImplemented);
      end
      else if isDefList(p) then
        result := rnDefList
      else if match(p, p.idx, '-w') or match(p, p.idx, '--w')
           or match(p, p.idx, '/w') then
        result := rnOptionList
      else
        result := rnParagraph
    end;
    tkWord, tkOther, tkWhite: begin
      if match(p, tokenAfterNewLine(p), 'ai') then
        result := rnHeadline
      else if isDefList(p) then
        result := rnDefList
      else if match(p, p.idx, 'e) ') or match(p, p.idx, 'e. ') then
        result := rnEnumList
      else
        result := rnParagraph;
    end;
    else result := rnLeaf;
  end
end;

function parseLineBlock(var p: TRstParser): PRstNode;
var
  col: int;
  item: PRstNode;
begin
  result := nil;
  if p.tok[p.idx+1].kind = tkWhite then begin
    col := p.tok[p.idx].col;
    result := newRstNode(rnLineBlock);
    pushInd(p, p.tok[p.idx+2].col);
    inc(p.idx, 2);
    while true do begin
      item := newRstNode(rnLineBlockItem);
      parseSection(p, item);
      addSon(result, item);
      if (p.tok[p.idx].kind = tkIndent) and (p.tok[p.idx].ival = col)
      and (p.tok[p.idx+1].symbol = '|'+'')
      and (p.tok[p.idx+2].kind = tkWhite) then inc(p.idx, 3)
      else break;
    end;
    popInd(p);
  end;
end;

procedure parseParagraph(var p: TRstParser; result: PRstNode);
begin
  while True do begin
    case p.tok[p.idx].kind of
      tkIndent: begin
        if p.tok[p.idx+1].kind = tkIndent then begin
          inc(p.idx);
          break
        end
        else if (p.tok[p.idx].ival = currInd(p)) then begin
          inc(p.idx);
          case whichSection(p) of
            rnParagraph, rnLeaf, rnHeadline, rnOverline, rnDirective:
              addSon(result, newRstNode(rnLeaf, ' '+''));
            rnLineBlock: addSonIfNotNil(result, parseLineBlock(p));
            else break;
          end;
        end
        else break
      end;
      tkPunct: begin
        if (p.tok[p.idx].symbol = '::') and (p.tok[p.idx+1].kind = tkIndent)
        and (currInd(p) < p.tok[p.idx+1].ival) then begin
          addSon(result, newRstNode(rnLeaf, ':'+''));
          inc(p.idx); // skip '::'
          addSon(result, parseLiteralBlock(p));
          break
        end
        else
          parseInline(p, result)
      end;
      tkWhite, tkWord, tkAdornment, tkOther:
        parseInline(p, result);
      else break;
    end
  end
end;

function parseParagraphWrapper(var p: TRstParser): PRstNode;
begin
  result := newRstNode(rnParagraph);
  parseParagraph(p, result);
end;

function parseHeadline(var p: TRstParser): PRstNode;
var
  c: Char;
begin
  result := newRstNode(rnHeadline);
  parseLine(p, result);
  assert(p.tok[p.idx].kind = tkIndent);
  assert(p.tok[p.idx+1].kind = tkAdornment);
  c := p.tok[p.idx+1].symbol[strStart];
  inc(p.idx, 2);
  result.level := getLevel(p.s.underlineToLevel, p.s.uLevel, c);
end;

type
  TIntSeq = array of int;

function tokEnd(const p: TRstParser): int;
begin
  result := p.tok[p.idx].col + length(p.tok[p.idx].symbol) - 1;
end;

procedure getColumns(var p: TRstParser; var cols: TIntSeq);
var
  L: int;
begin
  L := 0;
  while true do begin
    inc(L);
    setLength(cols, L);
    cols[L-1] := tokEnd(p);
    assert(p.tok[p.idx].kind = tkAdornment);
    inc(p.idx);
    if p.tok[p.idx].kind <> tkWhite then break;
    inc(p.idx);
    if p.tok[p.idx].kind <> tkAdornment then break
  end;
  if p.tok[p.idx].kind = tkIndent then inc(p.idx);
  // last column has no limit:
  cols[L-1] := 32000;
end;

function parseDoc(var p: TRstParser): PRstNode; forward;

function parseSimpleTable(var p: TRstParser): PRstNode;
var
  cols: TIntSeq;
  row: array of string;
  j, i, last, line: int;
  c: Char;
  q: TRstParser;
  a, b: PRstNode;
begin
  result := newRstNode(rnTable);
{@ignore}
  cols := nil;
  row := nil;
{@emit
  cols := @[];}
{@emit
  row := @[];}
  a := nil;
  c := p.tok[p.idx].symbol[strStart];
  while true do begin
    if p.tok[p.idx].kind = tkAdornment then begin
      last := tokenAfterNewline(p);
      if p.tok[last].kind in [tkEof, tkIndent] then begin
        // skip last adornment line:
        p.idx := last; break
      end;
      getColumns(p, cols);
      setLength(row, length(cols));
      if a <> nil then
        for j := 0 to rsonsLen(a)-1 do a.sons[j].kind := rnTableHeaderCell;
    end;
    if p.tok[p.idx].kind = tkEof then break;
    for j := 0 to high(row) do row[j] := '';
    // the following while loop iterates over the lines a single cell may span:
    line := p.tok[p.idx].line;
    while true do begin
      i := 0;
      while not (p.tok[p.idx].kind in [tkIndent, tkEof]) do begin
        if (tokEnd(p) <= cols[i]) then begin
          add(row[i], p.tok[p.idx].symbol);
          inc(p.idx);
        end
        else begin
          if p.tok[p.idx].kind = tkWhite then inc(p.idx);
          inc(i)
        end
      end;
      if p.tok[p.idx].kind = tkIndent then inc(p.idx);
      if tokEnd(p) <= cols[0] then break;
      if p.tok[p.idx].kind in [tkEof, tkAdornment] then break;
      for j := 1 to high(row) do addChar(row[j], #10);
    end;
    // process all the cells:
    a := newRstNode(rnTableRow);
    for j := 0 to high(row) do begin
      initParser(q, p.s);
      q.col := cols[j];
      q.line := line-1;
      q.filename := p.filename;
      getTokens(row[j], false, q.tok);
      b := newRstNode(rnTableDataCell);
      addSon(b, parseDoc(q));
      addSon(a, b);
    end;
    addSon(result, a);
  end;
end;

function parseTransition(var p: TRstParser): PRstNode;
begin
  result := newRstNode(rnTransition);
  inc(p.idx);
  if p.tok[p.idx].kind = tkIndent then inc(p.idx);
  if p.tok[p.idx].kind = tkIndent then inc(p.idx);
end;

function parseOverline(var p: TRstParser): PRstNode;
var
  c: char;
begin
  c := p.tok[p.idx].symbol[strStart];
  inc(p.idx, 2);
  result := newRstNode(rnOverline);
  while true do begin
    parseLine(p, result);
    if p.tok[p.idx].kind = tkIndent then begin
      inc(p.idx);
      if p.tok[p.idx-1].ival > currInd(p) then
        addSon(result, newRstNode(rnLeaf, ' '+''))
      else
        break
    end
    else break
  end;
  result.level := getLevel(p.s.overlineToLevel, p.s.oLevel, c);
  if p.tok[p.idx].kind = tkAdornment then begin
    inc(p.idx); // XXX: check?
    if p.tok[p.idx].kind = tkIndent then inc(p.idx);
  end
end;

function parseBulletList(var p: TRstParser): PRstNode;
var
  bullet: string;
  col: int;
  item: PRstNode;
begin
  result := nil;
  if p.tok[p.idx+1].kind = tkWhite then begin
    bullet := p.tok[p.idx].symbol;
    col := p.tok[p.idx].col;
    result := newRstNode(rnBulletList);
    pushInd(p, p.tok[p.idx+2].col);
    inc(p.idx, 2);
    while true do begin
      item := newRstNode(rnBulletItem);
      parseSection(p, item);
      addSon(result, item);
      if (p.tok[p.idx].kind = tkIndent) and (p.tok[p.idx].ival = col)
      and (p.tok[p.idx+1].symbol = bullet)
      and (p.tok[p.idx+2].kind = tkWhite) then inc(p.idx, 3)
      else break;
    end;
    popInd(p);
  end;
end;

function parseOptionList(var p: TRstParser): PRstNode;
var
  a, b, c: PRstNode;
  j: int;
begin
  result := newRstNode(rnOptionList);
  while true do begin
    if match(p, p.idx, '-w')
    or match(p, p.idx, '--w')
    or match(p, p.idx, '/w') then begin
      a := newRstNode(rnOptionGroup);
      b := newRstNode(rnDescription);
      c := newRstNode(rnOptionListItem);
      while not (p.tok[p.idx].kind in [tkIndent, tkEof]) do begin
        if (p.tok[p.idx].kind = tkWhite)
        and (length(p.tok[p.idx].symbol) > 1) then begin
          inc(p.idx); break
        end;
        addSon(a, newLeaf(p));
        inc(p.idx);
      end;
      j := tokenAfterNewline(p);
      if (j > 0) and (p.tok[j-1].kind = tkIndent)
      and (p.tok[j-1].ival > currInd(p)) then begin
        pushInd(p, p.tok[j-1].ival);
        parseSection(p, b);
        popInd(p);
      end
      else begin
        parseLine(p, b);
      end;
      if (p.tok[p.idx].kind = tkIndent) then inc(p.idx);
      addSon(c, a);
      addSon(c, b);
      addSon(result, c);
    end
    else break;
  end
end;

function parseDefinitionList(var p: TRstParser): PRstNode;
var
  j, col: int;
  a, b, c: PRstNode;
begin
  result := nil;
  j := tokenAfterNewLine(p)-1;
  if (j >= 1) and (p.tok[j].kind = tkIndent)
  and (p.tok[j].ival > currInd(p)) and (p.tok[j-1].symbol <> '::') then begin
    col := p.tok[p.idx].col;
    result := newRstNode(rnDefList);
    while true do begin
      j := p.idx;
      a := newRstNode(rnDefName);
      parseLine(p, a);
      //writeln('after def line: ', p.tok[p.idx].ival :1, '  ', col : 1);
      if (p.tok[p.idx].kind = tkIndent)
      and (p.tok[p.idx].ival > currInd(p))
      and (p.tok[p.idx+1].symbol <> '::')
      and not (p.tok[p.idx+1].kind in [tkIndent, tkEof]) then begin
        pushInd(p, p.tok[p.idx].ival);
        b := newRstNode(rnDefBody);
        parseSection(p, b);
        c := newRstNode(rnDefItem);
        addSon(c, a);
        addSon(c, b);
        addSon(result, c);
        popInd(p);
      end
      else begin
        p.idx := j;
        break
      end;
      if (p.tok[p.idx].kind = tkIndent) and (p.tok[p.idx].ival = col) then begin
        inc(p.idx);
        j := tokenAfterNewLine(p)-1;
        if (j >= 1) and (p.tok[j].kind = tkIndent)
        and (p.tok[j].ival > col)
        and (p.tok[j-1].symbol <> '::')
        and (p.tok[j+1].kind <> tkIndent) then begin end
        else break
      end
    end;
    if rsonsLen(result) = 0 then result := nil
  end
end;

function parseEnumList(var p: TRstParser): PRstNode;
const
  wildcards: array [0..2] of string = ('(e) ', 'e) ', 'e. ');
  wildpos: array [0..2] of int = (1, 0, 0);
var
  w, col, j: int;
  item: PRstNode;
begin
  result := nil;
  w := 0;
  while w <= 2 do begin
    if match(p, p.idx, wildcards[w]) then break;
    inc(w);
  end;
  if w <= 2 then begin
    col := p.tok[p.idx].col;
    result := newRstNode(rnEnumList);
    inc(p.idx, wildpos[w]+3);
    j := tokenAfterNewLine(p);
    if (p.tok[j].col = p.tok[p.idx].col) or match(p, j, wildcards[w]) then begin
      pushInd(p, p.tok[p.idx].col);
      while true do begin
        item := newRstNode(rnEnumItem);
        parseSection(p, item);
        addSon(result, item);
        if (p.tok[p.idx].kind = tkIndent)
        and (p.tok[p.idx].ival = col)
        and match(p, p.idx+1, wildcards[w]) then
          inc(p.idx, wildpos[w]+4)
        else
          break
      end;
      popInd(p);
    end
    else begin
      dec(p.idx, wildpos[w]+3);
      result := nil
    end
  end
end;

function sonKind(father: PRstNode; i: int): TRstNodeKind;
begin
  result := rnLeaf;
  if i < rsonsLen(father) then result := father.sons[i].kind;
end;

procedure parseSection(var p: TRstParser; result: PRstNode);
var
  a: PRstNode;
  k: TRstNodeKind;
  leave: bool;
begin
  while true do begin
    leave := false;
    assert(p.idx >= 0);
    while p.tok[p.idx].kind = tkIndent do begin
      if currInd(p) = p.tok[p.idx].ival then begin
        inc(p.idx);
      end
      else if p.tok[p.idx].ival > currInd(p) then begin
        pushInd(p, p.tok[p.idx].ival);
        a := newRstNode(rnBlockQuote);
        parseSection(p, a);
        addSon(result, a);
        popInd(p);
      end
      else begin
        leave := true;
        break;
      end
    end;
    if leave then break;
    if p.tok[p.idx].kind = tkEof then break;
    a := nil;
    k := whichSection(p);
    case k of
      rnLiteralBlock: begin
        inc(p.idx); // skip '::'
        a := parseLiteralBlock(p);
      end;
      rnBulletList: a := parseBulletList(p);
      rnLineblock: a := parseLineBlock(p);
      rnDirective: a := parseDotDot(p);
      rnEnumList: a := parseEnumList(p);
      rnLeaf: begin
        rstMessage(p, errNewSectionExpected);
      end;
      rnParagraph: begin end;
      rnDefList: a := parseDefinitionList(p);
      rnFieldList: begin
        dec(p.idx);
        a := parseFields(p);
      end;
      rnTransition: a := parseTransition(p);
      rnHeadline: a := parseHeadline(p);
      rnOverline: a := parseOverline(p);
      rnTable: a := parseSimpleTable(p);
      rnOptionList: a := parseOptionList(p);
      else InternalError('rst.parseSection()');
    end;
    if (a = nil) and (k <> rnDirective) then begin
      a := newRstNode(rnParagraph);
      parseParagraph(p, a);
    end;
    addSonIfNotNil(result, a);
  end;
  if (sonKind(result, 0) = rnParagraph)
  and (sonKind(result, 1) <> rnParagraph) then
    result.sons[0].kind := rnInner;
end;

function parseSectionWrapper(var p: TRstParser): PRstNode;
begin
  result := newRstNode(rnInner);
  parseSection(p, result);
  while (result.kind = rnInner) and (rsonsLen(result) = 1) do
    result := result.sons[0]
end;

function parseDoc(var p: TRstParser): PRstNode;
begin
  result := parseSectionWrapper(p);
  if p.tok[p.idx].kind <> tkEof then
    rstMessage(p, errGeneralParseError);
end;

type
  TDirFlag = (hasArg, hasOptions, argIsFile);
  TDirFlags = set of TDirFlag;
  TSectionParser = function (var p: TRstParser): PRstNode;

function parseDirective(var p: TRstParser; flags: TDirFlags;
                        contentParser: TSectionParser): PRstNode;
var
  args, options, content: PRstNode;
begin
  result := newRstNode(rnDirective);
  args := nil;
  options := nil;
  if hasArg in flags then begin
    args := newRstNode(rnDirArg);
    if argIsFile in flags then begin
      while True do begin
        case p.tok[p.idx].kind of
          tkWord, tkOther, tkPunct, tkAdornment: begin
            addSon(args, newLeaf(p));
            inc(p.idx);
          end;
          else break;
        end
      end
    end
    else begin
      parseLine(p, args);
    end
  end;
  addSon(result, args);
  if hasOptions in flags then begin
    if (p.tok[p.idx].kind = tkIndent) and (p.tok[p.idx].ival >= 3)
    and (p.tok[p.idx+1].symbol = ':'+'') then
      options := parseFields(p);
  end;
  addSon(result, options);
  if (assigned(contentParser)) and (p.tok[p.idx].kind = tkIndent)
  and (p.tok[p.idx].ival > currInd(p)) then begin
    pushInd(p, p.tok[p.idx].ival);
    content := contentParser(p);
    popInd(p);
    addSon(result, content)
  end
  else
    addSon(result, nil);
end;

function dirInclude(var p: TRstParser): PRstNode;
(*
The following options are recognized:

start-after : text to find in the external data file
    Only the content after the first occurrence of the specified text will
    be included.
end-before : text to find in the external data file
    Only the content before the first occurrence of the specified text
    (but after any after text) will be included.
literal : flag (empty)
    The entire included text is inserted into the document as a single
    literal block (useful for program listings).
encoding : name of text encoding
    The text encoding of the external data file. Defaults to the document's
    encoding (if specified).
*)
var
  n: PRstNode;
  filename, path: string;
  q: TRstParser;
begin
  result := nil;
  n := parseDirective(p, {@set}[hasArg, argIsFile, hasOptions], nil);
  filename := strip(addNodes(n.sons[0]));
  path := findFile(filename);
  if path = '' then
    rstMessage(p, errCannotOpenFile, filename)
  else begin
    // XXX: error handling; recursive file inclusion!
    if getFieldValue(n, 'literal') <> '' then begin
      result := newRstNode(rnLiteralBlock);
      addSon(result, newRstNode(rnLeaf, readFile(path)));
    end
    else begin
      initParser(q, p.s);
      q.filename := filename;
      getTokens(readFile(path), false, q.tok);
      // workaround a GCC bug: 
      if find(q.tok[high(q.tok)].symbol, #0#1#2) > 0 then begin
        InternalError('Too many binary zeros in include file');
      end;
      result := parseDoc(q);
    end
  end
end;

function dirCodeBlock(var p: TRstParser): PRstNode;
var
  n: PRstNode;
  filename, path: string;
begin
  result := parseDirective(p, {@set}[hasArg, hasOptions], parseLiteralBlock);
  filename := strip(getFieldValue(result, 'file'));
  if filename <> '' then begin
    path := findFile(filename);
    if path = '' then rstMessage(p, errCannotOpenFile, filename);
    n := newRstNode(rnLiteralBlock);
    addSon(n, newRstNode(rnLeaf, readFile(path)));
    result.sons[2] := n;
  end;
  result.kind := rnCodeBlock;
end;

function dirContainer(var p: TRstParser): PRstNode;
begin
  result := parseDirective(p, {@set}[hasArg], parseSectionWrapper);
  assert(result.kind = rnDirective);
  assert(rsonsLen(result) = 3);
  result.kind := rnContainer;
end;

function dirImage(var p: TRstParser): PRstNode;
begin
  result := parseDirective(p, {@set}[hasOptions, hasArg, argIsFile], nil);
  result.kind := rnImage
end;

function dirFigure(var p: TRstParser): PRstNode;
begin
  result := parseDirective(p, {@set}[hasOptions, hasArg, argIsFile],
                           parseSectionWrapper);
  result.kind := rnFigure
end;

function dirTitle(var p: TRstParser): PRstNode;
begin
  result := parseDirective(p, {@set}[hasArg], nil);
  result.kind := rnTitle
end;

function dirContents(var p: TRstParser): PRstNode;
begin
  result := parseDirective(p, {@set}[hasArg], nil);
  result.kind := rnContents
end;

function dirIndex(var p: TRstParser): PRstNode;
begin
  result := parseDirective(p, {@set}[], parseSectionWrapper);
  result.kind := rnIndex
end;

function dirRaw(var p: TRstParser): PRstNode;
(*
The following options are recognized:

file : string (newlines removed)
    The local filesystem path of a raw data file to be included.
url : string (whitespace removed)
    An Internet URL reference to a raw data file to be included.
encoding : name of text encoding
    The text encoding of the external raw data (file or URL).
    Defaults to the document's encoding (if specified).
*)
var
  filename, path, f: string;
begin
  result := parseDirective(p, {@set}[hasOptions], parseSectionWrapper);
  result.kind := rnRaw;
  filename := getFieldValue(result, 'file');
  if filename <> '' then begin
    path := findFile(filename);
    if path = '' then
      rstMessage(p, errCannotOpenFile, filename)
    else begin
      f := readFile(path);
      result := newRstNode(rnRaw);
      addSon(result, newRstNode(rnLeaf, f));
    end
  end
end;

function parseDotDot(var p: TRstParser): PRstNode;
var
  d: string;
  col: int;
  a, b: PRstNode;
begin
  result := nil;
  col := p.tok[p.idx].col;
  inc(p.idx);
  d := getDirective(p);
  if d <> '' then begin
    pushInd(p, col);
    case getDirKind(d) of
      dkInclude:    result := dirInclude(p);
      dkImage:      result := dirImage(p);
      dkFigure:     result := dirFigure(p);
      dkTitle:      result := dirTitle(p);
      dkContainer:  result := dirContainer(p);
      dkContents:   result := dirContents(p);
      dkRaw:        result := dirRaw(p);
      dkCodeblock:  result := dirCodeBlock(p);
      dkIndex:      result := dirIndex(p);
      else          rstMessage(p, errInvalidDirectiveX, d);
    end;
    popInd(p);
  end
  else if match(p, p.idx, ' _') then begin
    // hyperlink target:
    inc(p.idx, 2);
    a := getReferenceName(p, ':'+'');
    if p.tok[p.idx].kind = tkWhite then inc(p.idx);
    b := untilEol(p);
    setRef(p, rstnodeToRefname(a), b);
  end
  else if match(p, p.idx, ' |') then begin
    // substitution definitions:
    inc(p.idx, 2);
    a := getReferenceName(p, '|'+'');
    if p.tok[p.idx].kind = tkWhite then inc(p.idx);
    if cmpIgnoreStyle(p.tok[p.idx].symbol, 'replace') = 0 then begin
      inc(p.idx);
      expect(p, '::');
      b := untilEol(p);
    end
    else if cmpIgnoreStyle(p.tok[p.idx].symbol, 'image') = 0 then begin
      inc(p.idx);
      b := dirImage(p);
    end
    else
      rstMessage(p, errInvalidDirectiveX, p.tok[p.idx].symbol);
    setSub(p, addNodes(a), b);
  end
  else if match(p, p.idx, ' [') then begin
    // footnotes, citations
    inc(p.idx, 2);
    a := getReferenceName(p, ']'+'');
    if p.tok[p.idx].kind = tkWhite then inc(p.idx);
    b := untilEol(p);
    setRef(p, rstnodeToRefname(a), b);
  end
  else
    result := parseComment(p);
end;

function resolveSubs(var p: TRstParser; n: PRstNode): PRstNode;
var
  i, x: int;
  y: PRstNode;
  e, key: string;
begin
  result := n;
  if n = nil then exit;
  case n.kind of
    rnSubstitutionReferences: begin
      x := findSub(p, n);
      if x >= 0 then result := p.s.subs[x].value
      else begin
        key := addNodes(n);
        e := getEnv(key);
        if e <> '' then result := newRstNode(rnLeaf, e)
        else rstMessage(p, warnUnknownSubstitutionX, key);
      end
    end;
    rnRef: begin
      y := findRef(p, rstnodeToRefname(n));
      if y <> nil then begin
        result := newRstNode(rnHyperlink);
        n.kind := rnInner;
        addSon(result, n);
        addSon(result, y);
      end
    end;
    rnLeaf: begin end;
    rnContents: p.hasToc := true;
    else begin
      for i := 0 to rsonsLen(n)-1 do
        n.sons[i] := resolveSubs(p, n.sons[i]);
    end
  end
end;

function rstParse(const text: string; // the text to be parsed
                  skipPounds: bool;
                  const filename: string; // for error messages
                  line, column: int;
                  var hasToc: bool): PRstNode;
var
  p: TRstParser;
begin
  if isNil(text) then
    rawMessage(errCannotOpenFile, filename);
  initParser(p, newSharedState());
  p.filename := filename;
  p.line := line;
  p.col := column;
  getTokens(text, skipPounds, p.tok);
  result := resolveSubs(p, parseDoc(p));
  hasToc := p.hasToc;
end;

end.
