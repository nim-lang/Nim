# Container library for Nimrod
# Implemented with macros, because generics sucks in many ways

# Data structures for now:
# TTable, TSet, TList
# Algorithms: Trees, hashing,

TTable[key, val, [Algorithm]]

macro TTable(n: typeexpr): typeexpr =


