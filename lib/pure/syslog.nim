#
#
#            Nim's Runtime Library
#     (c) Copyright 2015 Federico Ceratto
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module for Unix Syslog

import posix
import strutils
import tables
import times

const
  # severity codes
  log_emerg = 0  # system is unusable
  log_alert = 1  # action must be taken immediately
  log_crit = 2  # critical conditions
  log_err = 3  # error conditions
  log_warning = 4  # warning conditions
  log_notice = 5  # normal but significant condition
  log_info = 6  # informational
  log_debug = 7  # debug-level messages

  severity_names_g = {
    "alert": log_alert,
    "crit": log_crit,
    "debug": log_debug,
    "emerg": log_emerg,
    "err": log_err,
    "error": log_err, # deprecated
    "info": log_info,
    "notice": log_notice,
    "panic": log_emerg, # deprecated
    "warn": log_warning, # deprecated
    "warning": log_warning,
  }

  # facility codes
  log_kern = 0  # kernel messages
  log_user = 1  # random user-level messages
  log_mail = 2  # mail system
  log_daemon = 3  # system daemons
  log_auth = 4  # security/authorization messages
  log_syslog = 5  # messages generated internally by syslogd
  log_lpr = 6  # line printer subsystem
  log_news = 7  # network news subsystem
  log_uucp = 8  # uucp subsystem
  log_cron = 9  # clock daemon
  log_authpriv = 10  # security/authorization messages (private)

  # other codes through 15 reserved for system use
  log_local0 = 16  # reserved for local use
  log_local1 = 17  # reserved for local use
  log_local2 = 18  # reserved for local use
  log_local3 = 19  # reserved for local use
  log_local4 = 20  # reserved for local use
  log_local5 = 21  # reserved for local use
  log_local6 = 22  # reserved for local use
  log_local7 = 23  # reserved for local use

  facility_names_g = {
    "auth": log_auth,
    "authpriv": log_authpriv,
    "cron": log_cron,
    "daemon": log_daemon,
    "kern": log_kern,
    "lpr": log_lpr,
    "mail": log_mail,
    "news": log_news,
    "security": log_auth, # deprecated
    "syslog": log_syslog,
    "user": log_user,
    "uucp": log_uucp,
    "local0": log_local0,
    "local1": log_local1,
    "local2": log_local2,
    "local3": log_local3,
    "local4": log_local4,
    "local5": log_local5,
    "local6": log_local6,
    "local7": log_local7,
  }

  default_facility = "user"

let
  severity_names = severity_names_g.toTable
  facility_names = facility_names_g.toTable


proc array256(s: string): array[0..255, char] =
  var
    result: array[0..255, char]
    cnt = 0

  for i in s:
    result[cnt] = i
    cnt.inc()

  return result


when defined(macosx):
  const syslog_socket_fname = "/var/run/syslog"
else:
  const syslog_socket_fname = "/dev/log"

const syslog_socket_fname_a = syslog_socket_fname.array256


proc calculate_priority(facility: string, severity: string): int =
  ## Calculate priority value
  let
    f = facility_names[facility]
    s = severity_names[severity]

  result = (f shl 3) or s


proc emit_log(facility, severity, msg: string) {.raises: [].} =

  var
    sock_addr: SockAddr
    tstamp: string
    logmsg: string

  let
    addr_len = Socklen(sizeof(sock_addr))
    flag: cint = 0
    sock = socket(AF_UNIX, SOCK_DGRAM, 0)
    pri = calculate_priority(facility, severity)

  try:
    tstamp = getTime().getLocalTime().format("MMM d HH:mm:ss")
    logmsg = "<$#>$# $#" % [$pri, $tstamp, msg]
  except ValueError:
    discard

  sock_addr = SockAddr(sa_family: posix.AF_UNIX, sa_data: syslog_socket_fname_a)

  var r = sock.connect(addr sock_addr, addr_len)
  if r != 0:
    try:
      writeln(stderr, "Unable to connect to syslog unix socket " & syslog_socket_fname)
      return
    except IOError:
      return

  discard sock.send(cstring(logmsg), cint(logmsg.len), flag)


proc emerg*(msg: string) =
  emit_log(default_facility, "emerg", msg)

proc alert*(msg: string) =
  emit_log(default_facility, "alert", msg)

proc crit*(msg: string) =
  emit_log(default_facility, "crit", msg)

proc error*(msg: string) =
  emit_log(default_facility, "error", msg)

proc info*(msg: string) =
  emit_log(default_facility, "info", msg)

proc debug*(msg: string) =
  emit_log(default_facility, "debug", msg)

proc notice*(msg: string) =
  emit_log(default_facility, "notice", msg)

proc warn*(msg: string) =
  emit_log(default_facility, "warning", msg)

proc warning*(msg: string) =
  emit_log(default_facility, "warning", msg)
