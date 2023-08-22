#
#
#              Nim's Runtime Library
#        (c) Copyright 2023 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# Main bcrypt and blowfish implementation based on OpenBSD bcrypt.c and blowfish.c.

## [bcrypt](https://en.wikipedia.org/wiki/Bcrypt) is a [Blowfish](https://en.wikipedia.org/wiki/Blowfish_(cipher))-based
## password hashing algorithm that is designed to be adaptively expensive to provide
## resistance against brute force based attacks and additionally includes a salt
## for lookup table resistance.
##
## Although bcrypt has been around for a long time, dating back to 1999, for many projects
## it is still a reasonable choice due to its adjustable cost factor that can provide security
## against all but the most well funded attackers.
##
## This module's design is based loosely on Python's `bcrypt` module and supports generating
## the newer version `2b` hashes as well as verifying the older `2a` and the PHP equivalent
## of `2b` called `2y`.

runnableExamples:

  # Generate a salt with a specific cost factor and use it to hash a password.
  let hashed = bcrypt("correct horse battery stape", generateSalt(8))

runnableExamples:

  # Verify a password against a known good hash from i.e. a database.
  let knownGood = "$2b$06$LzUyyYdKBoEy9V4NTvxDH.O11KQP30/Zyp5pQAQ.0Cy89WnkD5Jjy"

  assert verify("correct horse battery staple", knownGood)


import std/[sysrand, strutils]

