
type
  OtherEnum* = enum
    Success, Failed, More

proc some*(x: OtherEnum): bool = x == Success
