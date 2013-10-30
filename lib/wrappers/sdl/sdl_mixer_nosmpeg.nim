#******************************************************************************
# Copy of SDL_Mixer without smpeg dependency and mp3 support
#******************************************************************************

import
  sdl

when defined(windows):
  const
    MixerLibName = "SDL_mixer.dll"
elif defined(macosx):
  const
    MixerLibName = "libSDL_mixer-1.2.0.dylib"
else:
  const
    MixerLibName = "libSDL_mixer.so"
const
  MAJOR_VERSION* = 1
  MINOR_VERSION* = 2
  PATCHLEVEL* = 7    # Backwards compatibility

  CHANNELS* = 8           # Good default values for a PC soundcard
  DEFAULT_FREQUENCY* = 22050

when defined(IA32):
  const
    DEFAULT_FORMAT* = AUDIO_S16LSB
else:
  const
    DEFAULT_FORMAT* = AUDIO_S16MSB
const
  DEFAULT_CHANNELS* = 2
  MAX_VOLUME* = 128       # Volume of a chunk
  PATH_MAX* = 255

  LIBMIKMOD_VERSION_MAJOR* = 3
  LIBMIKMOD_VERSION_MINOR* = 1
  LIBMIKMOD_REVISION* = 8
  LIBMIKMOD_VERSION* = ((LIBMIKMOD_VERSION_MAJOR shl 16) or
      (LIBMIKMOD_VERSION_MINOR shl 8) or (LIBMIKMOD_REVISION))