const
  cryptBlocksInit = [
    0x4f'u8, 0x72'u8, 0x70'u8, 0x68'u8, # Orph
    0x65'u8, 0x61'u8, 0x6e'u8, 0x42'u8, # eanB
    0x65'u8, 0x68'u8, 0x6f'u8, 0x6c'u8, # ehol
    0x64'u8, 0x65'u8, 0x72'u8, 0x53'u8, # derS
    0x63'u8, 0x72'u8, 0x79'u8, 0x44'u8, # cryD
    0x6f'u8, 0x75'u8, 0x62'u8, 0x74'u8  # oubt
  ]

  subkeysInit = [
    0x243f6a88'u32, 0x85a308d3'u32, 0x13198a2e'u32, 0x03707344'u32,
    0xa4093822'u32, 0x299f31d0'u32, 0x082efa98'u32, 0xec4e6c89'u32,
    0x452821e6'u32, 0x38d01377'u32, 0xbe5466cf'u32, 0x34e90c6c'u32,
    0xc0ac29b7'u32, 0xc97c50dd'u32, 0x3f84d5b5'u32, 0xb5470917'u32,
    0x9216d5d9'u32, 0x8979fb1b'u32
  ]

  sboxesInit = [
    [0xd1310ba6'u32, 0x98dfb5ac'u32, 0x2ffd72db'u32, 0xd01adfb7'u32, 0xb8e1afed'u32, 0x6a267e96'u32, 0xba7c9045'u32, 0xf12c7f99'u32,
     0x24a19947'u32, 0xb3916cf7'u32, 0x0801f2e2'u32, 0x858efc16'u32, 0x636920d8'u32, 0x71574e69'u32, 0xa458fea3'u32, 0xf4933d7e'u32,
     0x0d95748f'u32, 0x728eb658'u32, 0x718bcd58'u32, 0x82154aee'u32, 0x7b54a41d'u32, 0xc25a59b5'u32, 0x9c30d539'u32, 0x2af26013'u32,
     0xc5d1b023'u32, 0x286085f0'u32, 0xca417918'u32, 0xb8db38ef'u32, 0x8e79dcb0'u32, 0x603a180e'u32, 0x6c9e0e8b'u32, 0xb01e8a3e'u32,
     0xd71577c1'u32, 0xbd314b27'u32, 0x78af2fda'u32, 0x55605c60'u32, 0xe65525f3'u32, 0xaa55ab94'u32, 0x57489862'u32, 0x63e81440'u32,
     0x55ca396a'u32, 0x2aab10b6'u32, 0xb4cc5c34'u32, 0x1141e8ce'u32, 0xa15486af'u32, 0x7c72e993'u32, 0xb3ee1411'u32, 0x636fbc2a'u32,
     0x2ba9c55d'u32, 0x741831f6'u32, 0xce5c3e16'u32, 0x9b87931e'u32, 0xafd6ba33'u32, 0x6c24cf5c'u32, 0x7a325381'u32, 0x28958677'u32,
     0x3b8f4898'u32, 0x6b4bb9af'u32, 0xc4bfe81b'u32, 0x66282193'u32, 0x61d809cc'u32, 0xfb21a991'u32, 0x487cac60'u32, 0x5dec8032'u32,
     0xef845d5d'u32, 0xe98575b1'u32, 0xdc262302'u32, 0xeb651b88'u32, 0x23893e81'u32, 0xd396acc5'u32, 0x0f6d6ff3'u32, 0x83f44239'u32,
     0x2e0b4482'u32, 0xa4842004'u32, 0x69c8f04a'u32, 0x9e1f9b5e'u32, 0x21c66842'u32, 0xf6e96c9a'u32, 0x670c9c61'u32, 0xabd388f0'u32,
     0x6a51a0d2'u32, 0xd8542f68'u32, 0x960fa728'u32, 0xab5133a3'u32, 0x6eef0b6c'u32, 0x137a3be4'u32, 0xba3bf050'u32, 0x7efb2a98'u32,
     0xa1f1651d'u32, 0x39af0176'u32, 0x66ca593e'u32, 0x82430e88'u32, 0x8cee8619'u32, 0x456f9fb4'u32, 0x7d84a5c3'u32, 0x3b8b5ebe'u32,
     0xe06f75d8'u32, 0x85c12073'u32, 0x401a449f'u32, 0x56c16aa6'u32, 0x4ed3aa62'u32, 0x363f7706'u32, 0x1bfedf72'u32, 0x429b023d'u32,
     0x37d0d724'u32, 0xd00a1248'u32, 0xdb0fead3'u32, 0x49f1c09b'u32, 0x075372c9'u32, 0x80991b7b'u32, 0x25d479d8'u32, 0xf6e8def7'u32,
     0xe3fe501a'u32, 0xb6794c3b'u32, 0x976ce0bd'u32, 0x04c006ba'u32, 0xc1a94fb6'u32, 0x409f60c4'u32, 0x5e5c9ec2'u32, 0x196a2463'u32,
     0x68fb6faf'u32, 0x3e6c53b5'u32, 0x1339b2eb'u32, 0x3b52ec6f'u32, 0x6dfc511f'u32, 0x9b30952c'u32, 0xcc814544'u32, 0xaf5ebd09'u32,
     0xbee3d004'u32, 0xde334afd'u32, 0x660f2807'u32, 0x192e4bb3'u32, 0xc0cba857'u32, 0x45c8740f'u32, 0xd20b5f39'u32, 0xb9d3fbdb'u32,
     0x5579c0bd'u32, 0x1a60320a'u32, 0xd6a100c6'u32, 0x402c7279'u32, 0x679f25fe'u32, 0xfb1fa3cc'u32, 0x8ea5e9f8'u32, 0xdb3222f8'u32,
     0x3c7516df'u32, 0xfd616b15'u32, 0x2f501ec8'u32, 0xad0552ab'u32, 0x323db5fa'u32, 0xfd238760'u32, 0x53317b48'u32, 0x3e00df82'u32,
     0x9e5c57bb'u32, 0xca6f8ca0'u32, 0x1a87562e'u32, 0xdf1769db'u32, 0xd542a8f6'u32, 0x287effc3'u32, 0xac6732c6'u32, 0x8c4f5573'u32,
     0x695b27b0'u32, 0xbbca58c8'u32, 0xe1ffa35d'u32, 0xb8f011a0'u32, 0x10fa3d98'u32, 0xfd2183b8'u32, 0x4afcb56c'u32, 0x2dd1d35b'u32,
     0x9a53e479'u32, 0xb6f84565'u32, 0xd28e49bc'u32, 0x4bfb9790'u32, 0xe1ddf2da'u32, 0xa4cb7e33'u32, 0x62fb1341'u32, 0xcee4c6e8'u32,
     0xef20cada'u32, 0x36774c01'u32, 0xd07e9efe'u32, 0x2bf11fb4'u32, 0x95dbda4d'u32, 0xae909198'u32, 0xeaad8e71'u32, 0x6b93d5a0'u32,
     0xd08ed1d0'u32, 0xafc725e0'u32, 0x8e3c5b2f'u32, 0x8e7594b7'u32, 0x8ff6e2fb'u32, 0xf2122b64'u32, 0x8888b812'u32, 0x900df01c'u32,
     0x4fad5ea0'u32, 0x688fc31c'u32, 0xd1cff191'u32, 0xb3a8c1ad'u32, 0x2f2f2218'u32, 0xbe0e1777'u32, 0xea752dfe'u32, 0x8b021fa1'u32,
     0xe5a0cc0f'u32, 0xb56f74e8'u32, 0x18acf3d6'u32, 0xce89e299'u32, 0xb4a84fe0'u32, 0xfd13e0b7'u32, 0x7cc43b81'u32, 0xd2ada8d9'u32,
     0x165fa266'u32, 0x80957705'u32, 0x93cc7314'u32, 0x211a1477'u32, 0xe6ad2065'u32, 0x77b5fa86'u32, 0xc75442f5'u32, 0xfb9d35cf'u32,
     0xebcdaf0c'u32, 0x7b3e89a0'u32, 0xd6411bd3'u32, 0xae1e7e49'u32, 0x00250e2d'u32, 0x2071b35e'u32, 0x226800bb'u32, 0x57b8e0af'u32,
     0x2464369b'u32, 0xf009b91e'u32, 0x5563911d'u32, 0x59dfa6aa'u32, 0x78c14389'u32, 0xd95a537f'u32, 0x207d5ba2'u32, 0x02e5b9c5'u32,
     0x83260376'u32, 0x6295cfa9'u32, 0x11c81968'u32, 0x4e734a41'u32, 0xb3472dca'u32, 0x7b14a94a'u32, 0x1b510052'u32, 0x9a532915'u32,
     0xd60f573f'u32, 0xbc9bc6e4'u32, 0x2b60a476'u32, 0x81e67400'u32, 0x08ba6fb5'u32, 0x571be91f'u32, 0xf296ec6b'u32, 0x2a0dd915'u32,
     0xb6636521'u32, 0xe7b9f9b6'u32, 0xff34052e'u32, 0xc5855664'u32, 0x53b02d5d'u32, 0xa99f8fa1'u32, 0x08ba4799'u32, 0x6e85076a'u32],
    [0x4b7a70e9'u32, 0xb5b32944'u32, 0xdb75092e'u32, 0xc4192623'u32, 0xad6ea6b0'u32, 0x49a7df7d'u32, 0x9cee60b8'u32, 0x8fedb266'u32,
     0xecaa8c71'u32, 0x699a17ff'u32, 0x5664526c'u32, 0xc2b19ee1'u32, 0x193602a5'u32, 0x75094c29'u32, 0xa0591340'u32, 0xe4183a3e'u32,
     0x3f54989a'u32, 0x5b429d65'u32, 0x6b8fe4d6'u32, 0x99f73fd6'u32, 0xa1d29c07'u32, 0xefe830f5'u32, 0x4d2d38e6'u32, 0xf0255dc1'u32,
     0x4cdd2086'u32, 0x8470eb26'u32, 0x6382e9c6'u32, 0x021ecc5e'u32, 0x09686b3f'u32, 0x3ebaefc9'u32, 0x3c971814'u32, 0x6b6a70a1'u32,
     0x687f3584'u32, 0x52a0e286'u32, 0xb79c5305'u32, 0xaa500737'u32, 0x3e07841c'u32, 0x7fdeae5c'u32, 0x8e7d44ec'u32, 0x5716f2b8'u32,
     0xb03ada37'u32, 0xf0500c0d'u32, 0xf01c1f04'u32, 0x0200b3ff'u32, 0xae0cf51a'u32, 0x3cb574b2'u32, 0x25837a58'u32, 0xdc0921bd'u32,
     0xd19113f9'u32, 0x7ca92ff6'u32, 0x94324773'u32, 0x22f54701'u32, 0x3ae5e581'u32, 0x37c2dadc'u32, 0xc8b57634'u32, 0x9af3dda7'u32,
     0xa9446146'u32, 0x0fd0030e'u32, 0xecc8c73e'u32, 0xa4751e41'u32, 0xe238cd99'u32, 0x3bea0e2f'u32, 0x3280bba1'u32, 0x183eb331'u32,
     0x4e548b38'u32, 0x4f6db908'u32, 0x6f420d03'u32, 0xf60a04bf'u32, 0x2cb81290'u32, 0x24977c79'u32, 0x5679b072'u32, 0xbcaf89af'u32,
     0xde9a771f'u32, 0xd9930810'u32, 0xb38bae12'u32, 0xdccf3f2e'u32, 0x5512721f'u32, 0x2e6b7124'u32, 0x501adde6'u32, 0x9f84cd87'u32,
     0x7a584718'u32, 0x7408da17'u32, 0xbc9f9abc'u32, 0xe94b7d8c'u32, 0xec7aec3a'u32, 0xdb851dfa'u32, 0x63094366'u32, 0xc464c3d2'u32,
     0xef1c1847'u32, 0x3215d908'u32, 0xdd433b37'u32, 0x24c2ba16'u32, 0x12a14d43'u32, 0x2a65c451'u32, 0x50940002'u32, 0x133ae4dd'u32,
     0x71dff89e'u32, 0x10314e55'u32, 0x81ac77d6'u32, 0x5f11199b'u32, 0x043556f1'u32, 0xd7a3c76b'u32, 0x3c11183b'u32, 0x5924a509'u32,
     0xf28fe6ed'u32, 0x97f1fbfa'u32, 0x9ebabf2c'u32, 0x1e153c6e'u32, 0x86e34570'u32, 0xeae96fb1'u32, 0x860e5e0a'u32, 0x5a3e2ab3'u32,
     0x771fe71c'u32, 0x4e3d06fa'u32, 0x2965dcb9'u32, 0x99e71d0f'u32, 0x803e89d6'u32, 0x5266c825'u32, 0x2e4cc978'u32, 0x9c10b36a'u32,
     0xc6150eba'u32, 0x94e2ea78'u32, 0xa5fc3c53'u32, 0x1e0a2df4'u32, 0xf2f74ea7'u32, 0x361d2b3d'u32, 0x1939260f'u32, 0x19c27960'u32,
     0x5223a708'u32, 0xf71312b6'u32, 0xebadfe6e'u32, 0xeac31f66'u32, 0xe3bc4595'u32, 0xa67bc883'u32, 0xb17f37d1'u32, 0x018cff28'u32,
     0xc332ddef'u32, 0xbe6c5aa5'u32, 0x65582185'u32, 0x68ab9802'u32, 0xeecea50f'u32, 0xdb2f953b'u32, 0x2aef7dad'u32, 0x5b6e2f84'u32,
     0x1521b628'u32, 0x29076170'u32, 0xecdd4775'u32, 0x619f1510'u32, 0x13cca830'u32, 0xeb61bd96'u32, 0x0334fe1e'u32, 0xaa0363cf'u32,
     0xb5735c90'u32, 0x4c70a239'u32, 0xd59e9e0b'u32, 0xcbaade14'u32, 0xeecc86bc'u32, 0x60622ca7'u32, 0x9cab5cab'u32, 0xb2f3846e'u32,
     0x648b1eaf'u32, 0x19bdf0ca'u32, 0xa02369b9'u32, 0x655abb50'u32, 0x40685a32'u32, 0x3c2ab4b3'u32, 0x319ee9d5'u32, 0xc021b8f7'u32,
     0x9b540b19'u32, 0x875fa099'u32, 0x95f7997e'u32, 0x623d7da8'u32, 0xf837889a'u32, 0x97e32d77'u32, 0x11ed935f'u32, 0x16681281'u32,
     0x0e358829'u32, 0xc7e61fd6'u32, 0x96dedfa1'u32, 0x7858ba99'u32, 0x57f584a5'u32, 0x1b227263'u32, 0x9b83c3ff'u32, 0x1ac24696'u32,
     0xcdb30aeb'u32, 0x532e3054'u32, 0x8fd948e4'u32, 0x6dbc3128'u32, 0x58ebf2ef'u32, 0x34c6ffea'u32, 0xfe28ed61'u32, 0xee7c3c73'u32,
     0x5d4a14d9'u32, 0xe864b7e3'u32, 0x42105d14'u32, 0x203e13e0'u32, 0x45eee2b6'u32, 0xa3aaabea'u32, 0xdb6c4f15'u32, 0xfacb4fd0'u32,
     0xc742f442'u32, 0xef6abbb5'u32, 0x654f3b1d'u32, 0x41cd2105'u32, 0xd81e799e'u32, 0x86854dc7'u32, 0xe44b476a'u32, 0x3d816250'u32,
     0xcf62a1f2'u32, 0x5b8d2646'u32, 0xfc8883a0'u32, 0xc1c7b6a3'u32, 0x7f1524c3'u32, 0x69cb7492'u32, 0x47848a0b'u32, 0x5692b285'u32,
     0x095bbf00'u32, 0xad19489d'u32, 0x1462b174'u32, 0x23820e00'u32, 0x58428d2a'u32, 0x0c55f5ea'u32, 0x1dadf43e'u32, 0x233f7061'u32,
     0x3372f092'u32, 0x8d937e41'u32, 0xd65fecf1'u32, 0x6c223bdb'u32, 0x7cde3759'u32, 0xcbee7460'u32, 0x4085f2a7'u32, 0xce77326e'u32,
     0xa6078084'u32, 0x19f8509e'u32, 0xe8efd855'u32, 0x61d99735'u32, 0xa969a7aa'u32, 0xc50c06c2'u32, 0x5a04abfc'u32, 0x800bcadc'u32,
     0x9e447a2e'u32, 0xc3453484'u32, 0xfdd56705'u32, 0x0e1e9ec9'u32, 0xdb73dbd3'u32, 0x105588cd'u32, 0x675fda79'u32, 0xe3674340'u32,
     0xc5c43465'u32, 0x713e38d8'u32, 0x3d28f89e'u32, 0xf16dff20'u32, 0x153e21e7'u32, 0x8fb03d4a'u32, 0xe6e39f2b'u32, 0xdb83adf7'u32],
    [0xe93d5a68'u32, 0x948140f7'u32, 0xf64c261c'u32, 0x94692934'u32, 0x411520f7'u32, 0x7602d4f7'u32, 0xbcf46b2e'u32, 0xd4a20068'u32,
     0xd4082471'u32, 0x3320f46a'u32, 0x43b7d4b7'u32, 0x500061af'u32, 0x1e39f62e'u32, 0x97244546'u32, 0x14214f74'u32, 0xbf8b8840'u32,
     0x4d95fc1d'u32, 0x96b591af'u32, 0x70f4ddd3'u32, 0x66a02f45'u32, 0xbfbc09ec'u32, 0x03bd9785'u32, 0x7fac6dd0'u32, 0x31cb8504'u32,
     0x96eb27b3'u32, 0x55fd3941'u32, 0xda2547e6'u32, 0xabca0a9a'u32, 0x28507825'u32, 0x530429f4'u32, 0x0a2c86da'u32, 0xe9b66dfb'u32,
     0x68dc1462'u32, 0xd7486900'u32, 0x680ec0a4'u32, 0x27a18dee'u32, 0x4f3ffea2'u32, 0xe887ad8c'u32, 0xb58ce006'u32, 0x7af4d6b6'u32,
     0xaace1e7c'u32, 0xd3375fec'u32, 0xce78a399'u32, 0x406b2a42'u32, 0x20fe9e35'u32, 0xd9f385b9'u32, 0xee39d7ab'u32, 0x3b124e8b'u32,
     0x1dc9faf7'u32, 0x4b6d1856'u32, 0x26a36631'u32, 0xeae397b2'u32, 0x3a6efa74'u32, 0xdd5b4332'u32, 0x6841e7f7'u32, 0xca7820fb'u32,
     0xfb0af54e'u32, 0xd8feb397'u32, 0x454056ac'u32, 0xba489527'u32, 0x55533a3a'u32, 0x20838d87'u32, 0xfe6ba9b7'u32, 0xd096954b'u32,
     0x55a867bc'u32, 0xa1159a58'u32, 0xcca92963'u32, 0x99e1db33'u32, 0xa62a4a56'u32, 0x3f3125f9'u32, 0x5ef47e1c'u32, 0x9029317c'u32,
     0xfdf8e802'u32, 0x04272f70'u32, 0x80bb155c'u32, 0x05282ce3'u32, 0x95c11548'u32, 0xe4c66d22'u32, 0x48c1133f'u32, 0xc70f86dc'u32,
     0x07f9c9ee'u32, 0x41041f0f'u32, 0x404779a4'u32, 0x5d886e17'u32, 0x325f51eb'u32, 0xd59bc0d1'u32, 0xf2bcc18f'u32, 0x41113564'u32,
     0x257b7834'u32, 0x602a9c60'u32, 0xdff8e8a3'u32, 0x1f636c1b'u32, 0x0e12b4c2'u32, 0x02e1329e'u32, 0xaf664fd1'u32, 0xcad18115'u32,
     0x6b2395e0'u32, 0x333e92e1'u32, 0x3b240b62'u32, 0xeebeb922'u32, 0x85b2a20e'u32, 0xe6ba0d99'u32, 0xde720c8c'u32, 0x2da2f728'u32,
     0xd0127845'u32, 0x95b794fd'u32, 0x647d0862'u32, 0xe7ccf5f0'u32, 0x5449a36f'u32, 0x877d48fa'u32, 0xc39dfd27'u32, 0xf33e8d1e'u32,
     0x0a476341'u32, 0x992eff74'u32, 0x3a6f6eab'u32, 0xf4f8fd37'u32, 0xa812dc60'u32, 0xa1ebddf8'u32, 0x991be14c'u32, 0xdb6e6b0d'u32,
     0xc67b5510'u32, 0x6d672c37'u32, 0x2765d43b'u32, 0xdcd0e804'u32, 0xf1290dc7'u32, 0xcc00ffa3'u32, 0xb5390f92'u32, 0x690fed0b'u32,
     0x667b9ffb'u32, 0xcedb7d9c'u32, 0xa091cf0b'u32, 0xd9155ea3'u32, 0xbb132f88'u32, 0x515bad24'u32, 0x7b9479bf'u32, 0x763bd6eb'u32,
     0x37392eb3'u32, 0xcc115979'u32, 0x8026e297'u32, 0xf42e312d'u32, 0x6842ada7'u32, 0xc66a2b3b'u32, 0x12754ccc'u32, 0x782ef11c'u32,
     0x6a124237'u32, 0xb79251e7'u32, 0x06a1bbe6'u32, 0x4bfb6350'u32, 0x1a6b1018'u32, 0x11caedfa'u32, 0x3d25bdd8'u32, 0xe2e1c3c9'u32,
     0x44421659'u32, 0x0a121386'u32, 0xd90cec6e'u32, 0xd5abea2a'u32, 0x64af674e'u32, 0xda86a85f'u32, 0xbebfe988'u32, 0x64e4c3fe'u32,
     0x9dbc8057'u32, 0xf0f7c086'u32, 0x60787bf8'u32, 0x6003604d'u32, 0xd1fd8346'u32, 0xf6381fb0'u32, 0x7745ae04'u32, 0xd736fccc'u32,
     0x83426b33'u32, 0xf01eab71'u32, 0xb0804187'u32, 0x3c005e5f'u32, 0x77a057be'u32, 0xbde8ae24'u32, 0x55464299'u32, 0xbf582e61'u32,
     0x4e58f48f'u32, 0xf2ddfda2'u32, 0xf474ef38'u32, 0x8789bdc2'u32, 0x5366f9c3'u32, 0xc8b38e74'u32, 0xb475f255'u32, 0x46fcd9b9'u32,
     0x7aeb2661'u32, 0x8b1ddf84'u32, 0x846a0e79'u32, 0x915f95e2'u32, 0x466e598e'u32, 0x20b45770'u32, 0x8cd55591'u32, 0xc902de4c'u32,
     0xb90bace1'u32, 0xbb8205d0'u32, 0x11a86248'u32, 0x7574a99e'u32, 0xb77f19b6'u32, 0xe0a9dc09'u32, 0x662d09a1'u32, 0xc4324633'u32,
     0xe85a1f02'u32, 0x09f0be8c'u32, 0x4a99a025'u32, 0x1d6efe10'u32, 0x1ab93d1d'u32, 0x0ba5a4df'u32, 0xa186f20f'u32, 0x2868f169'u32,
     0xdcb7da83'u32, 0x573906fe'u32, 0xa1e2ce9b'u32, 0x4fcd7f52'u32, 0x50115e01'u32, 0xa70683fa'u32, 0xa002b5c4'u32, 0x0de6d027'u32,
     0x9af88c27'u32, 0x773f8641'u32, 0xc3604c06'u32, 0x61a806b5'u32, 0xf0177a28'u32, 0xc0f586e0'u32, 0x006058aa'u32, 0x30dc7d62'u32,
     0x11e69ed7'u32, 0x2338ea63'u32, 0x53c2dd94'u32, 0xc2c21634'u32, 0xbbcbee56'u32, 0x90bcb6de'u32, 0xebfc7da1'u32, 0xce591d76'u32,
     0x6f05e409'u32, 0x4b7c0188'u32, 0x39720a3d'u32, 0x7c927c24'u32, 0x86e3725f'u32, 0x724d9db9'u32, 0x1ac15bb4'u32, 0xd39eb8fc'u32,
     0xed545578'u32, 0x08fca5b5'u32, 0xd83d7cd3'u32, 0x4dad0fc4'u32, 0x1e50ef5e'u32, 0xb161e6f8'u32, 0xa28514d9'u32, 0x6c51133c'u32,
     0x6fd5c7e7'u32, 0x56e14ec4'u32, 0x362abfce'u32, 0xddc6c837'u32, 0xd79a3234'u32, 0x92638212'u32, 0x670efa8e'u32, 0x406000e0'u32],
    [0x3a39ce37'u32, 0xd3faf5cf'u32, 0xabc27737'u32, 0x5ac52d1b'u32, 0x5cb0679e'u32, 0x4fa33742'u32, 0xd3822740'u32, 0x99bc9bbe'u32,
     0xd5118e9d'u32, 0xbf0f7315'u32, 0xd62d1c7e'u32, 0xc700c47b'u32, 0xb78c1b6b'u32, 0x21a19045'u32, 0xb26eb1be'u32, 0x6a366eb4'u32,
     0x5748ab2f'u32, 0xbc946e79'u32, 0xc6a376d2'u32, 0x6549c2c8'u32, 0x530ff8ee'u32, 0x468dde7d'u32, 0xd5730a1d'u32, 0x4cd04dc6'u32,
     0x2939bbdb'u32, 0xa9ba4650'u32, 0xac9526e8'u32, 0xbe5ee304'u32, 0xa1fad5f0'u32, 0x6a2d519a'u32, 0x63ef8ce2'u32, 0x9a86ee22'u32,
     0xc089c2b8'u32, 0x43242ef6'u32, 0xa51e03aa'u32, 0x9cf2d0a4'u32, 0x83c061ba'u32, 0x9be96a4d'u32, 0x8fe51550'u32, 0xba645bd6'u32,
     0x2826a2f9'u32, 0xa73a3ae1'u32, 0x4ba99586'u32, 0xef5562e9'u32, 0xc72fefd3'u32, 0xf752f7da'u32, 0x3f046f69'u32, 0x77fa0a59'u32,
     0x80e4a915'u32, 0x87b08601'u32, 0x9b09e6ad'u32, 0x3b3ee593'u32, 0xe990fd5a'u32, 0x9e34d797'u32, 0x2cf0b7d9'u32, 0x022b8b51'u32,
     0x96d5ac3a'u32, 0x017da67d'u32, 0xd1cf3ed6'u32, 0x7c7d2d28'u32, 0x1f9f25cf'u32, 0xadf2b89b'u32, 0x5ad6b472'u32, 0x5a88f54c'u32,
     0xe029ac71'u32, 0xe019a5e6'u32, 0x47b0acfd'u32, 0xed93fa9b'u32, 0xe8d3c48d'u32, 0x283b57cc'u32, 0xf8d56629'u32, 0x79132e28'u32,
     0x785f0191'u32, 0xed756055'u32, 0xf7960e44'u32, 0xe3d35e8c'u32, 0x15056dd4'u32, 0x88f46dba'u32, 0x03a16125'u32, 0x0564f0bd'u32,
     0xc3eb9e15'u32, 0x3c9057a2'u32, 0x97271aec'u32, 0xa93a072a'u32, 0x1b3f6d9b'u32, 0x1e6321f5'u32, 0xf59c66fb'u32, 0x26dcf319'u32,
     0x7533d928'u32, 0xb155fdf5'u32, 0x03563482'u32, 0x8aba3cbb'u32, 0x28517711'u32, 0xc20ad9f8'u32, 0xabcc5167'u32, 0xccad925f'u32,
     0x4de81751'u32, 0x3830dc8e'u32, 0x379d5862'u32, 0x9320f991'u32, 0xea7a90c2'u32, 0xfb3e7bce'u32, 0x5121ce64'u32, 0x774fbe32'u32,
     0xa8b6e37e'u32, 0xc3293d46'u32, 0x48de5369'u32, 0x6413e680'u32, 0xa2ae0810'u32, 0xdd6db224'u32, 0x69852dfd'u32, 0x09072166'u32,
     0xb39a460a'u32, 0x6445c0dd'u32, 0x586cdecf'u32, 0x1c20c8ae'u32, 0x5bbef7dd'u32, 0x1b588d40'u32, 0xccd2017f'u32, 0x6bb4e3bb'u32,
     0xdda26a7e'u32, 0x3a59ff45'u32, 0x3e350a44'u32, 0xbcb4cdd5'u32, 0x72eacea8'u32, 0xfa6484bb'u32, 0x8d6612ae'u32, 0xbf3c6f47'u32,
     0xd29be463'u32, 0x542f5d9e'u32, 0xaec2771b'u32, 0xf64e6370'u32, 0x740e0d8d'u32, 0xe75b1357'u32, 0xf8721671'u32, 0xaf537d5d'u32,
     0x4040cb08'u32, 0x4eb4e2cc'u32, 0x34d2466a'u32, 0x0115af84'u32, 0xe1b00428'u32, 0x95983a1d'u32, 0x06b89fb4'u32, 0xce6ea048'u32,
     0x6f3f3b82'u32, 0x3520ab82'u32, 0x011a1d4b'u32, 0x277227f8'u32, 0x611560b1'u32, 0xe7933fdc'u32, 0xbb3a792b'u32, 0x344525bd'u32,
     0xa08839e1'u32, 0x51ce794b'u32, 0x2f32c9b7'u32, 0xa01fbac9'u32, 0xe01cc87e'u32, 0xbcc7d1f6'u32, 0xcf0111c3'u32, 0xa1e8aac7'u32,
     0x1a908749'u32, 0xd44fbd9a'u32, 0xd0dadecb'u32, 0xd50ada38'u32, 0x0339c32a'u32, 0xc6913667'u32, 0x8df9317c'u32, 0xe0b12b4f'u32,
     0xf79e59b7'u32, 0x43f5bb3a'u32, 0xf2d519ff'u32, 0x27d9459c'u32, 0xbf97222c'u32, 0x15e6fc2a'u32, 0x0f91fc71'u32, 0x9b941525'u32,
     0xfae59361'u32, 0xceb69ceb'u32, 0xc2a86459'u32, 0x12baa8d1'u32, 0xb6c1075e'u32, 0xe3056a0c'u32, 0x10d25065'u32, 0xcb03a442'u32,
     0xe0ec6e0e'u32, 0x1698db3b'u32, 0x4c98a0be'u32, 0x3278e964'u32, 0x9f1f9532'u32, 0xe0d392df'u32, 0xd3a0342b'u32, 0x8971f21e'u32,
     0x1b0a7441'u32, 0x4ba3348c'u32, 0xc5be7120'u32, 0xc37632d8'u32, 0xdf359f8d'u32, 0x9b992f2e'u32, 0xe60b6f47'u32, 0x0fe3f11d'u32,
     0xe54cda54'u32, 0x1edad891'u32, 0xce6279cf'u32, 0xcd3e7e6f'u32, 0x1618b166'u32, 0xfd2c1d05'u32, 0x848fd2c5'u32, 0xf6fb2299'u32,
     0xf523f357'u32, 0xa6327623'u32, 0x93a83531'u32, 0x56cccd02'u32, 0xacf08162'u32, 0x5a75ebb5'u32, 0x6e163697'u32, 0x88d273cc'u32,
     0xde966292'u32, 0x81b949d0'u32, 0x4c50901b'u32, 0x71c65614'u32, 0xe6c6c7bd'u32, 0x327a140a'u32, 0x45e1d006'u32, 0xc3f27b9a'u32,
     0xc9aa53fd'u32, 0x62a80f00'u32, 0xbb25bfe2'u32, 0x35bdd2f6'u32, 0x71126905'u32, 0xb2040222'u32, 0xb6cbcf7c'u32, 0xcd769c2b'u32,
     0x53113ec0'u32, 0x1640e3d3'u32, 0x38abbd60'u32, 0x2547adf0'u32, 0xba38209c'u32, 0xf746ce76'u32, 0x77afa1c5'u32, 0x20756060'u32,
     0x85cbfe4e'u32, 0x8ae88dd8'u32, 0x7aaaf9b0'u32, 0x4cf9aa7e'u32, 0x1948c25c'u32, 0x02fb8a8c'u32, 0x01c36ae4'u32, 0xd6ebe1f9'u32,
     0x90d4f869'u32, 0xa65cdea0'u32, 0x3f09252d'u32, 0xc208e69f'u32, 0xb74e6132'u32, 0xce77e25b'u32, 0x578fdfe3'u32, 0x3ac372e6'u32]
  ]

  nullSalt = [0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8]

