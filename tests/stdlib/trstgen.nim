discard """
outputsub: ""
"""

# tests for rstgen module.

import ../../lib/packages/docutils/rstgen
import ../../lib/packages/docutils/rst
import unittest

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


  test "Markdown links":
    let
      a = rstToHtml("(( [Nim](https://nim-lang.org/) ))", {roSupportMarkdown}, defaultConfig())
      b = rstToHtml("(([Nim](https://nim-lang.org/)))", {roSupportMarkdown}, defaultConfig())
      c = rstToHtml("[[Nim](https://nim-lang.org/)]", {roSupportMarkdown}, defaultConfig())

    assert a == """(( <a class="reference external" href="https://nim-lang.org/">Nim</a> ))"""
    assert b == """((<a class="reference external" href="https://nim-lang.org/">Nim</a>))"""
    assert c == """[<a class="reference external" href="https://nim-lang.org/">Nim</a>]"""
