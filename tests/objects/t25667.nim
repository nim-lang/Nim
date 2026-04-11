type
  Generic[T] = object
    t: T

  WindowObj = object
    svgCache: Generic[SVGSVGElement]

  SVGSVGElement = Generic[SVGSVGElementObj]

  SVGSVGElementObj = object

proc foo() =
  let p: pointer = nil
  discard cast[ptr WindowObj](p)
