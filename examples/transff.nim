# Shows how to transform a file

import pegs

transformFile("infile.txt", "outfile.txt",
  [(peg"""S <- {typedesc} \s* {\ident} \s* ','
         typedesc <- \ident '*'* """, r"$2: $1")])

