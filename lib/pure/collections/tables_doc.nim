## The ``tables`` module implements variants of an efficient `hash table`:idx:
## (also often named `dictionary`:idx: in other programming languages) that is
## a mapping from keys to values.
##
## There are several different types of hash tables available:
## * `Table<#Table>`_ is the usual hash table,
## * `OrderedTable<#OrderedTable>`_ is like ``Table`` but remembers insertion order,
## * `CountTable<#CountTable>`_ is a mapping from a key to its number of occurrences
##
## For consistency with every other data type in Nim these have **value**
## semantics, this means that ``=`` performs a copy of the hash table.
##
## For `ref semantics<manual.html#types-ref-and-pointer-types>`_
## use their ``Ref`` variants: `TableRef<#TableRef>`_,
## `OrderedTableRef<#OrderedTableRef>`_, and `CountTableRef<#CountTableRef>`_.
##
## To give an example, when ``a`` is a ``Table``, then ``var b = a`` gives ``b``
## as a new independent table. ``b`` is initialised with the contents of ``a``.
## Changing ``b`` does not affect ``a`` and vice versa:
##
## .. code-block::
##   var
##     a = {1: "one", 2: "two"}.toTable  # creates a Table
##     b = a
##
##   echo a, b  # output: {1: one, 2: two}{1: one, 2: two}
##
##   b[3] = "three"
##   echo a, b  # output: {1: one, 2: two}{1: one, 2: two, 3: three}
##   echo a == b  # output: false
##
## On the other hand, when ``a`` is a ``TableRef`` instead, then changes to ``b``
## also affect ``a``. Both ``a`` and ``b`` **ref** the same data structure:
##
## .. code-block::
##   var
##     a = {1: "one", 2: "two"}.newTable  # creates a TableRef
##     b = a
##
##   echo a, b  # output: {1: one, 2: two}{1: one, 2: two}
##
##   b[3] = "three"
##   echo a, b  # output: {1: one, 2: two, 3: three}{1: one, 2: two, 3: three}
##   echo a == b  # output: true
##
##
##
## Basic usage
## ===========
##
## Table
## -----
##
## .. code-block::
##   from sequtils import zip
##
##   let
##     names = ["John", "Paul", "George", "Ringo"]
##     years = [1940, 1942, 1943, 1940]
##
##   var beatles = initTable[string, int]()
##
##   for pairs in zip(names, years):
##     let (name, birthYear) = pairs
##     beatles[name] = birthYear
##
##   echo beatles
##   # {"George": 1943, "Ringo": 1940, "Paul": 1942, "John": 1940}
##
##
##   var beatlesByYear = initTable[int, seq[string]]()
##
##   for pairs in zip(years, names):
##     let (birthYear, name) = pairs
##     if not beatlesByYear.hasKey(birthYear):
##       # if a key doesn't exists, we create one with an empty sequence
##       # before we can add elements to it
##       beatlesByYear[birthYear] = @[]
##     beatlesByYear[birthYear].add(name)
##
##   echo beatlesByYear
##   # {1940: @["John", "Ringo"], 1942: @["Paul"], 1943: @["George"]}
##
##
##
## OrderedTable
## ------------
##
## `OrderedTable<#OrderedTable>`_ is used when it is important to preserve
## the insertion order of keys.
##
## .. code-block::
##   let
##     a = [('z', 1), ('y', 2), ('x', 3)]
##     t = a.toTable          # regular table
##     ot = a.toOrderedTable  # ordered tables
##
##   echo t   # {'x': 3, 'y': 2, 'z': 1}
##   echo ot  # {'z': 1, 'y': 2, 'x': 3}
##
##
##
## CountTable
## ----------
##
## `CountTable<#CountTable>`_ is useful for counting number of items of some
## container (e.g. string, sequence or array), as it is a mapping where the
## items are the keys, and their number of occurrences are the values.
## For that purpose `toCountTable proc<#toCountTable,openArray[A]>`_
## comes handy:
##
## .. code-block::
##   let myString = "abracadabra"
##   let letterFrequencies = toCountTable(myString)
##   echo letterFrequencies
##   # 'a': 5, 'b': 2, 'c': 1, 'd': 1, 'r': 2}
##
## The same could have been achieved by manually iterating over a container
## and increasing each key's value with `inc proc<#inc,CountTable[A],A,int>`_:
##
## .. code-block::
##   let myString = "abracadabra"
##   var letterFrequencies = initCountTable[char]()
##   for c in myString:
##     letterFrequencies.inc(c)
##   echo letterFrequencies
##   # output: {'a': 5, 'b': 2, 'c': 1, 'd': 1, 'r': 2}
##
## ----
##
##
##
## Hashing
## -------
##
## If you are using simple standard types like ``int`` or ``string`` for the
## keys of the table you won't have any problems, but as soon as you try to use
## a more complex object as a key you will be greeted by a strange compiler
## error:
##
##   Error: type mismatch: got (Person)
##   but expected one of:
##   hashes.hash(x: openArray[A]): Hash
##   hashes.hash(x: int): Hash
##   hashes.hash(x: float): Hash
##   …
##
## What is happening here is that the types used for table keys require to have
## a ``hash()`` proc which will convert them to a `Hash <hashes.html#Hash>`_
## value, and the compiler is listing all the hash functions it knows.
## Additionally there has to be a ``==`` operator that provides the same
## semantics as its corresponding ``hash`` proc.
##
## After you add ``hash`` and ``==`` for your custom type everything will work.
## Currently, however, ``hash`` for objects is not defined, whereas
## ``system.==`` for objects does exist and performs a "deep" comparison (every
## field is compared) which is usually what you want. So in the following
## example implementing only ``hash`` suffices:
##
## .. code-block::
##   import tables, hashes
##
##   type
##     Person = object
##       firstName, lastName: string
##
##   proc hash(x: Person): Hash =
##     ## Piggyback on the already available string hash proc.
##     ##
##     ## Without this proc nothing works!
##     result = x.firstName.hash !& x.lastName.hash
##     result = !$result
##
##   var
##     salaries = initTable[Person, int]()
##     p1, p2: Person
##
##   p1.firstName = "Jon"
##   p1.lastName = "Ross"
##   salaries[p1] = 30_000
##
##   p2.firstName = "소진"
##   p2.lastName = "박"
##   salaries[p2] = 45_000
##
##
##
## See also
## ========
##
## * `json module<json.html>`_ for table-like structure which allows
##   heterogeneous members
## * `sharedtables module<sharedtables.html>`_ for shared hash table support
## * `strtabs module<strtabs.html>`_ for efficient hash tables
##   mapping from strings to strings
## * `hashes module<hashes.html>`_ for helper functions for hashing
