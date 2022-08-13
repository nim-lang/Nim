discard """
  output: '''

[Suite] RST parsing

[Suite] RST indentation

[Suite] Warnings

[Suite] RST include directive

[Suite] RST escaping

[Suite] RST inline markup
'''
"""

# tests for rst module

import ../../lib/packages/docutils/rstgen
import ../../lib/packages/docutils/rst
import ../../lib/packages/docutils/rstast
import unittest, strutils
import std/private/miscdollars
import os

proc toAst(input: string,
            rstOptions: RstParseOptions = {roPreferMarkdown, roSupportMarkdown, roNimFile, roSandboxDisabled},
            error: ref string = nil,
            warnings: ref seq[string] = nil): string =
  ## If `error` is nil then no errors should be generated.
  ## The same goes for `warnings`.
  proc testMsgHandler(filename: string, line, col: int, msgkind: MsgKind,
                      arg: string) =
    let mc = msgkind.whichMsgClass
    let a = $msgkind % arg
    var message: string
    toLocation(message, filename, line, col + ColRstOffset)
    message.add " $1: $2" % [$mc, a]
    if mc == mcError:
      if error == nil:
        raise newException(EParseError, "[unexpected error] " & message)
      error[] = message
      # we check only first error because subsequent ones may be meaningless
      raise newException(EParseError, "")
    else:
      doAssert warnings != nil, "unexpected RST warning '" & message & "'"
      warnings[].add message
  try:
    const filen = "input"

    proc myFindFile(filename: string): string =
      # we don't find any files in online mode:
      result = ""

    var (rst, _, _) = rstParse(input, filen, line=LineRstInit, column=ColRstInit,
                               rstOptions, myFindFile, testMsgHandler)
    result = treeRepr(rst)
  except EParseError as e:
    if e.msg != "":
      result = e.msg

suite "RST parsing":
  test "option list has priority over definition list":
    check(dedent"""
        --defusages
                      file
        -o            set
        """.toAst ==
      dedent"""
        rnOptionList
          rnOptionListItem  order=1
            rnOptionGroup
              rnLeaf  '--'
              rnLeaf  'defusages'
            rnDescription
              rnInner
                rnLeaf  'file'
          rnOptionListItem  order=2
            rnOptionGroup
              rnLeaf  '-'
              rnLeaf  'o'
            rnDescription
              rnLeaf  'set'
        """)

  test "items of 1 option list can be separated by blank lines":
    check(dedent"""
        -a  desc1

        -b  desc2
        """.toAst ==
      dedent"""
        rnOptionList
          rnOptionListItem  order=1
            rnOptionGroup
              rnLeaf  '-'
              rnLeaf  'a'
            rnDescription
              rnLeaf  'desc1'
          rnOptionListItem  order=2
            rnOptionGroup
              rnLeaf  '-'
              rnLeaf  'b'
            rnDescription
              rnLeaf  'desc2'
      """)

  test "no blank line is required before or after Markdown code block":
    check(dedent"""
        Some text
        ```
        CodeBlock()
        ```
        Other text""".toAst ==
      dedent"""
        rnInner
          rnParagraph
            rnLeaf  'Some'
            rnLeaf  ' '
            rnLeaf  'text'
          rnParagraph
            rnCodeBlock
              [nil]
              [nil]
              rnLiteralBlock
                rnLeaf  '
        CodeBlock()
        '
            rnLeaf  ' '
            rnLeaf  'Other'
            rnLeaf  ' '
            rnLeaf  'text'
      """)

  test "option list has priority over definition list":
    check(dedent"""
        defName
            defBody

        -b  desc2
        """.toAst ==
      dedent"""
        rnInner
          rnDefList
            rnDefItem
              rnDefName
                rnLeaf  'defName'
              rnDefBody
                rnInner
                  rnLeaf  'defBody'
          rnOptionList
            rnOptionListItem  order=1
              rnOptionGroup
                rnLeaf  '-'
                rnLeaf  'b'
              rnDescription
                rnLeaf  'desc2'
      """)

  test "RST comment":
    check(dedent"""
        .. comment1
         comment2
        someParagraph""".toAst ==
      dedent"""
        rnLeaf  'someParagraph'
        """)

    check(dedent"""
        ..
         comment1
         comment2
        someParagraph""".toAst ==
      dedent"""
        rnLeaf  'someParagraph'
        """)

  test "check that additional line right after .. ends comment":
    check(dedent"""
        ..

         notAcomment1
         notAcomment2
        someParagraph""".toAst ==
      dedent"""
        rnInner
          rnBlockQuote
            rnInner
              rnLeaf  'notAcomment1'
              rnLeaf  ' '
              rnLeaf  'notAcomment2'
          rnParagraph
            rnLeaf  'someParagraph'
        """)

  test "but blank lines after 2nd non-empty line don't end the comment":
    check(dedent"""
        ..
           comment1


         comment2
        someParagraph""".toAst ==
      dedent"""
        rnLeaf  'someParagraph'
        """)

  test "using .. as separator b/w directives and block quotes":
    check(dedent"""
        .. note:: someNote

        ..

          someBlockQuote""".toAst ==
      dedent"""
        rnInner
          rnAdmonition  adType=note
            [nil]
            [nil]
            rnLeaf  'someNote'
          rnBlockQuote
            rnInner
              rnLeaf  'someBlockQuote'
        """)

  test "no redundant blank lines in literal blocks":
    check(dedent"""
      Check::


        code

      """.toAst ==
      dedent"""
        rnInner
          rnLeaf  'Check'
          rnLeaf  ':'
          rnLiteralBlock
            rnLeaf  'code'
      """)

