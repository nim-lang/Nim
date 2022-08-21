#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## Scan for SSL/TLS CA certificates on disk
## The default locations can be overridden using the SSL_CERT_FILE and
## SSL_CERT_DIR environment variables.

import os, strutils

# FWIW look for files before scanning entire dirs.

when defined(macosx):
  const certificatePaths = [
    "/etc/ssl/cert.pem",
    "/System/Library/OpenSSL/certs/cert.pem"
  ]
elif defined(linux):
  const certificatePaths = [
    # Debian, Ubuntu, Arch: maintained by update-ca-certificates, SUSE, Gentoo
    # NetBSD (security/mozilla-rootcerts)
    # SLES10/SLES11, https://golang.org/issue/12139
    "/etc/ssl/certs/ca-certificates.crt",
    # OpenSUSE
    "/etc/ssl/ca-bundle.pem",
    # Red Hat 5+, Fedora, Centos
    "/etc/pki/tls/certs/ca-bundle.crt",
    # Red Hat 4
    "/usr/share/ssl/certs/ca-bundle.crt",
    # Fedora/RHEL
    "/etc/pki/tls/certs",
    # Android
    "/data/data/com.termux/files/usr/etc/tls/cert.pem",
    "/system/etc/security/cacerts",
  ]
elif defined(bsd):
  const certificatePaths = [
    # Debian, Ubuntu, Arch: maintained by update-ca-certificates, SUSE, Gentoo
    # NetBSD (security/mozilla-rootcerts)
    # SLES10/SLES11, https://golang.org/issue/12139
    "/etc/ssl/certs/ca-certificates.crt",
    # FreeBSD (security/ca-root-nss package)
    "/usr/local/share/certs/ca-root-nss.crt",
    # OpenBSD, FreeBSD (optional symlink)
    "/etc/ssl/cert.pem",
    # FreeBSD
    "/usr/local/share/certs",
    # NetBSD
    "/etc/openssl/certs",
  ]
else:
  const certificatePaths = [
    # Debian, Ubuntu, Arch: maintained by update-ca-certificates, SUSE, Gentoo
    # NetBSD (security/mozilla-rootcerts)
    # SLES10/SLES11, https://golang.org/issue/12139
    "/etc/ssl/certs/ca-certificates.crt",
    # OpenSUSE
    "/etc/ssl/ca-bundle.pem",
    # Red Hat 5+, Fedora, Centos
    "/etc/pki/tls/certs/ca-bundle.crt",
    # Red Hat 4
    "/usr/share/ssl/certs/ca-bundle.crt",
    # FreeBSD (security/ca-root-nss package)
    "/usr/local/share/certs/ca-root-nss.crt",
    # CentOS/RHEL 7
    "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",
    # OpenBSD, FreeBSD (optional symlink)
    "/etc/ssl/cert.pem",
    # Fedora/RHEL
    "/etc/pki/tls/certs",
    # Android
    "/system/etc/security/cacerts",
    # FreeBSD
    "/usr/local/share/certs",
    # NetBSD
    "/etc/openssl/certs",
  ]

when defined(haiku):
  const
    B_FIND_PATH_EXISTING_ONLY = 0x4
    B_FIND_PATH_DATA_DIRECTORY = 6

  proc find_paths_etc(architecture: cstring, baseDirectory: cint,
                      subPath: cstring, flags: uint32,
                      paths: var ptr UncheckedArray[cstring],
                      pathCount: var csize): int32
                     {.importc, header: "<FindDirectory.h>".}
  proc free(p: pointer) {.importc, header: "<stdlib.h>".}

iterator scanSSLCertificates*(useEnvVars = false): string =
  ## Scan for SSL/TLS CA certificates on disk.
  ##
  ## if `useEnvVars` is true, the SSL_CERT_FILE and SSL_CERT_DIR
  ## environment variables can be used to override the certificate
  ## directories to scan or specify a CA certificate file.
  if useEnvVars and existsEnv("SSL_CERT_FILE"):
    yield getEnv("SSL_CERT_FILE")

  elif useEnvVars and existsEnv("SSL_CERT_DIR"):
    let p = getEnv("SSL_CERT_DIR")
    for fn in joinPath(p, "*").walkFiles():
      yield fn

  else:
    when defined(windows):
      const cacert = "cacert.pem"
      let pem = getAppDir() / cacert
      if fileExists(pem):
        yield pem
      else:
        let path = getEnv("PATH")
        for candidate in split(path, PathSep):
          if candidate.len != 0:
            let x = (if candidate[0] == '"' and candidate[^1] == '"':
                      substr(candidate, 1, candidate.len-2) else: candidate) / cacert
            if fileExists(x):
              yield x
    elif not defined(haiku):
      for p in certificatePaths:
        if p.endsWith(".pem") or p.endsWith(".crt"):
          if fileExists(p):
            yield p
        elif dirExists(p):
          for fn in joinPath(p, "*").walkFiles():
            yield fn
    else:
      var
        paths: ptr UncheckedArray[cstring]
        size: csize
      let err = find_paths_etc(
        nil, B_FIND_PATH_DATA_DIRECTORY, "ssl/CARootCertificates.pem",
        B_FIND_PATH_EXISTING_ONLY, paths, size
      )
      if err == 0:
        defer: free(paths)
        for i in 0 ..< size:
          yield $paths[i]

# Certificates management on windows
# when defined(windows) or defined(nimdoc):
#
#   import openssl
#
#   type
#     PCCertContext {.final, pure.} = pointer
#     X509 {.final, pure.} = pointer
#     CertStore {.final, pure.} = pointer
#
#   # OpenSSL cert store
#
#   {.push stdcall, dynlib: "kernel32", importc.}
#
#   proc CertOpenSystemStore*(hprov: pointer=nil, szSubsystemProtocol: cstring): CertStore
#
#   proc CertEnumCertificatesInStore*(hCertStore: CertStore, pPrevCertContext: PCCertContext): pointer
#
#   proc CertFreeCertificateContext*(pContext: PCCertContext): bool
#
#   proc CertCloseStore*(hCertStore:CertStore, flags:cint): bool
#
#   {.pop.}
