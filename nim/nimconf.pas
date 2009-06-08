//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit nimconf;

// This module handles the reading of the config file.
{$include 'config.inc'}

interface

uses
  nsystem, llstream, nversion, commands, nos, strutils, msgs, platform, 
  condsyms, scanner, options, idents, wordrecg;
  
procedure LoadConfig(const project: string);

procedure LoadSpecialConfig(const configfilename: string);

implementation


// ---------------- configuration file parser -----------------------------
// we use Nimrod's scanner here to safe space and work

procedure ppGetTok(var L: TLexer; tok: PToken);
begin
  // simple filter
  rawGetTok(L, tok^);
  while (tok.tokType = tkInd) or (tok.tokType = tkSad)
      or (tok.tokType = tkDed) or (tok.tokType = tkComment) do
    rawGetTok(L, tok^)
end;

// simple preprocessor:
function parseExpr(var L: TLexer; tok: PToken): bool; forward;

function parseAtom(var L: TLexer; tok: PToken): bool;
begin
  if tok.tokType = tkParLe then begin
    ppGetTok(L, tok);
    result := parseExpr(L, tok);
    if tok.tokType = tkParRi then ppGetTok(L, tok)
    else lexMessage(L, errTokenExpected, ''')''')
  end
  else if tok.ident.id = ord(wNot) then begin
    ppGetTok(L, tok);
    result := not parseAtom(L, tok)
  end
  else begin
    result := isDefined(tok.ident);
    //condsyms.listSymbols();
    //writeln(tok.ident.s + ' has the value: ', result);
    ppGetTok(L, tok)
  end;
end;

function parseAndExpr(var L: TLexer; tok: PToken): bool;
var
  b: bool;
begin
  result := parseAtom(L, tok);
  while tok.ident.id = ord(wAnd) do begin
    ppGetTok(L, tok); // skip "and"
    b := parseAtom(L, tok);
    result := result and b;
  end
end;

function parseExpr(var L: TLexer; tok: PToken): bool;
var
  b: bool;
begin
  result := parseAndExpr(L, tok);
  while tok.ident.id = ord(wOr) do begin
    ppGetTok(L, tok); // skip "or"
    b := parseAndExpr(L, tok);
    result := result or b;
  end
end;

function EvalppIf(var L: TLexer; tok: PToken): bool;
begin
  ppGetTok(L, tok);  // skip 'if' or 'elif'
  result := parseExpr(L, tok);
  if tok.tokType = tkColon then ppGetTok(L, tok)
  else lexMessage(L, errTokenExpected, ''':''')
end;

var
  condStack: array of bool;
  
{@emit
  condStack := @[];
}

procedure doEnd(var L: TLexer; tok: PToken);
begin
  if high(condStack) < 0 then lexMessage(L, errTokenExpected, '@if');
  ppGetTok(L, tok); // skip 'end'
  setLength(condStack, high(condStack))
end;

type
  TJumpDest = (jdEndif, jdElseEndif);

procedure jumpToDirective(var L: TLexer; tok: PToken; dest: TJumpDest); forward;

procedure doElse(var L: TLexer; tok: PToken);
begin
  if high(condStack) < 0 then
    lexMessage(L, errTokenExpected, '@if');
  ppGetTok(L, tok);
  if tok.tokType = tkColon then ppGetTok(L, tok);
  if condStack[high(condStack)] then
    jumpToDirective(L, tok, jdEndif)
end;

procedure doElif(var L: TLexer; tok: PToken);
var
  res: bool;
begin
  if high(condStack) < 0 then
    lexMessage(L, errTokenExpected, '@if');
  res := EvalppIf(L, tok);
  if condStack[high(condStack)] or not res then
    jumpToDirective(L, tok, jdElseEndif)
  else
    condStack[high(condStack)] := true
end;

procedure jumpToDirective(var L: TLexer; tok: PToken; dest: TJumpDest);
var
  nestedIfs: int;
begin
  nestedIfs := 0;
  while True do begin
    if (tok.ident <> nil) and (tok.ident.s = '@'+'') then begin
      ppGetTok(L, tok);
      case whichKeyword(tok.ident) of
        wIf: Inc(nestedIfs);
        wElse: begin
          if (dest = jdElseEndif) and (nestedIfs = 0) then begin
            doElse(L, tok);
            break
          end
        end;
        wElif: begin
          if (dest = jdElseEndif) and (nestedIfs = 0) then begin
            doElif(L, tok);
            break
          end
        end;
        wEnd: begin
          if nestedIfs = 0 then begin
            doEnd(L, tok);
            break
          end;
          if nestedIfs > 0 then Dec(nestedIfs)
        end;
        else begin end;
      end;
      ppGetTok(L, tok)
    end
    else if tok.tokType = tkEof then
      lexMessage(L, errTokenExpected, '@end')
    else
      ppGetTok(L, tok)
  end
end;

procedure parseDirective(var L: TLexer; tok: PToken);
var
  res: bool;
  key: string;
