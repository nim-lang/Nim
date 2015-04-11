What is NRE?
============

A regular expression library for Nim using PCRE to do the hard work.

Why?
----

The `re.nim <http://nim-lang.org/re.html>`__ module that
`Nim <http://nim-lang.org/>`__ provides in its standard library is
inadequate:

-  It provides only a limited number of captures, while the underling
   library (PCRE) allows an unlimited number.

-  Instead of having one proc that returns both the bounds and
   substring, it has one for the bounds and another for the substring.

-  If the splitting regex is empty (``""``), then it returns the input
   string instead of following `Perl <https://ideone.com/dDMjmz>`__,
   `Javascript <http://jsfiddle.net/xtcbxurg/>`__, and
   `Java <https://ideone.com/hYJuJ5>`__'s precedent of returning a list
   of each character (``"123".split(re"") == @["1", "2", "3"]``).


Other Notes
-----------

By default, NRE compiles it’s own PCRE. If this is undesirable, pass
``-d:pcreDynlib`` to use whatever dynamic library is available on the
system. This may have unexpected consequences if the dynamic library
doesn’t have certain features enabled.

Types
-----

``type Regex* = ref object``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Represents the pattern that things are matched against, constructed with
``re(string, string)``. Examples: ``re"foo"``, ``re(r"foo # comment",
"x<anycrlf>")``, ``re"(?x)(*ANYCRLF)foo # comment"``. For more details
on the leading option groups, see the `Option
Setting <http://man7.org/linux/man-pages/man3/pcresyntax.3.html#OPTION_SETTING>`__
and the `Newline
Convention <http://man7.org/linux/man-pages/man3/pcresyntax.3.html#NEWLINE_CONVENTION>`__
sections of the `PCRE syntax
manual <http://man7.org/linux/man-pages/man3/pcresyntax.3.html>`__.

``pattern: string``
    the string that was used to create the pattern.

``captureCount: int``
    the number of captures that the pattern has.

``captureNameId: Table[string, int]``
    a table from the capture names to their numeric id.


Flags
.....

-  ``8`` - treat both the pattern and subject as UTF8
-  ``9`` - prevents the pattern from being interpreted as UTF, no matter
   what
-  ``A`` - as if the pattern had a ``^`` at the beginning
-  ``E`` - DOLLAR\_ENDONLY
-  ``f`` - fails if there is not a match on the first line
-  ``i`` - case insensitive
-  ``m`` - multi-line, ``^`` and ``$`` match the beginning and end of
   lines, not of the subject string
-  ``N`` - turn off auto-capture, ``(?foo)`` is necessary to capture.
-  ``s`` - ``.`` matches newline
-  ``U`` - expressions are not greedy by default. ``?`` can be added to
   a qualifier to make it greedy.
-  ``u`` - same as ``8``
-  ``W`` - Unicode character properties; ``\w`` matches ``к``.
-  ``X`` - "Extra", character escapes without special meaning (``\w``
   vs. ``\a``) are errors