type                          #music_cmd.h types
  PMusicCMD* = ptr TMusicCMD
  TMusicCMD*{.final.} = object  #wavestream.h types
    filename*: array[0..PATH_MAX - 1, char]
    cmd*: array[0..PATH_MAX - 1, char]
    pid*: TSYS_ThreadHandle

  PWAVStream* = ptr TWAVStream
  TWAVStream*{.final.} = object  #playmidi.h types
    wavefp*: Pointer
    start*: int32
    stop*: int32
    cvt*: TAudioCVT

  PMidiEvent* = ptr TMidiEvent
  TMidiEvent*{.final.} = object
    time*: int32
    channel*: byte
    typ*: byte
    a*: byte
    b*: byte

  PMidiSong* = ptr TMidiSong
  TMidiSong*{.final.} = object  #music_ogg.h types
    samples*: int32
    events*: PMidiEvent

  POGG_Music* = ptr TOGG_Music
  TOGG_Music*{.final.} = object  # mikmod.h types
                                 #*
                                 #  * Error codes
                                 #  *
    playing*: cint
    volume*: cint              #vf: OggVorbis_File;
    section*: cint
    cvt*: TAudioCVT
    len_available*: cint
    snd_available*: pointer

  TErrorEnum* = enum
    MMERR_OPENING_FILE, MMERR_OUT_OF_MEMORY, MMERR_DYNAMIC_LINKING,
    MMERR_SAMPLE_TOO_BIG, MMERR_OUT_OF_HANDLES, MMERR_UNKNOWN_WAVE_TYPE,
    MMERR_LOADING_PATTERN, MMERR_LOADING_TRACK, MMERR_LOADING_HEADER,
    MMERR_LOADING_SAMPLEINFO, MMERR_NOT_A_MODULE, MMERR_NOT_A_STREAM,
    MMERR_MED_SYNTHSAMPLES, MMERR_ITPACK_INVALID_DATA, MMERR_DETECTING_DEVICE,
    MMERR_INVALID_DEVICE, MMERR_INITIALIZING_MIXER, MMERR_OPENING_AUDIO,
    MMERR_8BIT_ONLY, MMERR_16BIT_ONLY, MMERR_STEREO_ONLY, MMERR_ULAW,
    MMERR_NON_BLOCK, MMERR_AF_AUDIO_PORT, MMERR_AIX_CONFIG_INIT,
    MMERR_AIX_CONFIG_CONTROL, MMERR_AIX_CONFIG_START, MMERR_GUS_SETTINGS,
    MMERR_GUS_RESET, MMERR_GUS_TIMER, MMERR_HP_SETSAMPLESIZE, MMERR_HP_SETSPEED,
    MMERR_HP_CHANNELS, MMERR_HP_AUDIO_OUTPUT, MMERR_HP_AUDIO_DESC,
    MMERR_HP_BUFFERSIZE, MMERR_OSS_SETFRAGMENT, MMERR_OSS_SETSAMPLESIZE,
    MMERR_OSS_SETSTEREO, MMERR_OSS_SETSPEED, MMERR_SGI_SPEED, MMERR_SGI_16BIT,
    MMERR_SGI_8BIT, MMERR_SGI_STEREO, MMERR_SGI_MONO, MMERR_SUN_INIT,
    MMERR_OS2_MIXSETUP, MMERR_OS2_SEMAPHORE, MMERR_OS2_TIMER, MMERR_OS2_THREAD,
    MMERR_DS_PRIORITY, MMERR_DS_BUFFER, MMERR_DS_FORMAT, MMERR_DS_NOTIFY,
    MMERR_DS_EVENT, MMERR_DS_THREAD, MMERR_DS_UPDATE, MMERR_WINMM_HANDLE,
    MMERR_WINMM_ALLOCATED, MMERR_WINMM_DEVICEID, MMERR_WINMM_FORMAT,
    MMERR_WINMM_UNKNOWN, MMERR_MAC_SPEED, MMERR_MAC_START, MMERR_MAX
  PMODULE* = ptr TMODULE
  TMODULE*{.final.} = object
  PUNIMOD* = ptr TUNIMOD
  TUNIMOD* = TMODULE          #SDL_mixer.h types
                              # The internal format for an audio chunk
  PChunk* = ptr TChunk
  TChunk*{.final.} = object
    allocated*: cint
    abuf*: pointer
    alen*: Uint32
    volume*: byte            # Per-sample volume, 0-128

  TFading* = enum
    MIX_NO_FADING, MIX_FADING_OUT, MIX_FADING_IN
  TMusicType* = enum
    MUS_NONE, MUS_CMD, MUS_WAV, MUS_MOD, MUS_MID, MUS_OGG
  PMusic* = ptr TMusic
  TMusic*{.final.} = object
    typ*: TMusicType

  TMixFunction* = proc (udata, stream: pointer, length: cint): Pointer{.
      cdecl.} # This macro can be used to fill a version structure with the compile-time
              #  version of the SDL_mixer library.

proc VERSION*(X: var sdl.TVersion)
  # This function gets the version of the dynamically linked SDL_mixer library.
  #     It should NOT be used to fill a version structure, instead you should use the
  #     SDL_MIXER_VERSION() macro.
proc Linked_Version*(): sdl.Pversion{.cdecl, importc: "Mix_Linked_Version",
                                      dynlib: MixerLibName.}
  # Open the mixer with a certain audio format
proc OpenAudio*(frequency: cint, format: Uint16, channels: cint,
                    chunksize: cint): cint{.cdecl, importc: "Mix_OpenAudio",
    dynlib: MixerLibName.}
  # Dynamically change the number of channels managed by the mixer.
  #   If decreasing the number of channels, the upper channels are
  #   stopped.
  #   This function returns the new number of allocated channels.
  #
proc AllocateChannels*(numchannels: cint): cint{.cdecl,
    importc: "Mix_AllocateChannels", dynlib: MixerLibName.}
  # Find out what the actual audio device parameters are.
  #   This function returns 1 if the audio has been opened, 0 otherwise.
  #
proc QuerySpec*(frequency: var cint, format: var Uint16, channels: var cint): cint{.
    cdecl, importc: "Mix_QuerySpec", dynlib: MixerLibName.}
  # Load a wave file or a music (.mod .s3m .it .xm) file
proc LoadWAV_RW*(src: PRWops, freesrc: cint): PChunk{.cdecl,
    importc: "Mix_LoadWAV_RW", dynlib: MixerLibName.}
