===================
Source Code Filters
===================

.. include:: rstcommon.rst
.. default-role:: code
.. contents::

A `Source Code Filter (SCF)`  transforms the input character stream to an in-memory
output stream before parsing. A filter can be used to provide templating
systems or preprocessors.

To use a filter for a source file the `#?` notation is used::

  #? stdtmpl(subsChar = '$', metaChar = '#')
  #proc generateXML(name, age: string): string =
  #  result = ""
  <xml>
    <name>$name</name>
    <age>$age</age>
  </xml>

As the example shows, passing arguments to a filter can be done
just like an ordinary procedure call with named or positional arguments. The
available parameters depend on the invoked filter. Before version 0.12.0 of
the language `#!` was used instead of `#?`.

**Hint:** With `--hint:codeBegin:on`:option: or `--verbosity:2`:option:
(or higher) while compiling or `nim check`:cmd:, Nim lists the processed code after
each filter application.

Usage
=====

First, put your SCF code in a separate file with filters specified in the first line. 
**Note:** You can name your SCF file with any file extension you want, but the
conventional extension is `.nimf`
(it used to be `.tmpl` but that was too generic, for example preventing github to
recognize it as Nim source file).

If we use `generateXML` code shown above and call the SCF file `xmlGen.nimf`
In your `main.nim`:

.. code-block:: nim
  include "xmlGen.nimf"
  
  echo generateXML("John Smith","42")

Pipe operator
=============

Filters can be combined with the `|` pipe operator::

  #? strip(startswith="<") | stdtmpl
  #proc generateXML(name, age: string): string =
  #  result = ""
  <xml>
    <name>$name</name>
    <age>$age</age>
  </xml>


Available filters
=================

Replace filter
--------------

The replace filter replaces substrings in each line.

Parameters and their defaults:

* `sub: string = ""`
    the substring that is searched for

* `by: string = ""`
    the string the substring is replaced with


Strip filter
------------

The strip filter simply removes leading and trailing whitespace from
each line.

Parameters and their defaults:

* `startswith: string = ""`
    strip only the lines that start with *startswith* (ignoring leading
    whitespace). If empty every line is stripped.

* `leading: bool = true`
    strip leading whitespace

* `trailing: bool = true`
    strip trailing whitespace


StdTmpl filter
--------------

The stdtmpl filter provides a simple templating engine for Nim. The
filter uses a line based parser: Lines prefixed with a *meta character*
(default: `#`) contain Nim code, other lines are verbatim. Because
indentation-based parsing is not suited for a templating engine, control flow
statements need `end X` delimiters.

Parameters and their defaults:

* `metaChar: char = '#'`
    prefix for a line that contains Nim code

* `subsChar: char = '$'`
    prefix for a Nim expression within a template line

* `conc: string = " & "`
    the operation for concatenation

* `emit: string = "result.add"`
    the operation to emit a string literal

* `toString: string = "$"`
    the operation that is applied to each expression

Example::

  #? stdtmpl | standard
  #proc generateHTMLPage(title, currentTab, content: string,
  #                      tabs: openArray[string]): string =
  #  result = ""
  <head><title>$title</title></head>
  <body>
    <div id="menu">
      <ul>
    #for tab in items(tabs):
      #if currentTab == tab:
      <li><a id="selected"
      #else:
      <li><a
      #end if
      href="${tab}.html">$tab</a></li>
    #end for
      </ul>
    </div>
    <div id="content">
      $content
      A dollar: $$.
    </div>
  </body>

The filter transforms this into:

.. code-block:: nim
  proc generateHTMLPage(title, currentTab, content: string,
                        tabs: openArray[string]): string =
    result = ""
    result.add("<head><title>" & $(title) & "</title></head>\n" &
      "<body>\n" &
      "  <div id=\"menu\">\n" &
      "    <ul>\n")
    for tab in items(tabs):
      if currentTab == tab:
        result.add("    <li><a id=\"selected\" \n")
      else:
        result.add("    <li><a\n")
      #end
      result.add("    href=\"" & $(tab) & ".html\">" & $(tab) & "</a></li>\n")
    #end
    result.add("    </ul>\n" &
      "  </div>\n" &
      "  <div id=\"content\">\n" &
      "    " & $(content) & "\n" &
      "    A dollar: $.\n" &
      "  </div>\n" &
      "</body>\n")


Each line that does not start with the meta character (ignoring leading
whitespace) is converted to a string literal that is added to `result`.

The substitution character introduces a Nim expression *e* within the
string literal. *e* is converted to a string with the *toString* operation
which defaults to `$`. For strong type checking, set `toString` to the
empty string. *e* must match this PEG pattern::

  e <- [a-zA-Z\128-\255][a-zA-Z0-9\128-\255_.]* / '{' x '}'
  x <- '{' x+ '}' / [^}]*

To produce a single substitution character it has to be doubled: `$$`
produces `$`.

The template engine is quite flexible. It is easy to produce a procedure that
writes the template code directly to a file::

  #? stdtmpl(emit="f.write") | standard
  #proc writeHTMLPage(f: File, title, currentTab, content: string,
  #                   tabs: openArray[string]) =
  <head><title>$title</title></head>
  <body>
    <div id="menu">
      <ul>
    #for tab in items(tabs):
      #if currentTab == tab:
      <li><a id="selected"
      #else:
      <li><a
      #end if
      href="${tab}.html" title = "$title - $tab">$tab</a></li>
    #end for
      </ul>
    </div>
    <div id="content">
      $content
      A dollar: $$.
    </div>
  </body>
