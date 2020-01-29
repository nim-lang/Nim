================================
   Nim Backend Integration
================================

:Author: Puppet Master
:Version: |nimversion|

.. contents::
  "Heresy grows from idleness." -- Unknown.


Introduction
============

The `Nim Compiler User Guide <nimc.html>`_ documents the typical
compiler invocation, using the ``compile`` or ``c`` command to transform a
``.nim`` file into one or more ``.c`` files which are then compiled with the
platform's C compiler into a static binary. However there are other commands
to compile to C++, Objective-C or JavaScript. This document tries to
concentrate in a single place all the backend and interfacing options.

The Nim compiler supports mainly two backend families: 

- C, C++ and Objective-C (C family) targets 
- JavaScript target

`The C like targets
<#backends-the-c-like-targets>`_ creates source files which can be compiled
into a library or a final executable. 

`The JavaScript target
<#backends-the-javascript-target>`_ can generate a ``.js`` file which you
reference from an HTML file or create a `standalone nodejs program
<http://nodejs.org>`_.

On top of generating libraries or standalone applications, Nim offers
bidirectional interfacing with the backend targets through generic and
specific pragmas.


Backends
========

- link to C backend document
- link to JavaScript backend document

Interfacing
===========

Nim offers bidirectional interfacing with the target backend. This means
that you can call backend code from Nim and Nim code can be called by
the backend code. Usually the direction of which calls which depends on your
software architecture (is Nim your main program or is Nim providing a
component?).

Nimcache naming logic
---------------------

The `nimcache`:idx: directory is generated during compilation and will hold
either temporary or final files depending on your backend target. The default
name for the directory depends on the used backend and on your OS but you can
use the ``--nimcache`` `compiler switch
<nimc.html#compiler-usage-command-line-switches>`_ to change it.







