##[
String `interpolation`:idx: / `format`:idx: inspired by
Python's ``f``-strings.



``fmt`` vs. ``&``
=================

You can use either ``fmt`` or the unary ``&`` operator for formatting. The
difference between them is subtle but important.

The ``fmt"{expr}"`` syntax is more aesthetically pleasing, but it hides a small
gotcha. The string is a
`generalized raw string literal <manual.html#lexical-analysis-generalized-raw-string-literals>`_.
This has some surprising effects:

.. code-block:: nim

    import strformat
    let msg = "hello"
    doAssert fmt"{msg}\n" == "hello\\n"

Because the literal is a raw string literal, the ``\n`` is not interpreted as
an escape sequence.

There are multiple ways to get around this, including the use of the ``&``
operator:

.. code-block:: nim

    import strformat
    let msg = "hello"

    doAssert &"{msg}\n" == "hello\n"

    doAssert fmt"{msg}{'\n'}" == "hello\n"
    doAssert fmt("{msg}\n") == "hello\n"
    doAssert "{msg}\n".fmt == "hello\n"

The choice of style is up to you.



Formatting strings
==================

.. code-block:: nim

    import strformat

    doAssert &"""{"abc":>4}""" == " abc"
    doAssert &"""{"abc":<4}""" == "abc "



Formatting floats
=================

.. code-block:: nim

    import strformat

    doAssert fmt"{-12345:08}" == "-0012345"
    doAssert fmt"{-1:3}" == " -1"
    doAssert fmt"{-1:03}" == "-01"
    doAssert fmt"{16:#X}" == "0x10"

    doAssert fmt"{123.456}" == "123.456"
    doAssert fmt"{123.456:>9.3f}" == "  123.456"
    doAssert fmt"{123.456:9.3f}" == "  123.456"
    doAssert fmt"{123.456:9.4f}" == " 123.4560"
    doAssert fmt"{123.456:>9.0f}" == "     123."
    doAssert fmt"{123.456:<9.4f}" == "123.4560 "

    doAssert fmt"{123.456:e}" == "1.234560e+02"
    doAssert fmt"{123.456:>13e}" == " 1.234560e+02"
    doAssert fmt"{123.456:13e}" == " 1.234560e+02"



Implementation details
======================

An expression like ``&"{key} is {value:arg} {{z}}"`` is transformed into:

.. code-block:: nim
  var temp = newStringOfCap(educatedCapGuess)
  format(key, temp)
  format(" is ", temp)
  format(value, arg, temp)
  format(" {z}", temp)
  temp

Parts of the string that are enclosed in the curly braces are interpreted
as Nim code, to escape an ``{`` or ``}`` double it.

``&`` delegates most of the work to an open overloaded set
of ``format`` procs. The required signature for a type ``T`` that supports
formatting is usually ``proc format(x: T; result: var string)`` for efficiency
but can also be ``proc format(x: T): string``. ``add`` and ``$`` procs are
used as the fallback implementation.

This is the concrete lookup algorithm that ``&`` uses:

.. code-block:: nim

  when compiles(format(arg, res)):
    format(arg, res)
  elif compiles(format(arg)):
    res.add format(arg)
  elif compiles(add(res, arg)):
    res.add(arg)
  else:
    res.add($arg)


The subexpression after the colon
(``arg`` in ``&"{key} is {value:arg} {{z}}"``) is an optional argument
passed to ``format``.

If an optional argument is present the following lookup algorithm is used:

.. code-block:: nim

  when compiles(format(arg, option, res)):
    format(arg, option, res)
  else:
    res.add format(arg, option)


For strings and numeric types the optional argument is a so-called
"standard format specifier".



Standard format specifier for strings, integers and floats
==========================================================

The general form of a standard format specifier is::

  [[fill]align][sign][#][0][minimumwidth][.precision][type]

The square brackets ``[]`` indicate an optional element.

The optional align flag can be one of the following:

'<'
    Forces the field to be left-aligned within the available
    space. (This is the default for strings.)

'>'
    Forces the field to be right-aligned within the available space.
    (This is the default for numbers.)

'^'
    Forces the field to be centered within the available space.

Note that unless a minimum field width is defined, the field width
will always be the same size as the data to fill it, so that the alignment
option has no meaning in this case.

The optional 'fill' character defines the character to be used to pad
the field to the minimum width. The fill character, if present, must be
followed by an alignment flag.

The 'sign' option is only valid for numeric types, and can be one of the following:

=================        ====================================================
  Sign                   Meaning
=================        ====================================================
``+``                    Indicates that a sign should be used for both
                         positive as well as negative numbers.
``-``                    Indicates that a sign should be used only for
                         negative numbers (this is the default behavior).
(space)                  Indicates that a leading space should be used on
                         positive numbers.
=================        ====================================================

If the '#' character is present, integers use the 'alternate form' for formatting.
This means that binary, octal, and hexadecimal output will be prefixed
with '0b', '0o', and '0x', respectively.

'width' is a decimal integer defining the minimum field width. If not specified,
then the field width will be determined by the content.

If the width field is preceded by a zero ('0') character, this enables
zero-padding.

The 'precision' is a decimal number indicating how many digits should be displayed
after the decimal point in a floating point conversion. For non-numeric types the
field indicates the maximum field size - in other words, how many characters will
be used from the field content. The precision is ignored for integer conversions.

Finally, the 'type' determines how the data should be presented.

The available integer presentation types are:


=================        ====================================================
  Type                   Result
=================        ====================================================
``b``                    Binary. Outputs the number in base 2.
``d``                    Decimal Integer. Outputs the number in base 10.
``o``                    Octal format. Outputs the number in base 8.
``x``                    Hex format. Outputs the number in base 16, using
                         lower-case letters for the digits above 9.
``X``                    Hex format. Outputs the number in base 16, using
                         uppercase letters for the digits above 9.
(None)                   the same as 'd'
=================        ====================================================


The available floating point presentation types are:

=================        ====================================================
  Type                   Result
=================        ====================================================
``e``                    Exponent notation. Prints the number in scientific
                         notation using the letter 'e' to indicate the
                         exponent.
``E``                    Exponent notation. Same as 'e' except it converts
                         the number to uppercase.
``f``                    Fixed point. Displays the number as a fixed-point
                         number.
``F``                    Fixed point. Same as 'f' except it converts the
                         number to uppercase.
``g``                    General format. This prints the number as a
                         fixed-point number, unless the number is too
                         large, in which case it switches to 'e'
                         exponent notation.
``G``                    General format. Same as 'g' except switches to 'E'
                         if the number gets to large.
(None)                   similar to 'g', except that it prints at least one
                         digit after the decimal point.
=================        ====================================================



Future directions
=================

A curly expression with commas in it like ``{x, argA, argB}`` could be
transformed to ``format(x, argA, argB, res)`` in order to support
formatters that do not need to parse a custom language within a custom
language but instead prefer to use Nim's existing syntax. This also
helps in readability since there is only so much you can cram into
single letter DSLs.

]##
