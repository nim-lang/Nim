Style Guide (Documentation)
===========================

General Guidelines
------------------

* Authors should document anything that is exported.
* Within a documentation for a procedure, a period (`.`) should follow each sentence in a comment block if there is more than one sentence in that block; otherwise, no period should be used. In other sections, complete sentences should have periods. Sentence fragments should have none.
* Documentation is parsed as RST (RestructuredText).
* Inline code should be surrounded by double tick marks (``` `` ```). With ReStructuredTest (RST), if you would like a character to immediately follow inline code (e.g., "``int8``s are great!"), escape the following character with a backslash (`\`). The preceding is typed as ``` ``int8``\s are great!```.

Module-level documentation
--------------------------

Documentation of a module is placed at the top of the module itself. Each line of documentation begins with double hashes (`##`).
Code samples are encouraged, and should follow the general RST syntax:

```nim
## The ``universe`` module computes the answer to life, the universe, and everything.
##
## .. code-block:: nim
##  echo computeAnswerString*() # "42"
```

Within this top-level comment, you can indicate the authorship and copyright of the code, which will be featured in the produced documentation.

```nim
## This is the best module ever. It provides answers to everything!
##
## :Author: Steve McQueen
## :Copyright: 1965
##
```

Users are encouraged to leave a space between the last line of top-level documentation and the beginning of Nim code (the imports, etc.).

Procs, Templates, Macros, Converters, and Iterators
---------------------------------------------------

The documentation of a procedure should begin with a capital letter and should be in present tense. Variables referenced in the documentation should be surrounded by double tick marks (``` `` ```).

```nim
    proc example1*(x: int) =
        ## Prints the value of ``x``
        echo x
```

Whenever an example of usage would be helpful to the user, please include a sample within the documentation in RST format as below.

```nim
    proc addThree*(x, y, z: int8): int =
        ## Adds three ``int8`` values, treating them as unsigned and
        ## truncating the result
        ##
        ## .. code-block:: nim
        ##  echo addThree(3, 125, 6) # -122
        result = x +% y +% z
```

The commands ``nim doc`` and ``nim doc2`` will then correctly syntax highlight the Nim code within the documentation.

Types
-----

Types should also be documented. This documentation can also contain code samples, but those are likely better placed with the functions to which they refer.

```nim
type
  NamedQueue*[T] = object ## Provides a linked data structure with names
                          ## throughout. Named for convenience. I'm making
                          ## this comment long to show how you can, too.
    name*: string ## The name of the item
    val*: T ## Its value
    next*: ref NamedQueue[T] ## The next item in the queue
```

You have some flexibility when placing the documentation:
```nim
type
  NamedQueue*[T] = object
    ## Provides a linked data structure with names
    ## throughout. Named for convenience. I'm making
    ## this comment long to show how you can, too.
    name*: string ## The name of the item
    val*: T ## Its value
    next*: ref NamedQueue[T] ## The next item in the queue
```

Make sure to place the documentation beside or within the object.

```nim
type
  ## This documentation disappears. It's basically annotating the
  ## ``type`` above.
  NamedQueue*[T] = object
    name*: string ## This becomes the main documentation for the object, which
                  ## is not what we want.
    val*: T ## Its value
    next*: ref NamedQueue[T] ## The next item in the queue

```

Var, Let, and Const
-------------------

When declaring module-wide constants and values, documentation is encouraged. The placement of doc comments is similar to the ``type`` sections.

```nim
const
  X* = 42 ## An awesome number
  SpreadArray* = [
    [1,2,3],
    [2,3,1],
    [3,1,2],
  ] ## Doc comment for ``SpreadArray``
```

Placement of comments in other areas is usually allowed, but will not become part of the documentation output.

```nim
const
  BadMathVals* = [
    3.14, ## pi
    2.72, ## e
    0.58, ## gamma
  ] ## A bunch of badly rounded values
```

In the produced documentation, the comments beside the elements of ``BadMathVals`` do not make it into the final documentation.

As a final note, Nim supports Unicode in comments just fine, so the above can be replaced with the following:

```nim
const
  BadMathVals* = [
    3.14, ## π
    2.72, ## e
    0.58, ## γ
  ] ## A bunch of badly rounded values (including π!)
```