proc LoadWAV*(filename: cstring): PChunk
proc LoadMUS*(filename: cstring): PMusic{.cdecl, importc: "Mix_LoadMUS",
    dynlib: MixerLibName.}
  # Load a wave file of the mixer format from a memory buffer
proc QuickLoad_WAV*(mem: pointer): PChunk{.cdecl,
    importc: "Mix_QuickLoad_WAV", dynlib: MixerLibName.}
  # Free an audio chunk previously loaded
proc FreeChunk*(chunk: PChunk){.cdecl, importc: "Mix_FreeChunk",
                                        dynlib: MixerLibName.}
proc FreeMusic*(music: PMusic){.cdecl, importc: "Mix_FreeMusic",
                                        dynlib: MixerLibName.}
  # Find out the music format of a mixer music, or the currently playing
  #   music, if 'music' is NULL.
proc GetMusicType*(music: PMusic): TMusicType{.cdecl,
    importc: "Mix_GetMusicType", dynlib: MixerLibName.}
  # Set a function that is called after all mixing is performed.
  #   This can be used to provide real-time visual display of the audio stream
  #   or add a custom mixer filter for the stream data.
  #
proc SetPostMix*(mixfunc: TMixFunction, arg: Pointer){.cdecl,
    importc: "Mix_SetPostMix", dynlib: MixerLibName.}
  # Add your own music player or additional mixer function.
  #   If 'mix_func' is NULL, the default music player is re-enabled.
  #
proc HookMusic*(mix_func: TMixFunction, arg: Pointer){.cdecl,
    importc: "Mix_HookMusic", dynlib: MixerLibName.}
  # Add your own callback when the music has finished playing.
  #
proc HookMusicFinished*(music_finished: Pointer){.cdecl,
    importc: "Mix_HookMusicFinished", dynlib: MixerLibName.}
  # Get a pointer to the user data for the current music hook
proc GetMusicHookData*(): Pointer{.cdecl, importc: "Mix_GetMusicHookData",
                                       dynlib: MixerLibName.}
  #* Add your own callback when a channel has finished playing. NULL
  # * to disable callback.*
type
  TChannel_finished* = proc (channel: cint){.cdecl.}

proc ChannelFinished*(channel_finished: TChannel_finished){.cdecl,
    importc: "Mix_ChannelFinished", dynlib: MixerLibName.}
const
  CHANNEL_POST* = - 2

type
  TEffectFunc* = proc (chan: cint, stream: Pointer, length: cint,
                           udata: Pointer): Pointer{.cdecl.}
  TEffectDone* = proc (chan: cint, udata: Pointer): Pointer{.cdecl.}

proc RegisterEffect*(chan: cint, f: TEffectFunc, d: TEffectDone,
                         arg: Pointer): cint{.cdecl,
    importc: "Mix_RegisterEffect", dynlib: MixerLibName.}

proc UnregisterEffect*(channel: cint, f: TEffectFunc): cint{.cdecl,
    importc: "Mix_UnregisterEffect", dynlib: MixerLibName.}

proc UnregisterAllEffects*(channel: cint): cint{.cdecl,
    importc: "Mix_UnregisterAllEffects", dynlib: MixerLibName.}

const
  EFFECTSMAXSPEED* = "MIX_EFFECTSMAXSPEED"

proc SetPanning*(channel: cint, left: byte, right: byte): cint{.cdecl,
    importc: "Mix_SetPanning", dynlib: MixerLibName.}

proc SetPosition*(channel: cint, angle: int16, distance: byte): cint{.cdecl,
    importc: "Mix_SetPosition", dynlib: MixerLibName.}

proc SetDistance*(channel: cint, distance: byte): cint{.cdecl,
    importc: "Mix_SetDistance", dynlib: MixerLibName.}

proc SetReverseStereo*(channel: cint, flip: cint): cint{.cdecl,
    importc: "Mix_SetReverseStereo", dynlib: MixerLibName.}

