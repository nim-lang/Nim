# `qzdimpl` after `tns2_stale_impl.nim` changed the body of `depValue`, not
# its interface.
proc depValue*(): int = 2
