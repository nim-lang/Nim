proc pub*(x: int): int = x + 1

proc hidden(): int = 42   # no `*` ...
export hidden             # ... but explicitly re-exported