suite "RST indentation":
  test "nested bullet lists":
    let input = dedent """
      * - bullet1
        - bullet2
      * - bullet3
        - bullet4
      """
    let output = input.toAst
    check(output == dedent"""
      rnBulletList
        rnBulletItem
          rnBulletList
            rnBulletItem
              rnInner
                rnLeaf  'bullet1'
            rnBulletItem
              rnInner
                rnLeaf  'bullet2'
        rnBulletItem
          rnBulletList
            rnBulletItem
              rnInner
                rnLeaf  'bullet3'
            rnBulletItem
              rnInner
                rnLeaf  'bullet4'
      """)

  test "nested markup blocks":
    let input = dedent"""
      #) .. Hint:: .. Error:: none
      #) .. Warning:: term0
                        Definition0
      #) some
         paragraph1
      #) term1
           Definition1
         term2
           Definition2
    """
    check(input.toAst == dedent"""
      rnEnumList  labelFmt=1)
        rnEnumItem
          rnAdmonition  adType=hint
            [nil]
            [nil]
            rnAdmonition  adType=error
              [nil]
              [nil]
              rnLeaf  'none'
        rnEnumItem
          rnAdmonition  adType=warning
            [nil]
            [nil]
            rnDefList
              rnDefItem
                rnDefName
                  rnLeaf  'term0'
                rnDefBody
                  rnInner
                    rnLeaf  'Definition0'
        rnEnumItem
          rnInner
            rnLeaf  'some'
            rnLeaf  ' '
            rnLeaf  'paragraph1'
        rnEnumItem
          rnDefList
            rnDefItem
              rnDefName
                rnLeaf  'term1'
              rnDefBody
                rnInner
                  rnLeaf  'Definition1'
            rnDefItem
              rnDefName
                rnLeaf  'term2'
              rnDefBody
                rnInner
                  rnLeaf  'Definition2'
      """)

  test "code-block parsing":
    let input1 = dedent"""
      .. code-block:: nim
          :test: "nim c $1"

        template additive(typ: typedesc) =
          discard
      """
    let input2 = dedent"""
      .. code-block:: nim
        :test: "nim c $1"

        template additive(typ: typedesc) =
          discard
      """
    let input3 = dedent"""
      .. code-block:: nim
         :test: "nim c $1"
         template additive(typ: typedesc) =
           discard
      """
    let inputWrong = dedent"""
      .. code-block:: nim
       :test: "nim c $1"

         template additive(typ: typedesc) =
           discard
      """
    let ast = dedent"""
      rnCodeBlock
        rnDirArg
          rnLeaf  'nim'
        rnFieldList
          rnField
            rnFieldName
              rnLeaf  'test'
            rnFieldBody
              rnInner
                rnLeaf  '"'
                rnLeaf  'nim'
                rnLeaf  ' '
                rnLeaf  'c'
                rnLeaf  ' '
                rnLeaf  '$'
                rnLeaf  '1'
                rnLeaf  '"'
          rnField
            rnFieldName
              rnLeaf  'default-language'
            rnFieldBody
              rnLeaf  'Nim'
        rnLiteralBlock
          rnLeaf  'template additive(typ: typedesc) =
        discard'
      """
    check input1.toAst == ast
    check input2.toAst == ast
    check input3.toAst == ast
    # "template..." should be parsed as a definition list attached to ":test:":
    check inputWrong.toAst != ast

