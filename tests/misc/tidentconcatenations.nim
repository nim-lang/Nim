type
  Hash*[bits: static[int]] = object
    data*: array[bits div 8, uint8]

{.emit: """

void sha_256(void* input, int input_len, void* output, int output_len) {}
void sha_512(void* input, int input_len, void* output, int output_len) {}

void keccak_256(void* input, int input_len, void* output, int output_len) {}
void keccak_512(void* input, int input_len, void* output, int output_len) {}

""".}

template defineKeccak(bits: untyped) =
  proc `extKeccak bits`(output: pointer, outSize: csize_t, input: pointer, inputSize: csize_t) {.nodecl, importc: "keccak_" & astToStr(bits).}

template defineSha(bits: static[int]) =
  proc `extSha bits`(output: pointer, outSize: csize_t, input: pointer, inputSize: csize_t) {.nodecl, importc: "sha_" & astToStr(bits).}

template defineHashProcs(bits) =
  defineSha(bits)
  defineKeccak(bits)

defineHashProcs(256)
defineHashProcs(512)

extSha256(nil, 0, nil, 0)
extSha512(nil, 0, nil, 0)
extKeccak256(nil, 0, nil, 0)
extKeccak512(nil, 0, nil, 0)
