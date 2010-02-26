# Does the config parsing for us

import 
  parsecfg, strtabs, strutils
  
type
  TTokenClass* = enum
    gtBackground,
    gtNone,
    gtWhitespace,
    gtDecNumber,
    gtBinNumber,
    gtHexNumber,
    gtOctNumber,
    gtFloatNumber,
    gtIdentifier,
    gtKeyword,
    gtStringLit,
    gtLongStringLit,
    gtCharLit,
    gtEscapeSequence,
    gtOperator,
    gtPunctation,
    gtComment,
    gtLongComment,
    gtRegularExpression,
    gtTagStart,
    gtTagEnd,
    gtKey,
    gtValue,
    gtRawData,
    gtAssembler,
    gtPreprocessor,
    gtDirective,
    gtCommand,
    gtRule,
    gtHyperlink,
    gtLabel,
    gtReference,
    gtOther,
    gtCursor

  TColor* = colKeywords, colIdentifiers, colComments
  TConfiguration* = object of TObject       ## the configuration object
    colors*: array [TTokenClass] of TColor  ## the colors to use
    filelist*: seq[string]                  ## the filelist
  
const
  colWhite = 0x00ffffff # rgb
  colBlack = 0x00000000
  colYellow = 
  
proc readConfig(filename: string): TConfiguration = 
  # fill with reasonable defaults:
  result.filelist = []
  result.colors[gtBackground] = colWhite
     gtNone: 
    gtWhitespace,
    gtDecNumber,
    gtBinNumber,
    gtHexNumber,
    gtOctNumber,
    gtFloatNumber,
    gtIdentifier,
    gtKeyword,
    gtStringLit,
    gtLongStringLit,
    gtCharLit,
    gtEscapeSequence,
    gtOperator,
    gtPunctation,
    gtComment,
    gtLongComment,
    gtRegularExpression,
    gtTagStart,
    gtTagEnd,
    gtKey,
    gtValue,
    gtRawData,
    gtAssembler,
    gtPreprocessor,
    gtDirective,
    gtCommand,
    gtRule,
    gtHyperlink,
    gtLabel,
    gtReference,
    gtOther
    gtCursor
  var
    p: TCfgParser
  if open(p, filename):
  
