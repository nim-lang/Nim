import strtabs

template t*() =
  block:
    bind newStringTable
    discard {"Content-Type": "text/html"}.newStringTable()

    discard {:}.newStringTable

#discard {"Content-Type": "text/html"}.newStringTable()

t()
