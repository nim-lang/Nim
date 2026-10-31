import tnested_groups {.cyclic.}

proc fa*(): int = fb() + 1
echo fa()
