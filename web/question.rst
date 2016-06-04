===========================================
         Questions and Answers
===========================================


General FAQ
===========


.. container:: standout

  What is Nim?
  ------------

  Nim (formerly known as "Nimrod") is a statically typed, imperative programming
  language that tries to give the programmer ultimate power without compromises
  on runtime efficiency.
  This means it focuses on compile-time mechanisms in all their
  various forms. Beneath a nice infix/indentation based syntax with a
  powerful (AST based, hygienic) macro system lies a semantic model that supports
  a soft realtime GC on thread local heaps. Asynchronous message passing is used
  between threads, so no "stop the world" mechanism is necessary. An unsafe
  shared memory heap is also provided for the increased efficiency that results
  from that model.



..  .. container:: standout

..    Why should I use Nim?
..    ---------------------

..    It's a conservative language in a sense that we stick to features that have
..    proven themselves for larger scale programming. But it's revolutionary by
..    the features which have been laid on top.

..    One of Nim's goals is to increase developer productivity without sacrificing
..    the produced software's stability. The way that this is done is by providing

..    Depending on your use case.

..    Nim is one of the few programming languages in the world which allows you to


..    The language inventor describes it as the ultimate programming language
..    with features which make it perfect for just about any problem.

.. container:: standout

  Why yet another programming language?
  -------------------------------------

  Nim is one of the very few *programmable* statically typed languages, and
  one of the even fewer that produces native binaries that require no
  runtime or interpreter.


.. container:: standout

  What have been the major influences in the language's design?
  -------------------------------------------------------------

  The language borrows heavily from (in order of impact): Modula 3, Delphi, Ada,
  C++, Python, Lisp, Oberon.


.. container:: standout

  What is Nim's take on concurrency?
  ----------------------------------

  Nim primarily focusses on thread local (and garbage collected) heaps and
  message passing between threads. Each thread has its own GC, so no
  "stop the world" mechanism is necessary. An unsafe shared memory heap is also
  provided.

  Future versions will additionally include a GC "per thread group"
  and Nim's type system will be enhanced to accurately model this shared
  memory heap.


.. container:: standout

  How is Nim licensed?
  --------------------

  The Nim compiler and the library are MIT licensed.
  This means that you can use any license for your own programs developed with
  Nim.


.. container:: standout

  How stable is Nim?
  ------------------

  The compiler is in development and some important features are still missing.
  However, the compiler is quite stable already: It is able to compile itself
  and a substantial body of other code. Until version 1.0.0 is released,
  minor incompatibilities with older versions of the compiler will be introduced.


.. container:: standout

  How fast is Nim?
  ----------------
  Benchmarks show it to be comparable to C. Some language features (methods,
  closures, message passing) are not yet as optimized as they could and will be.
  The only overhead Nim has over C is the GC which has been tuned
  for years but still needs some work.


.. container:: standout

  What about JVM/CLR backends?
  ----------------------------

  JVM/CLR support is not in the nearest plans. However, since these VMs support FFI to C
  it should be possible to create native Nim bridges, that transparenlty generate all the
  glue code thanks to powerful metaprogramming capabilities of Nim.


.. container:: standout

  What about editor support?
  --------------------------

  - Nim IDE: https://github.com/nim-lang/Aporia
  - Emacs: https://github.com/nim-lang/nim-mode
  - Vim: https://github.com/zah/nimrod.vim/
  - Scite: Included
  - Gedit: The `Aporia .lang file <https://github.com/nim-lang/Aporia/blob/master/share/gtksourceview-2.0/language-specs/nim.lang>`_
  - jEdit: https://github.com/exhu/nimrod-misc/tree/master/jedit
  - TextMate: Available in bundle installer (`Repository <https://github.com/textmate/nim.tmbundle>`_)
  - Sublime Text: Available via Package Control (`Repository <https://github.com/Varriount/NimLime>`_)
  - LiClipse: http://www.liclipse.com/ (Eclipse based plugin)
  - Howl: Included
  - Notepad++: Available via `plugin <https://github.com/jangko/nppnim/releases>`_
  

.. container:: standout

  Why is it named ``proc``?
  -------------------------

  *Procedure* used to be the common term as opposed to a *function* which is a
  mathematical entity that has no side effects. It is planned to have ``func``
  as syntactic sugar for ``proc {.noSideEffect.}`` and ``func`` is already a
  keyword. Naming it ``def`` would not make sense because Nim also provides a
  ``iterator`` and ``method`` keywords, whereas ``def`` stands for ``define``.


Compilation FAQ
===============

.. container:: standout

  Which option to use for the fastest executable?
  -----------------------------------------------

  For the standard configuration file, ``-d:release`` does the trick.

.. container:: standout

  Which option to use for the smallest executable?
  ------------------------------------------------

  For the standard configuration file, ``-d:quick --opt:size`` does the trick.

.. container:: standout

  How do I use a different C compiler than the default one?
  ---------------------------------------------------------

  Edit the ``config/nim.cfg`` file.
  Change the value of the ``cc`` variable to one of the following:

  ================  ============================================
  **Abbreviation**  **C/C++ Compiler**
  ================  ============================================
  ``vcc``           Microsoft's Visual C++
  ``gcc``           Gnu C
  ``llvm_gcc``      LLVM-GCC compiler
  ``icc``           Intel C++ compiler
  ``clang``         Clang compiler
  ``ucc``           Generic UNIX C compiler
  ================  ============================================

  Other C compilers are not officially supported, but might work too.

  If your C compiler is not in the above list, try using the
  *generic UNIX C compiler* (``ucc``). If the C compiler needs
  different command line arguments try the ``--passc`` and ``--passl`` switches.
