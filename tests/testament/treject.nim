discard """
action: "reject"
"""

# this line does not compile, so the test should pass, since action="reject"
let x: int = "type mismatch"