-  ``x`` - extended, comments (``#``) and newlines are ignored
   (extended)
-  ``Y`` - pcre.NO\_START\_OPTIMIZE,
-  ``<cr>`` - newlines are separated by ``\r``
-  ``<crlf>`` - newlines are separated by ``\r\n`` (Windows default)
-  ``<lf>`` - newlines are separated by ``\n`` (UNIX default)
-  ``<anycrlf>`` - newlines are separated by any of the above
-  ``<any>`` - newlines are separated by any of the above and Unicode
   newlines:

    single characters VT (vertical tab, U+000B), FF (form feed, U+000C),
    NEL (next line, U+0085), LS (line separator, U+2028), and PS
    (paragraph separator, U+2029). For the 8-bit library, the last two
    are recognized only in UTF-8 mode.
    —  man pcre

-  ``<bsr_anycrlf>`` - ``\R`` matches CR, LF, or CRLF
-  ``<bsr_unicode>`` - ``\R`` matches any unicode newline
-  ``<js>`` - Javascript compatibility
-  ``<no_study>`` - turn off studying; study is enabled by deafault


``type RegexMatch* = object``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Usually seen as Option[RegexMatch], it represents the result of an
execution. On failure, it is ``None[RegexMatch]``, but if you want
automated derefrence, import ``optional_t.nonstrict``. The available
fields are as follows:

``pattern: Regex``
    the pattern that is being matched

``str: string``
    the string that was matched against

``captures[]: string``
    the string value of whatever was captured at that id. If the value
    is invalid, then behavior is undefined. If the id is ``-1``, then
    the whole match is returned. If the given capture was not matched,
    ``nil`` is returned.

    -  ``"abc".match(re"(\w)").captures[0] == "a"``
    -  ``"abc".match(re"(?<letter>\w)").captures["letter"] == "a"``
    -  ``"abc".match(re"(\w)\w").captures[-1] == "ab"``

``captureBounds[]: Option[Slice[int]]``
    gets the bounds of the given capture according to the same rules as
    the above. If the capture is not filled, then ``None`` is returned.
    The bounds are both inclusive.

    -  ``"abc".match(re"(\w)").captureBounds[0] == 0 .. 0``
    -  ``"abc".match(re"").captureBounds[-1] == 0 .. -1``
    -  ``"abc".match(re"abc").captureBounds[-1] == 0 .. 2``

``match: string``
    the full text of the match.

``matchBounds: Slice[int]``
    the bounds of the match, as in ``captureBounds[]``

``(captureBounds|captures).toTable``
    returns a table with each named capture as a key.

``(captureBounds|captures).toSeq``
    returns all the captures by their number.

``$: string``
    same as ``match``


``type SyntaxError* = ref object of Exception``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Thrown when there is a syntax error in the
regular expression string passed in


``type StudyError* = ref object of Exception``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Thrown when studying the regular expression failes
for whatever reason. The message contains the error
code.


Operations
----------

``proc match*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch]``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Like ```find(...)`` <#proc-find>`__, but anchored to the start of the
string. This means that ``"foo".match(re"f") == true``, but
``"foo".match(re"o") == false``.


``iterator findIter*(str: string, pattern: Regex, start = 0, endpos = int.high): RegexMatch``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Works the same as ```find(...)`` <#proc-find>`__, but finds every
non-overlapping match. ``"2222".find(re"22")`` is ``"22", "22"``, not
``"22", "22", "22"``.

Arguments are the same as ```find(...)`` <#proc-find>`__

Variants:

-  ``proc findAll(...)`` returns a ``seq[string]``


``proc find*(str: string, pattern: Regex, start = 0, endpos = int.high): Option[RegexMatch]``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Finds the given pattern in the string between the end and start
positions.

``start``
    The start point at which to start matching. ``|abc`` is ``0``;
    ``a|bc`` is ``1``

``endpos``
    The maximum index for a match; ``int.high`` means the end of the
    string, otherwise it’s an inclusive upper bound.


``proc split*(str: string, pattern: Regex, maxSplit = -1, start = 0): seq[string]``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Splits the string with the given regex. This works according to the
rules that Perl and Javascript use:

-  If the match is zero-width, then the string is still split:
   ``"123".split(r"") == @["1", "2", "3"]``.

-  If the pattern has a capture in it, it is added after the string
   split: ``"12".split(re"(\d)") == @["", "1", "", "2", ""]``.

-  If ``maxsplit != -1``, then the string will only be split
   ``maxsplit - 1`` times. This means that there will be ``maxsplit``
   strings in the output seq.
   ``"1.2.3".split(re"\.", maxsplit = 2) == @["1", "2.3"]``

``start`` behaves the same as in ```find(...)`` <#proc-find>`__.


``proc replace*(str: string, pattern: Regex, subproc: proc (match: RegexMatch): string): string``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Replaces each match of Regex in the string with ``sub``, which should
never be or return ``nil``.

If ``sub`` is a ``proc (RegexMatch): string``, then it is executed with
each match and the return value is the replacement value.

If ``sub`` is a ``proc (string): string``, then it is executed with the
full text of the match and and the return value is the replacement
value.

If ``sub`` is a string, the syntax is as follows:

-  ``$$`` - literal ``$``
-  ``$123`` - capture number ``123``
-  ``$foo`` - named capture ``foo``
-  ``${foo}`` - same as above
-  ``$1$#`` - first and second captures
-  ``$#`` - first capture
-  ``$0`` - full match

If a given capture is missing, a ``ValueError`` exception is thrown.


``proc escapeRe*(str: string): string``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Escapes the string so it doesn’t match any special characters.
Incompatible with the Extra flag (``X``).
