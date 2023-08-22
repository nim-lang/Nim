# from issue #7632
# imported and used in tstrformat

import strformat

proc fails*(a: static[int]): string =
  &"formatted {a:2}"

proc fails2*[N: static[int]](a: int): string =
  &"formatted {a:2}"

proc works*(a: int): string =
  &"formatted {a:2}"

proc fails0*(a: int or uint): string =
  &"formatted {a:2}"