proc ReserveChannels*(num: cint): cint{.cdecl, importc: "Mix_ReserveChannels",
    dynlib: MixerLibName.}

proc GroupChannel*(which: cint, tag: cint): cint{.cdecl,
    importc: "Mix_GroupChannel", dynlib: MixerLibName.}
  # Assign several consecutive channels to a group
proc GroupChannels*(`from`: cint, `to`: cint, tag: cint): cint{.cdecl,
    importc: "Mix_GroupChannels", dynlib: MixerLibName.}
  # Finds the first available channel in a group of channels
proc GroupAvailable*(tag: cint): cint{.cdecl, importc: "Mix_GroupAvailable",
    dynlib: MixerLibName.}
  # Returns the number of channels in a group. This is also a subtle
  #   way to get the total number of channels when 'tag' is -1
  #
proc GroupCount*(tag: cint): cint{.cdecl, importc: "Mix_GroupCount",
                                     dynlib: MixerLibName.}
  # Finds the "oldest" sample playing in a group of channels
proc GroupOldest*(tag: cint): cint{.cdecl, importc: "Mix_GroupOldest",
                                      dynlib: MixerLibName.}
  # Finds the "most recent" (i.e. last) sample playing in a group of channels
proc GroupNewer*(tag: cint): cint{.cdecl, importc: "Mix_GroupNewer",
                                     dynlib: MixerLibName.}
  # The same as above, but the sound is played at most 'ticks' milliseconds
proc PlayChannelTimed*(channel: cint, chunk: PChunk, loops: cint,
                           ticks: cint): cint{.cdecl,
    importc: "Mix_PlayChannelTimed", dynlib: MixerLibName.}

proc PlayChannel*(channel: cint, chunk: PChunk, loops: cint): cint
proc PlayMusic*(music: PMusic, loops: cint): cint{.cdecl,
    importc: "Mix_PlayMusic", dynlib: MixerLibName.}
  # Fade in music or a channel over "ms" milliseconds, same semantics as the "Play" functions
proc FadeInMusic*(music: PMusic, loops: cint, ms: cint): cint{.cdecl,
    importc: "Mix_FadeInMusic", dynlib: MixerLibName.}
proc FadeInChannelTimed*(channel: cint, chunk: PChunk, loops: cint,
                             ms: cint, ticks: cint): cint{.cdecl,
    importc: "Mix_FadeInChannelTimed", dynlib: MixerLibName.}
proc FadeInChannel*(channel: cint, chunk: PChunk, loops: cint, ms: cint): cint
  # Set the volume in the range of 0-128 of a specific channel or chunk.
  #   If the specified channel is -1, set volume for all channels.
  #   Returns the original volume.
  #   If the specified volume is -1, just return the current volume.
  #
proc Volume*(channel: cint, volume: cint): cint{.cdecl, importc: "Mix_Volume",
    dynlib: MixerLibName.}
proc VolumeChunk*(chunk: PChunk, volume: cint): cint{.cdecl,
    importc: "Mix_VolumeChunk", dynlib: MixerLibName.}
proc VolumeMusic*(volume: cint): cint{.cdecl, importc: "Mix_VolumeMusic",
    dynlib: MixerLibName.}
  # Halt playing of a particular channel
proc HaltChannel*(channel: cint): cint{.cdecl, importc: "Mix_HaltChannel",
    dynlib: MixerLibName.}
proc HaltGroup*(tag: cint): cint{.cdecl, importc: "Mix_HaltGroup",
                                    dynlib: MixerLibName.}
proc HaltMusic*(): cint{.cdecl, importc: "Mix_HaltMusic",
                            dynlib: MixerLibName.}

proc ExpireChannel*(channel: cint, ticks: cint): cint{.cdecl,
    importc: "Mix_ExpireChannel", dynlib: MixerLibName.}

proc FadeOutChannel*(which: cint, ms: cint): cint{.cdecl,
    importc: "Mix_FadeOutChannel", dynlib: MixerLibName.}
