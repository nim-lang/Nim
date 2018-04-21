# The big stdlib review

This has been a long time coming. I believe that before 1.0 is released we
should look at the Nim standard library closely, decide what needs to be changed
and work to **change it** :)

**Please give your feedback**, there are bound to be a lot of pain points that you've experienced with the stdlib and I want to know about them!

There will be a lot of tasks outlined here, many of them
easy but admittedly boring, help very much encouraged. Please let me know
if you are starting one of these tasks.

**This is still a work in progress, I haven't gone through everything yet. Also many of these are just ideas at this stage, I will modify the list below based on your comments.**

# Examples in documentation

**Note:** I ask for more examples in many of these modules' documentation,
and that does not mean
a huge code sample plopped into the documentation.
It means a short and simple example of how to do specific
things, good examples of this in our documentation is in the
[``httpclient``](https://nim-lang.org/docs/httpclient.html) module, but even
that could be improved.

# Global tasks

- [ ] Remove all deprecated types/procedures/templates/etc.
- [ ] Ideally all (or a large proportion) of the stdlib should work without a GC.

# Misc files

- [ ] [`cycle.h`](https://github.com/nim-lang/Nim/blob/devel/lib/cycle.h) - Is this used?

- [ ] [`nimbase.h](https://github.com/nim-lang/Nim/blob/devel/lib/nimbase.h) - Needs to be documented somewhere.

- [ ]

# Prelude

- [ ] Needs better visibility (perhaps a note in lib.html?)

# nimrtl

- [ ] Needs better visibility.
- [ ] Needs better documentation. Some questions to answer:
  - Is it included implicitly or should it be included in source that is meant to be compiled into a DLL?
  - The ``-d:createNimRtl`` symbol needs to be mentioned somewhere.

# system

This is a large module. In general I believe it would make sense to split it up,
or at the very least create some custom documentation for it.

- [ ] The documentation should be split into categories. With a description for
  each category, for example "Basic types", "Generic types", "FFI",
  "Exception types". There is a vast amount of procedures, again could be
  put into categories, for example "Arithmetic operators", "File I/O", etc.
  This likely requires improvements to the doc gen.
- [ ] *(Optional and breaking)* Split into modules.
  - [ ] ``ffi`` - Defines all FFI types/procedures.
  - [ ] ``gc`` - Defines all types/procedures related to changing the garbage collector's behaviour, all ``GC_*`` procedures.
  - [ ] ``mem`` - Defines all procedures related to manual memory management,
    perhaps they should be in ``ffi`` and we should state that any procedures in
    ``ffi`` are not memory safe.
  - [ ] ``file`` - New home for ``readFile`` etc.
- [ ] Why is ``NimNode`` defined here and not in ``system``?

# core/locks

A simple, small and nice module. Looks good, but could always use more docs.

- [ ] More examples in documentation.

# core/macros

Another large module. But at least everything there belongs to that module.

- [ ] Needs better support for attaching stack trace information to
  ``NimNode``'s. @Araq mentioned creating a custom type for this and I agree.
- [ ] Remove the AST specifications for each statement/expression in
  the documentation. I've never
  looked at it, I always use ``dumpTree`` to see an expression's AST anyway so
  it's just noise.
- [ ] The documentation should show the *actual* definition of NimNode, not a
  fake shortened one. Pretty sure this definition is outdated anyway.
- [ ] Desperately needs examples.
- [ ] Not all exported procedures have documentation, and many could use
  examples inline as well.

# core/rlocks

Couldn't this be merged into the ``locks`` module?

# core/typeinfo

I'm happy with this module although I haven't had a chance to use it much.
As with any module, it could use more examples.

- [ ] More examples in documentation.

# impure/db_*

- [ ] *(Optional/Breaking)* Move out of stdlib and into a Nimble package.
  - [ ] *(Optional/Breaking) Only move db_odbc?
- [ ] Test each db module extensively.
  - [ ] Test the same code with each module (their interfaces should be the same)
- [ ] Document exactly what SQL param substitution symbols are supported by
  each backend.
- [ ] Ensure that each module implements the same interface, and that there
  is no divergence unless absolutely necessary.
- [ ] Clean up documentation for these modules. A couple have "Long examples"
  which should be split up into small examples.
- [ ] Define a ``concept`` or ``vtref concept`` for these modules?

# impure/nre

This is just about the only module in the standard library that makes use of
the ``Option[T]`` type. As much as I love this it doesn't feel idiomatic to
Nim. The documentation for this module is pretty good.
Unfortunately this module
still isn't used as much as the ``re`` module and so I think it might be best
to move it out of the standard library.

**That said, before commiting to a decision I think we need to see what
everyone else thinks**.

# impure/re

To be honest I'm still not clear about the reasons for the new ``re`` module,
I'm sure if I hunt through the PRs/Issues I would be able to find an
explanation but who has the time for that :)

From what I've used of this module it is fine, apart from the ``match`` vs.
``find`` gotcha. But I think that can be fixed by improving the documentation.

- [ ] Documentation needs to be cleaned up, putting priority on real Nim examples instead of the PCRE license or the description of regular expressions.

# impure/osinfo_*

- [ ] Move these files to the ``deprecated`` directory, better yet just
  remove them.

# impure/rdstdin

- [ ] Move contents to the ``terminal`` module?

# impure/ssl

- [ ] Remove this module (it's deprecated).



