Each example in this directory is referenced by some test snippet, for example:

```
Example snippet:

.. code-block:: nim
   :file: tests/examples/tdestructors1.nim

Rest of docs.
```


This ensures the examples keep working, and allows using all testament features.
The alternative is to use:
```
Example snippet:

.. code-block:: nim
    :test: "nim r $1"

Rest of docs.
```

but this is less flexible, for example it prevents reusing tests, or using testament spec such
as `matrix`, etc.
