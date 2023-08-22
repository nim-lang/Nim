import
  sfml
const
  Lib = "libcsfml-audio.so.2.0"
type
  PMusic* = ptr TMusic
  TMusic* {.pure, final.} = object
  PSound* = ptr TSound
  TSound* {.pure, final.} = object
  PSoundBuffer* = ptr TSoundBuffer
  TSoundBuffer* {.pure, final.} = object
  PSoundBufferRecorder* = ptr TSoundBufferRecorder
  TSoundBufferRecorder* {.pure, final.} = object
  PSoundRecorder* = ptr TSoundRecorder
  TSoundRecorder* {.pure, final.} = object
  PSoundStream* = ptr TSoundStream
  TSoundStream* {.pure, final.} = object
  TSoundStatus* {.size: sizeof(cint).} = enum
    Stopped, Paused, Playing

proc newMusic*(filename: cstring): PMusic {.
  cdecl, importc: "sfMusic_createFromFile", dynlib: Lib.}
proc newMusic*(data: pointer, size: cint): PMusic {.
  cdecl, importc: "sfMusic_createFromMemory", dynlib: Lib.}
proc newMusic*(stream: PInputStream): PMusic {.
  cdecl, importc: "sfMusic_createFromStream", dynlib: Lib.}
proc destroy*(music: PMusic) {.
  cdecl, importc: "sfMusic_destroy", dynlib: Lib.}
proc setLoop*(music: PMusic, loop: bool) {.
  cdecl, importc: "sfMusic_setLoop", dynlib: Lib.}
proc getLoop*(music: PMusic): bool {.
  cdecl, importc: "sfMusic_getLoop", dynlib: Lib.}
proc getDuration*(music: PMusic): TTime {.
  cdecl, importc: "sfMusic_getDuration", dynlib: Lib.}
proc play*(music: PMusic) {.
  cdecl, importc: "sfMusic_play", dynlib: Lib.}
proc pause*(music: PMusic) {.
  cdecl, importc: "sfMusic_pause", dynlib: Lib.}
proc stop*(music: PMusic) {.
  cdecl, importc: "sfMusic_stop", dynlib: Lib.}
proc getChannelCount*(music: PMusic): cint {.
  cdecl, importc: "sfMusic_getChannelCount", dynlib: Lib.}
proc getSampleRate*(music: PMusic): cint {.
  cdecl, importc: "sfMusic_getSampleRate", dynlib: Lib.}
proc getStatus*(music: PMusic): TSoundStatus {.
  cdecl, importc: "sfMusic_getStatus", dynlib: Lib.}
proc getPlayingOffset*(music: PMusic): TTime {.
  cdecl, importc: "sfMusic_getPlayingOffset", dynlib: Lib.}
proc setPitch*(music: PMusic, pitch: cfloat) {.
  cdecl, importc: "sfMusic_setPitch", dynlib: Lib.}
proc setVolume*(music: PMusic, volume: float) {.
  cdecl, importc: "sfMusic_setVolume", dynlib: Lib.}
proc setPosition*(music: PMusic, position: TVector3f) {.
  cdecl, importc: "sfMusic_setPosition", dynlib: Lib.}
proc setRelativeToListener*(music: PMusic, relative: bool) {.
  cdecl, importc: "sfMusic_setRelativeToListener", dynlib: Lib.}
proc setMinDistance*(music: PMusic, distance: cfloat) {.
  cdecl, importc: "sfMusic_setMinDistance", dynlib: Lib.}
proc setAttenuation*(music: PMusic, attenuation: cfloat) {.
  cdecl, importc: "sfMusic_setAttenuation", dynlib: Lib.}
proc setPlayingOffset*(music: PMusic, time: TTime) {.
  cdecl, importc: "sfMusic_setPlayingOffset", dynlib: Lib.}
proc getPitch*(music: PMusic): cfloat {.
  cdecl, importc: "sfMusic_getPitch", dynlib: Lib.}
proc getVolume*(music: PMusic): cfloat {.
  cdecl, importc: "sfMusic_getVolume", dynlib: Lib.}
proc getPosition*(music: PMusic): TVector3f {.
  cdecl, importc: "sfMusic_getPosition", dynlib: Lib.}
proc isRelativeToListener*(music: PMusic): bool {.
  cdecl, importc: "sfMusic_isRelativeToListener", dynlib: Lib.}
proc getMinDistance*(music: PMusic): cfloat {.
  cdecl, importc: "sfMusic_isRelativeToListener", dynlib: Lib.}
