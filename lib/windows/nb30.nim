#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
#       NetBIOS 3.0 interface unit

# This module contains the definitions for portable NetBIOS 3.0 support.

{.deadCodeElim: on.}

import                        # Data structure templates
  Windows

const
  NCBNAMSZ* = 16              # absolute length of a net name
  MAX_LANA* = 254             # lana's in range 0 to MAX_LANA inclusive

type                          # Network Control Block
  PNCB* = ptr TNCB
  TNCBPostProc* = proc (P: PNCB) {.stdcall.}
  TNCB* {.final.} = object # Structure returned to the NCB command NCBASTAT is ADAPTER_STATUS followed
                           # by an array of NAME_BUFFER structures.
    ncb_command*: Char        # command code
    ncb_retcode*: Char        # return code
    ncb_lsn*: Char            # local session number
    ncb_num*: Char            # number of our network name
    ncb_buffer*: cstring      # address of message buffer
    ncb_length*: int16        # size of message buffer
    ncb_callname*: array[0..NCBNAMSZ - 1, char] # blank-padded name of remote
    ncb_name*: array[0..NCBNAMSZ - 1, char] # our blank-padded netname
    ncb_rto*: Char            # rcv timeout/retry count
    ncb_sto*: Char            # send timeout/sys timeout
    ncb_post*: TNCBPostProc   # POST routine address
    ncb_lana_num*: Char       # lana (adapter) number
    ncb_cmd_cplt*: Char       # 0xff => commmand pending
    ncb_reserve*: array[0..9, Char] # reserved, used by BIOS
    ncb_event*: THandle       # HANDLE to Win32 event which
                              # will be set to the signalled
                              # state when an ASYNCH command
                              # completes

  PAdapterStatus* = ptr TAdapterStatus
  TAdapterStatus* {.final.} = object
    adapter_address*: array[0..5, Char]
    rev_major*: Char
    reserved0*: Char
    adapter_type*: Char
    rev_minor*: Char
    duration*: int16
    frmr_recv*: int16
    frmr_xmit*: int16
    iframe_recv_err*: int16
    xmit_aborts*: int16
    xmit_success*: DWORD
    recv_success*: DWORD
    iframe_xmit_err*: int16
    recv_buff_unavail*: int16
    t1_timeouts*: int16
    ti_timeouts*: int16
    reserved1*: DWORD
    free_ncbs*: int16
    max_cfg_ncbs*: int16
    max_ncbs*: int16
    xmit_buf_unavail*: int16
    max_dgram_size*: int16
    pending_sess*: int16
    max_cfg_sess*: int16
    max_sess*: int16
    max_sess_pkt_size*: int16
    name_count*: int16

  PNameBuffer* = ptr TNameBuffer
  TNameBuffer* {.final.} = object
    name*: array[0..NCBNAMSZ - 1, Char]
    name_num*: Char
    name_flags*: Char


const                         # values for name_flags bits.
  NAME_FLAGS_MASK* = 0x00000087
  GROUP_NAME* = 0x00000080
  UNIQUE_NAME* = 0x00000000
  REGISTERING* = 0x00000000
  REGISTERED* = 0x00000004
  DEREGISTERED* = 0x00000005
  DUPLICATE* = 0x00000006
  DUPLICATE_DEREG* = 0x00000007

type # Structure returned to the NCB command NCBSSTAT is SESSION_HEADER followed
     # by an array of SESSION_BUFFER structures. If the NCB_NAME starts with an
     # asterisk then an array of these structures is returned containing the
     # status for all names.
  PSessionHeader* = ptr TSessionHeader
  TSessionHeader* {.final.} = object
    sess_name*: Char
    num_sess*: Char
    rcv_dg_outstanding*: Char
    rcv_any_outstanding*: Char

  PSessionBuffer* = ptr TSessionBuffer
  TSessionBuffer* {.final.} = object
    lsn*: Char
    state*: Char
    local_name*: array[0..NCBNAMSZ - 1, Char]
    remote_name*: array[0..NCBNAMSZ - 1, Char]
    rcvs_outstanding*: Char
    sends_outstanding*: Char


const                         # Values for state
  LISTEN_OUTSTANDING* = 0x00000001
  CALL_PENDING* = 0x00000002
  SESSION_ESTABLISHED* = 0x00000003
  HANGUP_PENDING* = 0x00000004
  HANGUP_COMPLETE* = 0x00000005
  SESSION_ABORTED* = 0x00000006

type # Structure returned to the NCB command NCBENUM.
     # On a system containing lana's 0, 2 and 3, a structure with
     # length =3, lana[0]=0, lana[1]=2 and lana[2]=3 will be returned.
  PLanaEnum* = ptr TLanaEnum
  TLanaEnum* {.final.} = object # Structure returned to the NCB command NCBFINDNAME is FIND_NAME_HEADER followed
                                # by an array of FIND_NAME_BUFFER structures.
    len*: Char                #  Number of valid entries in lana[]
    lana*: array[0..MAX_LANA, Char]

  PFindNameHeader* = ptr TFindNameHeader
  TFindNameHeader* {.final.} = object
    node_count*: int16
    reserved*: Char
    unique_group*: Char

  PFindNameBuffer* = ptr TFindNameBuffer
  TFindNameBuffer* {.final.} = object # Structure provided with NCBACTION. The purpose of NCBACTION is to provide
                                      # transport specific extensions to netbios.
    len*: Char
    access_control*: Char
    frame_control*: Char
    destination_addr*: array[0..5, Char]
    source_addr*: array[0..5, Char]
    routing_info*: array[0..17, Char]

  PActionHeader* = ptr TActionHeader
  TActionHeader* {.final.} = object
    transport_id*: int32
    action_code*: int16
    reserved*: int16


