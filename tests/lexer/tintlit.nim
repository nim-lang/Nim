proc test(x: uint32) =
    var
      myuint: uint32

    #fixes issue #5858
    myuint = 0xFFFF_FFFF
    myuint = 0x7FFF_FFFF
    myuint = (0x7FFF_FFFF + 1)
    myuint = 0x8000_0000

test(0xFFFF_FFFF)

static:
    test(0xFFFF_FFFF)
