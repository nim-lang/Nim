when defined(NoSFML) or defined(NoChipmunk):
  {.error.}
import sfml_audio, sfml_stuff, sg_assets, chipmunk
const
  MinDistance* = 350.0
  Attenuation* = 20.0
var
  liveSounds: seq[PSound] = @[]
  deadSounds: seq[PSound] = @[]

proc playSound*(sound: PSoundRecord, pos: TVector) =
  if sound.isNil or sound.soundBuf.isNil: return
  var s: PSound
  if deadSounds.len == 0:
    s = sfml_audio.newSound()
    s.setLoop false
    s.setRelativeToListener true
    s.setAttenuation Attenuation
    s.setMinDistance MinDistance
  else:
    s = deadSounds.pop()
  s.setPosition(vec3f(pos.x, 0, pos.y))
  s.setBuffer(sound.soundBuf)
  s.play()
  liveSounds.add s

proc updateSoundBuffer*() =
  var i = 0
  while i < len(liveSounds):
    if liveSounds[i].getStatus == Stopped:
      deadSounds.add liveSounds[i]
      liveSounds.del i
    else:
      inc i

proc report*() =
  echo "live: ", liveSounds.len
  echo "dead: ", deadSounds.len