type
  CostFactor* = range[4..31]
    ## Adjustable cost factor. The value is a logarithm of 2, which means that
    ## a cost of 5 is twice as expensive as a cost of 4, and a cost of 16 is 2048
    ## times more expensive than a cost of 5.

  SaltBytes = array[16, uint8]
  HashBytes = array[24, uint8]

  Salt* = object
    ## A random 128 bit salt used to provide security against rainbow table attacks
    ## that also includes the bcrypt version and cost factor.
    costFactor*: CostFactor
    saltBytes: SaltBytes
    subversion: char

  Hash* = distinct HashBytes
    ## A 192 bit hash value produced by the `bcrypt` function.

  SaltedHash* = tuple
    salt: Salt
    hash: Hash

  BlowfishState = object
    # S-Boxes
    s: array[4, array[256, uint32]]

    # Subkeys
    p: array[18, uint32]


# Bcrypt base64 implementation. Unfortunately, the dialect of base64 is dissimilar
# enough from standard base64 to be used with our base64 module but similar enough
# to tempt one to modify our base64 module to use it. Since it's specific to Bcrypt,
# or rather, crypt, it doesn't really make sense to modify std/base64 for it.
const
  bcryptAlphabet = "./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

  lookup = [
    0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8,
    0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8,
    0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8,
    0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8,
    0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8,
    0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0x00'u8, 0x01'u8,
    0x36'u8, 0x37'u8, 0x38'u8, 0x39'u8, 0x3a'u8, 0x3b'u8, 0x3c'u8, 0x3d'u8,
    0x3e'u8, 0x3f'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8,
    0xff'u8, 0x02'u8, 0x03'u8, 0x04'u8, 0x05'u8, 0x06'u8, 0x07'u8, 0x08'u8,
    0x09'u8, 0x0a'u8, 0x0b'u8, 0x0c'u8, 0x0d'u8, 0x0e'u8, 0x0f'u8, 0x10'u8,
    0x11'u8, 0x12'u8, 0x13'u8, 0x14'u8, 0x15'u8, 0x16'u8, 0x17'u8, 0x18'u8,
    0x19'u8, 0x1a'u8, 0x1b'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8,
    0xff'u8, 0x1c'u8, 0x1d'u8, 0x1e'u8, 0x1f'u8, 0x20'u8, 0x21'u8, 0x22'u8,
    0x23'u8, 0x24'u8, 0x25'u8, 0x26'u8, 0x27'u8, 0x28'u8, 0x29'u8, 0x2a'u8,
    0x2b'u8, 0x2c'u8, 0x2d'u8, 0x2e'u8, 0x2f'u8, 0x30'u8, 0x31'u8, 0x32'u8,
    0x33'u8, 0x34'u8, 0x35'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8, 0xff'u8
  ]

