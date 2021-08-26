import std/dom

{.push importcpp.}
proc elementsFromPoint*(n: DocumentOrShadowRoot; x, y: float): seq[Element]
{.pop.}

{.deprecated: "use `std/dom` instead".}