proc getAttenuation*(music: PMusic): cfloat {.
  cdecl, importc: "sfMusic_isRelativeToListener", dynlib: Lib.}

#/ \brief Create a new sound
proc newSound*(): PSound{.
  cdecl, importc: "sfSound_create", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Create a new sound by copying an existing one
#/
#/ \param sound Sound to copy
#/
#/ \return A new sfSound object which is a copy of \a sound
#/
#//////////////////////////////////////////////////////////
proc copy*(sound: PSound): PSound{.
  cdecl, importc: "sfSound_copy", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Destroy a sound
proc destroy*(sound: PSound){.
  cdecl, importc: "sfSound_destroy", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Start or resume playing a sound
#/
#/ This function starts the sound if it was stopped, resumes
#/ it if it was paused, and restarts it from beginning if it
#/ was it already playing.
#/ This function uses its own thread so that it doesn't block
#/ the rest of the program while the sound is played.
proc play*(sound: PSound){.
  cdecl, importc: "sfSound_play", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ This function pauses the sound if it was playing,
#/ otherwise (sound already paused or stopped) it has no effect.
proc pause*(sound: PSound){.
  cdecl, importc: "sfSound_pause", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ This function stops the sound if it was playing or paused,
#/ and does nothing if it was already stopped.
#/ It also resets the playing position (unlike sfSound_pause).
proc stop*(sound: PSound){.
  cdecl, importc: "sfSound_stop", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ It is important to note that the sound buffer is not copied,
#/ thus the sfSoundBuffer object must remain alive as long
#/ as it is attached to the sound.
proc setBuffer*(sound: PSound; buffer: PSoundBuffer){.
  cdecl, importc: "sfSound_setBuffer", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the audio buffer attached to a sound
proc getBuffer*(sound: PSound): PSoundBuffer{.
  cdecl, importc: "sfSound_getBuffer", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set whether or not a sound should loop after reaching the end
#/
#/ If set, the sound will restart from beginning after
#/ reaching the end and so on, until it is stopped or
#/ sfSound_setLoop(sound, sfFalse) is called.
#/ The default looping state for sounds is false.
proc setLoop*(sound: PSound; loop: bool){.
  cdecl, importc: "sfSound_setLoop", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Tell whether or not a soud is in loop mode
proc getLoop*(sound: PSound): bool {.
  cdecl, importc: "sfSound_getLoop", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the current status of a sound (stopped, paused, playing)
proc getStatus*(sound: PSound): TSoundStatus{.
  cdecl, importc: "sfSound_getStatus", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the pitch of a sound
#/
#/ The pitch represents the perceived fundamental frequency
#/ of a sound; thus you can make a sound more acute or grave
#/ by changing its pitch. A side effect of changing the pitch
#/ is to modify the playing speed of the sound as well.
#/ The default value for the pitch is 1.
proc setPitch*(sound: PSound; pitch: cfloat){.
  cdecl, importc: "sfSound_setPitch", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the volume of a sound
#/
#/ The volume is a value between 0 (mute) and 100 (full volume).
#/ The default value for the volume is 100.
proc setVolume*(sound: PSound; volume: cfloat){.
  cdecl, importc: "sfSound_setVolume", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the 3D position of a sound in the audio scene
#/
#/ Only sounds with one channel (mono sounds) can be
#/ spatialized.
#/ The default position of a sound is (0, 0, 0).
proc setPosition*(sound: PSound; position: TVector3f){.
  cdecl, importc: "sfSound_setPosition", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Make the sound's position relative to the listener or absolute
#/
#/ Making a sound relative to the listener will ensure that it will always
#/ be played the same way regardless the position of the listener.
#/ This can be useful for non-spatialized sounds, sounds that are
#/ produced by the listener, or sounds attached to it.
#/ The default value is false (position is absolute).
proc setRelativeToListener*(sound: PSound; relative: bool){.
  cdecl, importc: "sfSound_setRelativeToListener", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the minimum distance of a sound
#/
#/ The "minimum distance" of a sound is the maximum
#/ distance at which it is heard at its maximum volume. Further
#/ than the minimum distance, it will start to fade out according
#/ to its attenuation factor. A value of 0 ("inside the head
#/ of the listener") is an invalid value and is forbidden.
#/ The default value of the minimum distance is 1.
proc setMinDistance*(sound: PSound; distance: cfloat){.
  cdecl, importc: "sfSound_setMinDistance", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the attenuation factor of a sound
#/
#/ The attenuation is a multiplicative factor which makes
#/ the sound more or less loud according to its distance
#/ from the listener. An attenuation of 0 will produce a
#/ non-attenuated sound, i.e. its volume will always be the same
#/ whether it is heard from near or from far. On the other hand,
#/ an attenuation value such as 100 will make the sound fade out
#/ very quickly as it gets further from the listener.
#/ The default value of the attenuation is 1.
proc setAttenuation*(sound: PSound; attenuation: cfloat){.
  cdecl, importc: "sfSound_setAttenuation", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Change the current playing position of a sound
#/
#/ The playing position can be changed when the sound is
#/ either paused or playing.
proc setPlayingOffset*(sound: PSound; timeOffset: sfml.TTime){.
  cdecl, importc: "sfSound_setPlayingOffset", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the pitch of a sound
proc getPitch*(sound: PSound): cfloat{.
  cdecl, importc: "sfSound_getPitch", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the volume of a sound
proc getVolume*(sound: PSound): cfloat{.
  cdecl, importc: "sfSound_getVolume", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the 3D position of a sound in the audio scene
proc getPosition*(sound: PSound): TVector3f{.
  cdecl, importc: "sfSound_getPosition", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Tell whether a sound's position is relative to the
#/        listener or is absolute
proc isRelativeToListener*(sound: PSound): bool{.
  cdecl, importc: "sfSound_isRelativeToListener", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the minimum distance of a sound
proc getMinDistance*(sound: PSound): cfloat{.
  cdecl, importc: "sfSound_getMinDistance", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the attenuation factor of a sound
proc getAttenuation*(sound: PSound): cfloat{.
  cdecl, importc: "sfSound_getAttenuation", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the current playing position of a sound
proc getPlayingOffset*(sound: PSound): TTime{.
  cdecl, importc: "sfSound_getPlayingOffset", dynlib: Lib.}

#//////////////////////////////////////////////////////////
# Headers
#//////////////////////////////////////////////////////////
#//////////////////////////////////////////////////////////
#/ \brief Create a new sound buffer and load it from a file
#/
#/ Here is a complete list of all the supported audio formats:
#/ ogg, wav, flac, aiff, au, raw, paf, svx, nist, voc, ircam,
#/ w64, mat4, mat5 pvf, htk, sds, avr, sd2, caf, wve, mpc2k, rf64.
#/
#/ \param filename Path of the sound file to load
#/
#/ \return A new sfSoundBuffer object (NULL if failed)
#/
#//////////////////////////////////////////////////////////
proc newSoundBuffer*(filename: cstring): PSoundBuffer{.
  cdecl, importc: "sfSoundBuffer_createFromFile", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Create a new sound buffer and load it from a file in memory
#/
#/ Here is a complete list of all the supported audio formats:
#/ ogg, wav, flac, aiff, au, raw, paf, svx, nist, voc, ircam,
#/ w64, mat4, mat5 pvf, htk, sds, avr, sd2, caf, wve, mpc2k, rf64.
#/
#/ \param data        Pointer to the file data in memory
#/ \param sizeInBytes Size of the data to load, in bytes
#/
#/ \return A new sfSoundBuffer object (NULL if failed)
#/
#//////////////////////////////////////////////////////////
proc newSoundBuffer*(data: pointer; sizeInBytes: cint): PSoundBuffer{.
  cdecl, importc: "sfSoundBuffer_createFromMemory", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Create a new sound buffer and load it from a custom stream
#/
#/ Here is a complete list of all the supported audio formats:
#/ ogg, wav, flac, aiff, au, raw, paf, svx, nist, voc, ircam,
#/ w64, mat4, mat5 pvf, htk, sds, avr, sd2, caf, wve, mpc2k, rf64.
#/
#/ \param stream Source stream to read from
#/
#/ \return A new sfSoundBuffer object (NULL if failed)
#/
#//////////////////////////////////////////////////////////
proc newSoundBuffer*(stream: PInputStream): PSoundBuffer{.
  cdecl, importc: "sfSoundBuffer_createFromStream", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Create a new sound buffer and load it from an array of samples in memory
#/
#/ The assumed format of the audio samples is 16 bits signed integer
#/ (sfint16).
#/
#/ \param samples      Pointer to the array of samples in memory
#/ \param sampleCount  Number of samples in the array
#/ \param channelCount Number of channels (1 = mono, 2 = stereo, ...)
#/ \param sampleRate   Sample rate (number of samples to play per second)
#/
#/ \return A new sfSoundBuffer object (NULL if failed)
#/
#//////////////////////////////////////////////////////////
proc createFromSamples*(samples: ptr int16; sampleCount: cuint;
                         channelCount: cuint; sampleRate: cuint): PSoundBuffer{.
  cdecl, importc: "sfSoundBuffer_createFromSamples", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Create a new sound buffer by copying an existing one
#/
#/ \param soundBuffer Sound buffer to copy
#/
#/ \return A new sfSoundBuffer object which is a copy of \a soundBuffer
#/
#//////////////////////////////////////////////////////////
proc copy*(soundBuffer: PSoundBuffer): PSoundBuffer{.
  cdecl, importc: "sfSoundBuffer_copy", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Destroy a sound buffer
#/
#/ \param soundBuffer Sound buffer to destroy
#/
#//////////////////////////////////////////////////////////
proc destroy*(soundBuffer: PSoundBuffer){.
  cdecl, importc: "sfSoundBuffer_destroy", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Save a sound buffer to an audio file
#/
#/ Here is a complete list of all the supported audio formats:
#/ ogg, wav, flac, aiff, au, raw, paf, svx, nist, voc, ircam,
#/ w64, mat4, mat5 pvf, htk, sds, avr, sd2, caf, wve, mpc2k, rf64.
#/
#/ \param soundBuffer Sound buffer object
#/ \param filename    Path of the sound file to write
#/
#/ \return sfTrue if saving succeeded, sfFalse if it failed
#/
#//////////////////////////////////////////////////////////
proc saveToFile*(soundBuffer: PSoundBuffer; filename: cstring): bool {.
  cdecl, importc: "sfSoundBuffer_saveToFile", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the array of audio samples stored in a sound buffer
#/
#/ The format of the returned samples is 16 bits signed integer
#/ (sfint16). The total number of samples in this array
#/ is given by the sfSoundBuffer_getSampleCount function.
#/
#/ \param soundBuffer Sound buffer object
#/
#/ \return Read-only pointer to the array of sound samples
#/
#//////////////////////////////////////////////////////////
proc sfSoundBuffer_getSamples*(soundBuffer: PSoundBuffer): ptr int16{.
  cdecl, importc: "sfSoundBuffer_getSamples", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the number of samples stored in a sound buffer
#/
#/ The array of samples can be accessed with the
#/ sfSoundBuffer_getSamples function.
proc getSampleCount*(soundBuffer: PSoundBuffer): cint{.
  cdecl, importc: "sfSoundBuffer_getSampleCount", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the sample rate of a sound buffer
#/
#/ The sample rate is the number of samples played per second.
#/ The higher, the better the quality (for example, 44100
#/ samples/s is CD quality).
proc getSampleRate*(soundBuffer: PSoundBuffer): cuint{.
  cdecl, importc: "sfSoundBuffer_getSampleRate", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the number of channels used by a sound buffer
#/
#/ If the sound is mono then the number of channels will
#/ be 1, 2 for stereo, etc.
proc getChannelCount*(soundBuffer: PSoundBuffer): cuint{.
  cdecl, importc: "sfSoundBuffer_getChannelCount", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the total duration of a sound buffer
#/
#/ \param soundBuffer Sound buffer object
#/
#/ \return Sound duration
#/
#//////////////////////////////////////////////////////////
proc getDuration*(soundBuffer: PSoundBuffer): TTime{.
  cdecl, importc: "sfSoundBuffer_getDuration", dynlib: Lib.}

#//////////////////////////////////////////////////////////
#/ \brief Change the global volume of all the sounds and musics
#/
#/ The volume is a number between 0 and 100; it is combined with
#/ the individual volume of each sound / music.
#/ The default value for the volume is 100 (maximum).
#/
#/ \param volume New global volume, in the range [0, 100]
#/
#//////////////////////////////////////////////////////////
proc listenerSetGlobalVolume*(volume: cfloat){.
  cdecl, importc: "sfListener_setGlobalVolume", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the current value of the global volume
#/
#/ \return Current global volume, in the range [0, 100]
#/
#//////////////////////////////////////////////////////////
proc listenerGetGlobalVolume*(): cfloat{.
  cdecl, importc: "sfListener_getGlobalVolume", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the position of the listener in the scene
#/
#/ The default listener's position is (0, 0, 0).
#/
#/ \param position New position of the listener
#/
#//////////////////////////////////////////////////////////
proc listenerSetPosition*(position: TVector3f){.
  cdecl, importc: "sfListener_setPosition", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the current position of the listener in the scene
#/
#/ \return The listener's position
#/
#//////////////////////////////////////////////////////////
proc listenerGetPosition*(): TVector3f{.
  cdecl, importc: "sfListener_getPosition", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the orientation of the listener in the scene
#/
#/ The orientation defines the 3D axes of the listener
#/ (left, up, front) in the scene. The orientation vector
#/ doesn't have to be normalized.
#/ The default listener's orientation is (0, 0, -1).
#/
#/ \param position New direction of the listener
#/
#//////////////////////////////////////////////////////////
proc listenerSetDirection*(orientation: TVector3f){.
  cdecl, importc: "sfListener_setDirection", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the current orientation of the listener in the scene
#/
#/ \return The listener's direction
#/
#//////////////////////////////////////////////////////////
proc listenerGetDirection*(): TVector3f{.
  cdecl, importc: "sfListener_getDirection", dynlib: Lib.}

type
  TSoundRecorderStartCallback* = proc (a2: pointer): bool {.cdecl.}
  #/< Type of the callback used when starting a capture
  TSoundRecorderProcessCallback* = proc(a2: ptr int16; a3: cuint;
    a4: pointer): bool {.cdecl.}
  #/< Type of the callback used to process audio data
  TSoundRecorderStopCallback* = proc (a2: pointer){.cdecl.}
  #/< Type of the callback used when stopping a capture
#//////////////////////////////////////////////////////////
#/ \brief Construct a new sound recorder from callback functions
#/
#/ \param onStart   Callback function which will be called when a new capture starts (can be NULL)
#/ \param onProcess Callback function which will be called each time there's audio data to process
#/ \param onStop    Callback function which will be called when the current capture stops (can be NULL)
#/ \param userData  Data to pass to the callback function (can be NULL)
#/
#/ \return A new sfSoundRecorder object (NULL if failed)
#/
#//////////////////////////////////////////////////////////
proc newSoundRecorder*(onStart: TSoundRecorderStartCallback;
                        onProcess: TSoundRecorderProcessCallback;
                        onStop: TSoundRecorderStopCallback;
                        userData: pointer = nil): PSoundRecorder{.
  cdecl, importc: "sfSoundRecorder_create", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Destroy a sound recorder
#/
#/ \param soundRecorder Sound recorder to destroy
#/
#//////////////////////////////////////////////////////////
proc destroy*(soundRecorder: PSoundRecorder){.
  cdecl, importc: "sfSoundRecorder_destroy", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Start the capture of a sound recorder
#/
#/ The \a sampleRate parameter defines the number of audio samples
#/ captured per second. The higher, the better the quality
#/ (for example, 44100 samples/sec is CD quality).
#/ This function uses its own thread so that it doesn't block
#/ the rest of the program while the capture runs.
#/ Please note that only one capture can happen at the same time.
#/
#/ \param soundRecorder Sound recorder object
#/ \param sampleRate    Desired capture rate, in number of samples per second
#/
#//////////////////////////////////////////////////////////
proc start*(soundRecorder: PSoundRecorder; sampleRate: cuint){.
  cdecl, importc: "sfSoundRecorder_start", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Stop the capture of a sound recorder
#/
#/ \param soundRecorder Sound recorder object
#/
#//////////////////////////////////////////////////////////
proc stop*(soundRecorder: PSoundRecorder){.
  cdecl, importc: "sfSoundRecorder_stop", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the sample rate of a sound recorder
#/
#/ The sample rate defines the number of audio samples
#/ captured per second. The higher, the better the quality
#/ (for example, 44100 samples/sec is CD quality).
#/
#/ \param soundRecorder Sound recorder object
#/
#/ \return Sample rate, in samples per second
#/
#//////////////////////////////////////////////////////////
proc getSampleRate*(soundRecorder: PSoundRecorder): cuint{.
  cdecl, importc: "sfSoundRecorder_getSampleRate", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Check if the system supports audio capture
#/
#/ This function should always be called before using
#/ the audio capture features. If it returns false, then
#/ any attempt to use sfSoundRecorder will fail.
#/
#/ \return sfTrue if audio capture is supported, sfFalse otherwise
#/
#//////////////////////////////////////////////////////////
proc soundRecorderIsAvailable*(): bool {.
  cdecl, importc: "sfSoundRecorder_isAvailable", dynlib: Lib.}

#//////////////////////////////////////////////////////////
#/ \brief Create a new sound buffer recorder
#/
#/ \return A new sfSoundBufferRecorder object (NULL if failed)
#/
#//////////////////////////////////////////////////////////
proc newSoundBufferRecorder*(): PSoundBufferRecorder{.
  cdecl, importc: "sfSoundBufferRecorder_create", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Destroy a sound buffer recorder
#/
#/ \param soundBufferRecorder Sound buffer recorder to destroy
#/
#//////////////////////////////////////////////////////////
proc destroy*(soundBufferRecorder: PSoundBufferRecorder){.
  cdecl, importc: "sfSoundBufferRecorder_destroy", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Start the capture of a sound recorder recorder
#/
#/ The \a sampleRate parameter defines the number of audio samples
#/ captured per second. The higher, the better the quality
#/ (for example, 44100 samples/sec is CD quality).
#/ This function uses its own thread so that it doesn't block
#/ the rest of the program while the capture runs.
#/ Please note that only one capture can happen at the same time.
#/
#/ \param soundBufferRecorder Sound buffer recorder object
#/ \param sampleRate          Desired capture rate, in number of samples per second
#/
#//////////////////////////////////////////////////////////
proc start*(soundBufferRecorder: PSoundBufferRecorder; sampleRate: cuint){.
  cdecl, importc: "sfSoundBufferRecorder_start", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Stop the capture of a sound recorder
#/
#/ \param soundBufferRecorder Sound buffer recorder object
#/
#//////////////////////////////////////////////////////////
proc stop*(soundBufferRecorder: PSoundBufferRecorder){.
  cdecl, importc: "sfSoundBufferRecorder_stop", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the sample rate of a sound buffer recorder
#/
#/ The sample rate defines the number of audio samples
#/ captured per second. The higher, the better the quality
#/ (for example, 44100 samples/sec is CD quality).
#/
#/ \param soundBufferRecorder Sound buffer recorder object
#/
#/ \return Sample rate, in samples per second
#/
#//////////////////////////////////////////////////////////
proc getSampleRate*(soundBufferRecorder: PSoundBufferRecorder): cuint{.
  cdecl, importc: "sfSoundBufferRecorder_getSampleRate", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the sound buffer containing the captured audio data
#/
#/ The sound buffer is valid only after the capture has ended.
#/ This function provides a read-only access to the internal
#/ sound buffer, but it can be copied if you need to
#/ make any modification to it.
#/
#/ \param soundBufferRecorder Sound buffer recorder object
#/
#/ \return Read-only access to the sound buffer
#/
#//////////////////////////////////////////////////////////
proc getBuffer*(soundBufferRecorder: PSoundBufferRecorder): PSoundBuffer{.
  cdecl, importc: "sfSoundBufferRecorder_getBuffer", dynlib: Lib.}


#//////////////////////////////////////////////////////////
#/ \brief defines the data to fill by the OnGetData callback
#/
#//////////////////////////////////////////////////////////
type
  PSoundStreamChunk* = ptr TSoundStreamChunk
  TSoundStreamChunk*{.pure, final.} = object
    samples*: ptr int16   #/< Pointer to the audio samples
    sampleCount*: cuint     #/< Number of samples pointed by Samples

  TSoundStreamGetDataCallback* = proc (a2: PSoundStreamChunk;
      a3: pointer): bool{.cdecl.}
  #/< Type of the callback used to get a sound stream data
  TSoundStreamSeekCallback* = proc (a2: TTime; a3: pointer){.cdecl.}
  #/< Type of the callback used to seek in a sound stream
#//////////////////////////////////////////////////////////
#/ \brief Create a new sound stream
#/
#/ \param onGetData    Function called when the stream needs more data (can't be NULL)
#/ \param onSeek       Function called when the stream seeks (can't be NULL)
#/ \param channelCount Number of channels to use (1 = mono, 2 = stereo)
#/ \param sampleRate   Sample rate of the sound (44100 = CD quality)
#/ \param userData     Data to pass to the callback functions
#/
#/ \return A new sfSoundStream object
#/
#//////////////////////////////////////////////////////////
proc create*(onGetData: TSoundStreamGetDataCallback; onSeek: TSoundStreamSeekCallback;
              channelCount: cuint; sampleRate: cuint; userData: pointer): PSoundStream{.
  cdecl, importc: "sfSoundStream_create", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Destroy a sound stream
#/
#/ \param soundStream Sound stream to destroy
#/
#//////////////////////////////////////////////////////////
proc destroy*(soundStream: PSoundStream){.
  cdecl, importc: "sfSoundStream_destroy", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Start or resume playing a sound stream
#/
#/ This function starts the stream if it was stopped, resumes
#/ it if it was paused, and restarts it from beginning if it
#/ was it already playing.
#/ This function uses its own thread so that it doesn't block
#/ the rest of the program while the music is played.
#/
#/ \param soundStream Sound stream object
#/
#//////////////////////////////////////////////////////////
proc play*(soundStream: PSoundStream){.
  cdecl, importc: "sfSoundStream_play", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Pause a sound stream
#/
#/ This function pauses the stream if it was playing,
#/ otherwise (stream already paused or stopped) it has no effect.
#/
#/ \param soundStream Sound stream object
#/
#//////////////////////////////////////////////////////////
proc pause*(soundStream: PSoundStream){.
  cdecl, importc: "sfSoundStream_pause", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Stop playing a sound stream
#/
#/ This function stops the stream if it was playing or paused,
#/ and does nothing if it was already stopped.
#/ It also resets the playing position (unlike sfSoundStream_pause).
#/
#/ \param soundStream Sound stream object
#/
#//////////////////////////////////////////////////////////
proc stop*(soundStream: PSoundStream){.
  cdecl, importc: "sfSoundStream_stop", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the current status of a sound stream (stopped, paused, playing)
#/
#/ \param soundStream Sound stream object
#/
#/ \return Current status
#/
#//////////////////////////////////////////////////////////
proc getStatus*(soundStream: PSoundStream): TSoundStatus{.
  cdecl, importc: "sfSoundStream_getStatus", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Return the number of channels of a sound stream
#/
#/ 1 channel means a mono sound, 2 means stereo, etc.
#/
#/ \param soundStream Sound stream object
#/
#/ \return Number of channels
#/
#//////////////////////////////////////////////////////////
proc getChannelCount*(soundStream: PSoundStream): cuint{.
  cdecl, importc: "sfSoundStream_getChannelCount", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the sample rate of a sound stream
#/
#/ The sample rate is the number of audio samples played per
#/ second. The higher, the better the quality.
#/
#/ \param soundStream Sound stream object
#/
#/ \return Sample rate, in number of samples per second
#/
#//////////////////////////////////////////////////////////
proc getSampleRate*(soundStream: PSoundStream): cuint{.
  cdecl, importc: "sfSoundStream_getSampleRate", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the pitch of a sound stream
#/
#/ The pitch represents the perceived fundamental frequency
#/ of a sound; thus you can make a stream more acute or grave
#/ by changing its pitch. A side effect of changing the pitch
#/ is to modify the playing speed of the stream as well.
#/ The default value for the pitch is 1.
#/
#/ \param soundStream Sound stream object
#/ \param pitch       New pitch to apply to the stream
#/
#//////////////////////////////////////////////////////////
proc setPitch*(soundStream: PSoundStream; pitch: cfloat){.
  cdecl, importc: "sfSoundStream_setPitch", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the volume of a sound stream
#/
#/ The volume is a value between 0 (mute) and 100 (full volume).
#/ The default value for the volume is 100.
#/
#/ \param soundStream Sound stream object
#/ \param volume      Volume of the stream
#/
#//////////////////////////////////////////////////////////
proc setVolume*(soundStream: PSoundStream; volume: cfloat){.
  cdecl, importc: "sfSoundStream_setVolume", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the 3D position of a sound stream in the audio scene
#/
#/ Only streams with one channel (mono streams) can be
#/ spatialized.
#/ The default position of a stream is (0, 0, 0).
#/
#/ \param soundStream Sound stream object
#/ \param position    Position of the stream in the scene
#/
#//////////////////////////////////////////////////////////
proc setPosition*(soundStream: PSoundStream; position: TVector3f){.
  cdecl, importc: "sfSoundStream_setPosition", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Make a sound stream's position relative to the listener or absolute
#/
#/ Making a stream relative to the listener will ensure that it will always
#/ be played the same way regardless the position of the listener.
#/ This can be useful for non-spatialized streams, streams that are
#/ produced by the listener, or streams attached to it.
#/ The default value is false (position is absolute).
#/
#/ \param soundStream Sound stream object
#/ \param relative    sfTrue to set the position relative, sfFalse to set it absolute
#/
#//////////////////////////////////////////////////////////
proc setRelativeToListener*(soundStream: PSoundStream; relative: bool){.
  cdecl, importc: "sfSoundStream_setRelativeToListener", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the minimum distance of a sound stream
#/
#/ The "minimum distance" of a stream is the maximum
#/ distance at which it is heard at its maximum volume. Further
#/ than the minimum distance, it will start to fade out according
#/ to its attenuation factor. A value of 0 ("inside the head
#/ of the listener") is an invalid value and is forbidden.
#/ The default value of the minimum distance is 1.
#/
#/ \param soundStream Sound stream object
#/ \param distance    New minimum distance of the stream
#/
#//////////////////////////////////////////////////////////
proc setMinDistance*(soundStream: PSoundStream; distance: cfloat){.
  cdecl, importc: "sfSoundStream_setMinDistance", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set the attenuation factor of a sound stream
#/
#/ The attenuation is a multiplicative factor which makes
#/ the stream more or less loud according to its distance
#/ from the listener. An attenuation of 0 will produce a
#/ non-attenuated stream, i.e. its volume will always be the same
#/ whether it is heard from near or from far. On the other hand,
#/ an attenuation value such as 100 will make the stream fade out
#/ very quickly as it gets further from the listener.
#/ The default value of the attenuation is 1.
#/
#/ \param soundStream Sound stream object
#/ \param attenuation New attenuation factor of the stream
#/
#//////////////////////////////////////////////////////////
proc setAttenuation*(soundStream: PSoundStream; attenuation: cfloat){.
  cdecl, importc: "sfSoundStream_setAttenuation", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Change the current playing position of a sound stream
#/
#/ The playing position can be changed when the stream is
#/ either paused or playing.
#/
#/ \param soundStream Sound stream object
#/ \param timeOffset  New playing position
#/
#//////////////////////////////////////////////////////////
proc setPlayingOffset*(soundStream: PSoundStream; timeOffset: TTime){.
  cdecl, importc: "sfSoundStream_setPlayingOffset", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Set whether or not a sound stream should loop after reaching the end
#/
#/ If set, the stream will restart from beginning after
#/ reaching the end and so on, until it is stopped or
#/ sfSoundStream_setLoop(stream, sfFalse) is called.
#/ The default looping state for sound streams is false.
#/
#/ \param soundStream Sound stream object
#/ \param loop        sfTrue to play in loop, sfFalse to play once
#/
#//////////////////////////////////////////////////////////
proc setLoop*(soundStream: PSoundStream; loop: bool){.
  cdecl, importc: "sfSoundStream_setLoop", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the pitch of a sound stream
#/
#/ \param soundStream Sound stream object
#/
#/ \return Pitch of the stream
#/
#//////////////////////////////////////////////////////////
proc getPitch*(soundStream: PSoundStream): cfloat{.
  cdecl, importc: "sfSoundStream_getPitch", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the volume of a sound stream
#/
#/ \param soundStream Sound stream object
#/
#/ \return Volume of the stream, in the range [0, 100]
#/
#//////////////////////////////////////////////////////////
proc getVolume*(soundStream: PSoundStream): cfloat{.
  cdecl, importc: "sfSoundStream_getVolume", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the 3D position of a sound stream in the audio scene
#/
#/ \param soundStream Sound stream object
#/
#/ \return Position of the stream in the world
#/
#//////////////////////////////////////////////////////////
proc getPosition*(soundStream: PSoundStream): TVector3f{.
  cdecl, importc: "sfSoundStream_getPosition", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Tell whether a sound stream's position is relative to the
#/        listener or is absolute
#/
#/ \param soundStream Sound stream object
#/
#/ \return sfTrue if the position is relative, sfFalse if it's absolute
#/
#//////////////////////////////////////////////////////////
proc isRelativeToListener*(soundStream: PSoundStream): bool{.
  cdecl, importc: "sfSoundStream_isRelativeToListener", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the minimum distance of a sound stream
#/
#/ \param soundStream Sound stream object
#/
#/ \return Minimum distance of the stream
#/
#//////////////////////////////////////////////////////////
proc getMinDistance*(soundStream: PSoundStream): cfloat{.
  cdecl, importc: "sfSoundStream_getMinDistance", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the attenuation factor of a sound stream
#/
#/ \param soundStream Sound stream object
#/
#/ \return Attenuation factor of the stream
#/
#//////////////////////////////////////////////////////////
proc getAttenuation*(soundStream: PSoundStream): cfloat{.
  cdecl, importc: "sfSoundStream_getAttenuation", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Tell whether or not a sound stream is in loop mode
#/
#/ \param soundStream Sound stream object
#/
#/ \return sfTrue if the music is looping, sfFalse otherwise
#/
#//////////////////////////////////////////////////////////
proc getLoop*(soundStream: PSoundStream): bool{.
  cdecl, importc: "sfSoundStream_getLoop", dynlib: Lib.}
#//////////////////////////////////////////////////////////
#/ \brief Get the current playing position of a sound stream
#/
#/ \param soundStream Sound stream object
#/
#/ \return Current playing position
#/
#//////////////////////////////////////////////////////////
proc getPlayingOffset*(soundStream: PSoundStream): TTime{.
  cdecl, importc: "sfSoundStream_getPlayingOffset", dynlib: Lib.}
