# Testing compiler improvements

```nim
import macros, jsffi
{.emit: "import { x as x$$  } from './aba'".}
```

Run tests on compiler w stack trace enabled :)

```sh
./koch temp js 'testfile.nim'
```
