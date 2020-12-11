import dom

{.push importcpp.}
proc elementsFromPoint*(n: DocumentOrShadowRoot; x, y: float): seq[Element]
{.pop.}