template c(b64: char): uint8 =
  if b64 > 0x7f.char:
    0xff'u8
  else:
    lookup[b64.int]

func decodeBcrypt64(data: openArray[char], dest: var openArray[uint8]) =
  # It'd probably be a good idea to check dest.len occasionally just for
  # correctness, but we only use it internally where we control the buffer
  # sizes.
  var i = 0

  for offset in countup(0, data.len, 4):
    let c1 = c(data[offset])
    let c2 = c(data[offset + 1])

    dest[i] = (c1 shl 2) or ((c2 and 0x30) shr 4)
    inc i

    if offset + 3 >= data.len:
      break

    let c3 = c(data[offset + 2])
    let c4 = c(data[offset + 3])

    dest[i] = ((c2 and 0x0f) shl 4) or ((c3 and 0x3c) shr 2)
    inc i

    dest[i] = (c3 and 0x03) shl 6 or c4
    inc i

proc encodeBcrypt64(data: openArray[uint8]): string =
  # There's more "efficient" ways of doing this that involve lese
  # repeating ourselves, but this is quite easy to understand.
  for offset in countup(0, high(data), 3):
    let c1 = data[offset]

    result &= bcryptAlphabet[c1 shr 2]

    if offset + 1 >= data.len:
      result &= bcryptAlphabet[(c1 and 0x03) shl 4]
    elif offset + 2 >= data.len:
      let c2 = data[offset + 1]

      result &= bcryptAlphabet[(c1 and 0x03) shl 4 or ((c2 shr 4) and 0x0f)]
      result &= bcryptAlphabet[(c2 and 0x0f) shl 2]
    else:
      let c2 = data[offset + 1]
      let c3 = data[offset + 2]

      result &= bcryptAlphabet[(c1 and 0x03) shl 4 or ((c2 shr 4) and 0x0f)]
      result &= bcryptAlphabet[((c2 and 0x0f) shl 2) or ((c3 shr 6) and 0x03)]
      result &= bcryptAlphabet[c3 and 0x3f]

