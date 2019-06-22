discard """
outputsub: ""
"""

# tests for rstgen module.

import ../../lib/packages/docutils/rstgen
import ../../lib/packages/docutils/rst
import unittest


# Some input strings for Testing, we use the same for 3 modes.
const inputBasics = """.. code-block:: yaml
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

const inputBlockScalars = """.. code-block:: yaml
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

const inputDirectives = """.. code-block:: yaml
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

const inputStyleFlow = """.. code-block:: yaml
    {
      "quoted string": 42,
      'single quoted string': false,
      [ list, "with", 'entries' ]: 73.32e-73,
      more numbers: [-783, 11e78],
      not numbers: [ 42e, 0023, +32.37, 8 ball]
    }"""

const inputAnchorsAndTags = """.. code-block:: yaml
    --- !!map
    !!str string: !<tag:yaml.org,2002:int> 42
    ? &anchor !!seq []:
    : !localtag foo
    alias: *anchor
    """

const inputEdgeCases = """.. code-block:: yaml
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


suite "YAML syntax highlighting":
  test "rstTohtml: Basics":
    let input = inputBasics
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

  test "rstTohtml: Block scalars":
    let input = inputBlockScalars
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

  test "rstTohtml: Directives":
    let input = inputDirectives
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

  test "rstTohtml: Flow Style and Numbers":
    let input = inputStyleFlow
    let output = rstToHtml(input, {}, defaultConfig())
    assert output == """<pre class = "listing"><span class="Punctuation">{</span>
  <span class="StringLit">&quot;</span><span class="StringLit">quoted string&quot;</span><span class="Punctuation">:</span> <span class="DecNumber">42</span><span class="Punctuation">,</span>
  <span class="StringLit">'single quoted string'</span><span class="Punctuation">:</span> <span class="StringLit">false</span><span class="Punctuation">,</span>
  <span class="Punctuation">[</span> <span class="StringLit">list</span><span class="Punctuation">,</span> <span class="StringLit">&quot;</span><span class="StringLit">with&quot;</span><span class="Punctuation">,</span> <span class="StringLit">'entries'</span> <span class="Punctuation">]</span><span class="Punctuation">:</span> <span class="FloatNumber">73.32e-73</span><span class="Punctuation">,</span>
  <span class="StringLit">more numbers</span><span class="Punctuation">:</span> <span class="Punctuation">[</span><span class="DecNumber">-783</span><span class="Punctuation">,</span> <span class="FloatNumber">11e78</span><span class="Punctuation">]</span><span class="Punctuation">,</span>
  <span class="StringLit">not numbers</span><span class="Punctuation">:</span> <span class="Punctuation">[</span> <span class="StringLit">42e</span><span class="Punctuation">,</span> <span class="StringLit">0023</span><span class="Punctuation">,</span> <span class="StringLit">+32.37</span><span class="Punctuation">,</span> <span class="StringLit">8 ball</span><span class="Punctuation">]</span>
<span class="Punctuation">}</span></pre>"""

  test "rstTohtml: Anchors, Aliases, Tags":
    let input = inputAnchorsAndTags
    let output = rstToHtml(input, {}, defaultConfig())
    assert output == """<pre class = "listing"><span class="Keyword">---</span> <span class="TagStart">!!map</span>
<span class="TagStart">!!str</span> <span class="StringLit">string</span><span class="Punctuation">:</span> <span class="TagStart">!&lt;tag:yaml.org,2002:int&gt;</span> <span class="DecNumber">42</span>
<span class="Punctuation">?</span> <span class="Label">&amp;anchor</span> <span class="TagStart">!!seq</span> <span class="Punctuation">[</span><span class="Punctuation">]</span><span class="Punctuation">:</span>
<span class="Punctuation">:</span> <span class="TagStart">!localtag</span> <span class="StringLit">foo</span>
<span class="StringLit">alias</span><span class="Punctuation">:</span> <span class="Reference">*anchor</span></pre>"""

  test "rstTohtml: Edge cases":
    let input = inputEdgeCases
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

  test "rstTohtml: Markdown links":
    let
      a = rstToHtml("(( [Nim](https://nim-lang.org/) ))", {roSupportMarkdown}, defaultConfig())
      b = rstToHtml("(([Nim](https://nim-lang.org/)))", {roSupportMarkdown}, defaultConfig())
      c = rstToHtml("[[Nim](https://nim-lang.org/)]", {roSupportMarkdown}, defaultConfig())

    assert a == """(( <a class="reference external" href="https://nim-lang.org/">Nim</a> ))"""
    assert b == """((<a class="reference external" href="https://nim-lang.org/">Nim</a>))"""
    assert c == """[<a class="reference external" href="https://nim-lang.org/">Nim</a>]"""


  test "rstToLatex: Basics":
    let input = inputBasics
    let output = rstToLatex(input, {})
    assert output == """\begin{rstpre}
\spanDirective{\%YAML 1.2}
\spanKeyword{---}
\spanStringLit{a string}\spanPunctuation{:} \spanStringLit{string}
\spanStringLit{a list}\spanPunctuation{:}
  \spanPunctuation{-} \spanStringLit{item 1}
  \spanPunctuation{-} \spanStringLit{item 2}
\spanStringLit{a map}\spanPunctuation{:}
\spanPunctuation{?} \spanStringLit{key}
\spanPunctuation{:} \spanStringLit{value}
\spanKeyword{...}
\end{rstpre}
"""

  test "rstToLatex: Block scalars":
    let input = inputBlockScalars
    let output = rstToLatex(input, {})
    assert output == """\begin{rstpre}
\spanStringLit{a literal block scalar}\spanPunctuation{:} \spanCommand{|}\spanCommand{}\spanLongStringLit{
  some text
  \# not a comment
 }\spanComment{\# a comment, since less indented}
  \spanComment{\# another comment}
\spanStringLit{a folded block scalar}\spanPunctuation{:} \spanCommand{>2}\spanCommand{}\spanLongStringLit{
   some text
  \# not a comment since indented as specified
 }\spanComment{\# a comment}
\spanStringLit{another literal block scalar}\spanPunctuation{:}
  \spanCommand{|+} \spanComment{\# comment after header}\spanLongStringLit{
 allowed, since more indented than parent}
\end{rstpre}
"""

  test "rstToLatex: Directives":
    let input = inputDirectives
    let output = rstToLatex(input, {})
    assert output == """\begin{rstpre}
\spanDirective{\%YAML 1.2}
\spanKeyword{---}
\spanStringLit{\%not a directive}
\spanKeyword{...}
\spanDirective{\%a directive}
\spanKeyword{...}
\spanStringLit{a string}
\spanStringLit{\% not a directive}
\spanKeyword{...}
\spanDirective{\%TAG ! !foo:}
\end{rstpre}
"""

  test "rstToLatex: Flow Style and Numbers":
    let input = inputStyleFlow
    let output = rstToLatex(input, {})
    assert output == """\begin{rstpre}
\spanPunctuation{\symbol{123}}
  \spanStringLit{"}\spanStringLit{quoted string"}\spanPunctuation{:} \spanDecNumber{42}\spanPunctuation{,}
  \spanStringLit{'single quoted string'}\spanPunctuation{:} \spanStringLit{false}\spanPunctuation{,}
  \spanPunctuation{\symbol{91}} \spanStringLit{list}\spanPunctuation{,} \spanStringLit{"}\spanStringLit{with"}\spanPunctuation{,} \spanStringLit{'entries'} \spanPunctuation{\symbol{93}}\spanPunctuation{:} \spanFloatNumber{73.32e-73}\spanPunctuation{,}
  \spanStringLit{more numbers}\spanPunctuation{:} \spanPunctuation{\symbol{91}}\spanDecNumber{-783}\spanPunctuation{,} \spanFloatNumber{11e78}\spanPunctuation{\symbol{93}}\spanPunctuation{,}
  \spanStringLit{not numbers}\spanPunctuation{:} \spanPunctuation{\symbol{91}} \spanStringLit{42e}\spanPunctuation{,} \spanStringLit{0023}\spanPunctuation{,} \spanStringLit{+32.37}\spanPunctuation{,} \spanStringLit{8 ball}\spanPunctuation{\symbol{93}}
\spanPunctuation{\symbol{125}}
\end{rstpre}
"""

  test "rstToLatex: Anchors, Aliases, Tags":
    let input = inputAnchorsAndTags
    let output = rstToLatex(input, {})
    assert output == """\begin{rstpre}
\spanKeyword{---} \spanTagStart{!!map}
\spanTagStart{!!str} \spanStringLit{string}\spanPunctuation{:} \spanTagStart{!<tag:yaml.org,2002:int>} \spanDecNumber{42}
\spanPunctuation{?} \spanLabel{\&anchor} \spanTagStart{!!seq} \spanPunctuation{\symbol{91}}\spanPunctuation{\symbol{93}}\spanPunctuation{:}
\spanPunctuation{:} \spanTagStart{!localtag} \spanStringLit{foo}
\spanStringLit{alias}\spanPunctuation{:} \spanReference{*anchor}
\end{rstpre}
"""

  test "rstToLatex: Edge cases":
    let input = inputEdgeCases
    let output = rstToLatex(input, {})
    assert output == """\begin{rstpre}
\spanKeyword{...}
 \spanStringLit{\%a string}\spanPunctuation{:}
  \spanStringLit{a:string:not:a:map}
\spanKeyword{...}
\spanStringLit{not a list}\spanPunctuation{:}
  \spanDecNumber{-2}
  \spanDecNumber{-3}
  \spanDecNumber{-4}
\spanStringLit{example.com/not/a\#comment}\spanPunctuation{:}
  \spanStringLit{?not a map key}
\end{rstpre}
"""

  test "rstToLatex: Markdown links":
    let
      a = rstToLatex(r"""(( [Nim](https://nim-lang.org/) ))""", {roSupportMarkdown})
      b = rstToLatex(r"""(([Nim](https://nim-lang.org/)))""", {roSupportMarkdown})
      c = rstToLatex(r"""[[Nim](https://nim-lang.org/)]""", {roSupportMarkdown})

    assert a == r"""(( \href{https://nim-lang.org/}{Nim} ))"""
    assert b == r"""((\href{https://nim-lang.org/}{Nim}))"""
    assert c == r"""\symbol{91}\href{https://nim-lang.org/}{Nim}\symbol{93}"""


  test "rstToOdt: Basics":
    let input = inputBasics
    let output = rstToOdt(input, {})
    const expected = staticRead"trstgenOdtTestSample0.xml" # Too big for inlined string
    assert output == expected

  test "rstToOdt: Block scalars":
    let input = inputBlockScalars
    let output = rstToOdt(input, {})
    const expected = staticRead"trstgenOdtTestSample1.xml" # Too big
    assert output == expected

  test "rstToOdt: Directives":
    let input = inputDirectives
    let output = rstToOdt(input, {})
    const expected = staticRead"trstgenOdtTestSample2.xml" # big
    assert output == expected

  test "rstToOdt: Flow Style and Numbers":
    let input = inputStyleFlow
    let output = rstToOdt(input, {})
    const expected = staticRead"trstgenOdtTestSample3.xml"
    assert output == expected

  test "rstToOdt: Anchors, Aliases, Tags":
    let input = inputAnchorsAndTags
    let output = rstToOdt(input, {})
    const expected = staticRead"trstgenOdtTestSample4.xml"
    assert output == expected

  test "rstToOdt: Edge cases":
    let input = inputEdgeCases
    let output = rstToOdt(input, {})
    const expected = staticRead"trstgenOdtTestSample5.xml"
    assert output == expected

  test "rstToOdt: Markdown links":
    let
      output0 = rstToOdt(r"""(( [Nim](https://nim-lang.org/) ))""", {roSupportMarkdown})
      output1 = rstToOdt(r"""(([Nim](https://nim-lang.org/)))""", {roSupportMarkdown})
      output2 = rstToOdt(r"""[[Nim](https://nim-lang.org/)]""", {roSupportMarkdown})
    const
      expected0 = staticRead"trstgenOdtTestSample6.xml"
      expected1 = staticRead"trstgenOdtTestSample7.xml"
      expected2 = staticRead"trstgenOdtTestSample8.xml"
    assert output0 == expected0
    assert output1 == expected1
    assert output2 == expected2