proc FadeOutGroup*(tag: cint, ms: cint): cint{.cdecl,
    importc: "Mix_FadeOutGroup", dynlib: MixerLibName.}
proc FadeOutMusic*(ms: cint): cint{.cdecl, importc: "Mix_FadeOutMusic",
                                      dynlib: MixerLibName.}
  # Query the fading status of a channel
proc FadingMusic*(): TFading{.cdecl, importc: "Mix_FadingMusic",
                                      dynlib: MixerLibName.}
proc FadingChannel*(which: cint): TFading{.cdecl,
    importc: "Mix_FadingChannel", dynlib: MixerLibName.}
  # Pause/Resume a particular channel
proc Pause*(channel: cint){.cdecl, importc: "Mix_Pause", dynlib: MixerLibName.}
proc Resume*(channel: cint){.cdecl, importc: "Mix_Resume",
                                dynlib: MixerLibName.}
proc Paused*(channel: cint): cint{.cdecl, importc: "Mix_Paused",
                                     dynlib: MixerLibName.}
  # Pause/Resume the music stream
proc PauseMusic*(){.cdecl, importc: "Mix_PauseMusic", dynlib: MixerLibName.}
proc ResumeMusic*(){.cdecl, importc: "Mix_ResumeMusic", dynlib: MixerLibName.}
proc RewindMusic*(){.cdecl, importc: "Mix_RewindMusic", dynlib: MixerLibName.}
proc PausedMusic*(): cint{.cdecl, importc: "Mix_PausedMusic",
                              dynlib: MixerLibName.}
  # Set the current position in the music stream.
  #  This returns 0 if successful, or -1 if it failed or isn't implemented.
  #  This function is only implemented for MOD music formats (set pattern
  #  order number) and for OGG music (set position in seconds), at the
  #  moment.
  #
proc SetMusicPosition*(position: float64): cint{.cdecl,
    importc: "Mix_SetMusicPosition", dynlib: MixerLibName.}
  # Check the status of a specific channel.
  #   If the specified channel is -1, check all channels.
  #
proc Playing*(channel: cint): cint{.cdecl, importc: "Mix_Playing",
                                      dynlib: MixerLibName.}
proc PlayingMusic*(): cint{.cdecl, importc: "Mix_PlayingMusic",
                               dynlib: MixerLibName.}
  # Stop music and set external music playback command
proc SetMusicCMD*(command: cstring): cint{.cdecl, importc: "Mix_SetMusicCMD",
    dynlib: MixerLibName.}
  # Synchro value is set by MikMod from modules while playing
proc SetSynchroValue*(value: cint): cint{.cdecl,
    importc: "Mix_SetSynchroValue", dynlib: MixerLibName.}
proc GetSynchroValue*(): cint{.cdecl, importc: "Mix_GetSynchroValue",
                                  dynlib: MixerLibName.}
  #
  #  Get the Mix_Chunk currently associated with a mixer channel
  #    Returns nil if it's an invalid channel, or there's no chunk associated.
  #
proc GetChunk*(channel: cint): PChunk{.cdecl, importc: "Mix_GetChunk",
    dynlib: MixerLibName.}
  # Close the mixer, halting all playing audio
proc CloseAudio*(){.cdecl, importc: "Mix_CloseAudio", dynlib: MixerLibName.}
  # We'll use SDL for reporting errors

proc VERSION(X: var Tversion) =
  X.major = MAJOR_VERSION
  X.minor = MINOR_VERSION
  X.patch = PATCHLEVEL

proc LoadWAV(filename: cstring): PChunk =
  result = LoadWAV_RW(RWFromFile(filename, "rb"), 1)

proc PlayChannel(channel: cint, chunk: PChunk, loops: cint): cint =
  result = PlayChannelTimed(channel, chunk, loops, - 1)

proc FadeInChannel(channel: cint, chunk: PChunk, loops: cint, ms: cint): cint =
  result = FadeInChannelTimed(channel, chunk, loops, ms, - 1)

