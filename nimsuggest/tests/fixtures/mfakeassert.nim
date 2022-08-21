# Template for testing defs

template fakeAssert*(cond: untyped, msg: string = "") =
  ## template to allow def lookup testing
  if not cond: quit(1)
