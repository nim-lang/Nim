
# bug #9505

import std/[
    strutils, os
]
import pkg/[
  regex
]

proc fun() =
    let a = [
      1,
      2,
    ]
    discard

proc funB() =
  let a = [
    1,
    2,
    3
  ]
  discard


# bug #10156
proc foo =
    ## Comment 1
    ## Comment 2
    discard

proc bar =
  ## Comment 3
  ## Comment 4
  ## More here.
  discard


proc barB =
  # Comment 5
  # Comment 6
  discard


var x: int = 2

echo x
# bug #9144

proc a() =
  if cond:
    while true:
      discard
      # comment 1
    # end while
  #end if

  # comment 2
    #if
      #case
      #end case
    #end if
  discard


proc a() =
  while true:
    discard
    # comment 1

  # comment 2
  discard


proc i11937() =
    result = %*
        {
            "_comment": "pbreports-style JSON",
            "attributes": [],
            "dataset_uuids": [],
            "id": "microbial_asm_polishing_report",
            "plotGroups": [],
            "tables": [
                {
                "columns": [
                    {
                        "header": "Contig",
                        "id": "microbial",
                        "values": values_contig
                    },
                    {
                        "header": "Length",
                        "id": "microbial",
                        "values": values_length
                    },
                    {
                        "header": "Circular?",
                        "id": "microbial",
                        "values": values_circular
                    }
                ],
                "id": "microbial_asm_polishing_report.contigs_table",
                "title": "Polished contigs from Microbial Assembly"
                },
            ],
            "tags": [],
            "title": "Microbial Assembly Polishing Report",
            "uuid": uuid,
            "version": version
        }
