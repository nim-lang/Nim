Documentation Style
===================

General Guidelines
------------------

* See also `nep1<https://nim-lang.github.io/Nim/nep1.html>`_ which should probably be merged here.
* Authors should document anything that is exported; documentation for private
  procs can be useful too (visible via `nim doc --docInternal foo.nim`:cmd:).
* Within documentation, a period (`.`) should follow each sentence (or sentence fragment) in a comment block.
  The documentation may be limited to one sentence fragment, but if multiple sentences are within the documentation,
  each sentence after the first should be complete and in present tense.
* Documentation is parsed as a custom ReStructuredText (RST) with partial markdown support.
* In nim sources, prefer single backticks to double backticks since it's simpler
  and `nim doc`:cmd: supports it. Likewise with ``rst`` files: `nim rst2html`:cmd: will render those as monospace, and
  adding ``.. default-role:: code`` to an ``rst`` file will also make those render as monospace when rendered directly
  in tools such as github.
* (debatable) In nim sources, for links, prefer ``[link text](link.html)`` to `\`link text<link.html>\`_`:code:
  since the syntax is simpler and markdown is more common (likewise, `nim rst2html`:cmd: also supports it in ``rst`` files).

.. code-block:: nim

  proc someproc*(s: string, foo: int) =
    ## Use single backticks for inline code, e.g.: `s` or `someExpr(true)`.
    ## Use a backlash to follow with alphanumeric char: `int8`\s are great.


Module-level documentation
--------------------------

Documentation of a module is placed at the top of the module itself. Each line of documentation begins with double hashes (`##`).
Sometimes `##[ multiline docs containing code ]##` is preferable, see ``lib/pure/times.nim``.
Code samples are encouraged, and should follow the general RST syntax:

.. code-block:: Nim

  ## The `universe` module computes the answer to life, the universe, and everything.
  ##
  ## .. code-block::
  ##  doAssert computeAnswerString() == 42


Within this top-level comment, you can indicate the authorship and copyright of the code, which will be featured in the produced documentation.

.. code-block:: Nim

  ## This is the best module ever. It provides answers to everything!
  ##
  ## :Author: Steve McQueen
  ## :Copyright: 1965
  ##

Leave a space between the last line of top-level documentation and the beginning of Nim code (the imports, etc.).

Procs, Templates, Macros, Converters, and Iterators
---------------------------------------------------

The documentation of a procedure should begin with a capital letter and should be in present tense. Variables referenced in the documentation should be surrounded by single tick marks:

.. code-block:: Nim

  proc example1*(x: int) =
    ## Prints the value of `x`.
    echo x

Whenever an example of usage would be helpful to the user, you should include one within the documentation in RST format as below.

.. code-block:: Nim

  proc addThree*(x, y, z: int8): int =
    ## Adds three `int8` values, treating them as unsigned and
    ## truncating the result.
    ##
    ## .. code-block::
    ##  # things that aren't suitable for a `runnableExamples` go in code-block:
    ##  echo execCmdEx("git pull")
    ##  drawOnScreen()
    runnableExamples:
      # `runnableExamples` is usually preferred to ``code-block``, when possible.
      doAssert addThree(3, 125, 6) == -122
    result = x +% y +% z

The command `nim doc`:cmd: will then correctly syntax highlight the Nim code within the documentation.

Types
-----

Exported types should also be documented. This documentation can also contain code samples, but those are better placed with the functions to which they refer.

.. code-block:: Nim

  type
    NamedQueue*[T] = object ## Provides a linked data structure with names
                            ## throughout. It is named for convenience. I'm making
                            ## this comment long to show how you can, too.
      name*: string ## The name of the item
      val*: T ## Its value
      next*: ref NamedQueue[T] ## The next item in the queue


You have some flexibility when placing the documentation:

.. code-block:: Nim

  type
    NamedQueue*[T] = object
      ## Provides a linked data structure with names
      ## throughout. It is named for convenience. I'm making
      ## this comment long to show how you can, too.
      name*: string ## The name of the item
      val*: T ## Its value
      next*: ref NamedQueue[T] ## The next item in the queue

Make sure to place the documentation beside or within the object.

.. code-block:: Nim

  type
    ## Bad: this documentation disappears because it annotates the `type` keyword
    ## above, not `NamedQueue`.
    NamedQueue*[T] = object
      name*: string ## This becomes the main documentation for the object, which
                    ## is not what we want.
      val*: T ## Its value
      next*: ref NamedQueue[T] ## The next item in the queue

Var, Let, and Const
-------------------

When declaring module-wide constants and values, documentation is encouraged. The placement of doc comments is similar to the `type` sections.

.. code-block:: Nim

  const
    X* = 42 ## An awesome number.
    SpreadArray* = [
      [1,2,3],
      [2,3,1],
      [3,1,2],
    ] ## Doc comment for `SpreadArray`.

Placement of comments in other areas is usually allowed, but will not become part of the documentation output and should therefore be prefaced by a single hash (`#`).

.. code-block:: Nim

  const
    BadMathVals* = [
      3.14, # pi
      2.72, # e
      0.58, # gamma
    ] ## A bunch of badly rounded values.

Nim supports Unicode in comments, so the above can be replaced with the following:

.. code-block:: Nim

  const
    BadMathVals* = [
      3.14, # π
      2.72, # e
      0.58, # γ
    ] ## A bunch of badly rounded values (including π!).