proc `$`*(s: Salt): string =
  ## Renders the given `Salt` into the canonical bcrypt-type Base64 representation
  ## along with its version and cost factor information.
  result = "$2" & s.subversion & "$" & ($s.costFactor).align(2, '0') & '$' & encodeBcrypt64(s.saltBytes)[0..<22]

proc `$`*(s: Hash): string =
  ## Renders the given `Hash` into the canonical bcrypt-type Base64 representation.
  encodeBcrypt64(HashBytes(s)[0..^2]) # Bcrypt only displays 23 of its hash bytes.

proc `$`*(s: SaltedHash): string =
  ## Renders the given `SaltedHash` into the canonical bcrypt-type Base64 representation
  ## resulting in the actual hash string to be stored.
  $s.salt & $s.hash


proc perturb(ctx: BlowfishState; x: uint32): uint32 {.inline.} =
  ((ctx.s[0][((x shr 24) and 0xff)] +
    ctx.s[1][((x shr 16) and 0xff)]) xor
    ctx.s[2][((x shr 8)  and 0xff)]) +
    ctx.s[3][ (x         and 0xff)]

proc encrypt(ctx: var BlowfishState; l, r: var uint32) =
  var xl = l
  var xr = r

  xl = xl xor ctx.p[0]

  for n in countup(1, 15, 2):
    xr = xr xor ctx.perturb(xl) xor ctx.p[n]
    xl = xl xor ctx.perturb(xr) xor ctx.p[n + 1]

  l = xr xor ctx.p[17]
  r = xl

