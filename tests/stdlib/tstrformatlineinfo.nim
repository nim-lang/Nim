# issue #21759

{.hint[ConvFromXToItselfNotNeeded]: on.}

import std/strformat

echo fmt"{string ""abc""}" #[tt.Hint
        ^ conversion from string to itself is pointless]#
