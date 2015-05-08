discard """
  cmd: "nim cpp $file"
"""

{.emit: """

namespace System {
  struct Input {};
}

struct SystemManager {
  template <class T>
  static T* getSubsystem() { return new T; }
};

""".}

type Input {.importcpp: "System::Input".} = object
proc getSubsystem*[T](): ptr T {.
  importcpp: "SystemManager::getSubsystem<'*0>()", nodecl.}

let input: ptr Input = getSubsystem[Input]()

