# Helper for tgenericoffer.nim: imports mgofmh but NOT mgofmc, then calls the
# generic `digest`. Under IC this re-instantiates digest here, where mgofmc's
# `==` is NOT in scope — so getOrDefault[MultiCodec] must be REUSED from mgofmh's
# offer, not re-instantiated, or `==(MultiCodec)` resolution fails.
import mgofmh
proc callDigest*(): int = digest(5)
