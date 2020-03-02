
var 
  x: string
{.emit: "%[STOREID:var=x]%".}

# echo x
# {.emit: "%[BEFORE:var(x)]%/*@enhance({x:1});*/".}
# {.emit: "%[AFTER:var(x)]%/*after-x*/;".}

# {.emit: "%[BEFORE:var(y)]%/*ignore-before*/;".}
# {.emit: "%[AFTER:var(y)]%/*ignore-after*/;".}

{.emit: "%[GENID:var(x)]%/*genid:x*/".}
{.emit: "%[ID:var(x)]%/*id:x*/".}
{.emit: "%[GENID:var(y)]%/*ignore-genid:y*/".}
{.emit: "%[ID:var(y)]%/*ignore-id:y*/".}

# {.emit: "%GENID% = x$$".}