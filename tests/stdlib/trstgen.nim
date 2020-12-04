discard """
outputsub: ""
"""

# tests for rstgen module.

import ../../lib/packages/docutils/rstgen
import ../../lib/packages/docutils/rst
import unittest, strutils, strtabs

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
    let output = rstTohtml(input, {}, defaultConfig())
    assert output == """<pre class = "listing"><span class="Directive">%YAML 1.2</span>
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
    let output = rstToHtml(input, {}, defaultConfig())
    assert output == """<pre class = "listing"><span class="StringLit">a literal block scalar</span><span class="Punctuation">:</span> <span class="Command">|</span><span class="Command"></span><span class="LongStringLit">
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
    let output = rstToHtml(input, {}, defaultConfig())
    assert output == """<pre class = "listing"><span class="Directive">%YAML 1.2</span>
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
    let output = rstToHtml(input, {}, defaultConfig())
    assert output == """<pre class = "listing"><span class="Punctuation">{</span>
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
    let output = rstToHtml(input, {}, defaultConfig())
    assert output == """<pre class = "listing"><span class="Keyword">---</span> <span class="TagStart">!!map</span>
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
    let output = rstToHtml(input, {}, defaultConfig())
    assert output == """<pre class = "listing"><span class="Keyword">...</span>
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
    assert rstToHtml("*Hello* **world**!", {},
      newStringTable(modeStyleInsensitive)) ==
      "<em>Hello</em> <strong>world</strong>!"

  test "Markdown links":
    let
      a = rstToHtml("(( [Nim](https://nim-lang.org/) ))", {roSupportMarkdown}, defaultConfig())
      b = rstToHtml("(([Nim](https://nim-lang.org/)))", {roSupportMarkdown}, defaultConfig())
      c = rstToHtml("[[Nim](https://nim-lang.org/)]", {roSupportMarkdown}, defaultConfig())

    assert a == """(( <a class="reference external" href="https://nim-lang.org/">Nim</a> ))"""
    assert b == """((<a class="reference external" href="https://nim-lang.org/">Nim</a>))"""
    assert c == """[<a class="reference external" href="https://nim-lang.org/">Nim</a>]"""

  test "Markdown tables":
    let input1 = """
| A1 header    | A2 \| not fooled
| :---         | ----:       |
| C1           | C2 **bold** | ignored |
| D1 `code \|` | D2          | also ignored
| E1 \| text   |
|              | F2 without pipe
not in table"""
    let output1 = rstToHtml(input1, {roSupportMarkdown}, defaultConfig())
    assert output1 == """<table border="1" class="docutils"><tr><th>A1 header</th><th>A2 | not fooled</th></tr>
<tr><td>C1</td><td>C2 <strong>bold</strong></td></tr>
<tr><td>D1 <tt class="docutils literal"><span class="pre">code |</span></tt></td><td>D2</td></tr>
<tr><td>E1 | text</td><td></td></tr>
<tr><td></td><td>F2 without pipe</td></tr>
</table><p>not in table</p>
"""
    let input2 = """
| A1 header | A2 |
| --- | --- |"""
    let output2 = rstToHtml(input2, {roSupportMarkdown}, defaultConfig())
    assert output2 == """<table border="1" class="docutils"><tr><th>A1 header</th><th>A2</th></tr>
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
    assert "{|X|X|}" in output1  # 2 columns
    assert count(output1, "\\\\") == 4  # 4 rows
    for cell in ["H0", "H1", "A0", "A1", "A2", "A3", "A4", "A5"]:
      assert cell in output1

    let input2 = """
Now test 3 columns / 2 rows, and also borders containing 4 =, 3 =, 1 = signs:

====   ===  =
H0     H1   H
====   ===  =
A0     A1   X
       Ax   Y
====   ===  = """
    let output2 = rstToLatex(input2, {})
    assert "{|X|X|X|}" in output2  # 3 columns
    assert count(output2, "\\\\") == 2  # 2 rows
    for cell in ["H0", "H1", "H", "A0", "A1", "X", "Ax", "Y"]:
      assert cell in output2


  test "RST adornments":
    let input1 = """
Check that a few punctuation symbols are not parsed as adornments:
:word1: word2 .... word3 """
    let output1 = rstToHtml(input1, {roSupportMarkdown}, defaultConfig())
    discard output1

  test "RST sections":
    let input1 = """
Long chapter name
'''''''''''''''''''
"""
    let output1 = rstToHtml(input1, {roSupportMarkdown}, defaultConfig())
    assert "Long chapter name" in output1 and "<h1" in output1

    let input2 = """
Short chapter name:

ChA
===
"""
    let output2 = rstToHtml(input2, {roSupportMarkdown}, defaultConfig())
    assert "ChA" in output2 and "<h1" in output2

    let input3 = """
Very short chapter name:

X
~
"""
    let output3 = rstToHtml(input3, {roSupportMarkdown}, defaultConfig())
    assert "X" in output3 and "<h1" in output3

    let input4 = """
Check that short underline is not enough to make section:

Wrong chapter
------------

"""
    let output4 = rstToHtml(input4, {roSupportMarkdown}, defaultConfig())
    assert "Wrong chapter" in output4 and "<h1" notin output4

    let input5 = """
Check that punctuation after adornment and indent are not detected as adornment.

Some chapter
--------------

  "punctuation symbols" """
    let output5 = rstToHtml(input5, {roSupportMarkdown}, defaultConfig())
    assert "&quot;punctuation symbols&quot;" in output5 and "<h1" in output5


  test "RST links":
    let input1 = """
Want to learn about `my favorite programming language`_?

.. _my favorite programming language: https://nim-lang.org"""
    let output1 = rstToHtml(input1, {roSupportMarkdown}, defaultConfig())
    assert "<a" in output1 and "href=\"https://nim-lang.org\"" in output1

  test "RST transitions":
    let input1 = """
context1

~~~~

context2
"""
    let output1 = rstToHtml(input1, {roSupportMarkdown}, defaultConfig())
    assert "<hr" in output1

    let input2 = """
This is too short to be a transition:

---

context2
"""
    let output2 = rstToHtml(input2, {roSupportMarkdown}, defaultConfig())
    assert "<hr" notin output2

  test "RST literal block":
    let input1 = """
Test literal block

::

  check """
    let output1 = rstToHtml(input1, {roSupportMarkdown}, defaultConfig())
    assert "<pre>" in output1

  test "Markdown code block":
    let input1 = """
```
let x = 1
``` """
    let output1 = rstToHtml(input1, {roSupportMarkdown}, defaultConfig())
    assert "<pre" in output1 and "class=\"Keyword\"" notin output1

    let input2 = """
Parse the block with language specifier:
```Nim
let x = 1
``` """
    let output2 = rstToHtml(input2, {roSupportMarkdown}, defaultConfig())
    assert "<pre" in output2 and "class=\"Keyword\"" in output2

  test "RST comments":
    let input1 = """
Check that comment disappears:

..
  some comment """
    let output1 = rstToHtml(input1, {roSupportMarkdown}, defaultConfig())
    assert output1 == "Check that comment disappears:"

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
    assert rstGenera.meta[metaTitle] == "Test1"
      # check that title was not overwritten to '|'
    assert "line block<br />" in output1
    assert "other line<br />" in output1
    let output1l = rstToLatex(input1, {})
    assert "line block\\\\" in output1l
    assert "other line\\\\" in output1l
