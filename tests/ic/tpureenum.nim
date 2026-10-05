discard """
output: '''5
Number
Object'''
"""

# Regression test: a `{.pure.}` enum loaded from a NIF must keep its fields out
# of the importer's unqualified scope (no leak), while still being reachable
# qualified AND via the restricted unambiguous-bare pure-enum fallback
# (`importPureEnumFields`, fed by `ifaces[].pureEnums` which the loader rebuilds
# from `PureEnumEntry` log ops).
#
# Before the fix the pure fields leaked into `interf` under `nim ic`, so
# `JsonValueKind.Number` shadowed the distinct `Number` type and the conversion
# below failed: "undeclared field 'Number' for type system.uint64".

import mpureenum

echo toNumber(5'u64).val      # distinct conversion: field must NOT shadow type
echo JsonValueKind.Number     # qualified pure-enum access still works
echo Object                   # unambiguous bare pure-enum field still resolves
