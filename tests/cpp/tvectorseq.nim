discard """
  targets: "cpp"
  output: '''(x: 1.0)
(x: 0.0)'''
  disabled: "true"
"""

# This cannot work yet because we omit type information for importcpp'ed types.
# Fixing this is not hard, but also requires fixing Urhonimo.

# bug #2536

{.emit: """/*TYPESECTION*/
struct Vector3 {
public:
  Vector3(): x(5) {}
  Vector3(float x_): x(x_) {}
  float x;
};
""".}

type Vector3 {.importcpp: "Vector3", nodecl} = object
  x: cfloat

proc constructVector3(a: cfloat): Vector3 {.importcpp: "Vector3(@)", nodecl}

# hack around another codegen issue: Generics are attached to where they came
# from:
proc `$!`(v:  seq[Vector3]): string = "(x: " & $v[0].x & ")"

proc vec3List*(): seq[Vector3] =
  let s = @[constructVector3(cfloat(1))]
  echo($!s)
  result = s
  echo($!result)

let f = vec3List()
#echo($!f)
