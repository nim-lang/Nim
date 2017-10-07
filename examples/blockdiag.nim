##
## docgen - blockdiag adaptor examples
##
## Generate blockdiag.html using:
##
## .. code-block::
##    nim doc examples/blockdiag.nim
##
## Example 1:
##
## .. code-block::
##    .. code-block:: blockdiag
##
##       blockdiag {
##         default_shape = roundedbox;
##         "parse .nim file" -> "generate RST AST" -> "run blockdiag" -> "embed SVG output";
##       }
##
## .. code-block:: blockdiag
##
##    blockdiag {
##      default_shape = roundedbox;
##      "parse .nim file" -> "generate RST AST" -> "run blockdiag" -> "embed SVG";
##    }
##
## Example 2:
##
## .. code-block::
##    .. code-block:: blockdiag
##
##       blockdiag {
##         default_shape = roundedbox;
##         client -> dispatcher -> worker1, workerDots, workerN;
##         workerDots [shape = "dots"];
##       }
##
##
## .. code-block:: blockdiag
##
##    blockdiag {
##      default_shape = roundedbox;
##      client -> dispatcher -> worker1, workerDots, workerN;
##      workerDots [shape = "dots"];
##    }
##
##
