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
Virtual machine                jangko, cooldome, GULPF, araq
Sempass2: effects tracking     araq
type system, concepts          zahary
transf                         araq
semfold constant folding       araq
template instantiation         zahary, araq
term rewriting macros          araq
closure interators             yglukhov, araq
lambda lifting                 yglukhov, araq
c, cpp codegen                 lemonboy, araq
js codegen                     yglukhov, lemonboy
alias analysis                 araq
dfa, writetracking             araq
parallel, multithreading       araq
incremental                    araq
sizeof computations            krux02
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
os, ospaths                    dom96, araq
re                             araq
nre                            flaviu
math                           krux02
io                             dom96
garbage collector              araq
Go garbage collector           stefantalpalaru
coroutines                     Rokas Kupstys
collections                    GULPF
parseopt                       araq
json                           dom96
======================         ======================================================
