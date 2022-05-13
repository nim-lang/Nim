import std/wordwrap
import openssl

const PubKey = r"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAknKWvrdnncCIzBnIGrZ5qtZrPH+Yo3t7ag9WZIu6Gmc/JgIDDaZhJeyGW0YSnifeAEhooWvM4jDWhTEARzktalSHqYtmwI/1Oxwp6NTYH8akMe2LCpZ5pX9FVA6m9o2tkbdXatbDKRqeD4UA8Ow7Iyrdo6eb1SU8vk+26i+uXHTtsb25p8uf2ppOJrJCy+1vr8Gsnuwny1UdoYZTxMsxRFPf+UX/LrSXMHVq/oPVa3SJ4VHMpYrG/httAugVP6K58xiZ93jst63/dd0JL85mWJu1uS3uz92aL5O97xzth3wR4BbdmDUlN4LuTIwi6DtEcC7gUOTnOzH4zgp2b5RyHwIDAQAB"
const PrivateKey = r"MIIEpAIBAAKCAQEAknKWvrdnncCIzBnIGrZ5qtZrPH+Yo3t7ag9WZIu6Gmc/JgIDDaZhJeyGW0YSnifeAEhooWvM4jDWhTEARzktalSHqYtmwI/1Oxwp6NTYH8akMe2LCpZ5pX9FVA6m9o2tkbdXatbDKRqeD4UA8Ow7Iyrdo6eb1SU8vk+26i+uXHTtsb25p8uf2ppOJrJCy+1vr8Gsnuwny1UdoYZTxMsxRFPf+UX/LrSXMHVq/oPVa3SJ4VHMpYrG/httAugVP6K58xiZ93jst63/dd0JL85mWJu1uS3uz92aL5O97xzth3wR4BbdmDUlN4LuTIwi6DtEcC7gUOTnOzH4zgp2b5RyHwIDAQABAoIBACSOxmLFlfAjaALLTNCeTLEA5bQshgYJhT1sprxixQpiS7lJN0npBsdYzBFs5KjmetzHNpdVOcgdOO/204L0Gwo4H8WLLxNS3HztAulEeM813zc3fUYfWi6eHshk//j8VR/TDNd21TElm99z7FA4KGsXAE0iQhxrN0aqz5aWYIhjprtHA5KxXIiESnTkof5Cud8oXEnPiwPGNhq93QeQzh7xQIKSaDKBcdAa6edTFhzc4RLUQRfrik/GqJzouEDQ9v6H/uiOLTB3FxxwErQIf6dvSVhD9gs1nSLQfyj3S2Hxe9S2zglTl07EsawTQUxtVQkdZUOok67c7CPBxecZ2wECgYEA2c31gr/UJwczT+P/AE52GkHHETXMxqE3Hnh9n4CitfAFSD5X0VwZvGjZIlln2WjisTd92Ymf65eDylX2kCm93nzZ2GfXgS4zl4oY1N87+VeNQlx9f2+6GU7Hs0HFdfu8bGd+0sOuWA1PFqQCobxCACMPTkuzsG9M7knUTN59HS8CgYEArCEoP4ReYoOFveXUE0AteTPb4hryvR9VDEolP+LMoiPe8AzBMeB5fP493TPdjtnWmrPCXNLc7UAFSj2CZsRhau4PuiqnNrsb5iz/7iXVl3E8wZvS4w7WYpO4m33L0cijA6MdcdqilQu4Z5tw4nG45lAW9UYyOc9D4hJTzgtGHhECgYA6QyDoj931brSoK0ocT+DB11Sj4utbOuberMaV8zgTSRhwodSl+WgdAUMMMDRacPcrBrgQiAMSZ15msqYZHEFhEa7Id8arFKvSXquTzf9iDKyJ0unzO/ThLjS3W+GxVNyrdufzA0tQ3IaKfOcDUrOpC7fdbtyrVqqSl4dF5MI9GwKBgQCl3OF6qyOEDDZgsUk1L59h7k3QR6VmBf4e9IeGUxZamvQlHjU/yY1nm1mjgGnbUB/SPKtqZKoMV6eBTVoNiuhQcItpGda9D3mnx+7p3T0/TBd+fJeuwcplfPDjrEktogcq5w/leQc3Ve7gr1EMcwb3r28f8/9L42QHQR/OKODs8QKBgQCFAvxDRPyYg7V/AgD9rt1KzXi4+b3Pls5NXZa2g/w+hmdhHUNxV5IGmHlqFnptGyshgYgQGxMMkW0iJ1j8nLamFnkbFQOp5/UKbdPLRKiB86oPpxsqYtPXucDUqEfcMsp57mD1CpGVODbspogFpSUvQpMECkhvI0XLMbolMdo53g=="

proc rsaPublicEncrypt(fr: string): string =
  let mKey = "-----BEGIN PUBLIC KEY-----\n" & PubKey.wrapWords(64) & "\n-----END PUBLIC KEY-----"
  let bio = bioNew(bioSMem())
  doAssert BIO_write(bio, mKey.cstring, mKey.len.cint) >= 0
  let rsa = PEM_read_bio_RSA_PUBKEY(bio, nil, nil, nil)
  doAssert rsa != nil
  doAssert BIO_free(bio) >= 0
  result = newString(RSA_size(rsa))
  let frdata = cast[ptr uint8](fr.cstring)
  var todata = cast[ptr uint8](result.cstring)
  doAssert RSA_public_encrypt(fr.len.cint, frdata, todata, rsa, RSA_PKCS1_PADDING) != -1
  RSA_free(rsa)

proc rasPrivateDecrypt(fr: string): string =
  let mKey = "-----BEGIN RSA PRIVATE KEY-----\n" & PrivateKey.wrapWords(64) & "\n-----END RSA PRIVATE KEY-----"
  let bio = bioNew(bioSMem())
  doAssert BIO_write(bio, mKey.cstring, mKey.len.cint) >= 0
  let rsa = PEM_read_bio_RSAPrivateKey(bio, nil, nil, nil)
  doAssert rsa != nil
  doAssert BIO_free(bio) >= 0
  let rsaLen = RSA_size(rsa)
  result = newString(rsaLen)
  let frdata = cast[ptr uint8](fr.cstring)
  var todata = cast[ptr uint8](result.cstring)
  let lenOrig = RSA_private_decrypt(rsaLen, frdata, todata, rsa, RSA_PKCS1_PADDING)
  doAssert lenOrig >= 0 and lenOrig < result.len
  doAssert result[lenOrig] == '\0'
  result.setLen lenOrig
  RSA_free(rsa)

let res = "TEST"
let miwen = rsaPublicEncrypt(res)
let mingwen = rasPrivateDecrypt(miwen)
doAssert mingwen == res

