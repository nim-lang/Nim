# This file was created from a script.

const
  wideSinglets = [
    0x02329,
    0x0232A,
    0x023F0,
    0x023F3,
    0x0267F,
    0x02693,
    0x026A1,
    0x026CE,
    0x026D4,
    0x026EA,
    0x026F5,
    0x026FA,
    0x026FD,
    0x02705,
    0x02728,
    0x0274C,
    0x0274E,
    0x02757,
    0x027B0,
    0x027BF,
    0x02B50,
    0x02B55,
    0x03000,
    0x03004,
    0x03005,
    0x03006,
    0x03007,
    0x03008,
    0x03009,
    0x0300A,
    0x0300B,
    0x0300C,
    0x0300D,
    0x0300E,
    0x0300F,
    0x03010,
    0x03011,
    0x03014,
    0x03015,
    0x03016,
    0x03017,
    0x03018,
    0x03019,
    0x0301A,
    0x0301B,
    0x0301C,
    0x0301D,
    0x03020,
    0x03030,
    0x0303B,
    0x0303C,
    0x0303D,
    0x0303E,
    0x0309F,
    0x030A0,
    0x030FB,
    0x030FF,
    0x03250,
    0x0A015,
    0x0FE17,
    0x0FE18,
    0x0FE19,
    0x0FE30,
    0x0FE35,
    0x0FE36,
    0x0FE37,
    0x0FE38,
    0x0FE39,
    0x0FE3A,
    0x0FE3B,
    0x0FE3C,
    0x0FE3D,
    0x0FE3E,
    0x0FE3F,
    0x0FE40,
    0x0FE41,
    0x0FE42,
    0x0FE43,
    0x0FE44,
    0x0FE47,
    0x0FE48,
    0x0FE58,
    0x0FE59,
    0x0FE5A,
    0x0FE5B,
    0x0FE5C,
    0x0FE5D,
    0x0FE5E,
    0x0FE62,
    0x0FE63,
    0x0FE68,
    0x0FE69,
    0x0FF04,
    0x0FF08,
    0x0FF09,
    0x0FF0A,
    0x0FF0B,
    0x0FF0C,
    0x0FF0D,
    0x0FF3B,
    0x0FF3C,
    0x0FF3D,
    0x0FF3E,
    0x0FF3F,
    0x0FF40,
    0x0FF5B,
    0x0FF5C,
    0x0FF5D,
    0x0FF5E,
    0x0FF5F,
    0x0FF60,
    0x0FFE2,
    0x0FFE3,
    0x0FFE4,
    0x16FE2,
    0x16FE3,
    0x1F004,
    0x1F0CF,
    0x1F18E,
    0x1F3F4,
    0x1F440,
    0x1F57A,
    0x1F5A4,
    0x1F6CC,
    0x1F6D5,
  ]

  wideRanges = [
    0x01100, 0x0115F,
    0x0231A, 0x0231B,
    0x023E9, 0x023EC,
    0x025FD, 0x025FE,
    0x02614, 0x02615,
    0x02648, 0x02653,
    0x026AA, 0x026AB,
    0x026BD, 0x026BE,
    0x026C4, 0x026C5,
    0x026F2, 0x026F3,
    0x0270A, 0x0270B,
    0x02753, 0x02755,
    0x02795, 0x02797,
    0x02B1B, 0x02B1C,
    0x02E80, 0x02E99,
    0x02E9B, 0x02EF3,
    0x02F00, 0x02FD5,
    0x02FF0, 0x02FFB,
    0x03001, 0x03003,
    0x03012, 0x03013,
    0x0301E, 0x0301F,
    0x03021, 0x03029,
    0x0302A, 0x0302D,
    0x0302E, 0x0302F,
    0x03031, 0x03035,
    0x03036, 0x03037,
    0x03038, 0x0303A,
    0x03041, 0x03096,
    0x03099, 0x0309A,
    0x0309B, 0x0309C,
    0x0309D, 0x0309E,
    0x030A1, 0x030FA,
    0x030FC, 0x030FE,
    0x03105, 0x0312F,
    0x03131, 0x0318E,
    0x03190, 0x03191,
    0x03192, 0x03195,
    0x03196, 0x0319F,
    0x031A0, 0x031BA,
    0x031C0, 0x031E3,
    0x031F0, 0x031FF,
    0x03200, 0x0321E,
    0x03220, 0x03229,
    0x0322A, 0x03247,
    0x03251, 0x0325F,
    0x03260, 0x0327F,
    0x03280, 0x03289,
    0x0328A, 0x032B0,
    0x032B1, 0x032BF,
    0x032C0, 0x032FF,
    0x03300, 0x033FF,
    0x03400, 0x04DB5,
    0x04DB6, 0x04DBF,
    0x04E00, 0x09FEF,
    0x09FF0, 0x09FFF,
    0x0A000, 0x0A014,
    0x0A016, 0x0A48C,
    0x0A490, 0x0A4C6,
    0x0A960, 0x0A97C,
    0x0AC00, 0x0D7A3,
    0x0F900, 0x0FA6D,
    0x0FA6E, 0x0FA6F,
    0x0FA70, 0x0FAD9,
    0x0FADA, 0x0FAFF,
    0x0FE10, 0x0FE16,
    0x0FE31, 0x0FE32,
    0x0FE33, 0x0FE34,
    0x0FE45, 0x0FE46,
    0x0FE49, 0x0FE4C,
    0x0FE4D, 0x0FE4F,
    0x0FE50, 0x0FE52,
    0x0FE54, 0x0FE57,
    0x0FE5F, 0x0FE61,
    0x0FE64, 0x0FE66,
    0x0FE6A, 0x0FE6B,
    0x0FF01, 0x0FF03,
    0x0FF05, 0x0FF07,
    0x0FF0E, 0x0FF0F,
    0x0FF10, 0x0FF19,
    0x0FF1A, 0x0FF1B,
    0x0FF1C, 0x0FF1E,
    0x0FF1F, 0x0FF20,
    0x0FF21, 0x0FF3A,
    0x0FF41, 0x0FF5A,
    0x0FFE0, 0x0FFE1,
    0x0FFE5, 0x0FFE6,
    0x16FE0, 0x16FE1,
    0x17000, 0x187F7,
    0x18800, 0x18AF2,
    0x1B000, 0x1B0FF,
    0x1B100, 0x1B11E,
    0x1B150, 0x1B152,
    0x1B164, 0x1B167,
    0x1B170, 0x1B2FB,
    0x1F191, 0x1F19A,
    0x1F200, 0x1F202,
    0x1F210, 0x1F23B,
    0x1F240, 0x1F248,
    0x1F250, 0x1F251,
    0x1F260, 0x1F265,
    0x1F300, 0x1F320,
    0x1F32D, 0x1F335,
    0x1F337, 0x1F37C,
    0x1F37E, 0x1F393,
    0x1F3A0, 0x1F3CA,
    0x1F3CF, 0x1F3D3,
    0x1F3E0, 0x1F3F0,
    0x1F3F8, 0x1F3FA,
    0x1F3FB, 0x1F3FF,
    0x1F400, 0x1F43E,
    0x1F442, 0x1F4FC,
    0x1F4FF, 0x1F53D,
    0x1F54B, 0x1F54E,
    0x1F550, 0x1F567,
    0x1F595, 0x1F596,
    0x1F5FB, 0x1F5FF,
    0x1F600, 0x1F64F,
    0x1F680, 0x1F6C5,
    0x1F6D0, 0x1F6D2,
    0x1F6EB, 0x1F6EC,
    0x1F6F4, 0x1F6FA,
    0x1F7E0, 0x1F7EB,
    0x1F90D, 0x1F971,
    0x1F973, 0x1F976,
    0x1F97A, 0x1F9A2,
    0x1F9A5, 0x1F9AA,
    0x1F9AE, 0x1F9CA,
    0x1F9CD, 0x1F9FF,
    0x1FA70, 0x1FA73,
    0x1FA78, 0x1FA7A,
    0x1FA80, 0x1FA82,
    0x1FA90, 0x1FA95,
    0x20000, 0x2A6D6,
    0x2A6D7, 0x2A6FF,
    0x2A700, 0x2B734,
    0x2B735, 0x2B73F,
    0x2B740, 0x2B81D,
    0x2B81E, 0x2B81F,
    0x2B820, 0x2CEA1,
    0x2CEA2, 0x2CEAF,
    0x2CEB0, 0x2EBE0,
    0x2EBE1, 0x2F7FF,
    0x2F800, 0x2FA1D,
    0x2FA1E, 0x2FA1F,
    0x2FA20, 0x2FFFD,
    0x30000, 0x3FFFD,
  ]

  combiningChars = [0x00300, 0x0036F]
