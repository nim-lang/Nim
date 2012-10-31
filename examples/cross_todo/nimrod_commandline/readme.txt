This directory contains the nimrod commandline version of the todo cross
platform example.

The commandline interface can be used only through switches, running the binary
once will spit out the basic help. The commands you can use are the typical on
such an application: add, check/uncheck and delete (further could be added,
like modification at expense of parsing/option complexity). The list command is
the only one which dumps the contents of the database. The output can be
filtered and sorted through additional parameters.

When you run the program for the first time the todo database will be generated
in your user's data directory. To cope with an empty database, a special
generation switch can be used to fill the database with some basic todo entries
you can play with.

Compilation of the interface is fairly easy, just include the path to the
backend in your compilation command. A basic build.sh is provided for unix like
platforms with the correct parameters.
