import
  llstream, strutils, ast, options, pathutils

import filters

type
  ## where we are in the parse process?
  MarkdownState = enum Began, Blank, Code, Markdown
  ## the myriad ways in which to frame markdown
  MarkdownRender = enum WrapComments, OmitMarkdown
  ## if so configured, how do we comment out markdown when we find it?
  MarkdownStyle = enum
    NoComments = ""
    MultilineDocs = "##["
    Documentation = "##"
    BlockComment = "#["
    LineComment = "#"
  LiterateInput = enum EmptyLine, Literate, Source
  # results of examining an input line
  LiterateForm = tuple[input: LiterateInput; valid: bool; indent: string]
  # results of examining an input line
  LiterateChunk = tuple[lineNum: int; valid: bool; text: string]

proc literately(line: string; spaces: var int): LiterateForm =
  ## classify input lines and store the detected indent
  # (source code starts with a tab or 4+ spaces)
  if line == "":
    return (input: EmptyLine, valid: true, indent: "")
  if line.startsWith("\t"):
    return (input: Source, valid: true, indent: "\t")
  # detect indent, grow it, or catch errors with this ugly mess
  if spaces < 4:
    if line.startsWith("    "):
      spaces = 4
      while line.high >= spaces and line[spaces] == ' ':
        spaces.inc
      return (input: Source, valid: true, indent: line[line.low..spaces - 1])
  elif line.startsWith(spaces.spaces):
    return (input: Source, valid: true, indent: line[line.low..spaces - 1])
  elif line.startsWith(4.spaces):
    return (input: Source, valid: false, indent: spaces.spaces)
  return (input: Literate, valid: true, indent: "")

proc dedent(form: LiterateForm; line: string): string =
  ## strip leading indent from a line of source code
  result = if form.input == Literate:
    line
  elif line.len > form.indent.len:
    line[form.indent.len..^1]
  else:
    ""
proc openComment(style: MarkdownStyle): string =
  ## render the opening of a comment in a single-line
  result = case style:
  of MultilineDocs, BlockComment: $style
  of NoComments, Documentation, LineComment: ""

proc closeComment(style: MarkdownStyle): string =
  ## suffix the comment text in single-line comments
  result = case style:
  of MultilineDocs: "]##"
  of BlockComment: "]#"
  of NoComments, Documentation, LineComment: ""

proc openCommentBlock(style: MarkdownStyle): string =
  ## prefix the comment text & locate comment block openers on an empty line
  result = case style:
  of MultilineDocs, BlockComment: style.openComment & "\n"
  of NoComments, Documentation, LineComment: "\n" & style.openComment

proc closeCommentBlock(style: MarkdownStyle): string =
  ## all block closures are identically trivial at the moment
  result = style.closeComment

proc commentBody(style: MarkdownStyle; body: string): string =
  ## single-line representation of a comment
  result = case style:
  of MultilineDocs, BlockComment: body
  of NoComments: ""
  of Documentation, LineComment: $style & " " & body

template validChunk(lineNum: int; s: string): LiterateChunk =
  ## yield a dressed chunk of text that is acceptable source
  (lineNum: lineNum, valid: true, text: s)

template validLine(lineNum: var int; s: string): LiterateChunk =
  ## yield a dressed line of text that is acceptable source
  lineNum.inc
  (lineNum: lineNum, valid: true, text: s & "\n")

template invalidLine(lineNum: var int; s: string): LiterateChunk =
  ## bubble up a warning to the compiler than input is invalid
  (lineNum: lineNum, valid: false, text: "{.warning: \"" & s & "\".}\n")

iterator literateFree(input: PLLStream;
  render=OmitMarkdown; style=NoComments): LiterateChunk =
  ## yield chunks of input stream which may be parsed as source code
  var
    lineNum = 0
    numSpaces = 0
    line = newStringOfCap(80)
    state: MarkdownState = Began

  defer:
    # what to do when we terminate in various states
    case render:
    of OmitMarkdown: discard
    of WrapComments:
      case state:
      of Blank:
        yield lineNum.validLine("")
      of Began, Code: discard
      of Markdown:
        yield lineNum.validLine(style.closeCommentBlock)
        yield lineNum.invalidLine(
          "Use a blank line both before and after markdown blocks.")

  while input.llStreamReadLine(line):
    # see what kind of line we're dealing with, and make sure the indent
    # hasn't magically shrunk due to invalid input
    var form: LiterateForm = line.literately(spaces = numSpaces)
    if not form.valid:
        yield lineNum.invalidLine(
          "Parse error with literate input; did your source indent change?")

    case render:
    # first, trivially omitting markdown from the output
    of OmitMarkdown:
      case form.input:
      of Source:
        yield lineNum.validLine(form.dedent(line))
      of EmptyLine, Literate:
        yield lineNum.validLine("")

    # we need to wrap our markdown with comments in the source, so we try to
    # steal opportunities to use empty lines to host multiline comment syntax;
    # it's important that the input and output source line numbers match up!
    of WrapComments:
      case form.input:
      of EmptyLine:
        # per above, empty lines demand special treatment
        case state:
        of Began, Code:
          discard
        of Blank:
          yield lineNum.validLine("")
        of Markdown:
          yield lineNum.validLine(style.closeCommentBlock)
        state = Blank

      of Literate:
        # the line is markdown (unindented), but first,
        if state == Began and line.startsWith("#?"):
          # a special hack if it looks like we are running on source code file
          # input with magic source code filter syntax in the first line
          state = Code
        else:
          case state:
          of Began:
            # we have to re-use the line, sadly, but it beats warning the user
            yield lineNum.validLine(style.openComment & style.commentBody(line))
          of Code:
            yield lineNum.invalidLine(
              "Use a blank line between code and the adjacent markdown block.")
            yield lineNum.validLine(style.openComment & style.commentBody(line))
          of Blank:
            yield lineNum.validChunk(style.openCommentBlock)
            yield lineNum.validLine(style.commentBody(line))
          of Markdown:
            yield lineNum.validLine(style.commentBody(line))
          state = Markdown

      of Source:
        # the line is indented source code
        case state:
        of Began, Code, Blank:
          yield lineNum.validLine(form.dedent(line))
        of Markdown:
          yield lineNum.validLine(style.closeCommentBlock)
          yield lineNum.invalidLine(
            "Use a blank line between markdown and the adjacent code block.")
          yield lineNum.validLine(form.dedent(line))
        state = Code

proc filterLiterate*(conf: ConfigRef; stdin: PLLStream, filename: AbsoluteFile, call: PNode): PLLStream =
  var
    render: MarkdownRender = OmitMarkdown
    style: MarkdownStyle = NoComments
    stylin = strArg(conf, call, "style", 1, "")

  # elide markdown from the output unless we can parse the comment style, so
  # that we don't risk breaking source should the compiler change
  if stylin != "":
    for s in MarkdownStyle.low..MarkdownStyle.high:
      if $s != stylin:
        continue
      style = s
      render = WrapComments
      break
  result = llStreamOpen("")
  for chunk in stdin.literateFree(render, style):
    # we might want to do something special when `not chunk.valid`...
    llStreamWrite(result, chunk.text)
  llStreamClose(stdin)
