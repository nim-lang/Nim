# module A
import mexportb
export mexportb.TMyObject, mexportb.xyz

export mexportb.q

proc `$`*(x: TMyObject): string = "my object"