suite "Warnings":
  test "warnings for broken footnotes/links/substitutions":
    let input = dedent"""
      firstParagraph

      footnoteRef [som]_

      link `a broken Link`_

      substitution |undefined subst|

      link short.link_

      lastParagraph
      """
    var warnings = new seq[string]
    let output = input.toAst(warnings=warnings)
    check(warnings[] == @[
        "input(3, 14) Warning: broken link 'citation-som'",
        "input(5, 7) Warning: broken link 'a-broken-link'",
        "input(7, 15) Warning: unknown substitution 'undefined subst'",
        "input(9, 6) Warning: broken link 'shortdotlink'"
        ])

  test "With include directive and blank lines at the beginning":
    "other.rst".writeFile(dedent"""


        firstParagraph

        here brokenLink_""")
    let input = ".. include:: other.rst"
    var warnings = new seq[string]
    let output = input.toAst(warnings=warnings)
    check warnings[] == @["other.rst(5, 6) Warning: broken link 'brokenlink'"]
    check(output == dedent"""
      rnInner
        rnParagraph
          rnLeaf  'firstParagraph'
        rnParagraph
          rnLeaf  'here'
          rnLeaf  ' '
          rnRef
            rnLeaf  'brokenLink'
      """)
    removeFile("other.rst")

suite "RST include directive":
  test "Include whole":
    "other.rst".writeFile("**test1**")
    let input = ".. include:: other.rst"
    doAssert "<strong>test1</strong>" == rstToHtml(input, {roSandboxDisabled}, defaultConfig())
    removeFile("other.rst")

  test "Include starting from":
    "other.rst".writeFile("""
And this should **NOT** be visible in `docs.html`
OtherStart
*Visible*
""")

    let input = """
.. include:: other.rst
             :start-after: OtherStart
"""
    check "<em>Visible</em>" == rstToHtml(input, {roSandboxDisabled}, defaultConfig())
    removeFile("other.rst")

  test "Include everything before":
    "other.rst".writeFile("""
*Visible*
OtherEnd
And this should **NOT** be visible in `docs.html`
""")

    let input = """
.. include:: other.rst
             :end-before: OtherEnd
"""
    doAssert "<em>Visible</em>" == rstToHtml(input, {roSandboxDisabled}, defaultConfig())
    removeFile("other.rst")


  test "Include everything between":
    "other.rst".writeFile("""
And this should **NOT** be visible in `docs.html`
OtherStart
*Visible*
OtherEnd
And this should **NOT** be visible in `docs.html`
""")

    let input = """
.. include:: other.rst
             :start-after: OtherStart
             :end-before: OtherEnd
"""
    check "<em>Visible</em>" == rstToHtml(input, {roSandboxDisabled}, defaultConfig())
    removeFile("other.rst")


  test "Ignore premature ending string":
    "other.rst".writeFile("""

OtherEnd
And this should **NOT** be visible in `docs.html`
OtherStart
*Visible*
OtherEnd
And this should **NOT** be visible in `docs.html`
""")

    let input = """
.. include:: other.rst
             :start-after: OtherStart
             :end-before: OtherEnd
"""
    doAssert "<em>Visible</em>" == rstToHtml(input, {roSandboxDisabled}, defaultConfig())
    removeFile("other.rst")

suite "RST escaping":
  test "backspaces":
    check("""\ this""".toAst == dedent"""
      rnLeaf  'this'
      """)

    check("""\\ this""".toAst == dedent"""
      rnInner
        rnLeaf  '\'
        rnLeaf  ' '
        rnLeaf  'this'
      """)

    check("""\\\ this""".toAst == dedent"""
      rnInner
        rnLeaf  '\'
        rnLeaf  'this'
      """)

    check("""\\\\ this""".toAst == dedent"""
      rnInner
        rnLeaf  '\'
        rnLeaf  '\'
        rnLeaf  ' '
        rnLeaf  'this'
      """)

