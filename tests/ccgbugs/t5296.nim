discard """
cmd: "nim c -d:release $file"
output: 1
"""

proc bug() : void =
    var x = 0
    try:
        inc x
        raise new(Exception)
    except Exception:
        echo x

bug()
