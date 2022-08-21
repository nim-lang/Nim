discard """
targets: "cpp"
output: "{A, B, C}"
"""

type Enum {.importcpp: "namespaced::Enum", header: "enum.hpp".} = enum A, B, C

var vals = {low(Enum) .. high(Enum)}
echo vals
