discard """
  cmd: "nim check --hints:off --warnings:off --hintAsError:XDeclaredButNotUsed $file"
  joinable: false
"""

let x = 12
echo x
