# The ChatApp source code

This directory contains the ChatApp project, which is the project that is
created as part of Chapter 3 of the Nim in Action book.

To compile run:

```
nim c src/client
nim c src/server
```

You can then run the ``server`` in one terminal by executing ``./src/server``.

After doing so you can execute multiple clients in different terminals and have
them communicate via the server.

To execute a client, make sure to specify the server address and user name
on the command line:

```bash
./src/client localhost Peter
```

You should then be able to start typing in messages and sending them
by pressing the Enter key.