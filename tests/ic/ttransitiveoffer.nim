discard """
output: '''size 64 64'''
"""

# Regression test for TRANSITIVE generic-instance offers. `fromRaw[int]` is first
# instantiated in mtscopewarm (a clean scope where `TScopeSize` is unambiguously
# 65). The consumer here also imports mtscopeb (`TScopeSize` = 33), so a fresh
# re-instantiation of fromRaw's body would resolve `TScopeSize` ambiguously. The
# clean instance reaches here only TRANSITIVELY (via mtscopemid), so the offer
# rebuild must walk the whole import closure, not just direct imports. Mirrors
# nimbus-eth2 `keys.fromRaw` -> `SkRawPublicKeySize` (secp vs secp256k1).
import mtscopegen, mtscopeb, mtscopemid

echo fromRaw(64)