begin
  ppGetTok(L, tok); // skip @
  case whichKeyword(tok.ident) of
    wIf: begin
      setLength(condStack, length(condStack)+1);
      res := EvalppIf(L, tok);
      condStack[high(condStack)] := res;
      if not res then // jump to "else", "elif" or "endif"
        jumpToDirective(L, tok, jdElseEndif)
    end;
    wElif: doElif(L, tok);
    wElse: doElse(L, tok);
    wEnd:  doEnd(L, tok);
    wWrite: begin
      ppGetTok(L, tok);
      msgs.MessageOut(tokToStr(tok));
      ppGetTok(L, tok)
    end;
    wPutEnv: begin
      ppGetTok(L, tok);
      key := tokToStr(tok);
      ppGetTok(L, tok);
      nos.putEnv(key, tokToStr(tok));
      ppGetTok(L, tok)
    end;
    wPrependEnv: begin
      ppGetTok(L, tok);
      key := tokToStr(tok);
      ppGetTok(L, tok);
      nos.putEnv(key, tokToStr(tok) +{&} nos.getenv(key));
      ppGetTok(L, tok)
    end;
    wAppendenv: begin
      ppGetTok(L, tok);
      key := tokToStr(tok);
      ppGetTok(L, tok);
      nos.putEnv(key, nos.getenv(key) +{&} tokToStr(tok));
      ppGetTok(L, tok)
    end
    else
      lexMessage(L, errUnknownDirective, tokToStr(tok))
  end
end;

procedure confTok(var L: TLexer; tok: PToken);
begin
  ppGetTok(L, tok);
  while (tok.ident <> nil) and (tok.ident.s = '@'+'') do
    parseDirective(L, tok)
  // else: give the token to the parser
end;

// ----------- end of preprocessor ----------------------------------------

procedure checkSymbol(const L: TLexer; tok: PToken);
begin
  if not (tok.tokType in [tkSymbol..pred(tkIntLit),
                          tkStrLit..tkTripleStrLit]) then
    lexMessage(L, errIdentifierExpected, tokToStr(tok))
end;

procedure parseAssignment(var L: TLexer; tok: PToken);
var
  s, val: string;
  info: TLineInfo;
begin
  if (tok.ident.id = getIdent('-'+'').id)
  or (tok.ident.id = getIdent('--').id) then
    confTok(L, tok); // skip unnecessary prefix
  info := getLineInfo(L); // safe for later in case of an error
  checkSymbol(L, tok);
  s := tokToStr(tok);
  confTok(L, tok); // skip symbol
  val := '';
  while tok.tokType = tkDot do begin
    addChar(s, '.');
    confTok(L, tok);
    checkSymbol(L, tok);
    add(s, tokToStr(tok));
    confTok(L, tok)
  end;
  if tok.tokType = tkBracketLe then begin
    // BUGFIX: val, not s!
    // BUGFIX: do not copy '['!
    confTok(L, tok);
    checkSymbol(L, tok);
    add(val, tokToStr(tok));
    confTok(L, tok);
    if tok.tokType = tkBracketRi then confTok(L, tok)
    else lexMessage(L, errTokenExpected, ''']''');
    addChar(val, ']');
  end;
  if (tok.tokType = tkColon) or (tok.tokType = tkEquals) then begin
    if length(val) > 0 then addChar(val, ':'); // BUGFIX
    confTok(L, tok); // skip ':' or '='
    checkSymbol(L, tok);
    add(val, tokToStr(tok));
    confTok(L, tok); // skip symbol
    while (tok.ident <> nil) and (tok.ident.id = getIdent('&'+'').id) do begin
      confTok(L, tok);
      checkSymbol(L, tok);
      add(val, tokToStr(tok));
      confTok(L, tok)
    end
  end;
  processSwitch(s, val, passPP, info)
end;

procedure readConfigFile(const filename: string);
var
  L: TLexer;
  tok: PToken;
  stream: PLLStream;
begin
  new(tok);
{@ignore}
  fillChar(tok^, sizeof(tok^), 0);
  fillChar(L, sizeof(L), 0);
{@emit}
  stream := LLStreamOpen(filename, fmRead);
  if stream <> nil then begin
    openLexer(L, filename, stream);
    tok.tokType := tkEof; // to avoid a pointless warning
    confTok(L, tok); // read in the first token
    while tok.tokType <> tkEof do
      parseAssignment(L, tok);
    if length(condStack) > 0 then
      lexMessage(L, errTokenExpected, '@end');
    closeLexer(L);
    if gVerbosity >= 1 then rawMessage(hintConf, filename);
  end
end;

// ------------------------------------------------------------------------

function getConfigPath(const filename: string): string;
begin
  // try local configuration file:
  result := joinPath(getConfigDir(), filename);
  if not ExistsFile(result) then begin
    // try standard configuration file (installation did not distribute files
    // the UNIX way)
    result := joinPath([getPrefixDir(), 'config', filename]);
    if not ExistsFile(result) then begin
      result := '/etc/' +{&} filename    
    end
  end
end;

procedure LoadSpecialConfig(const configfilename: string);
begin
  if not (optSkipConfigFile in gGlobalOptions) then 
    readConfigFile(getConfigPath(configfilename));
end;

procedure LoadConfig(const project: string);
var
  conffile, prefix: string;
begin
  // set default value (can be overwritten):
  if libpath = '' then begin
    // choose default libpath:
    prefix := getPrefixDir();
    if (prefix = '/usr') then
      libpath := '/usr/lib/nimrod'
    else if (prefix = '/usr/local') then
      libpath := '/usr/local/lib/nimrod'
    else
      libpath := joinPath(prefix, 'lib')
  end;
  // read default config file:
  LoadSpecialConfig('nimrod.cfg');
  // read project config file:
  if not (optSkipProjConfigFile in gGlobalOptions) and (project <> '') then begin
    conffile := changeFileExt(project, 'cfg');
    if existsFile(conffile) then
      readConfigFile(conffile)
  end
end;

end.
