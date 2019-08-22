===========
Code owners
===========


Subsystems and code owners
--------------------------

*Note*: This list is incomplete, in doubt dom96 is responsible for the standard
library, araq is responsible for the compiler.


Compiler
~~~~~~~~

======================         ======================================================
subsystem                      owner(s)
======================         ======================================================
Parsing, Lexing                araq
Renderer                       cooldome, araq
Order of passes                cooldome
Semantic Checking              araq
Virtual machine                jangko, GULPF, araq
Sempass2: effects tracking     cooldome, araq
type system, concepts          zahary
transf                         cooldome, araq
semfold constant folding       araq
template instantiation         zahary, araq
term rewriting macros          cooldome, araq
closure interators             yglukhov, araq
lambda lifting                 yglukhov, araq
c, cpp codegen                 lemonboy, araq
js codegen                     yglukhov, lemonboy
alias analysis                 araq
dfa, writetracking             araq
parallel, multithreading       araq
incremental                    araq
sizeof computations            krux02
Exception handling             cooldome, araq
======================         ======================================================



Standard library
~~~~~~~~~~~~~~~~

======================         ======================================================
subsystem                      owner(s)
======================         ======================================================
async                          dom96
strutils                       araq
sequtils                       dom96, araq
times                          GULPF
os                             dom96, araq
re                             araq
nre                            flaviu
math, fenv                     krux02, cooldome
io                             dom96
garbage collector              araq
Go garbage collector           stefantalpalaru
coroutines                     Rokas Kupstys
collections                    GULPF
parseopt                       araq
json                           dom96
======================         ======================================================
