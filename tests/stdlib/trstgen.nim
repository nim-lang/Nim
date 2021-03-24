discard """
outputsub: ""
"""

# tests for rstgen module.

import ../../lib/packages/docutils/rstgen
import ../../lib/packages/docutils/rst
import unittest, strutils, strtabs
import std/private/miscdollars

proc toHtml(input: string,
            rstOptions: RstParseOptions = {roSupportMarkdown},
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
      doAssert error != nil, "unexpected RST error '" & message & "'"
      error[] = message
      # we check only first error because subsequent ones may be meaningless
      raise newException(EParseError, message)
    else:
      doAssert warnings != nil, "unexpected RST warning '" & message & "'"
      warnings[].add message
  try:
    result = rstToHtml(input, rstOptions, defaultConfig(),
                       msgHandler=testMsgHandler)
  except EParseError:
    discard

suite "YAML syntax highlighting":
  test "Basics":
    let input = """.. code-block:: yaml
    %YAML 1.2
    ---
    a string: string
    a list:
      - item 1
      - item 2
    a map:
    ? key
    : value
    ..."""
    let output = input.toHtml({})
    doAssert output == """<pre class = "listing"><span class="Directive">%YAML 1.2</span>
<span class="Keyword">---</span>
<span class="StringLit">a string</span><span class="Punctuation">:</span> <span class="StringLit">string</span>
<span class="StringLit">a list</span><span class="Punctuation">:</span>
  <span class="Punctuation">-</span> <span class="StringLit">item 1</span>
  <span class="Punctuation">-</span> <span class="StringLit">item 2</span>
<span class="StringLit">a map</span><span class="Punctuation">:</span>
<span class="Punctuation">?</span> <span class="StringLit">key</span>
<span class="Punctuation">:</span> <span class="StringLit">value</span>
<span class="Keyword">...</span></pre>"""

  test "Block scalars":
    let input = """.. code-block:: yaml
    a literal block scalar: |
      some text
      # not a comment
     # a comment, since less indented
      # another comment
    a folded block scalar: >2
       some text
      # not a comment since indented as specified
     # a comment
    another literal block scalar:
      |+ # comment after header
     allowed, since more indented than parent"""
    let output = input.toHtml({})
    doAssert output == """<pre class = "listing"><span class="StringLit">a literal block scalar</span><span class="Punctuation">:</span> <span class="Command">|</span><span class="Command"></span><span class="LongStringLit">
  some text
  # not a comment
 </span><span class="Comment"># a comment, since less indented</span>
  <span class="Comment"># another comment</span>
<span class="StringLit">a folded block scalar</span><span class="Punctuation">:</span> <span class="Command">&gt;2</span><span class="Command"></span><span class="LongStringLit">
   some text
  # not a comment since indented as specified
 </span><span class="Comment"># a comment</span>
<span class="StringLit">another literal block scalar</span><span class="Punctuation">:</span>
  <span class="Command">|+</span> <span class="Comment"># comment after header</span><span class="LongStringLit">
 allowed, since more indented than parent</span></pre>"""

  test "Directives":
    let input = """.. code-block:: yaml
    %YAML 1.2
    ---
    %not a directive
    ...
    %a directive
    ...
    a string
    % not a directive
    ...
    %TAG ! !foo:"""
    let output = input.toHtml({})
    doAssert output == """<pre class = "listing"><span class="Directive">%YAML 1.2</span>
<span class="Keyword">---</span>
<span class="StringLit">%not a directive</span>
<span class="Keyword">...</span>
<span class="Directive">%a directive</span>
<span class="Keyword">...</span>
<span class="StringLit">a string</span>
<span class="StringLit">% not a directive</span>
<span class="Keyword">...</span>
<span class="Directive">%TAG ! !foo:</span></pre>"""

  test "Flow Style and Numbers":
    let input = """.. code-block:: yaml
    {
      "quoted string": 42,
      'single quoted string': false,
      [ list, "with", 'entries' ]: 73.32e-73,
      more numbers: [-783, 11e78],
      not numbers: [ 42e, 0023, +32.37, 8 ball]
    }"""
    let output = input.toHtml({})
    doAssert output == """<pre class = "listing"><span class="Punctuation">{</span>
  <span class="StringLit">&quot;</span><span class="StringLit">quoted string&quot;</span><span class="Punctuation">:</span> <span class="DecNumber">42</span><span class="Punctuation">,</span>
  <span class="StringLit">'single quoted string'</span><span class="Punctuation">:</span> <span class="StringLit">false</span><span class="Punctuation">,</span>
  <span class="Punctuation">[</span> <span class="StringLit">list</span><span class="Punctuation">,</span> <span class="StringLit">&quot;</span><span class="StringLit">with&quot;</span><span class="Punctuation">,</span> <span class="StringLit">'entries'</span> <span class="Punctuation">]</span><span class="Punctuation">:</span> <span class="FloatNumber">73.32e-73</span><span class="Punctuation">,</span>
  <span class="StringLit">more numbers</span><span class="Punctuation">:</span> <span class="Punctuation">[</span><span class="DecNumber">-783</span><span class="Punctuation">,</span> <span class="FloatNumber">11e78</span><span class="Punctuation">]</span><span class="Punctuation">,</span>
  <span class="StringLit">not numbers</span><span class="Punctuation">:</span> <span class="Punctuation">[</span> <span class="StringLit">42e</span><span class="Punctuation">,</span> <span class="StringLit">0023</span><span class="Punctuation">,</span> <span class="StringLit">+32.37</span><span class="Punctuation">,</span> <span class="StringLit">8 ball</span><span class="Punctuation">]</span>
<span class="Punctuation">}</span></pre>"""

  test "Anchors, Aliases, Tags":
    let input = """.. code-block:: yaml
    --- !!map
    !!str string: !<tag:yaml.org,2002:int> 42
    ? &anchor !!seq []:
    : !localtag foo
    alias: *anchor
    """
    let output = input.toHtml({})
    doAssert output == """<pre class = "listing"><span class="Keyword">---</span> <span class="TagStart">!!map</span>
<span class="TagStart">!!str</span> <span class="StringLit">string</span><span class="Punctuation">:</span> <span class="TagStart">!&lt;tag:yaml.org,2002:int&gt;</span> <span class="DecNumber">42</span>
<span class="Punctuation">?</span> <span class="Label">&amp;anchor</span> <span class="TagStart">!!seq</span> <span class="Punctuation">[</span><span class="Punctuation">]</span><span class="Punctuation">:</span>
<span class="Punctuation">:</span> <span class="TagStart">!localtag</span> <span class="StringLit">foo</span>
<span class="StringLit">alias</span><span class="Punctuation">:</span> <span class="Reference">*anchor</span></pre>"""

  test "Edge cases":
    let input = """.. code-block:: yaml
    ...
     %a string:
      a:string:not:a:map
    ...
    not a list:
      -2
      -3
      -4
    example.com/not/a#comment:
      ?not a map key
    """
    let output = input.toHtml({})
    doAssert output == """<pre class = "listing"><span class="Keyword">...</span>
 <span class="StringLit">%a string</span><span class="Punctuation">:</span>
  <span class="StringLit">a:string:not:a:map</span>
<span class="Keyword">...</span>
<span class="StringLit">not a list</span><span class="Punctuation">:</span>
  <span class="DecNumber">-2</span>
  <span class="DecNumber">-3</span>
  <span class="DecNumber">-4</span>
<span class="StringLit">example.com/not/a#comment</span><span class="Punctuation">:</span>
  <span class="StringLit">?not a map key</span></pre>"""


suite "RST/Markdown general":
  test "RST emphasis":
    doAssert rstToHtml("*Hello* **world**!", {},
      newStringTable(modeStyleInsensitive)) ==
      "<em>Hello</em> <strong>world</strong>!"

  test "Markdown links":
    check("(( [Nim](https://nim-lang.org/) ))".toHtml ==
        """(( <a class="reference external" href="https://nim-lang.org/">Nim</a> ))""")
    check("(([Nim](https://nim-lang.org/)))".toHtml ==
        """((<a class="reference external" href="https://nim-lang.org/">Nim</a>))""")
    check("[[Nim](https://nim-lang.org/)]".toHtml ==
        """[<a class="reference external" href="https://nim-lang.org/">Nim</a>]""")

  test "Markdown tables":
    let input1 = """
| A1 header    | A2 \| not fooled
| :---         | ----:       |
| C1           | C2 **bold** | ignored |
| D1 `code \|` | D2          | also ignored
| E1 \| text   |
|              | F2 without pipe
not in table"""
    let output1 = input1.toHtml
    doAssert output1 == """<table border="1" class="docutils"><tr><th>A1 header</th><th>A2 | not fooled</th></tr>
<tr><td>C1</td><td>C2 <strong>bold</strong></td></tr>
<tr><td>D1 <tt class="docutils literal"><span class="pre">code |</span></tt></td><td>D2</td></tr>
<tr><td>E1 | text</td><td></td></tr>
<tr><td></td><td>F2 without pipe</td></tr>
</table><p>not in table</p>
"""
    let input2 = """
| A1 header | A2 |
| --- | --- |"""
    let output2 = input2.toHtml
    doAssert output2 == """<table border="1" class="docutils"><tr><th>A1 header</th><th>A2</th></tr>
</table>"""

  test "RST tables":
    let input1 = """
Test 2 column/4 rows table:
====   ===
H0     H1
====   ===
A0     A1
====   ===
A2     A3
====   ===
A4     A5
====   === """
    let output1 = rstToLatex(input1, {})
    doAssert "{|X|X|}" in output1  # 2 columns
    doAssert count(output1, "\\\\") == 4  # 4 rows
    for cell in ["H0", "H1", "A0", "A1", "A2", "A3", "A4", "A5"]:
      doAssert cell in output1

    let input2 = """
Now test 3 columns / 2 rows, and also borders containing 4 =, 3 =, 1 = signs:

====   ===  =
H0     H1   H
====   ===  =
A0     A1   X
       Ax   Y
====   ===  = """
    let output2 = rstToLatex(input2, {})
    doAssert "{|X|X|X|}" in output2  # 3 columns
    doAssert count(output2, "\\\\") == 2  # 2 rows
    for cell in ["H0", "H1", "H", "A0", "A1", "X", "Ax", "Y"]:
      doAssert cell in output2


  test "RST adornments":
    let input1 = """
Check that a few punctuation symbols are not parsed as adornments:
:word1: word2 .... word3 """
    let output1 = input1.toHtml
    discard output1

  test "RST sections":
    let input1 = """
Long chapter name
'''''''''''''''''''
"""
    let output1 = input1.toHtml
    doAssert "Long chapter name" in output1 and "<h1" in output1

    let input2 = """
Short chapter name:

ChA
===
"""
    let output2 = input2.toHtml
    doAssert "ChA" in output2 and "<h1" in output2

    let input3 = """
Very short chapter name:

X
~
"""
    let output3 = input3.toHtml
    doAssert "X" in output3 and "<h1" in output3

    let input4 = """
Check that short underline is not enough to make section:

Wrong chapter
------------

"""
    var error4 = new string
    let output4 = input4.toHtml(error = error4)
    check(error4[] == "input(3, 1) Error: new section expected (underline " &
            "\'------------\' is too short)")

    let input5 = """
Check that punctuation after adornment and indent are not detected as adornment.

Some chapter
--------------

  "punctuation symbols" """
    let output5 = input5.toHtml
    doAssert "&quot;punctuation symbols&quot;" in output5 and "<h1" in output5

    # check that EOF after adornment does not prevent it parsing as heading
    let input6 = dedent """
      Some chapter
      ------------"""
    let output6 = input6.toHtml
    doAssert "<h1 id=\"some-chapter\">Some chapter</h1>" in output6

    # check that overline and underline match
    let input7 = dedent """
      ------------
      Some chapter
      -----------
      """
    var error7 = new string
    let output7 = input7.toHtml(error=error7)
    check(error7[] == "input(1, 1) Error: new section expected (underline " &
            "\'-----------\' does not match overline \'------------\')")

    let input8 = dedent """
      -----------
          Overflow
      -----------
      """
    var error8 = new string
    let output8 = input8.toHtml(error=error8)
    check(error8[] == "input(1, 1) Error: new section expected (overline " &
            "\'-----------\' is too short)")

    # check that hierarchy of title styles works
    let input9good = dedent """
      Level1
      ======

      Level2
      ------

      Level3
      ~~~~~~

      L1
      ==

      Another2
      --------

      More3
      ~~~~~

      """
    let output9good = input9good.toHtml
    doAssert "<h1 id=\"level1\">Level1</h1>" in output9good
    doAssert "<h2 id=\"level2\">Level2</h2>" in output9good
    doAssert "<h3 id=\"level3\">Level3</h3>" in output9good
    doAssert "<h1 id=\"l1\">L1</h1>" in output9good
    doAssert "<h2 id=\"another2\">Another2</h2>" in output9good
    doAssert "<h3 id=\"more3\">More3</h3>" in output9good

    # check that swap causes an exception
    let input9Bad = dedent """
      Level1
      ======

      Level2
      ------
      
      Level3
      ~~~~~~

      L1
      ==

      More
      ~~~~
      
      Another
      -------

      """
    var error9Bad = new string
    let output9Bad = input9bad.toHtml(error=error9Bad)
    check(error9Bad[] == "input(15, 1) Error: new section expected (section " &
            "level inconsistent: underline ~~~~~ unexpectedly found, while " &
            "the following intermediate section level(s) are missing on " &
            "lines 12..15: underline -----)")

    # the same as input9good but with overline headings
    # first overline heading has a special meaning: document title
    let input10 = dedent """
      ======
      Title0
      ======

      +++++++++
      SubTitle0
      +++++++++

      ------
      Level1
      ------

      Level2
      ------

      ~~~~~~
      Level3
      ~~~~~~

      --
      L1
      --

      Another2
      --------

      ~~~~~
      More3
      ~~~~~

      """
    var option: bool
    var rstGenera: RstGenerator
    var output10: string
    rstGenera.initRstGenerator(outHtml, defaultConfig(), "input", {})
    rstGenera.renderRstToOut(rstParse(input10, "", 1, 1, option, {}), output10)
    doAssert rstGenera.meta[metaTitle] == "Title0"
    doAssert rstGenera.meta[metaSubTitle] == "SubTitle0"
    doAssert "<h1 id=\"level1\"><center>Level1</center></h1>" in output10
    doAssert "<h2 id=\"level2\">Level2</h2>" in output10
    doAssert "<h3 id=\"level3\"><center>Level3</center></h3>" in output10
    doAssert "<h1 id=\"l1\"><center>L1</center></h1>" in output10
    doAssert "<h2 id=\"another2\">Another2</h2>" in output10
    doAssert "<h3 id=\"more3\"><center>More3</center></h3>" in output10

    # check that a paragraph prevents interpreting overlines as document titles
    let input11 = dedent """
      Paragraph

      ======
      Title0
      ======

      +++++++++
      SubTitle0
      +++++++++
      """
    var option11: bool
    var rstGenera11: RstGenerator
    var output11: string
    rstGenera11.initRstGenerator(outHtml, defaultConfig(), "input", {})
    rstGenera11.renderRstToOut(rstParse(input11, "", 1, 1, option11, {}), output11)
    doAssert rstGenera11.meta[metaTitle] == ""
    doAssert rstGenera11.meta[metaSubTitle] == ""
    doAssert "<h1 id=\"title0\"><center>Title0</center></h1>" in output11
    doAssert "<h2 id=\"subtitle0\"><center>SubTitle0</center></h2>" in output11

    # check that RST and Markdown headings don't interfere
    let input12 = dedent """
      ======
      Title0
      ======

      MySection1a
      +++++++++++

      # MySection1b

      MySection1c
      +++++++++++

      ##### MySection5a

      MySection2a
      -----------
      """
    var option12: bool
    var rstGenera12: RstGenerator
    var output12: string
    rstGenera12.initRstGenerator(outHtml, defaultConfig(), "input", {})
    rstGenera12.renderRstToOut(rstParse(input12, "", 1, 1, option12, {roSupportMarkdown}), output12)
    doAssert rstGenera12.meta[metaTitle] == "Title0"
    doAssert rstGenera12.meta[metaSubTitle] == ""
    doAssert output12 ==
             "\n<h1 id=\"mysection1a\">MySection1a</h1>" & # RST
             "\n<h1 id=\"mysection1b\">MySection1b</h1>" & # Markdown
             "\n<h1 id=\"mysection1c\">MySection1c</h1>" & # RST
             "\n<h5 id=\"mysection5a\">MySection5a</h5>" & # Markdown
             "\n<h2 id=\"mysection2a\">MySection2a</h2>"   # RST

  test "RST inline text":
    let input1 = "GC_step"
    let output1 = input1.toHtml
    doAssert output1 == "GC_step"

  test "RST links":
    let input1 = """
Want to learn about `my favorite programming language`_?

.. _my favorite programming language: https://nim-lang.org"""
    let output1 = input1.toHtml
    doAssert "<a" in output1 and "href=\"https://nim-lang.org\"" in output1

  test "RST transitions":
    let input1 = """
context1

~~~~

context2
"""
    let output1 = input1.toHtml
    doAssert "<hr" in output1

    let input2 = """
This is too short to be a transition:

---

context2
"""
    var error2 = new string
    let output2 = input2.toHtml(error=error2)
    check(error2[] == "input(3, 1) Error: new section expected (overline " &
            "\'---\' is too short)")

  test "RST literal block":
    let input1 = """
Test literal block

::

  check """
    let output1 = input1.toHtml
    doAssert "<pre>" in output1

  test "Markdown code block":
    let input1 = """
```
let x = 1
``` """
    let output1 = input1.toHtml
    doAssert "<pre" in output1 and "class=\"Keyword\"" notin output1

    let input2 = """
Parse the block with language specifier:
```Nim
let x = 1
``` """
    let output2 = input2.toHtml
    doAssert "<pre" in output2 and "class=\"Keyword\"" in output2

  test "RST comments":
    let input1 = """
Check that comment disappears:

..
  some comment """
    let output1 = input1.toHtml
    doAssert output1 == "Check that comment disappears:"

  test "RST line blocks":
    let input1 = """
=====
Test1
=====

|
|
| line block
| other line

"""
    var option: bool
    var rstGenera: RstGenerator
    var output1: string
    rstGenera.initRstGenerator(outHtml, defaultConfig(), "input", {})
    rstGenera.renderRstToOut(rstParse(input1, "", 1, 1, option, {}), output1)
    doAssert rstGenera.meta[metaTitle] == "Test1"
      # check that title was not overwritten to '|'
    doAssert output1 == "<p><br/><br/>line block<br/>other line<br/></p>"
    let output1l = rstToLatex(input1, {})
    doAssert "line block\n\n" in output1l
    doAssert "other line\n\n" in output1l
    doAssert output1l.count("\\vspace") == 2 + 2  # +2 surrounding paddings

    let input2 = dedent"""
      Paragraph1
      
      |

      Paragraph2"""

    let output2 = input2.toHtml
    doAssert "Paragraph1<p><br/></p> <p>Paragraph2</p>\n" == output2

    let input3 = dedent"""
      | xxx
      |   yyy
      |     zzz"""

    let output3 = input3.toHtml
    doAssert "xxx<br/>" in output3
    doAssert "<span style=\"margin-left: 1.0em\">yyy</span><br/>" in output3
    doAssert "<span style=\"margin-left: 2.0em\">zzz</span><br/>" in output3

    # check that '|   ' with a few spaces is still parsed as new line
    let input4 = dedent"""
      | xxx
      |      
      |     zzz"""

    let output4 = input4.toHtml
    doAssert "xxx<br/><br/>" in output4
    doAssert "<span style=\"margin-left: 2.0em\">zzz</span><br/>" in output4

  test "RST enumerated lists":
    let input1 = dedent """
      1. line1
         1
      2. line2
         2

      3. line3
         3


      4. line4
         4



      5. line5
         5
      """
    let output1 = input1.toHtml
    for i in 1..5:
      doAssert ($i & ". line" & $i) notin output1
      doAssert ("<li>line" & $i & " " & $i & "</li>") in output1

    let input2 = dedent """
      3. line3

      4. line4


      5. line5



      7. line7




      8. line8
      """
    let output2 = input2.toHtml
    for i in [3, 4, 5, 7, 8]:
      doAssert ($i & ". line" & $i) notin output2
      doAssert ("<li>line" & $i & "</li>") in output2

    # check that nested enumerated lists work
    let input3 = dedent """
      1.  a) string1
      2. string2
      """
    let output3 = input3.toHtml
    doAssert count(output3, "<ol ") == 2
    doAssert count(output3, "</ol>") == 2
    doAssert "<li>string1</li>" in output3 and "<li>string2</li>" in output3

    let input4 = dedent """
      Check that enumeration specifiers are respected

      9. string1
      10. string2
      12. string3

      b) string4
      c) string5
      e) string6
      """
    let output4 = input4.toHtml
    doAssert count(output4, "<ol ") == 4
    doAssert count(output4, "</ol>") == 4
    for enumerator in [9, 12]:
      doAssert "start=\"$1\"" % [$enumerator] in output4
    for enumerator in [2, 5]:  # 2=b, 5=e
      doAssert "start=\"$1\"" % [$enumerator] in output4

    let input5 = dedent """
      Check that auto-numbered enumeration lists work.

      #. string1

      #. string2

      #. string3

      #) string5
      #) string6
      """
    let output5 = input5.toHtml
    doAssert count(output5, "<ol ") == 2
    doAssert count(output5, "</ol>") == 2
    doAssert count(output5, "<li>") == 5

    let input5a = dedent """
      Auto-numbered RST list can start with 1 even when Markdown support is on.

      1. string1
      #. string2
      #. string3
      """
    let output5a = input5a.toHtml
    doAssert count(output5a, "<ol ") == 1
    doAssert count(output5a, "</ol>") == 1
    doAssert count(output5a, "<li>") == 3

    let input6 = dedent """
      ... And for alphabetic enumerators too!

      b. string1
      #. string2
      #. string3
      """
    let output6 = input6.toHtml
    doAssert count(output6, "<ol ") == 1
    doAssert count(output6, "</ol>") == 1
    doAssert count(output6, "<li>") == 3
    doAssert "start=\"2\"" in output6 and "class=\"loweralpha simple\"" in output6

    let input7 = dedent """
      ... And for uppercase alphabetic enumerators.

      C. string1
      #. string2
      #. string3
      """
    let output7 = input7.toHtml
    doAssert count(output7, "<ol ") == 1
    doAssert count(output7, "</ol>") == 1
    doAssert count(output7, "<li>") == 3
    doAssert "start=\"3\"" in output7 and "class=\"upperalpha simple\"" in output7

    # check that it's not recognized as enum.list without indentation on 2nd line
    let input8 = dedent """
      Paragraph.

      A. stringA
      B. stringB
      C. string1
      string2
      """
    var warnings8 = new seq[string]
    let output8 = input8.toHtml(warnings = warnings8)
    check(warnings8[].len == 1)
    check("input(6, 1) Warning: RST style: \n" &
          "  not enough indentation on line 6" in warnings8[0])
    doAssert output8 == "Paragraph.<ol class=\"upperalpha simple\">" &
        "<li>stringA</li>\n<li>stringB</li>\n</ol>\n<p>C. string1 string2 </p>\n"

  test "Markdown enumerated lists":
    let input1 = dedent """
      Below are 2 enumerated lists: Markdown-style (5 items) and RST (1 item)
      1. line1
      1. line2
      1. line3
      1. line4

      1. line5

      #. lineA
      """
    let output1 = input1.toHtml
    for i in 1..5:
      doAssert ($i & ". line" & $i) notin output1
      doAssert ("<li>line" & $i & "</li>") in output1
    doAssert count(output1, "<ol ") == 2
    doAssert count(output1, "</ol>") == 2

  test "RST bullet lists":
    let input1 = dedent """
      * line1
        1
      * line2
        2

      * line3
        3


      * line4
        4



      * line5
        5
      """
    let output1 = input1.toHtml
    for i in 1..5:
      doAssert ("<li>line" & $i & " " & $i & "</li>") in output1
    doAssert count(output1, "<ul ") == 1
    doAssert count(output1, "</ul>") == 1

  test "Nim RST footnotes and citations":
    # check that auto-label footnote enumerated properly after a manual one
    let input1 = dedent """
      .. [1] Body1.
      .. [#note] Body2

      Ref. [#note]_
      """
    let output1 = input1.toHtml
    doAssert output1.count(">[1]</a>") == 1
    doAssert output1.count(">[2]</a>") == 2
    doAssert "href=\"#footnote-note\"" in output1
    doAssert ">[-1]" notin output1
    doAssert "Body1." in output1
    doAssert "Body2" in output1

    # check that there are NO footnotes/citations, only comments:
    let input2 = dedent """
      .. [1 #] Body1.
      .. [# note] Body2.
      .. [wrong citation] That gives you a comment.

      .. [not&allowed] That gives you a comment.

      Not references[#note]_[1 #]_ [wrong citation]_ and [not&allowed]_.
      """
    let output2 = input2.toHtml
    doAssert output2 == "Not references[#note]_[1 #]_ [wrong citation]_ and [not&amp;allowed]_. "

    # check that auto-symbol footnotes work:
    let input3 = dedent """
      Ref. [*]_ and [*]_ and [*]_.

      .. [*] Body1
      .. [*] Body2.


      .. [*] Body3.
      .. [*] Body4

      And [*]_.
      """
    let output3 = input3.toHtml
    # both references and footnotes. Footnotes have link to themselves.
    doAssert output3.count("href=\"#footnotesym-1\">[*]</a>") == 2
    doAssert output3.count("href=\"#footnotesym-2\">[**]</a>") == 2
    doAssert output3.count("href=\"#footnotesym-3\">[***]</a>") == 2
    doAssert output3.count("href=\"#footnotesym-4\">[^]</a>") == 2
    # footnote group
    doAssert output3.count("<hr class=\"footnote\">" &
                           "<div class=\"footnote-group\">") == 1
    # footnotes
    doAssert output3.count("<div class=\"footnote-label\"><sup><strong>" &
               "<a href=\"#footnotesym-1\">[*]</a></strong></sup></div>") == 1
    doAssert output3.count("<div class=\"footnote-label\"><sup><strong>" &
               "<a href=\"#footnotesym-2\">[**]</a></strong></sup></div>") == 1
    doAssert output3.count("<div class=\"footnote-label\"><sup><strong>" &
               "<a href=\"#footnotesym-3\">[***]</a></strong></sup></div>") == 1
    doAssert output3.count("<div class=\"footnote-label\"><sup><strong>" &
               "<a href=\"#footnotesym-4\">[^]</a></strong></sup></div>") == 1
    for i in 1 .. 4: doAssert ("Body" & $i) in output3

    # check manual, auto-number and auto-label footnote enumeration
    let input4 = dedent """
      .. [3] Manual1.
      .. [#] Auto-number1.
      .. [#mylabel] Auto-label1.
      .. [#note] Auto-label2.
      .. [#] Auto-number2.

      Ref. [#note]_ and [#]_ and [#]_.
      """
    let output4 = input4.toHtml
    doAssert ">[-1]" notin output1
    let order = @[
        "footnote-3", "[3]", "Manual1.",
        "footnoteauto-1", "[1]", "Auto-number1",
        "footnote-mylabel", "[2]", "Auto-label1",
        "footnote-note", "[4]", "Auto-label2",
        "footnoteauto-2", "[5]", "Auto-number2",
        ]
    for i in 0 .. order.len-2:
      let pos1 = output4.find(order[i])
      let pos2 = output4.find(order[i+1])
      doAssert pos1 >= 0
      doAssert pos2 >= 0
      doAssert pos1 < pos2

    # forgot [#]_
    let input5 = dedent """
      .. [3] Manual1.
      .. [#] Auto-number1.
      .. [#note] Auto-label2.

      Ref. [#note]_
      """
    var error5 = new string
    let output5 = input5.toHtml(error=error5)
    check(error5[] == "input(6, 1) Error: mismatch in number of footnotes " &
            "and their refs: 1 (lines 2) != 0 (lines ) for auto-numbered " &
            "footnotes")

    # extra [*]_
    let input6 = dedent """
      Ref. [*]_

      .. [*] Auto-Symbol.

      Ref. [*]_
      """
    var error6 = new string
    let output6 = input6.toHtml(error=error6)
    check(error6[] == "input(6, 1) Error: mismatch in number of footnotes " &
            "and their refs: 1 (lines 3) != 2 (lines 2, 6) for auto-symbol " &
            "footnotes")

    let input7 = dedent """
      .. [Some:CITATION-2020] Citation.

      Ref. [some:citation-2020]_.
      """
    let output7 = input7.toHtml
    doAssert output7.count("href=\"#citation-somecoloncitationminus2020\"") == 2
    doAssert output7.count("[Some:CITATION-2020]") == 1
    doAssert output7.count("[some:citation-2020]") == 1
    doAssert output3.count("<hr class=\"footnote\">" &
                           "<div class=\"footnote-group\">") == 1

    let input8 = dedent """
      .. [Some] Citation.

      Ref. [som]_.
      """
    var warnings8 = new seq[string]
    let output8 = input8.toHtml(warnings=warnings8)
    check(warnings8[] == @["input(4, 1) Warning: unknown substitution " &
            "\'citation-som\'"])

    # check that footnote group does not break parsing of other directives:
    let input9 = dedent """
      .. [Some] Citation.

      .. _`internal anchor`:

      .. [Another] Citation.
      .. just comment.
      .. [Third] Citation.

      Paragraph1.

      Paragraph2 ref `internal anchor`_.
      """
    let output9 = input9.toHtml
    #doAssert "id=\"internal-anchor\"" in output9
    #doAssert "internal anchor" notin output9
    doAssert output9.count("<hr class=\"footnote\">" &
                           "<div class=\"footnote-group\">") == 1
    doAssert output9.count("<div class=\"footnote-label\">") == 3
    doAssert "just comment" notin output9

    # check that nested citations/footnotes work
    let input10 = dedent """
      Paragraph1 [#]_.

      .. [First] Citation.

         .. [#] Footnote.

            .. [Third] Citation.
      """
    let output10 = input10.toHtml
    doAssert output10.count("<hr class=\"footnote\">" &
                            "<div class=\"footnote-group\">") == 3
    doAssert output10.count("<div class=\"footnote-label\">") == 3
    doAssert "<a href=\"#citation-first\">[First]</a>" in output10
    doAssert "<a href=\"#footnoteauto-1\">[1]</a>" in output10
    doAssert "<a href=\"#citation-third\">[Third]</a>" in output10

    let input11 = ".. [note]\n"  # should not crash
    let output11 = input11.toHtml
    doAssert "<a href=\"#citation-note\">[note]</a>" in output11

    # check that references to auto-numbered footnotes work
    let input12 = dedent """
      Ref. [#]_ and [#]_ STOP.

      .. [#] Body1.
      .. [#] Body3
      .. [2] Body2.
      """
    let output12 = input12.toHtml
    let orderAuto = @[
        "#footnoteauto-1", "[1]",
        "#footnoteauto-2", "[3]",
        "STOP.",
        "Body1.", "Body3", "Body2."
        ]
    for i in 0 .. orderAuto.len-2:
      let pos1 = output12.find(orderAuto[i])
      let pos2 = output12.find(orderAuto[i+1])
      doAssert pos1 >= 0
      doAssert pos2 >= 0
      doAssert pos1 < pos2

  test "Nim (RST extension) code-block":
    # check that presence of fields doesn't consume the following text as
    # its code (which is a literal block)
    let input0 = dedent """
      .. code-block:: nim
         :number-lines: 0

      Paragraph1"""
    let output0 = input0.toHtml
    doAssert "<p>Paragraph1</p>" in output0

  test "RST admonitions":
    # check that all admonitions are implemented
    let input0 = dedent """
      .. admonition:: endOf admonition
      .. attention:: endOf attention
      .. caution:: endOf caution
      .. danger:: endOf danger
      .. error:: endOf error
      .. hint:: endOf hint
      .. important:: endOf important
      .. note:: endOf note
      .. tip:: endOf tip
      .. warning:: endOf warning
    """
    let output0 = input0.toHtml
    for a in ["admonition", "attention", "caution", "danger", "error", "hint",
        "important", "note", "tip", "warning" ]:
      doAssert "endOf " & a & "</div>" in output0

    # Test that admonition does not swallow up the next paragraph.
    let input1 = dedent """
      .. error:: endOfError

      Test paragraph.
    """
    let output1 = input1.toHtml
    doAssert "endOfError</div>" in output1
    doAssert "<p>Test paragraph. </p>" in output1
    doAssert "class=\"admonition admonition-error\"" in output1

    # Test that second line is parsed as continuation of the first line.
    let input2 = dedent """
      .. error:: endOfError
        Test2p.

      Test paragraph.
    """
    let output2 = input2.toHtml
    doAssert "endOfError Test2p.</div>" in output2
    doAssert "<p>Test paragraph. </p>" in output2
    doAssert "class=\"admonition admonition-error\"" in output2

    let input3 = dedent """
      .. note:: endOfNote
    """
    let output3 = input3.toHtml
    doAssert "endOfNote</div>" in output3
    doAssert "class=\"admonition admonition-info\"" in output3

  test "RST internal links":
    let input1 = dedent """
      Start.

      .. _target000:

      Paragraph.

      .. _target001:

      * bullet list
      * Y

      .. _target002:

      1. enumeration list
      2. Y

      .. _target003:

      term 1
        Definition list 1.

      .. _target004:

      | line block

      .. _target005:

      :a: field list value

      .. _target006:

      -a  option description

      .. _target007:

      ::

        Literal block

      .. _target008:

      Doctest blocks are not implemented.

      .. _target009:

          block quote

      .. _target010:

      =====  =====  =======
        A      B    A and B
      =====  =====  =======
      False  False  False
      =====  =====  =======

      .. _target100:

      .. CAUTION:: admonition

      .. _target101:

      .. code:: nim

         const pi = 3.14

      .. _target102:

      .. code-block::

         const pi = 3.14

      Paragraph2.

      .. _target202:

      ----

      That was a transition.
    """
    let output1 = input1.toHtml
    doAssert "<p id=\"target000\""     in output1
    doAssert "<ul id=\"target001\""    in output1
    doAssert "<ol id=\"target002\""    in output1
    doAssert "<dl id=\"target003\""    in output1
    doAssert "<p id=\"target004\""     in output1
    doAssert "<table id=\"target005\"" in output1  # field list
    doAssert "<table id=\"target006\"" in output1  # option list
    doAssert "<pre id=\"target007\""   in output1
    doAssert "<blockquote id=\"target009\"" in output1
    doAssert "<table id=\"target010\"" in output1  # just table
    doAssert "<span id=\"target100\""  in output1
    doAssert "<pre id=\"target101\""   in output1  # code
    doAssert "<pre id=\"target102\""   in output1  # code-block
    doAssert "<hr id=\"target202\""    in output1

  test "RST internal links for sections":
    let input1 = dedent """
      .. _target101:
      .. _target102:

      Section xyz
      -----------

      Ref. target101_
    """
    let output1 = input1.toHtml
    # "target101" should be erased and changed to "section-xyz":
    doAssert "href=\"#target101\"" notin output1
    doAssert "id=\"target101\""    notin output1
    doAssert "href=\"#target102\"" notin output1
    doAssert "id=\"target102\""    notin output1
    doAssert "id=\"section-xyz\""     in output1
    doAssert "href=\"#section-xyz\""  in output1

    let input2 = dedent """
      .. _target300:

      Section xyz
      ===========

      .. _target301:

      SubsectionA
      -----------

      Ref. target300_ and target301_.

      .. _target103:

      .. [cit2020] note.

      Ref. target103_.

    """
    let output2 = input2.toHtml
    # "target101" should be erased and changed to "section-xyz":
    doAssert "href=\"#target300\"" notin output2
    doAssert "id=\"target300\""    notin output2
    doAssert "href=\"#target301\"" notin output2
    doAssert "id=\"target301\""    notin output2
    doAssert "<h1 id=\"section-xyz\"" in output2
    doAssert "<h2 id=\"subsectiona\"" in output2
    # links should preserve their original names but point to section labels:
    doAssert "href=\"#section-xyz\">target300" in output2
    doAssert "href=\"#subsectiona\">target301" in output2
    doAssert "href=\"#citation-cit2020\">target103" in output2

    let output2l = rstToLatex(input2, {})
    doAssert "\\label{section-xyz}\\hypertarget{section-xyz}{}" in output2l
    doAssert "\\hyperlink{section-xyz}{target300}"  in output2l
    doAssert "\\hyperlink{subsectiona}{target301}"  in output2l

  test "RST internal links (inline)":
    let input1 = dedent """
      Paragraph with _`some definition`.

      Ref. `some definition`_.
    """
    let output1 = input1.toHtml
    doAssert "<span class=\"target\" " &
        "id=\"some-definition\">some definition</span>" in output1
    doAssert "Ref. <a class=\"reference internal\" " &
        "href=\"#some-definition\">some definition</a>" in output1

  test "RST references (additional symbols)":
    # check that ., _, -, +, : are allowed symbols in references without ` `
    let input1 = dedent """
      sec.1
      -----

      2-other:sec+c_2
      ^^^^^^^^^^^^^^^

      .. _link.1_2021:

      Paragraph

      Ref. sec.1_! and 2-other:sec+c_2_;and link.1_2021_.
    """
    let output1 = input1.toHtml
    doAssert "id=\"secdot1\"" in output1
    doAssert "id=\"Z2minusothercolonsecplusc-2\"" in output1
    doAssert "id=\"linkdot1-2021\"" in output1
    let ref1 = "<a class=\"reference internal\" href=\"#secdot1\">sec.1</a>"
    let ref2 = "<a class=\"reference internal\" href=\"#Z2minusothercolonsecplusc-2\">2-other:sec+c_2</a>"
    let ref3 = "<a class=\"reference internal\" href=\"#linkdot1-2021\">link.1_2021</a>"
    let refline = "Ref. " & ref1 & "! and " & ref2 & ";and " & ref3 & "."
    doAssert refline in output1

suite "RST/Code highlight":
  test "Basic Python code highlight":
    let pythonCode = """
    .. code-block:: python

      def f_name(arg=42):
          print(f"{arg}")

    """

    let expected = """<blockquote><p><span class="Keyword">def</span> f_name<span class="Punctuation">(</span><span class="Punctuation">arg</span><span class="Operator">=</span><span class="DecNumber">42</span><span class="Punctuation">)</span><span class="Punctuation">:</span>
    print<span class="Punctuation">(</span><span class="RawData">f&quot;{arg}&quot;</span><span class="Punctuation">)</span></p></blockquote>"""

    check strip(rstToHtml(pythonCode, {}, newStringTable(modeCaseSensitive))) ==
      strip(expected)