proc wordFromStream(stream: openArray[uint8]; offset: var int; pad0: bool = false): uint32 =
  for i in 0..<4:
    if offset >= stream.len:
      offset = 0

    result = (result shl 8) or stream[offset].uint8
    inc offset

  if pad0:
    echo result.toHex(8)

proc expandKeyBcrypt(ctx: var BlowfishState;
    salt: SaltBytes;
    password: openArray[uint8]) =
  ## More expensive key expansion variant for Bcrypt
  var offset = 0

  for n in 0..<18:
    ctx.p[n] = ctx.p[n] xor wordFromStream(password, offset)

  offset = 0

  var blockL = 0'u32
  var blockR = 0'u32

  for n in countup(0, 17, 2):
    blockL = blockL xor wordFromStream(salt, offset)
    blockR = blockR xor wordFromStream(salt, offset)

    ctx.encrypt(blockL, blockR)

    ctx.p[n]     = blockL
    ctx.p[n + 1] = blockR

  for i in 0..<4:
    for k in countup(0, 255, 2):
      blockL = blockL xor wordFromStream(salt, offset)
      blockR = blockR xor wordFromStream(salt, offset)

      ctx.encrypt(blockL, blockR)

      ctx.s[i][k]     = blockL
      ctx.s[i][k + 1] = blockR

