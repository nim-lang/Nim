discard """
  file: "tno_int_in_bool_context.nim"
  line: 7
  errormsg: "type mismatch: got (int literal(1)) but expected 'bool'"
"""

if 1:
  echo "wtf?"
