{.passL: "-lsfml-graphics -lsfml-system -lsfml-window".}

type
  VideoMode* {.importcpp: "sf::VideoMode".} = object
  RenderWindowObj {.importcpp: "sf::RenderWindow".} = object
  RenderWindow* = ptr RenderWindowObj
  Color* {.importcpp: "sf::Color".} = object
  Event* {.importcpp: "sf::Event".} = object

{.push cdecl, header: "<SFML/Graphics.hpp>".}

proc videoMode*(modeWidth, modeHeight: cuint, modeBitsPerPixel: cuint = 32): VideoMode
    {.importcpp: "sf::VideoMode(@)", constructor.}

proc newRenderWindow*(mode: VideoMode, title: cstring): RenderWindow
    {.importcpp: "new sf::RenderWindow(@)", constructor.}

proc pollEvent*(window: RenderWindow, event: var Event): bool
    {.importcpp: "#.pollEvent(@)".}

proc newColor*(red, green, blue, alpha: uint8): Color
    {.importcpp: "sf::Color(@)", constructor.}

proc clear*(window: RenderWindow, color: Color) {.importcpp: "#.clear(@)".}

proc display*(window: RenderWindow) {.importcpp: "#.display()".}
