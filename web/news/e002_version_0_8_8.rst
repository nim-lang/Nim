Version 0.8.8 released
======================

.. container:: metadata

  Posted by Andreas Rumpf on 14/03/2010

Bugfixes
--------
- The Posix version of ``os.copyFile`` has better error handling.
- Fixed bug #502670 (underscores in identifiers).
- Fixed a bug in the ``parsexml`` module concerning the parsing of
  ``<tag attr="value" />``.
- Fixed a bug in the ``parsexml`` module concerning the parsing of
  enities like ``&ltXX``.
- ``system.write(f: TFile, s: string)`` now works even if ``s`` contains binary
  zeros.
- Fixed a bug in ``os.setFilePermissions`` for Windows.
- An overloadable symbol can now have the same name as an imported module.
- Fixed a serious bug in ``strutils.cmpIgnoreCase``.
- Fixed ``unicode.toUTF8``.
- The compiler now rejects ``'\n'`` (use ``"\n"`` instead).
- ``times.getStartMilsecs()`` now works on Mac OS X.
- Fixed a bug in ``pegs.match`` concerning start offsets.
- Lots of other little bugfixes.


Additions
---------
- Added ``system.cstringArrayToSeq``.
- Added ``system.lines(f: TFile)`` iterator.
- Added ``system.delete``, ``system.del`` and ``system.insert`` for sequences.
- Added ``system./`` for int.
- Exported ``system.newException`` template.
- Added ``cgi.decodeData(data: string): tuple[key, value: string]``.
- Added ``strutils.insertSep``.
- Added ``math.trunc``.
- Added ``ropes`` module.
- Added ``sockets`` module.
- Added ``browsers`` module.
- Added ``httpserver`` module.
- Added ``httpclient`` module.
- Added ``parseutils`` module.
- Added ``unidecode`` module.
- Added ``xmldom`` module.
- Added ``xmldomparser`` module.
- Added ``xmltree`` module.
- Added ``xmlparser`` module.
- Added ``htmlparser`` module.
- Added ``re`` module.
- Added ``graphics`` module.
- Added ``colors`` module.
- Many wrappers now do not contain redundant name prefixes (like ``GTK_``,
  ``lua``). The old wrappers are still available in ``lib/oldwrappers``.
  You can change your configuration file to use these.
- Triple quoted strings allow for ``"`` in more contexts.
- ``""`` within raw string literals stands for a single quotation mark.
- Arguments to ``openArray`` parameters can be left out.
- More extensive subscript operator overloading. (To be documented.)
- The documentation generator supports the ``.. raw:: html`` directive.
- The Pegs module supports back references via the notation ``$capture_index``.


Changes affecting backwards compatibility
-----------------------------------------

- Overloading of the subscript operator only works if the type does not provide
  a built-in one.
- The search order for libraries which is affected by the ``path`` option
  has been reversed, so that the project's path is searched before
  the standard library's path.
- The compiler does not include a Pascal parser for bootstrapping purposes any
  more. Instead there is a ``pas2nim`` tool that contains the old functionality.
- The procs ``os.copyFile`` and ``os.moveFile`` have been deprecated
  temporarily, so that the compiler warns about their usage. Use them with
  named arguments only, because the parameter order will change the next
  version!
- ``atomic`` and ``let`` are now keywords.
- The ``\w`` character class for pegs now includes the digits ``'0'..'9'``.
- Many wrappers now do not contain redundant name prefixes (like ``GTK_``,
  ``lua``) anymore.
- Arguments to ``openArray`` parameters can be left out.
