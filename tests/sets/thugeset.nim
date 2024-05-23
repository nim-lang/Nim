let x = 20_000
let s = {x, 123} #[tt.Warning
        ^ type 'int' is too big to be a `set` element, assuming a range of 0..65535, explicitly write this range to get rid of warning [AboveMaxSizeSet]]#
doAssert x in s
doAssert 20_000 in s
{.push warningAsError[AboveMaxSizeSet]: on.}
let s2 = {range[0..65535](x), 123}
doAssert x in s
doAssert 20_000 in s
{.pop.}
