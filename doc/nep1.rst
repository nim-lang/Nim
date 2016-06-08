==============================================
Nim Enhancement Proposal #1 - Standard Library Style Guide
==============================================
:Author: Clay Sweetser
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
    const aConstant = 42
    const FooBar = 4.2

    var aVariable = "Meep"

    type FooBar = object

  For constants coming from a C/C++ wrapper, ALL_UPPERCASE are allowed, but ugly.
  (Why shout CONSTANT? Constants do no harm, variables do!)

- When naming types that come in value, pointer, and reference varieties, use a
  regular name for the variety that is to be used the most, and add a "Obj",
  "Ref", or "Ptr" suffix for the other varieties. If there is no single variety
  that will be used the most, add the suffixes to the pointer variants only. The
  same applies to C/C++ wrappers.

  .. code-block:: nim
    type
      Handle = int64 # Will be used most often
      HandleRef = ref Handle # Will be used less often
- Exception and Error types should have the "Error" suffix.

  .. code-block:: nim
    type UnluckyError = object of Exception
- Unless marked with the `{.pure.}` pragma, members of enums should have an
  identifying prefix, such as an abbreviation of the enum's name.

  .. code-block:: nim
    type PathComponent = enum
      pcDir
      pcLinkToDir
      pcFile
      pcLinkToFile
- Non-pure enum values should use camelCase whereas pure enum values should use
  PascalCase.

  .. code-block:: nim
    type PathComponent {.pure.} = enum
      Dir
      LinkToDir
      File
      LinkToFile
- In the age of HTTP, HTML, FTP, TCP, IP, UTF, WWW it is foolish to pretend
  these are somewhat special words requiring all uppercase. Instead tread them as what they are: Real words. So it's ``parseUrl`` rather than ``parseURL``, ``checkHttpHeader`` instead of ``checkHTTPHeader`` etc.


Coding Conventions
------------------

- The 'return' statement should only be used when it's control-flow properties
  are required. Use a procedures implicit 'result' variable instead. This
  improves readability.

- Prefer to return `[]` and `""` instead of `nil`, or throw an exception if
  that is appropriate.

- Use a proc when possible, only using the more powerful facilities of macros,
  templates, iterators, and converters when necessary.

- Use the 'let' statement (not the var statement) when declaring variables that
  do not change within their scope. Using the let statement ensures that
  variables remain immutable, and gives those who read the code a better idea
  of the code's purpose.

- For new types, it is usually recommended to have both 'ref' and 'object'
  versions of the type available for others to use. By making both variants
  available for use, the type may be allocated both on the stack and the heap.


Conventions for multi-line statements and expressions
-----------------------------------------------------

- Any tuple type declarations that are longer than one line should use the
  regular object type layout instead. This enhances the readability of the
  tuple declaration by splitting its members information across multiple lines.

  .. code-block:: nim
    type
      ShortTuple = tuple[a: int, b: string]

      ReallyLongTuple = tuple
        wordyTupleMemberOne: string
        wordyTupleMemberTwo: int
        wordyTupleMemberThree: double
- Similarly, any procedure type declarations that are longer than one line
  should be formatted in the style of a regular type.

  .. code-block:: nim
    type
      EventCallback = proc (
        timeRecieved: Time
        errorCode: int
        event: Event
      )
- Multi-line procedure declarations/argument lists should continue on the same
  column as the opening brace. This style is different from that of procedure
  type declarations in order to distinguish between the heading of a procedure
  and its body. If the procedure name is too long to make this style
  convenient, then one of the styles for multi-line procedure calls (or
  consider renaming your procedure).

  .. code-block:: nim
    proc lotsOfArguments(argOne: string, argTwo: int, argThree:float
                         argFour: proc(), argFive: bool): int
                        {.heyLookALongPragma.} =
- Multi-line procedure calls should either have one argument per line (like
  multi-line type declarations) or continue on the same column as the opening
  parenthesis (like multi-line procedure declarations).  It is suggested that
  the former style be used for procedure calls with complex argument
  structures, and the latter style for procedure calls with simpler argument
  structures.

  .. code-block:: nim
    # Each argument on a new line, like type declarations
    # Best suited for 'complex' procedure calls.
    readDirectoryChangesW(
      directoryHandle.THandle,
      buffer.start,
      bufferSize.int32,
      watchSubdir.WinBool,
      filterFlags,
      cast[ptr dword](nil),
      cast[Overlapped](ol),
      cast[OverlappedCompletionRoutine](nil)
    )

    # Multiple arguments on new lines, aligned to the opening parenthesis
    # Best suited for 'simple' procedure calls
    startProcess(nimExecutable, currentDirectory, compilerArguments
                 environment, processOptions)