proc initBcryptState(salt: Salt; password: openArray[uint8]): BlowfishState =
  result = BlowfishState(s: sboxesInit, p: subkeysInit)
  result.expandKeyBcrypt(salt.saltBytes, password)

  for i in 0..<(1 shl salt.costFactor):
    result.expandKeyBcrypt(nullSalt, password)
    result.expandKeyBcrypt(nullSalt, salt.saltBytes)

proc parseSalt*(salt: string): Salt {.raises: ValueError.} =
  ## Parses a `Salt` from the given string (which may be a full bcrypt hash or only the preamble).
  ##
  ## It accepts the `2a`, `2b` and `2y` subversions.
  runnableExamples:
    # Parse full hash
    let salt1 = parseSalt "$2b$06$LzUyyYdKBoEy9V4NTvxDH."

    # Parse salt part
    let salt2 = parseSalt "$2b$06$LzUyyYdKBoEy9V4NTvxDH.PvwrAArbP0DUvDUFf8ChnJl6/79lh3C"

    assert $salt1 == "$2b$06$LzUyyYdKBoEy9V4NTvxDH."
    assert $salt2 == "$2b$06$LzUyyYdKBoEy9V4NTvxDH."

  let segments = salt.split('$')

  case segments[1]
    # 2a = older OpenBSD with wraparound length issue (not recognized)
    # 2b = fixed and current OpenBSD version
    # 2x = PHP exclusive marker for broken crypt_blowfish generated "2a" hashes (not recognized)
    # 2y = PHP exclusive marker for fixed crypt_blowfish generated "2a" hashes
    of "2a", "2b", "2y":
      discard

    else:
      raise newException(ValueError, "bad bcrypt salt version " & segments[1])

  let costFactor = parseInt segments[2]

  if costFactor < 4 or costFactor > 31:
    raise newException(ValueError, "bad bcrypt salt cost factor " & segments[2])
  elif segments[3].len < 22:
    raise newException(ValueError, "bad bcrypt salt length")

  # We only want the salt but we may have been passed a full salted hash
  segments[3][0..<22].decodeBcrypt64(result.saltBytes)

  result.subversion = segments[1][1]
  result.costFactor = costFactor

