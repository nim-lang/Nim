.. title:: Welcome to Nim Book
.. importdoc:: page1
.. importdoc:: sections/1/intro

This is a test project for `nim book`:cmd:.

# Code

Inline code snippet:

```nim
proc twice*(a: int): int =
  a * 2
```

This snippet is tested during documentation build:

```nim test
proc twice*(a: int): int =
  a * 2

assert 10.twice == 20
```

The same but using `.. code::` directive:

.. code::
  proc twice*(a: int): int =
    a * 2

.. code::
  :test:

  proc twice*(a: int): int =
    a * 2

  assert 10.twice == 20

Code included from a source file:

.. include:: ./code1.nim
  :code:
  
Selective inclusuion:

.. include:: ./code2.nim
  :code:
  :start-after:#doublestart
  :end-before:#doubleend

Doesn't have to be Nim code:

.. include:: ./code3.py
  :code: python

# Admonitions

.. note:: General info

.. warning::
    It's dangerous to go alone!

    Take this!

.. error:: Oh, snap :-(

.. important::
  Admonitions can contain lists and code blocks.

  - This
  - is
  - great!

  .. code-block::
    echo "Indeed"

# Links

This is a link to a heading on the same page: [Code].

This is a link to a heading on another page: [Heading].

Same, but with different syntax: `Heading`_.

You can use standard Markdown syntax, too: [I am a link](page1.html#heading)
