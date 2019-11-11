discard """
errmsg: "alignas not allowed in top level declaration"
line: 10
"""





var myother {.alignas: 32.}: int32