proc generateSalt*(cost: CostFactor): Salt {.raises: ResourceExhaustedError.} =
  ## Generates a new, random salt with the provided `CostFactor`. Only salts with
  ## subversion `2b` are generated since it's the newest and default version of the
  ## reference bcrypt implementation.

  var randBytes: array[16, uint8]

  # XXX: OSError? IOError?
  if not urandom(randBytes):
    raise newException(ResourceExhaustedError, "Unable to retrieve enough randomness for salt")

  result.costFactor = cost
  result.saltBytes = randBytes
  result.subversion = 'b'

proc bcrypt*(password: openArray[char]; salt: Salt): SaltedHash =
  ## Produces a `SaltedHash` from the given password string and salt.
  ##
  ## Be careful when accepting a salt from a source outside of your control
  ## as a malicious user could pass in salts with a very high cost factor, resulting
  ## in denial of service attack.
  runnableExamples:
    let hashed = bcrypt("correct horse battery stape", generateSalt(8))

  var passwordNul: array[72, uint8]
  var actLen: int

  if salt.subversion in {'b', 'y'}:
    actLen = min(72, password.len)
  else:
    # Replicate the OpenBSD uint8_t truncation bug
    actLen = (password.len) mod 256

  when defined(js):
    for i in 0..<actLen:
      passwordNul[i] = password[i].uint8
  else:
    copyMem(addr passwordNul[0], addr password[0], actLen)

  if actLen != 72:
    passwordNul[actLen] = 0x00

  var ctx = initBcryptState(salt, passwordNul[0..actLen])
  var offset = 0

  var cipherText = cryptBlocksInit
  var cipher: array[6, uint32]

  for i in 0..<6:
    cipher[i] = wordFromStream(cipherText, offset)

  for i in 0..<64:
    for j in 0..<3:
      ctx.encrypt(cipher[j*2], cipher[j*2 + 1])

  for i in 0..<6:
    ciphertext[4 * i + 3] = cipher[i].uint8 and 0xff'u8
    cipher[i] = cipher[i] shr 8
    ciphertext[4 * i + 2] = cipher[i].uint8 and 0xff'u8
    cipher[i] = cipher[i] shr 8
    ciphertext[4 * i + 1] = cipher[i].uint8 and 0xff'u8
    cipher[i] = cipher[i] shr 8
    ciphertext[4 * i + 0] = cipher[i].uint8 and 0xff'u8

  result.salt = salt

  when defined(js):
    for i in 0..<24:
      HashBytes(result.hash)[i] = ciphertext[i]
  else:
    copyMem(addr HashBytes(result.hash)[0], addr ciphertext[0], 24)

proc verify*(password: openArray[char]; knownGood: string): bool =
  ## Verifies a given plaintext password against a hash from a known good source
  ## such as a database or other data storage.
  ##
  ## Be careful when accepting a hash from a source outside of your control
  ## as a malicious user could pass salts with a very high cost factor, resulting
  ## in denial of service attack.
  runnableExamples:
    let knownGood = "$2b$06$LzUyyYdKBoEy9V4NTvxDH.O11KQP30/Zyp5pQAQ.0Cy89WnkD5Jjy"

    assert verify("correct horse battery staple", knownGood)

  # Extract the originally used salt from our known good source and rehash
  # the password with it. If it comes out the same, the password matches
  # the known good hash.
  let reclaimedHash = bcrypt(password, parseSalt(knownGood))

  $reclaimedHash == knownGood
