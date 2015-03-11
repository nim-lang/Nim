# bug #2316

type
    EventType = enum
      QuitEvent = 5
    AppMain* = ref object of RootObj
        width: int
        height: int
        title: string
        running: bool
        event_type: EventType
    App* = ref object of AppMain
        draw_proc: proc(app: AppMain): void {.closure.}
        events_proc: proc(app: AppMain): void {.closure.}
        update_proc: proc(app: AppMain, dt: float): void {.closure.}
        load_proc: proc(app: AppMain): void {.closure.}


proc initApp*(t: string, w, h: int): App =
    App(width: w, height: h, title: t, event_type: EventType.QuitEvent)


method getTitle*(self: AppMain): string = self.title
method getWidth*(self: AppMain): int = self.width
method getHeight*(self: AppMain): int = self.height


method draw*(self: App, draw: proc(app: AppMain)): void =
    self.draw_proc = draw

method load*(self: App, load: proc(a: AppMain)): void =
    self.load_proc = load

method events*(self: App, events: proc(app: AppMain)): void =
    self.events_proc = events

method update*(self: App, update: proc(app: AppMain, delta: float)): void =
    self.update_proc = update

method run*(self: App): void = discard

var mygame = initApp("Example", 800, 600)

mygame.load(proc(app: AppMain): void =
    echo app.getTitle()
    echo app.getWidth()
    echo app.getHeight()
)

mygame.events(proc(app: AppMain): void =
    discard
)

mygame.run()
