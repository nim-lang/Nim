##[
The system module defines several common functions for working with strings,
such as:
* ``$`` for converting other data-types to strings
* ``&`` for string concatenation
* ``add`` for adding a new character or a string to the existing one
* ``in`` (alias for ``contains``) and ``notin`` for checking if a character
  is in a string

This module builds upon that, providing additional functionality in form of
procedures, iterators and templates for strings.
]##

runnableExamples:
  let
    numbers = @[867, 5309]
    multiLineString = "first line\nsecond line\nthird line"

  let jenny = numbers.join("-")
  assert jenny == "867-5309"

  assert splitLines(multiLineString) ==
        @["first line", "second line", "third line"]
  assert split(multiLineString) == @["first", "line", "second",
                                     "line", "third", "line"]
  assert indent(multiLineString, 4) ==
         "    first line\n    second line\n    third line"
  assert 'z'.repeat(5) == "zzzzz"

## The chaining of functions is possible thanks to the
## `method call syntax<manual.html#procedures-method-call-syntax>`_.

runnableExamples:
  from sequtils import map

  let jenny = "867-5309"
  assert jenny.split('-').map(parseInt) == @[867, 5309]

  assert "Beetlejuice".indent(1).repeat(3).strip ==
         "Beetlejuice Beetlejuice Beetlejuice"

##[
This module is also available for the `JavaScript target
<backends.html#the-javascript-target>`_.

----

**See also:**
* `strformat module<strformat.html>`_ for string interpolation and formatting
* `unicode module<unicode.html>`_ for Unicode UTF-8 handling
* `sequtils module<collections/sequtils.html>`_ for operations on container
  types (including strings)
* `parseutils module<parseutils.html>`_ for lower-level parsing of tokens,
  numbers, identifiers, etc.
* `parseopt module<parseopt.html>`_ for command-line parsing
* `strtabs module<strtabs.html>`_ for efficient hash tables
  (dictionaries, in some programming languages) mapping from strings to strings
* `pegs module<pegs.html>`_ for PEG (Parsing Expression Grammar) support
* `ropes module<ropes.html>`_ for rope data type, which can represent very
  long strings efficiently
* `re module<re.html>`_ for regular expression (regex) support
* `strscans<strscans.html>`_ for ``scanf`` and ``scanp`` macros, which offer
  easier substring extraction than regular expressions

]##