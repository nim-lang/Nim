import std/dom

{.push importjs.}
proc elementsFromPoint*(n: DocumentOrShadowRoot; x, y: float): seq[Element]
{.pop.}