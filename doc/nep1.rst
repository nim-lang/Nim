==============================================
Nim Enhancement Proposal #1 - Standard Library Style Guide
==============================================
:Author: Clay Sweetser, Dominik Picheta
:Version: |nimversion|

.. contents::


Introduction
============
Although Nim supports a variety of code and formatting styles, it is
nevertheless beneficial that certain community efforts, such as the standard
library, should follow a consistent set of style guidelines when suitable.
This enhancement proposal aims to list a series of guidelines that the standard
library should follow.

Note that there can be exceptions to these rules. Nim being as flexible as it
is, there will be parts of this style guide that don't make sense in certain
contexts. Furthermore, just as
`Python's style guide<http://legacy.python.org/dev/peps/pep-0008/>`_ changes
over time, this style guide will too.

These rules will only be enforced for contributions to the Nim
codebase and official projects, such as the Nim compiler, the standard library,
and the various official tools such as C2Nim.

----------------
Style Guidelines
----------------

Spacing and Whitespace Conventions
-----------------------------------

- Lines should be no longer than 80 characters. Limiting the amount of
  information present on each line makes for more readable code - the reader
  has smaller chunks to process.

- Two spaces should be used for indentation of blocks; tabstops are not allowed
  (the compiler enforces this). Using spaces means that the appearance of code
  is more consistent across editors. Unlike spaces, tabstop width varies across
  editors, and not all editors provide means of changing this width.

- Although use of whitespace for stylistic reasons other than the ones endorsed
  by this guide are allowed, careful thought should be put into such practices.
  Not all editors support automatic alignment of code sections, and re-aligning
  long sections of code by hand can quickly become tedious.

  .. code-block:: nim
    # This is bad, as the next time someone comes
    # to edit this code block, they
    # must re-align all the assignments again:
    type
      WordBool*    = int16
      CalType*     = int
      ... # 5 lines later
      CalId*       = int
      LongLong*    = int64
      LongLongPtr* = ptr LongLong


Naming Conventions
-------------------------

Note: While the rules outlined below are the *current* naming conventions,
these conventions have not always been in place. Previously, the naming
conventions for identifiers followed the Pascal tradition of prefixes which
indicated the base type of the identifier - PFoo for pointer and reference
types, TFoo for value types, EFoo for exceptions, etc. Though this has since
changed, there are many places in the standard library which still use this
convention. Such style remains in place purely for legacy reasons, and will be
changed in the future.

- Type identifiers should be in PascalCase. All other identifiers should be in
  camelCase with the exception of constants which **may** use PascalCase but
  are not required to.

  .. code-block:: nim
    # Constants can start with either a lower case or upper case letter.
    const aConstant = 42
    const FooBar = 4.2

    var aVariable = "Meep" # Variables must start with a lowercase letter.

    # Types must start with an uppercase letter.
    type
      FooBar = object

  For constants coming from a C/C++ wrapper, ALL_UPPERCASE are allowed, but ugly.
  (Why shout CONSTANT? Constants do no harm, variables do!)

- When naming types that come in value, pointer, and reference varieties, use a
  regular name for the variety that is to be used the most, and add a "Obj",
  "Ref", or "Ptr" suffix for the other varieties. If there is no single variety
  that will be used the most, add the suffixes to the pointer variants only. The
  same applies to C/C++ wrappers.

  .. code-block:: nim
    type
      Handle = object # Will be used most often
        fd: int64
      HandleRef = ref Handle # Will be used less often

- Exception and Error types should have the "Error" suffix.

  .. code-block:: nim
    type
      UnluckyError = object of Exception

- Unless marked with the `{.pure.}` pragma, members of enums should have an
  identifying prefix, such as an abbreviation of the enum's name.

  .. code-block:: nim
    type
      PathComponent = enum
        pcDir
        pcLinkToDir
        pcFile
        pcLinkToFile

- Non-pure enum values should use camelCase whereas pure enum values should use
  PascalCase.

  .. code-block:: nim
    type
      PathComponent {.pure.} = enum
        Dir
        LinkToDir
        File
        LinkToFile

- In the age of HTTP, HTML, FTP, TCP, IP, UTF, WWW it is foolish to pretend
  these are somewhat special words requiring all uppercase. Instead treat them
  as what they are: Real words. So it's ``parseUrl`` rather than
  ``parseURL``, ``checkHttpHeader`` instead of ``checkHTTPHeader`` etc.

- Operations like ``mitems`` or ``mpairs`` (or the now deprecated ``mget``)
  that allow a *mutating view* into some data structure should start with an ``m``.
- When both in-place mutation and 'returns transformed copy' are available the latter
  is a past participle of the former:

  - reverse and reversed in algorithm
  - sort and sorted
  - rotate and rotated

- When the 'returns transformed copy' version already exists like ``strutils.replace``
  an in-place version should get an ``-In`` suffix (``replaceIn`` for this example).


Coding Conventions
------------------

- The 'return' statement should ideally be used when its control-flow properties
  are required. Use a procedure's implicit 'result' variable whenever possible.
  This improves readability.

  .. code-block:: nim
    proc repeat(text: string, x: int): string =
      result = ""

      for i in 0 .. x:
        result.add($i)

- Use a proc when possible, only using the more powerful facilities of macros,
  templates, iterators, and converters when necessary.

- Use the ``let`` statement (not the ``var`` statement) when declaring variables that
  do not change within their scope. Using the ``let`` statement ensures that
  variables remain immutable, and gives those who read the code a better idea
  of the code's purpose.


Conventions for multi-line statements and expressions
-----------------------------------------------------

- Tuples which are longer than one line should indent their parameters to
  align with the parameters above it.

  .. code-block:: nim
    type
      LongTupleA = tuple[wordyTupleMemberOne: int, wordyTupleMemberTwo: string,
                         wordyTupleMemberThree: float]

- Similarly, any procedure and procedure type declarations that are longer
  than one line should do the same thing.

  .. code-block:: nim
    type
      EventCallback = proc (timeReceived: Time, errorCode: int, event: Event,
                            output: var string)

    proc lotsOfArguments(argOne: string, argTwo: int, argThree: float
                         argFour: proc(), argFive: bool): int
                        {.heyLookALongPragma.} =

- Multi-line procedure calls should continue on the same column as the opening
  parenthesis (like multi-line procedure declarations).

  .. code-block:: nim
    startProcess(nimExecutable, currentDirectory, compilerArguments
                 environment, processOptions)