const                         # Values for transport_id
  ALL_TRANSPORTS* = "M\0\0\0"
  MS_NBF* = "MNBF"            # Special values and constants

const                         # NCB Command codes
  NCBCALL* = 0x00000010       # NCB CALL
  NCBLISTEN* = 0x00000011     # NCB LISTEN
  NCBHANGUP* = 0x00000012     # NCB HANG UP
  NCBSEND* = 0x00000014       # NCB SEND
  NCBRECV* = 0x00000015       # NCB RECEIVE
  NCBRECVANY* = 0x00000016    # NCB RECEIVE ANY
  NCBCHAINSEND* = 0x00000017  # NCB CHAIN SEND
  NCBDGSEND* = 0x00000020     # NCB SEND DATAGRAM
  NCBDGRECV* = 0x00000021     # NCB RECEIVE DATAGRAM
  NCBDGSENDBC* = 0x00000022   # NCB SEND BROADCAST DATAGRAM
  NCBDGRECVBC* = 0x00000023   # NCB RECEIVE BROADCAST DATAGRAM
  NCBADDNAME* = 0x00000030    # NCB ADD NAME
  NCBDELNAME* = 0x00000031    # NCB DELETE NAME
  NCBRESET* = 0x00000032      # NCB RESET
  NCBASTAT* = 0x00000033      # NCB ADAPTER STATUS
  NCBSSTAT* = 0x00000034      # NCB SESSION STATUS
  NCBCANCEL* = 0x00000035     # NCB CANCEL
  NCBADDGRNAME* = 0x00000036  # NCB ADD GROUP NAME
  NCBENUM* = 0x00000037       # NCB ENUMERATE LANA NUMBERS
  NCBUNLINK* = 0x00000070     # NCB UNLINK
  NCBSENDNA* = 0x00000071     # NCB SEND NO ACK
  NCBCHAINSENDNA* = 0x00000072 # NCB CHAIN SEND NO ACK
  NCBLANSTALERT* = 0x00000073 # NCB LAN STATUS ALERT
  NCBACTION* = 0x00000077     # NCB ACTION
  NCBFINDNAME* = 0x00000078   # NCB FIND NAME
  NCBTRACE* = 0x00000079      # NCB TRACE
  ASYNCH* = 0x00000080        # high bit set = asynchronous
                              # NCB Return codes
  NRC_GOODRET* = 0x00000000   # good return
                              # also returned when ASYNCH request accepted
  NRC_BUFLEN* = 0x00000001    # illegal buffer length
  NRC_ILLCMD* = 0x00000003    # illegal command
  NRC_CMDTMO* = 0x00000005    # command timed out
  NRC_INCOMP* = 0x00000006    # message incomplete, issue another command
  NRC_BADDR* = 0x00000007     # illegal buffer address
  NRC_SNUMOUT* = 0x00000008   # session number out of range
  NRC_NORES* = 0x00000009     # no resource available
  NRC_SCLOSED* = 0x0000000A   # session closed
  NRC_CMDCAN* = 0x0000000B    # command cancelled
  NRC_DUPNAME* = 0x0000000D   # duplicate name
  NRC_NAMTFUL* = 0x0000000E   # name table full
  NRC_ACTSES* = 0x0000000F    # no deletions, name has active sessions
  NRC_LOCTFUL* = 0x00000011   # local session table full
  NRC_REMTFUL* = 0x00000012   # remote session table full
  NRC_ILLNN* = 0x00000013     # illegal name number
  NRC_NOCALL* = 0x00000014    # no callname
  NRC_NOWILD* = 0x00000015    # cannot put * in NCB_NAME
  NRC_INUSE* = 0x00000016     # name in use on remote adapter
  NRC_NAMERR* = 0x00000017    # name deleted
  NRC_SABORT* = 0x00000018    # session ended abnormally
  NRC_NAMCONF* = 0x00000019   # name conflict detected
  NRC_IFBUSY* = 0x00000021    # interface busy, IRET before retrying
  NRC_TOOMANY* = 0x00000022   # too many commands outstanding, retry later
  NRC_BRIDGE* = 0x00000023    # NCB_lana_num field invalid
  NRC_CANOCCR* = 0x00000024   # command completed while cancel occurring
  NRC_CANCEL* = 0x00000026    # command not valid to cancel
  NRC_DUPENV* = 0x00000030    # name defined by anther local process
  NRC_ENVNOTDEF* = 0x00000034 # environment undefined. RESET required
  NRC_OSRESNOTAV* = 0x00000035 # required OS resources exhausted
  NRC_MAXAPPS* = 0x00000036   # max number of applications exceeded
  NRC_NOSAPS* = 0x00000037    # no saps available for netbios
  NRC_NORESOURCES* = 0x00000038 # requested resources are not available
  NRC_INVADDRESS* = 0x00000039 # invalid ncb address or length > segment
  NRC_INVDDID* = 0x0000003B   # invalid NCB DDID
  NRC_LOCKFAIL* = 0x0000003C  # lock of user area failed
  NRC_OPENERR* = 0x0000003F   # NETBIOS not loaded
  NRC_SYSTEM* = 0x00000040    # system error
  NRC_PENDING* = 0x000000FF   # asynchronous command is not yet finished
                              # main user entry point for NetBIOS 3.0
                              #   Usage: Result = Netbios( pncb );

proc Netbios*(P: PNCB): Char{.stdcall, dynlib: "netapi32.dll",
                              importc: "Netbios".}
# implementation
