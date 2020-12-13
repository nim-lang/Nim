discard """
  matrix: "-d:ssl"
"""
import openssl

# bug #16308
block:
  var rsa: PRSA
  var file: File

  if not file.open("topenssl_rsa_public_key.pem"):
    raise newException(Exception, "Error opening file")

  rsa = PEM_read_RSAPUBKEY(file, nil, nil, nil)
  if rsa == nil:
    raise newException(Exception, "Error reading public key")
  RSA_free(rsa)
  file.close()
 