suite "RST inline markup":
  test "* and ** surrounded by spaces are not inline markup":
    check("a * b * c ** d ** e".toAst == dedent"""
      rnInner
        rnLeaf  'a'
        rnLeaf  ' '
        rnLeaf  '*'
        rnLeaf  ' '
        rnLeaf  'b'
        rnLeaf  ' '
        rnLeaf  '*'
        rnLeaf  ' '
        rnLeaf  'c'
        rnLeaf  ' '
        rnLeaf  '**'
        rnLeaf  ' '
        rnLeaf  'd'
        rnLeaf  ' '
        rnLeaf  '**'
        rnLeaf  ' '
        rnLeaf  'e'
      """)

  test "end-string has repeating symbols":
    check("*emphasis content****".toAst == dedent"""
      rnEmphasis
        rnLeaf  'emphasis'
        rnLeaf  ' '
        rnLeaf  'content'
        rnLeaf  '***'
      """)

    check("""*emphasis content\****""".toAst == dedent"""
      rnEmphasis
        rnLeaf  'emphasis'
        rnLeaf  ' '
        rnLeaf  'content'
        rnLeaf  '*'
        rnLeaf  '**'
      """)  # exact configuration of leafs with * is not really essential,
            # only total number of * is essential

    check("**strong content****".toAst == dedent"""
      rnStrongEmphasis
        rnLeaf  'strong'
        rnLeaf  ' '
        rnLeaf  'content'
        rnLeaf  '**'
      """)

    check("""**strong content*\****""".toAst == dedent"""
      rnStrongEmphasis
        rnLeaf  'strong'
        rnLeaf  ' '
        rnLeaf  'content'
        rnLeaf  '*'
        rnLeaf  '*'
        rnLeaf  '*'
      """)

    check("``lit content`````".toAst == dedent"""
      rnInlineLiteral
        rnLeaf  'lit'
        rnLeaf  ' '
        rnLeaf  'content'
        rnLeaf  '```'
      """)

  test "interpreted text parsing: code fragments":
    check(dedent"""
        .. default-role:: option

        `--gc:refc`""".toAst ==
      dedent"""
        rnInner
          rnDefaultRole
            rnDirArg
              rnLeaf  'option'
            [nil]
            [nil]
          rnParagraph
            rnCodeFragment
              rnInner
                rnLeaf  '--'
                rnLeaf  'gc'
                rnLeaf  ':'
                rnLeaf  'refc'
              rnLeaf  'option'
        """)

  test """interpreted text can be ended with \` """:
    let output = (".. default-role:: literal\n" & """`\``""").toAst
    check(output.endsWith """
  rnParagraph
    rnInlineLiteral
      rnLeaf  '`'""" & "\n")

    let output2 = """`\``""".toAst
    check(output2 == dedent"""
      rnInlineCode
        rnDirArg
          rnLeaf  'nim'
        [nil]
        rnLiteralBlock
          rnLeaf  '`'
      """)

    let output3 = """`proc \`+\``""".toAst
    check(output3 == dedent"""
      rnInlineCode
        rnDirArg
          rnLeaf  'nim'
        [nil]
        rnLiteralBlock
          rnLeaf  'proc `+`'
      """)

    check("""`\\`""".toAst ==
      dedent"""
        rnInlineCode
          rnDirArg
            rnLeaf  'nim'
          [nil]
          rnLiteralBlock
            rnLeaf  '\\'
        """)

  test "Markdown-style code/backtick":
    # no whitespace is required before `
    check("`try`...`except`".toAst ==
      dedent"""
        rnInner
          rnInlineCode
            rnDirArg
              rnLeaf  'nim'
            [nil]
            rnLiteralBlock
              rnLeaf  'try'
          rnLeaf  '...'
          rnInlineCode
            rnDirArg
              rnLeaf  'nim'
            [nil]
            rnLiteralBlock
              rnLeaf  'except'
        """)


  test """inline literals can contain \ anywhere""":
    check("""``\``""".toAst == dedent"""
      rnInlineLiteral
        rnLeaf  '\'
      """)

    check("""``\\``""".toAst == dedent"""
      rnInlineLiteral
        rnLeaf  '\'
        rnLeaf  '\'
      """)

    check("""``\```""".toAst == dedent"""
      rnInlineLiteral
        rnLeaf  '\'
        rnLeaf  '`'
      """)

    check("""``\\```""".toAst == dedent"""
      rnInlineLiteral
        rnLeaf  '\'
        rnLeaf  '\'
        rnLeaf  '`'
      """)

    check("""``\````""".toAst == dedent"""
      rnInlineLiteral
        rnLeaf  '\'
        rnLeaf  '`'
        rnLeaf  '`'
      """)

  test "references with _ at the end":
    check(dedent"""
      .. _lnk: https

      lnk_""".toAst ==
      dedent"""
        rnHyperlink
          rnInner
            rnLeaf  'lnk'
          rnInner
            rnLeaf  'https'
      """)

  test "not a hyper link":
    check(dedent"""
      .. _lnk: https

      lnk___""".toAst ==
      dedent"""
        rnInner
          rnLeaf  'lnk'
          rnLeaf  '___'
      """)

  test "no punctuation in the end of a standalone URI is allowed":
    check(dedent"""
        [see (http://no.org)], end""".toAst ==
      dedent"""
        rnInner
          rnLeaf  '['
          rnLeaf  'see'
          rnLeaf  ' '
          rnLeaf  '('
          rnStandaloneHyperlink
            rnLeaf  'http://no.org'
          rnLeaf  ')'
          rnLeaf  ']'
          rnLeaf  ','
          rnLeaf  ' '
          rnLeaf  'end'
        """)

    # but `/` at the end is OK
    check(
      dedent"""
        See http://no.org/ end""".toAst ==
      dedent"""
        rnInner
          rnLeaf  'See'
          rnLeaf  ' '
          rnStandaloneHyperlink
            rnLeaf  'http://no.org/'
          rnLeaf  ' '
          rnLeaf  'end'
        """)

    # a more complex URL with some made-up ending '&='.
    # Github Markdown would include final &= and
    # so would rst2html.py in contradiction with RST spec.
    check(
      dedent"""
        See https://www.google.com/url?sa=t&source=web&cd=&cad=rja&url=https%3A%2F%2Fnim-lang.github.io%2FNim%2Frst.html%23features&usg=AO&= end""".toAst ==
      dedent"""
        rnInner
          rnLeaf  'See'
          rnLeaf  ' '
          rnStandaloneHyperlink
            rnLeaf  'https://www.google.com/url?sa=t&source=web&cd=&cad=rja&url=https%3A%2F%2Fnim-lang.github.io%2FNim%2Frst.html%23features&usg=AO'
          rnLeaf  '&'
          rnLeaf  '='
          rnLeaf  ' '
          rnLeaf  'end'
        """)

  test "URL with balanced parentheses (Markdown rule)":
    # 2 balanced parens, 1 unbalanced:
    check(dedent"""
        https://en.wikipedia.org/wiki/APL_((programming_language)))""".toAst ==
      dedent"""
        rnInner
          rnStandaloneHyperlink
            rnLeaf  'https://en.wikipedia.org/wiki/APL_((programming_language))'
          rnLeaf  ')'
      """)

    # the same for Markdown-style link:
    check(dedent"""
        [foo [bar]](https://en.wikipedia.org/wiki/APL_((programming_language))))""".toAst ==
      dedent"""
        rnInner
          rnHyperlink
            rnLeaf  'foo [bar]'
            rnLeaf  'https://en.wikipedia.org/wiki/APL_((programming_language))'
          rnLeaf  ')'
      """)

    # unbalanced (here behavior is more RST-like actually):
    check(dedent"""
        https://en.wikipedia.org/wiki/APL_(programming_language(""".toAst ==
      dedent"""
        rnInner
          rnStandaloneHyperlink
            rnLeaf  'https://en.wikipedia.org/wiki/APL_(programming_language'
          rnLeaf  '('
      """)

    # unbalanced [, but still acceptable:
    check(dedent"""
        [my {link example](http://example.com/bracket_(symbol_[))""".toAst ==
      dedent"""
        rnHyperlink
          rnLeaf  'my {link example'
          rnLeaf  'http://example.com/bracket_(symbol_[)'
      """)
