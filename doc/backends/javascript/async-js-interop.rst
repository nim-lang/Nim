Async Javascript interop
========================

To interop with asynchronous JavaScript such as `async/await` and `Promises`, 
please use the `asyncjs <asyncjs.html>`_ module.

.. code-block:: nim

  proc loadGame(name: string): Future[Game] {.async.} =
    # code

should be equivalent to

.. code-block:: nim
  async function loadGame(name) {
    // code
  }

A call to an asynchronous procedure usually needs ``await`` to wait for the completion of the ``Future``.

.. code-block:: nim

  var game = await loadGame(name)

Callbacks
---------

You can wrap callbacks with asynchronous procedures using a promise via ``newPromise``:

.. code-block:: nim

  proc loadGame(name: string): Future[Game] =
    var promise = newPromise() do (resolve: proc(response: Game)):
      cbBasedLoadGame(name) do (game: Game):
        resolve(game)
    return promise

Promises
--------

Use the ``PromiseJs`` type and ``newPromise`` (as demonstrated above)

.. code-block:: nim
type
  PromiseJs {...} = ref object

Usage

.. code-block:: nim
  proc loadGame(init: PromiseJs): Future[Game]