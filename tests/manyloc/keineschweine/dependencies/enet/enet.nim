discard """Copyright (c) 2002-2012 Lee Salzman

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

const Lib = "libenet.so.1(|.0.3)"

const
  ENET_VERSION_MAJOR* = 1
  ENET_VERSION_MINOR* = 3
  ENET_VERSION_PATCH* = 3
template ENET_VERSION_CREATE(major, minor, patch: untyped): untyped =
  (((major) shl 16) or ((minor) shl 8) or (patch))

const
  ENET_VERSION* = ENET_VERSION_CREATE(ENET_VERSION_MAJOR, ENET_VERSION_MINOR,
                                      ENET_VERSION_PATCH)
type
  TVersion* = cuint
  TSocketType*{.size: sizeof(cint).} = enum
    ENET_SOCKET_TYPE_STREAM = 1, ENET_SOCKET_TYPE_DATAGRAM = 2
  TSocketWait*{.size: sizeof(cint).} = enum
    ENET_SOCKET_WAIT_NONE = 0, ENET_SOCKET_WAIT_SEND = (1 shl 0),
    ENET_SOCKET_WAIT_RECEIVE = (1 shl 1)
  TSocketOption*{.size: sizeof(cint).} = enum
    ENET_SOCKOPT_NONBLOCK = 1, ENET_SOCKOPT_BROADCAST = 2,
    ENET_SOCKOPT_RCVBUF = 3, ENET_SOCKOPT_SNDBUF = 4,
    ENET_SOCKOPT_REUSEADDR = 5
const
  ENET_HOST_ANY* = 0
  ENET_HOST_BROADCAST* = 0xFFFFFFFF
  ENET_PORT_ANY* = 0

  ENET_PROTOCOL_MINIMUM_MTU* = 576
  ENET_PROTOCOL_MAXIMUM_MTU* = 4096
  ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS* = 32
  ENET_PROTOCOL_MINIMUM_WINDOW_SIZE* = 4096
  ENET_PROTOCOL_MAXIMUM_WINDOW_SIZE* = 32768
  ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT* = 1
  ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT* = 255
  ENET_PROTOCOL_MAXIMUM_PEER_ID* = 0x00000FFF
type
  PAddress* = ptr TAddress
  TAddress*{.pure, final.} = object
    host*: cuint
    port*: cushort

  TPacketFlag*{.size: sizeof(cint).} = enum
    FlagReliable = (1 shl 0),
    FlagUnsequenced = (1 shl 1),
    NoAllocate = (1 shl 2),
    UnreliableFragment = (1 shl 3)

  TENetListNode*{.pure, final.} = object
      next*: ptr T_ENetListNode
      previous*: ptr T_ENetListNode

  PENetListIterator* = ptr TENetListNode
  TENetList*{.pure, final.} = object
    sentinel*: TENetListNode

  T_ENetPacket*{.pure, final.} = object
  TPacketFreeCallback* = proc (a2: ptr T_ENetPacket){.cdecl.}

  PPacket* = ptr TPacket
  TPacket*{.pure, final.} = object
    referenceCount: csize_t
    flags*: cint
    data*: cstring#ptr cuchar
    dataLength*: csize_t
    freeCallback*: TPacketFreeCallback

  PAcknowledgement* = ptr TAcknowledgement
  TAcknowledgement*{.pure, final.} = object
    acknowledgementList*: TEnetListNode
    sentTime*: cuint
    command*: TEnetProtocol

  POutgoingCommand* = ptr TOutgoingCommand
  TOutgoingCommand*{.pure, final.} = object
    outgoingCommandList*: TEnetListNode
    reliableSequenceNumber*: cushort
    unreliableSequenceNumber*: cushort
    sentTime*: cuint
    roundTripTimeout*: cuint
    roundTripTimeoutLimit*: cuint
    fragmentOffset*: cuint
    fragmentLength*: cushort
    sendAttempts*: cushort
    command*: TEnetProtocol
    packet*: PPacket

  PIncomingCommand* = ptr TIncomingCommand
  TIncomingCommand*{.pure, final.} = object
    incomingCommandList*: TEnetListNode
    reliableSequenceNumber*: cushort
    unreliableSequenceNumber*: cushort
    command*: TEnetProtocol
    fragmentCount*: cuint
    fragmentsRemaining*: cuint
    fragments*: ptr cuint
    packet*: ptr TPacket

  TPeerState*{.size: sizeof(cint).} = enum
    ENET_PEER_STATE_DISCONNECTED = 0, ENET_PEER_STATE_CONNECTING = 1,
    ENET_PEER_STATE_ACKNOWLEDGING_CONNECT = 2,
    ENET_PEER_STATE_CONNECTION_PENDING = 3,
    ENET_PEER_STATE_CONNECTION_SUCCEEDED = 4, ENET_PEER_STATE_CONNECTED = 5,
    ENET_PEER_STATE_DISCONNECT_LATER = 6, ENET_PEER_STATE_DISCONNECTING = 7,
    ENET_PEER_STATE_ACKNOWLEDGING_DISCONNECT = 8, ENET_PEER_STATE_ZOMBIE = 9

  TENetProtocolCommand*{.size: sizeof(cint).} = enum
    ENET_PROTOCOL_COMMAND_NONE = 0, ENET_PROTOCOL_COMMAND_ACKNOWLEDGE = 1,
    ENET_PROTOCOL_COMMAND_CONNECT = 2,
    ENET_PROTOCOL_COMMAND_VERIFY_CONNECT = 3,
    ENET_PROTOCOL_COMMAND_DISCONNECT = 4, ENET_PROTOCOL_COMMAND_PING = 5,
    ENET_PROTOCOL_COMMAND_SEND_RELIABLE = 6,
    ENET_PROTOCOL_COMMAND_SEND_UNRELIABLE = 7,
    ENET_PROTOCOL_COMMAND_SEND_FRAGMENT = 8,
    ENET_PROTOCOL_COMMAND_SEND_UNSEQUENCED = 9,
    ENET_PROTOCOL_COMMAND_BANDWIDTH_LIMIT = 10,
    ENET_PROTOCOL_COMMAND_THROTTLE_CONFIGURE = 11,
    ENET_PROTOCOL_COMMAND_SEND_UNRELIABLE_FRAGMENT = 12,
    ENET_PROTOCOL_COMMAND_COUNT = 13, ENET_PROTOCOL_COMMAND_MASK = 0x0000000F
  TENetProtocolFlag*{.size: sizeof(cint).} = enum
    ENET_PROTOCOL_HEADER_SESSION_SHIFT = 12,
    ENET_PROTOCOL_COMMAND_FLAG_UNSEQUENCED = (1 shl 6),
    ENET_PROTOCOL_COMMAND_FLAG_ACKNOWLEDGE = (1 shl 7),
    ENET_PROTOCOL_HEADER_SESSION_MASK = (3 shl 12),
    ENET_PROTOCOL_HEADER_FLAG_COMPRESSED = (1 shl 14),
    ENET_PROTOCOL_HEADER_FLAG_SENT_TIME = (1 shl 15),
    ENET_PROTOCOL_HEADER_FLAG_MASK = ENET_PROTOCOL_HEADER_FLAG_COMPRESSED.cint or
        ENET_PROTOCOL_HEADER_FLAG_SENT_TIME.cint

  TENetProtocolHeader*{.pure, final.} = object
    peerID*: cushort
    sentTime*: cushort

  TENetProtocolCommandHeader*{.pure, final.} = object
    command*: cuchar
    channelID*: cuchar
    reliableSequenceNumber*: cushort

  TENetProtocolAcknowledge*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    receivedReliableSequenceNumber*: cushort
    receivedSentTime*: cushort

  TENetProtocolConnect*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    outgoingPeerID*: cushort
    incomingSessionID*: cuchar
    outgoingSessionID*: cuchar
    mtu*: cuint
    windowSize*: cuint
    channelCount*: cuint
    incomingBandwidth*: cuint
    outgoingBandwidth*: cuint
    packetThrottleInterval*: cuint
    packetThrottleAcceleration*: cuint
    packetThrottleDeceleration*: cuint
    connectID*: cuint
    data*: cuint

  TENetProtocolVerifyConnect*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    outgoingPeerID*: cushort
    incomingSessionID*: cuchar
    outgoingSessionID*: cuchar
    mtu*: cuint
    windowSize*: cuint
    channelCount*: cuint
    incomingBandwidth*: cuint
    outgoingBandwidth*: cuint
    packetThrottleInterval*: cuint
    packetThrottleAcceleration*: cuint
    packetThrottleDeceleration*: cuint
    connectID*: cuint

  TENetProtocolBandwidthLimit*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    incomingBandwidth*: cuint
    outgoingBandwidth*: cuint

  TENetProtocolThrottleConfigure*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    packetThrottleInterval*: cuint
    packetThrottleAcceleration*: cuint
    packetThrottleDeceleration*: cuint

  TENetProtocolDisconnect*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    data*: cuint

  TENetProtocolPing*{.pure, final.} = object
    header*: TENetProtocolCommandHeader

  TENetProtocolSendReliable*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    dataLength*: cushort

  TENetProtocolSendUnreliable*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    unreliableSequenceNumber*: cushort
    dataLength*: cushort

  TENetProtocolSendUnsequenced*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    unsequencedGroup*: cushort
    dataLength*: cushort

  TENetProtocolSendFragment*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
    startSequenceNumber*: cushort
    dataLength*: cushort
    fragmentCount*: cuint
    fragmentNumber*: cuint
    totalLength*: cuint
    fragmentOffset*: cuint

  ## this is incomplete; need helper templates or something
  ## ENetProtocol
  TENetProtocol*{.pure, final.} = object
    header*: TENetProtocolCommandHeader
const
  ENET_BUFFER_MAXIMUM* = (1 + 2 * ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS)
  ENET_HOST_RECEIVE_BUFFER_SIZE          = 256 * 1024
  ENET_HOST_SEND_BUFFER_SIZE             = 256 * 1024
  ENET_HOST_BANDWIDTH_THROTTLE_INTERVAL  = 1000
  ENET_HOST_DEFAULT_MTU                  = 1400

  ENET_PEER_DEFAULT_ROUND_TRIP_TIME      = 500
  ENET_PEER_DEFAULT_PACKET_THROTTLE      = 32
  ENET_PEER_PACKET_THROTTLE_SCALE        = 32
  ENET_PEER_PACKET_THROTTLE_COUNTER      = 7
  ENET_PEER_PACKET_THROTTLE_ACCELERATION = 2
  ENET_PEER_PACKET_THROTTLE_DECELERATION = 2
  ENET_PEER_PACKET_THROTTLE_INTERVAL     = 5000
  ENET_PEER_PACKET_LOSS_SCALE            = (1 shl 16)
  ENET_PEER_PACKET_LOSS_INTERVAL         = 10000
  ENET_PEER_WINDOW_SIZE_SCALE            = 64 * 1024
  ENET_PEER_TIMEOUT_LIMIT                = 32
  ENET_PEER_TIMEOUT_MINIMUM              = 5000
  ENET_PEER_TIMEOUT_MAXIMUM              = 30000
  ENET_PEER_PING_INTERVAL                = 500
  ENET_PEER_UNSEQUENCED_WINDOWS          = 64
  ENET_PEER_UNSEQUENCED_WINDOW_SIZE      = 1024
  ENET_PEER_FREE_UNSEQUENCED_WINDOWS     = 32
  ENET_PEER_RELIABLE_WINDOWS             = 16
  ENET_PEER_RELIABLE_WINDOW_SIZE         = 0x1000
  ENET_PEER_FREE_RELIABLE_WINDOWS        = 8

when defined(linux) or true:
  import posix
  const
    ENET_SOCKET_NULL*: cint = -1
  type
    TENetSocket* = cint
    PEnetBuffer* = ptr object
    TENetBuffer*{.pure, final.} = object
      data*: pointer
      dataLength*: csize_t
    TENetSocketSet* = Tfd_set
  ## see if these are different on win32, if not then get rid of these
  template ENET_HOST_TO_NET_16*(value: untyped): untyped =
    (htons(value))
  template ENET_HOST_TO_NET_32*(value: untyped): untyped =
    (htonl(value))
  template ENET_NET_TO_HOST_16*(value: untyped): untyped =
    (ntohs(value))
  template ENET_NET_TO_HOST_32*(value: untyped): untyped =
    (ntohl(value))

  template ENET_SOCKETSET_EMPTY*(sockset: untyped): untyped =
    FD_ZERO(addr((sockset)))
  template ENET_SOCKETSET_ADD*(sockset, socket: untyped): untyped =
    FD_SET(socket, addr((sockset)))
  template ENET_SOCKETSET_REMOVE*(sockset, socket: untyped): untyped =
    FD_CLEAR(socket, addr((sockset)))
  template ENET_SOCKETSET_CHECK*(sockset, socket: untyped): untyped =
    FD_ISSET(socket, addr((sockset)))

when defined(windows):
  ## put the content of win32.h in here


type
  PChannel* = ptr TChannel
  TChannel*{.pure, final.} = object
    outgoingReliableSequenceNumber*: cushort
    outgoingUnreliableSequenceNumber*: cushort
    usedReliableWindows*: cushort
    reliableWindows*: array[0..ENET_PEER_RELIABLE_WINDOWS - 1, cushort]
    incomingReliableSequenceNumber*: cushort
    incomingUnreliableSequenceNumber*: cushort
    incomingReliableCommands*: TENetList
    incomingUnreliableCommands*: TENetList

  PPeer* = ptr TPeer
  TPeer*{.pure, final.} = object
    dispatchList*: TEnetListNode
    host*: ptr THost
    outgoingPeerID*: cushort
    incomingPeerID*: cushort
    connectID*: cuint
    outgoingSessionID*: cuchar
    incomingSessionID*: cuchar
    address*: TAddress
    data*: pointer
    state*: TPeerState
    channels*: PChannel
    channelCount*: csize_t
    incomingBandwidth*: cuint
    outgoingBandwidth*: cuint
    incomingBandwidthThrottleEpoch*: cuint
    outgoingBandwidthThrottleEpoch*: cuint
    incomingDataTotal*: cuint
    outgoingDataTotal*: cuint
    lastSendTime*: cuint
    lastReceiveTime*: cuint
    nextTimeout*: cuint
    earliestTimeout*: cuint
    packetLossEpoch*: cuint
    packetsSent*: cuint
    packetsLost*: cuint
    packetLoss*: cuint
    packetLossVariance*: cuint
    packetThrottle*: cuint
    packetThrottleLimit*: cuint
    packetThrottleCounter*: cuint
    packetThrottleEpoch*: cuint
    packetThrottleAcceleration*: cuint
    packetThrottleDeceleration*: cuint
    packetThrottleInterval*: cuint
    lastRoundTripTime*: cuint
    lowestRoundTripTime*: cuint
    lastRoundTripTimeVariance*: cuint
    highestRoundTripTimeVariance*: cuint
    roundTripTime*: cuint
    roundTripTimeVariance*: cuint
    mtu*: cuint
    windowSize*: cuint
    reliableDataInTransit*: cuint
    outgoingReliableSequenceNumber*: cushort
    acknowledgements*: TENetList
    sentReliableCommands*: TENetList
    sentUnreliableCommands*: TENetList
    outgoingReliableCommands*: TENetList
    outgoingUnreliableCommands*: TENetList
    dispatchedCommands*: TENetList
    needsDispatch*: cint
    incomingUnsequencedGroup*: cushort
    outgoingUnsequencedGroup*: cushort
    unsequencedWindow*: array[0..ENET_PEER_UNSEQUENCED_WINDOW_SIZE div 32 - 1,
                              cuint]
    eventData*: cuint

  PCompressor* = ptr TCompressor
  TCompressor*{.pure, final.} = object
    context*: pointer
    compress*: proc (context: pointer; inBuffers: ptr TEnetBuffer;
                     inBufferCount: csize_t; inLimit: csize_t;
                     outData: ptr cuchar; outLimit: csize_t): csize_t{.cdecl.}
    decompress*: proc (context: pointer; inData: ptr cuchar; inLimit: csize_t;
                       outData: ptr cuchar; outLimit: csize_t): csize_t{.cdecl.}
    destroy*: proc (context: pointer){.cdecl.}

  TChecksumCallback* = proc (buffers: ptr TEnetBuffer; bufferCount: csize_t): cuint{.
      cdecl.}

  PHost* = ptr THost
  THost*{.pure, final.} = object
    socket*: TEnetSocket
    address*: TAddress
    incomingBandwidth*: cuint
    outgoingBandwidth*: cuint
    bandwidthThrottleEpoch*: cuint
    mtu*: cuint
    randomSeed*: cuint
    recalculateBandwidthLimits*: cint
    peers*: ptr TPeer
    peerCount*: csize_t
    channelLimit*: csize_t
    serviceTime*: cuint
    dispatchQueue*: TEnetList
    continueSending*: cint
    packetSize*: csize_t
    headerFlags*: cushort
    commands*: array[0..ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS - 1,
                     TEnetProtocol]
    commandCount*: csize_t
    buffers*: array[0..ENET_BUFFER_MAXIMUM - 1, TEnetBuffer]
    bufferCount*: csize_t
    checksum*: TChecksumCallback
    compressor*: TCompressor
    packetData*: array[0..ENET_PROTOCOL_MAXIMUM_MTU - 1,
                       array[0..2 - 1, cuchar]]
    receivedAddress*: TAddress
    receivedData*: ptr cuchar
    receivedDataLength*: csize_t
    totalSentData*: cuint
    totalSentPackets*: cuint
    totalReceivedData*: cuint
    totalReceivedPackets*: cuint

  TEventType*{.size: sizeof(cint).} = enum
    EvtNone = 0, EvtConnect = 1,
    EvtDisconnect = 2, EvtReceive = 3
  PEvent* = ptr TEvent
  TEvent*{.pure, final.} = object
    kind*: TEventType
    peer*: ptr TPeer
    channelID*: cuchar
    data*: cuint
    packet*: ptr TPacket

  TENetCallbacks*{.pure, final.} = object
    malloc*: proc (size: csize_t): pointer{.cdecl.}
    free*: proc (memory: pointer){.cdecl.}
    no_memory*: proc (){.cdecl.}

{.push callConv:cdecl.}
proc enet_malloc*(a2: csize_t): pointer{.
  importc: "enet_malloc", dynlib: Lib.}
proc enet_free*(a2: pointer){.
  importc: "enet_free", dynlib: Lib.}

proc enetInit*(): cint{.
  importc: "enet_initialize", dynlib: Lib.}
proc enetInit*(version: TVersion; inits: ptr TENetCallbacks): cint{.
  importc: "enet_initialize_with_callbacks", dynlib: Lib.}
proc enetDeinit*(){.
  importc: "enet_deinitialize", dynlib: Lib.}
proc enet_time_get*(): cuint{.
  importc: "enet_time_get", dynlib: Lib.}
proc enet_time_set*(a2: cuint){.
  importc: "enet_time_set", dynlib: Lib.}

#enet docs are pretty lacking, i'm not sure what the names of these arguments should be
proc createSocket*(kind: TSocketType): TEnetSocket{.
  importc: "enet_socket_create", dynlib: Lib.}
proc bindTo*(socket: TEnetSocket; address: var TAddress): cint{.
  importc: "enet_socket_bind", dynlib: Lib.}
proc bindTo*(socket: TEnetSocket; address: ptr TAddress): cint{.
  importc: "enet_socket_bind", dynlib: Lib.}
proc listen*(socket: TEnetSocket; a3: cint): cint{.
  importc: "enet_socket_listen", dynlib: Lib.}
proc accept*(socket: TEnetSocket; address: var TAddress): TEnetSocket{.
  importc: "enet_socket_accept", dynlib: Lib.}
proc accept*(socket: TEnetSocket; address: ptr TAddress): TEnetSocket{.
  importc: "enet_socket_accept", dynlib: Lib.}
proc connect*(socket: TEnetSocket; address: var TAddress): cint{.
  importc: "enet_socket_connect", dynlib: Lib.}
proc connect*(socket: TEnetSocket; address: ptr TAddress): cint{.
  importc: "enet_socket_connect", dynlib: Lib.}
proc send*(socket: TEnetSocket; address: var TAddress; buffer: ptr TEnetBuffer; size: csize_t): cint{.
  importc: "enet_socket_send", dynlib: Lib.}
proc send*(socket: TEnetSocket; address: ptr TAddress; buffer: ptr TEnetBuffer; size: csize_t): cint{.
  importc: "enet_socket_send", dynlib: Lib.}
proc receive*(socket: TEnetSocket; address: var TAddress;
               buffer: ptr TEnetBuffer; size: csize_t): cint{.
  importc: "enet_socket_receive", dynlib: Lib.}
proc receive*(socket: TEnetSocket; address: ptr TAddress;
               buffer: ptr TEnetBuffer; size: csize_t): cint{.
  importc: "enet_socket_receive", dynlib: Lib.}
proc wait*(socket: TEnetSocket; a3: ptr cuint; a4: cuint): cint{.
  importc: "enet_socket_wait", dynlib: Lib.}
proc setOption*(socket: TEnetSocket; a3: TSocketOption; a4: cint): cint{.
  importc: "enet_socket_set_option", dynlib: Lib.}
proc destroy*(socket: TEnetSocket){.
  importc: "enet_socket_destroy", dynlib: Lib.}
proc select*(socket: TEnetSocket; a3: ptr TENetSocketSet;
              a4: ptr TENetSocketSet; a5: cuint): cint{.
  importc: "enet_socketset_select", dynlib: Lib.}

proc setHost*(address: PAddress; hostName: cstring): cint{.
  importc: "enet_address_set_host", dynlib: Lib.}
proc setHost*(address: var TAddress; hostName: cstring): cint{.
  importc: "enet_address_set_host", dynlib: Lib.}
proc getHostIP*(address: var TAddress; hostName: cstring; nameLength: csize_t): cint{.
  importc: "enet_address_get_host_ip", dynlib: Lib.}
proc getHost*(address: var TAddress; hostName: cstring; nameLength: csize_t): cint{.
  importc: "enet_address_get_host", dynlib: Lib.}

## Call the above two funcs but trim the result string
proc getHostIP*(address: var TAddress; hostName: var string; nameLength: csize_t): cint{.inline.} =
  hostName.setLen nameLength
  result = getHostIP(address, cstring(hostName), nameLength)
  if result == 0:
    hostName.setLen(len(cstring(hostName)))
proc getHost*(address: var TAddress; hostName: var string; nameLength: csize_t): cint{.inline.} =
  hostName.setLen nameLength
  result = getHost(address, cstring(hostName), nameLength)
  if result == 0:
    hostName.setLen(len(cstring(hostName)))

proc createPacket*(data: pointer; len: csize_t; flag: TPacketFlag): PPacket{.
  importc: "enet_packet_create", dynlib: Lib.}
proc destroy*(packet: PPacket){.
  importc: "enet_packet_destroy", dynlib: Lib.}
proc resize*(packet: PPacket; dataLength: csize_t): cint{.
  importc: "enet_packet_resize", dynlib: Lib.}

proc crc32*(buffers: ptr TEnetBuffer; bufferCount: csize_t): cuint{.
  importc: "enet_crc32", dynlib: Lib.}

proc createHost*(address: ptr TAddress; maxConnections, maxChannels: csize_t; downSpeed, upSpeed: cuint): PHost{.
  importc: "enet_host_create", dynlib: Lib.}
proc createHost*(address: var TAddress; maxConnections, maxChannels: csize_t; downSpeed, upSpeed: cuint): PHost{.
  importc: "enet_host_create", dynlib: Lib.}
proc destroy*(host: PHost){.
  importc: "enet_host_destroy", dynlib: Lib.}
proc connect*(host: PHost; address: ptr TAddress; channelCount: csize_t; data: cuint): PPeer{.
  importc: "enet_host_connect", dynlib: Lib.}
proc connect*(host: PHost; address: var TAddress; channelCount: csize_t; data: cuint): PPeer{.
  importc: "enet_host_connect", dynlib: Lib.}

proc checkEvents*(host: PHost; event: var TEvent): cint{.
  importc: "enet_host_check_events", dynlib: Lib.}
proc checkEvents*(host: PHost; event: ptr TEvent): cint{.
  importc: "enet_host_check_events", dynlib: Lib.}
proc hostService*(host: PHost; event: var TEvent; timeout: cuint): cint{.
  importc: "enet_host_service", dynlib: Lib.}
proc hostService*(host: PHost; event: ptr TEvent; timeout: cuint): cint{.
  importc: "enet_host_service", dynlib: Lib.}
proc flush*(host: PHost){.
  importc: "enet_host_flush", dynlib: Lib.}
proc broadcast*(host: PHost; channelID: cuchar; packet: PPacket){.
  importc: "enet_host_broadcast", dynlib: Lib.}
proc compress*(host: PHost; compressor: PCompressor){.
  importc: "enet_host_compress", dynlib: Lib.}
proc compressWithRangeCoder*(host: PHost): cint{.
  importc: "enet_host_compress_with_range_coder", dynlib: Lib.}
proc channelLimit*(host: PHost; channelLimit: csize_t){.
  importc: "enet_host_channel_limit", dynlib: Lib.}
proc bandwidthLimit*(host: PHost; incoming, outgoing: cuint){.
  importc: "enet_host_bandwidth_limit", dynlib: Lib.}
proc bandwidthThrottle*(host: PHost){.
  importc: "enet_host_bandwidth_throttle", dynlib: Lib.}


proc send*(peer: PPeer; channel: cuchar; packet: PPacket): cint{.
  importc: "enet_peer_send", dynlib: Lib.}
proc receive*(peer: PPeer; channelID: ptr cuchar): PPacket{.
  importc: "enet_peer_receive", dynlib: Lib.}
proc ping*(peer: PPeer){.
  importc: "enet_peer_ping", dynlib: Lib.}
proc reset*(peer: PPeer){.
  importc: "enet_peer_reset", dynlib: Lib.}
proc disconnect*(peer: PPeer; a3: cuint){.
  importc: "enet_peer_disconnect", dynlib: Lib.}
proc disconnectNow*(peer: PPeer; a3: cuint){.
  importc: "enet_peer_disconnect_now", dynlib: Lib.}
proc disconnectLater*(peer: PPeer; a3: cuint){.
  importc: "enet_peer_disconnect_later", dynlib: Lib.}
proc throttleConfigure*(peer: PPeer; interval, acceleration, deceleration: cuint){.
  importc: "enet_peer_throttle_configure", dynlib: Lib.}
proc throttle*(peer: PPeer; rtt: cuint): cint{.
  importc: "enet_peer_throttle", dynlib: Lib.}
proc resetQueues*(peer: PPeer){.
  importc: "enet_peer_reset_queues", dynlib: Lib.}
proc setupOutgoingCommand*(peer: PPeer; outgoingCommand: POutgoingCommand){.
  importc: "enet_peer_setup_outgoing_command", dynlib: Lib.}

proc queueOutgoingCommand*(peer: PPeer; command: ptr TEnetProtocol;
          packet: PPacket; offset: cuint; length: cushort): POutgoingCommand{.
  importc: "enet_peer_queue_outgoing_command", dynlib: Lib.}
proc queueIncomingCommand*(peer: PPeer; command: ptr TEnetProtocol;
                    packet: PPacket; fragmentCount: cuint): PIncomingCommand{.
  importc: "enet_peer_queue_incoming_command", dynlib: Lib.}
proc queueAcknowledgement*(peer: PPeer; command: ptr TEnetProtocol;
                            sentTime: cushort): PAcknowledgement{.
  importc: "enet_peer_queue_acknowledgement", dynlib: Lib.}
proc dispatchIncomingUnreliableCommands*(peer: PPeer; channel: PChannel){.
  importc: "enet_peer_dispatch_incoming_unreliable_commands", dynlib: Lib.}
proc dispatchIncomingReliableCommands*(peer: PPeer; channel: PChannel){.
  importc: "enet_peer_dispatch_incoming_reliable_commands", dynlib: Lib.}

proc createRangeCoder*(): pointer{.
  importc: "enet_range_coder_create", dynlib: Lib.}
proc rangeCoderDestroy*(context: pointer){.
  importc: "enet_range_coder_destroy", dynlib: Lib.}
proc rangeCoderCompress*(context: pointer; inBuffers: PEnetBuffer; inLimit,
               bufferCount: csize_t; outData: cstring; outLimit: csize_t): csize_t{.
  importc: "enet_range_coder_compress", dynlib: Lib.}
proc rangeCoderDecompress*(context: pointer; inData: cstring; inLimit: csize_t;
                            outData: cstring; outLimit: csize_t): csize_t{.
  importc: "enet_range_coder_decompress", dynlib: Lib.}
proc protocolCommandSize*(commandNumber: cuchar): csize_t{.
  importc: "enet_protocol_command_size", dynlib: Lib.}

{.pop.}

from hashes import `!$`, `!&`, Hash, hash
proc hash*(x: TAddress): Hash {.nimcall, noSideEffect.} =
  result = !$(hash(x.host.int32) !& hash(x.port.int16))
