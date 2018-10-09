==============================================
  Embedded Nim Debugger (ENDB) User Guide
==============================================

:Author: Andreas Rumpf
:Version: |nimversion|

.. contents::

**WARNING**: ENDB is not maintained anymore! Please help if you're interested
in this tool.

Nim comes with a platform independent debugger -
the Embedded Nim Debugger (ENDB). The debugger is
*embedded* into your executable if it has been
compiled with the ``--debugger:on`` command line option.
This also defines the conditional symbol ``ENDB`` for you.

Note: You must not compile your program with the ``--app:gui``
command line option because then there would be no console
available for the debugger.

If you start your program the debugger will immediately show
a prompt on the console. You can now enter a command. The next sections
deal with the possible commands. As usual in Nim in all commands
underscores and case do not matter. Optional components of a command
are listed in brackets ``[...]`` here.


General Commands
================

``h``, ``help``
    Display a quick reference of the possible commands.

``q``, ``quit``
    Quit the debugger and the program.

<ENTER>
    (Without any typed command) repeat the previous debugger command.
    If there is no previous command, ``step_into`` is assumed.

Executing Commands
==================

``s``, ``step_into``
    Single step, stepping into routine calls.

``n``, ``step_over``
    Single step, without stepping into routine calls.

``f``, ``skip_current``
    Continue execution until the current routine finishes.

``c``, ``continue``
    Continue execution until the next breakpoint.

``i``, ``ignore``
    Continue execution, ignore all breakpoints. This effectively quits
    the debugger and runs the program until it finishes.


Breakpoint Commands
===================

``b``, ``setbreak`` [fromline [toline]] [file]
    Set a new breakpoint for the given file
    and line numbers. If no file is given, the current execution point's
    filename is used. If the filename has no extension, ``.nim`` is
    appended for your convenience.
    If no line numbers are given, the current execution point's
    line is used. If both ``fromline`` and ``toline`` are given the
    breakpoint contains a line number range. Some examples if it is still
    unclear:

    * ``b 12 15 thallo`` creates a breakpoint that
      will be triggered if the instruction pointer reaches one of the
      lines 12-15 in the file ``thallo.nim``.
    * ``b 12 thallo`` creates a breakpoint that
      will be triggered if the instruction pointer reaches the
      line 12 in the file ``thallo.nim``.
    * ``b 12`` creates a breakpoint that
      will be triggered if the instruction pointer reaches the
      line 12 in the current file.
    * ``b`` creates a breakpoint that
      will be triggered if the instruction pointer reaches the
      current line in the current file again.

``breakpoints``
    Display the entire breakpoint list.

``disable`` <identifier>
    Disable a breakpoint. It remains disabled until you turn it on again
    with the ``enable`` command.

``enable`` <identifier>
    Enable a breakpoint.

Often it happens when debugging that you keep retyping the breakpoints again
and again because they are lost when you restart your program. This is not
necessary: A special pragma has been defined for this:


The ``breakpoint`` pragma
-------------------------

The ``breakpoint`` pragma is syntactically a statement. It can be used
to mark the *following line* as a breakpoint:

.. code-block:: Nim
  write("1")
  {.breakpoint: "before_write_2".}
  write("2")

The name of the breakpoint here is ``before_write_2``. Of course the
breakpoint's name is optional - the compiler will generate one for you
if you leave it out.

Code for the ``breakpoint`` pragma is only generated if the debugger
is turned on, so you don't need to remove it from your source code after
debugging.


The ``watchpoint`` pragma
-------------------------

The ``watchpoint`` pragma is syntactically a statement. It can be used
to mark a location as a watchpoint:

.. code-block:: Nim
  var a: array[0..20, int]

  {.watchpoint: a[3].}
  for i in 0 .. 20: a[i] = i

ENDB then writes a stack trace whenever the content of the location ``a[3]``
changes. The current implementation only tracks a hash value of the location's
contents and so locations that are not word sized may encounter false
negatives in very rare cases.

Code for the ``watchpoint`` pragma is only generated if the debugger
is turned on, so you don't need to remove it from your source code after
debugging.

Due to the primitive implementation watchpoints are even slower than
breakpoints: After *every* executed Nim code line it is checked whether the
location changed.


Data Display Commands
=====================

``e``, ``eval`` <exp>
    Evaluate the expression <exp>. Note that ENDB has no full-blown expression
    evaluator built-in. So expressions are limited:

    * To display global variables prefix their names with their
      owning module: ``nim1.globalVar``
    * To display local variables or parameters just type in
      their name: ``localVar``. If you want to inspect variables that are not
      in the current stack frame, use the ``up`` or ``down`` command.

    Unfortunately, only inspecting variables is possible at the moment. Maybe
    a future version will implement a full-blown Nim expression evaluator,
    but this is not easy to do and would bloat the debugger's code.

    Since displaying the whole data structures is often not needed and
    painfully slow, the debugger uses a *maximal display depth* concept for
    displaying.

    You can alter the maximal display depth with the ``maxdisplay``
    command.

``maxdisplay`` <natural>
    Sets the maximal display depth to the given integer value. A value of 0
    means there is no maximal display depth. Default is 3.

``o``, ``out`` <filename> <exp>
    Evaluate the expression <exp> and store its string representation into a
    file named <filename>. If the file does not exist, it will be created,
    otherwise it will be opened for appending.

``w``, ``where``
    Display the current execution point.

``u``, ``up``
    Go up in the call stack.

``d``, ``down``
    Go down in the call stack.

``stackframe`` [file]
    Displays the content of the current stack frame in ``stdout`` or
    appends it to the file, depending on whether a file is given.

``callstack``
    Display the entire call stack (but not its content).

``l``, ``locals``
    Display the available local variables in the current stack frame.

``g``, ``globals``
    Display all the global variables that are available for inspection.
