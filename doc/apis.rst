=================
API naming design
=================

.. default-role:: code
.. include:: rstcommon.rst

The API is designed to be **easy to use** and consistent. Ease of use is
measured by the number of calls to achieve a concrete high-level action.


Naming scheme
=============

The library uses a simple naming scheme that makes use of common abbreviations
to keep the names short but meaningful. Since version 0.8.2 many symbols have
been renamed to fit this scheme. The ultimate goal is that the programmer can
*guess* a name.


-------------------     ------------   --------------------------------------
English word            To use         Notes
-------------------     ------------   --------------------------------------
initialize              initT          `init` is used to create a
                                       value type `T`
new                     newP           `new` is used to create a
                                       reference type `P`
find                    find           should return the position where
                                       something was found; for a bool result
                                       use `contains`
contains                contains       often short for `find() >= 0`
append                  add            use `add` instead of `append`
compare                 cmp            should return an int with the
                                       `< 0` `== 0` or `> 0` semantics;
                                       for a bool result use `sameXYZ`
put                     put, `[]=`     consider overloading `[]=` for put
get                     get, `[]`      consider overloading `[]` for get;
                                       consider to not use `get` as a
                                       prefix: `len` instead of `getLen`
length                  len            also used for *number of elements*
size                    size, len      size should refer to a byte size
capacity                cap
memory                  mem            implies a low-level operation
items                   items          default iterator over a collection
pairs                   pairs          iterator over (key, value) pairs
delete                  delete, del    del is supposed to be faster than
                                       delete, because it does not keep
                                       the order; delete keeps the order
remove                  delete, del    inconsistent right now
remove-and-return       pop            `Table`/`TableRef` alias to `take`
include                 incl
exclude                 excl
command                 cmd
execute                 exec
environment             env
variable                var
value                   value, val     val is preferred, inconsistent right
                                       now
executable              exe
directory               dir
path                    path           path is the string "/usr/bin" (for
                                       example), dir is the content of
                                       "/usr/bin"; inconsistent right now
extension               ext
separator               sep
column                  col, column    col is preferred, inconsistent right
                                       now
application             app
configuration           cfg
message                 msg
argument                arg
object                  obj
parameter               param
operator                opr
procedure               proc
function                func
coordinate              coord
rectangle               rect
point                   point
symbol                  sym
literal                 lit
string                  str
identifier              ident
indentation             indent
-------------------     ------------   --------------------------------------
