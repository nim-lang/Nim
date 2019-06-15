#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a `reStructuredText`:idx: parser. A large
## subset is implemented. Some features of the `markdown`:idx: wiki syntax are
## also supported.
##
## **Note:** Import ``packages/docutils/rst`` to use this module

import
  os, strutils, rstast

type
  RstParseOption* = enum     ## options for the RST parser
    roSkipPounds,             ## skip ``#`` at line beginning (documentation
                              ## embedded in Nim comments)
    roSupportSmilies,         ## make the RST parser support smilies like ``:)``
    roSupportRawDirective,    ## support the ``raw`` directive (don't support
                              ## it for sandboxing)
    roSupportMarkdown         ## support additional features of markdown

  RstParseOptions* = set[RstParseOption]

  MsgClass* = enum
    mcHint = "Hint",
    mcWarning = "Warning",
    mcError = "Error"

  MsgKind* = enum          ## the possible messages
    meCannotOpenFile,
    meExpected,
    meGridTableNotImplemented,
    meNewSectionExpected,
    meGeneralParseError,
    meInvalidDirective,
    mwRedefinitionOfLabel,
    mwUnknownSubstitution,
    mwUnsupportedLanguage,
    mwUnsupportedField

  MsgHandler* = proc (filename: string, line, col: int, msgKind: MsgKind,
                       arg: string) {.closure, gcsafe.} ## what to do in case of an error
  FindFileHandler* = proc (filename: string): string {.closure, gcsafe.}

const
  messages: array[MsgKind, string] = [
    meCannotOpenFile: "cannot open '$1'",
    meExpected: "'$1' expected",
    meGridTableNotImplemented: "grid table is not implemented",
    meNewSectionExpected: "new section expected",
    meGeneralParseError: "general parse error",
    meInvalidDirective: "invalid directive: '$1'",
    mwRedefinitionOfLabel: "redefinition of label '$1'",
    mwUnknownSubstitution: "unknown substitution '$1'",
    mwUnsupportedLanguage: "language '$1' not supported",
    mwUnsupportedField: "field '$1' not supported"
  ]

proc rstnodeToRefname*(n: PRstNode): string
proc addNodes*(n: PRstNode): string
proc getFieldValue*(n: PRstNode, fieldname: string): string
proc getArgument*(n: PRstNode): string

# ----------------------------- scanner part --------------------------------

const
  SymChars: set[char] = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF'}
  SmileyStartChars: set[char] = {':', ';', '8'}
  Smilies = {
    ":D": "icon_e_biggrin",
    ":-D": "icon_e_biggrin",
    ":)": "icon_e_smile",
    ":-)": "icon_e_smile",
    ";)": "icon_e_wink",
    ";-)": "icon_e_wink",
    ":(": "icon_e_sad",
    ":-(": "icon_e_sad",
    ":o": "icon_e_surprised",
    ":-o": "icon_e_surprised",
    ":shock:": "icon_eek",
    ":?": "icon_e_confused",
    ":-?": "icon_e_confused",
    ":-/": "icon_e_confused",

    "8-)": "icon_cool",

    ":lol:": "icon_lol",
    ":x": "icon_mad",
    ":-x": "icon_mad",
    ":P": "icon_razz",
    ":-P": "icon_razz",
    ":oops:": "icon_redface",
    ":cry:": "icon_cry",
    ":evil:": "icon_evil",
    ":twisted:": "icon_twisted",
    ":roll:": "icon_rolleyes",
    ":!:": "icon_exclaim",

    ":?:": "icon_question",
    ":idea:": "icon_idea",
    ":arrow:": "icon_arrow",
    ":|": "icon_neutral",
    ":-|": "icon_neutral",
    ":mrgreen:": "icon_mrgreen",
    ":geek:": "icon_e_geek",
    ":ugeek:": "icon_e_ugeek",

    # Unicode Standard Emoji http://unicode.org/emoji/charts/full-emoji-list.html
    ":orange_heart:": "icon_orange_heart", # v10  \u1f9e1
    ":yellow_heart:": "icon_yellow_heart", # v6  \u1f49b
    ":green_heart:": "icon_green_heart", # v6  \u1f49a
    ":blue_heart:": "icon_blue_heart", # v6  \u1f499
    ":purple_heart:": "icon_purple_heart", # v6  \u1f49c
    ":black_heart:": "icon_black_heart", # v9  \u1f5a4
    ":broken_heart:": "icon_broken_heart", # v6  \u1f494
    ":two_hearts:": "icon_two_hearts", # v6  \u1f495
    ":revolving_hearts:": "icon_revolving_hearts", # v6  \u1f49e
    ":heartbeat:": "icon_heartbeat", # v6  \u1f493
    ":heartpulse:": "icon_heartpulse", # v6  \u1f497
    ":sparkling_heart:": "icon_sparkling_heart", # v6  \u1f496
    ":cupid:": "icon_cupid", # v6  \u1f498
    ":gift_heart:": "icon_gift_heart", # v6  \u1f49d
    ":heart_decoration:": "icon_heart_decoration", # v6  \u1f49f
    ":om_symbol:": "icon_om_symbol", # v7  \u1f549
    ":six_pointed_star:": "icon_six_pointed_star", # v6  \u1f52f
    ":menorah:": "icon_menorah", # v8  \u1f54e
    ":place_of_worship:": "icon_place_of_worship", # v8  \u1f6d0
    ":accept:": "icon_accept", # v6  \u1f251
    ":mobile_phone_off:": "icon_mobile_phone_off", # v6  \u1f4f4
    ":vibration_mode:": "icon_vibration_mode", # v6  \u1f4f3
    ":u6709:": "icon_u6709", # v6  \u1f236
    ":u7121:": "icon_u7121", # v5.2  \u1f21a
    ":u7533:": "icon_u7533", # v6  \u1f238
    ":u55b6:": "icon_u55b6", # v6  \u1f23a
    ":u6708:": "icon_u6708", # v6  \u1f237
    ":white_flower:": "icon_white_flower", # v6  \u1f4ae
    ":ideograph_advantage:": "icon_ideograph_advantage", # v6  \u1f250
    ":u5408:": "icon_u5408", # v6  \u1f234
    ":u6e80:": "icon_u6e80", # v6  \u1f235
    ":u5272:": "icon_u5272", # v6  \u1f239
    ":u7981:": "icon_u7981", # v6  \u1f232
    ":octagonal_sign:": "icon_octagonal_sign", # v9  \u1f6d1
    ":name_badge:": "icon_name_badge", # v6  \u1f4db
    ":no_entry_sign:": "icon_no_entry_sign", # v6  \u1f6ab
    ":anger:": "icon_anger", # v6  \u1f4a2
    ":no_pedestrians:": "icon_no_pedestrians", # v6  \u1f6b7
    ":do_not_litter:": "icon_do_not_litter", # v6  \u1f6af
    ":no_bicycles:": "icon_no_bicycles", # v6  \u1f6b3
    ":non_potable_water:": "icon_non_potable_water", # v6  \u1f6b1
    ":underage:": "icon_underage", # v6  \u1f51e
    ":no_mobile_phones:": "icon_no_mobile_phones", # v6  \u1f4f5
    ":no_smoking:": "icon_no_smoking", # v6  \u1f6ad
    ":low_brightness:": "icon_low_brightness", # v6  \u1f505
    ":high_brightness:": "icon_high_brightness", # v6  \u1f506
    ":children_crossing:": "icon_children_crossing", # v6  \u1f6b8
    ":trident:": "icon_trident", # v6  \u1f531
    ":beginner:": "icon_beginner", # v6  \u1f530
    ":u6307:": "icon_u6307", # v5.2  \u1f22f
    ":chart:": "icon_chart", # v6  \u1f4b9
    ":globe_with_meridians:": "icon_globe_with_meridians", # v6  \u1f310
    ":diamond_shape_with_a_dot_inside:": "icon_diamond_shape_with_a_dot_inside", # v6  \u1f4a0
    ":cyclone:": "icon_cyclone", # v6  \u1f300
    ":parking:": "icon_parking", # v5.2  \u1f17f
    ":u7a7a:": "icon_u7a7a", # v6  \u1f233
    ":passport_control:": "icon_passport_control", # v6  \u1f6c2
    ":customs:": "icon_customs", # v6  \u1f6c3
    ":baggage_claim:": "icon_baggage_claim", # v6  \u1f6c4
    ":left_luggage:": "icon_left_luggage", # v6  \u1f6c5
    ":mens:": "icon_mens", # v6  \u1f6b9
    ":womens:": "icon_womens", # v6  \u1f6ba
    ":baby_symbol:": "icon_baby_symbol", # v6  \u1f6bc
    ":restroom:": "icon_restroom", # v6  \u1f6bb
    ":put_litter_in_its_place:": "icon_put_litter_in_its_place", # v6  \u1f6ae
    ":cinema:": "icon_cinema", # v6  \u1f3a6
    ":signal_strength:": "icon_signal_strength", # v6  \u1f4f6
    ":koko:": "icon_koko", # v6  \u1f201
    ":symbols:": "icon_symbols", # v6  \u1f523
    ":abcd:": "icon_abcd", # v6  \u1f521
    ":capital_abcd:": "icon_capital_abcd", # v6  \u1f520
    ":cool:": "icon_cool", # v6  \u1f192
    ":free:": "icon_free", # v6  \u1f193
    ":keycap_ten:": "icon_keycap_ten", # v6  \u1f51f
    ":1234:": "icon_1234", # v6  \u1f522
    ":arrow_up_small:": "icon_arrow_up_small", # v6  \u1f53c
    ":arrow_down_small:": "icon_arrow_down_small", # v6  \u1f53d
    ":twisted_rightwards_arrows:": "icon_twisted_rightwards_arrows", # v6  \u1f500
    ":repeat:": "icon_repeat", # v6  \u1f501
    ":repeat_one:": "icon_repeat_one", # v6  \u1f502
    ":arrows_counterclockwise:": "icon_arrows_counterclockwise", # v6  \u1f504
    ":arrows_clockwise:": "icon_arrows_clockwise", # v6  \u1f503
    ":musical_note:": "icon_musical_note", # v6  \u1f3b5
    ":notes:": "icon_notes", # v6  \u1f3b6
    ":heavy_dollar_sign:": "icon_heavy_dollar_sign", # v6  \u1f4b2
    ":currency_exchange:": "icon_currency_exchange", # v6  \u1f4b1
    ":back:": "icon_back", # v6  \u1f519
    ":soon:": "icon_soon", # v6  \u1f51c
    ":radio_button:": "icon_radio_button", # v6  \u1f518
    ":red_circle:": "icon_red_circle", # v6  \u1f534
    ":blue_circle:": "icon_blue_circle", # v6  \u1f535
    ":small_red_triangle:": "icon_small_red_triangle", # v6  \u1f53a
    ":small_red_triangle_down:": "icon_small_red_triangle_down", # v6  \u1f53b
    ":small_orange_diamond:": "icon_small_orange_diamond", # v6  \u1f538
    ":small_blue_diamond:": "icon_small_blue_diamond", # v6  \u1f539
    ":large_orange_diamond:": "icon_large_orange_diamond", # v6  \u1f536
    ":large_blue_diamond:": "icon_large_blue_diamond", # v6  \u1f537
    ":white_square_button:": "icon_white_square_button", # v6  \u1f533
    ":black_square_button:": "icon_black_square_button", # v6  \u1f532
    ":speaker:": "icon_speaker", # v6  \u1f508
    ":mute:": "icon_mute", # v6  \u1f507
    ":sound:": "icon_sound", # v6  \u1f509
    ":loud_sound:": "icon_loud_sound", # v6  \u1f50a
    ":bell:": "icon_bell", # v6  \u1f514
    ":no_bell:": "icon_no_bell", # v6  \u1f515
    ":mega:": "icon_mega", # v6  \u1f4e3
    ":loudspeaker:": "icon_loudspeaker", # v6  \u1f4e2
    ":speech_left:": "icon_speech_left", # v7  \u1f5e8
    ":speech_balloon:": "icon_speech_balloon", # v6  \u1f4ac
    ":thought_balloon:": "icon_thought_balloon", # v6  \u1f4ad
    ":anger_right:": "icon_anger_right", # v7  \u1f5ef
    ":black_joker:": "icon_black_joker", # v6  \u1f0cf
    ":flower_playing_cards:": "icon_flower_playing_cards", # v6  \u1f3b4
    ":mahjong:": "icon_mahjong", # v5.1  \u1f004
    ":clock1:": "icon_clock1", # v6  \u1f550
    ":clock2:": "icon_clock2", # v6  \u1f551
    ":clock3:": "icon_clock3", # v6  \u1f552
    ":clock4:": "icon_clock4", # v6  \u1f553
    ":clock5:": "icon_clock5", # v6  \u1f554
    ":clock6:": "icon_clock6", # v6  \u1f555
    ":clock7:": "icon_clock7", # v6  \u1f556
    ":clock8:": "icon_clock8", # v6  \u1f557
    ":clock9:": "icon_clock9", # v6  \u1f558
    ":clock10:": "icon_clock10", # v6  \u1f559
    ":clock11:": "icon_clock11", # v6  \u1f55a
    ":clock12:": "icon_clock12", # v6  \u1f55b
    ":clock130:": "icon_clock130", # v6  \u1f55c
    ":clock230:": "icon_clock230", # v6  \u1f55d
    ":clock330:": "icon_clock330", # v6  \u1f55e
    ":clock430:": "icon_clock430", # v6  \u1f55f
    ":clock530:": "icon_clock530", # v6  \u1f560
    ":clock630:": "icon_clock630", # v6  \u1f561
    ":clock730:": "icon_clock730", # v6  \u1f562
    ":clock830:": "icon_clock830", # v6  \u1f563
    ":clock930:": "icon_clock930", # v6  \u1f564
    ":clock1030:": "icon_clock1030", # v6  \u1f565
    ":clock1130:": "icon_clock1130", # v6  \u1f566
    ":clock1230:": "icon_clock1230", # v6  \u1f567
    ":basketball:": "icon_basketball", # v6  \u1f3c0
    ":football:": "icon_football", # v6  \u1f3c8
    ":softball:": "icon_softball", # v11  \u1f94e
    ":tennis:": "icon_tennis", # v6  \u1f3be
    ":volleyball:": "icon_volleyball", # v8  \u1f3d0
    ":rugby_football:": "icon_rugby_football", # v6  \u1f3c9
    ":8ball:": "icon_8ball", # v6  \u1f3b1
    ":ping_pong:": "icon_ping_pong", # v8  \u1f3d3
    ":badminton:": "icon_badminton", # v8  \u1f3f8
    ":goal:": "icon_goal", # v9  \u1f945
    ":hockey:": "icon_hockey", # v8  \u1f3d2
    ":field_hockey:": "icon_field_hockey", # v8  \u1f3d1
    ":cricket_game:": "icon_cricket_game", # v8  \u1f3cf
    ":lacrosse:": "icon_lacrosse", # v11  \u1f94d
    ":flying_disc:": "icon_flying_disc", # v11  \u1f94f
    ":bow_and_arrow:": "icon_bow_and_arrow", # v8  \u1f3f9
    ":fishing_pole_and_fish:": "icon_fishing_pole_and_fish", # v6  \u1f3a3
    ":boxing_glove:": "icon_boxing_glove", # v9  \u1f94a
    ":martial_arts_uniform:": "icon_martial_arts_uniform", # v9  \u1f94b
    ":running_shirt_with_sash:": "icon_running_shirt_with_sash", # v6  \u1f3bd
    ":skateboard:": "icon_skateboard", # v11  \u1f6f9
    ":sled:": "icon_sled", # v10  \u1f6f7
    ":snowboarder:": "icon_snowboarder", # v6  \u1f3c2
    ":person_lifting_weights:": "icon_person_lifting_weights", # v7  \u1f3cb
    ":people_wrestling:": "icon_people_wrestling", # v9  \u1f93c
    ":person_doing_cartwheel:": "icon_person_doing_cartwheel", # v9  \u1f938
    ":person_fencing:": "icon_person_fencing", # v9  \u1f93a
    ":person_playing_handball:": "icon_person_playing_handball", # v9  \u1f93e
    ":person_golfing:": "icon_person_golfing", # v7  \u1f3cc
    ":horse_racing:": "icon_horse_racing", # v6  \u1f3c7
    ":person_in_lotus_position:": "icon_person_in_lotus_position", # v10  \u1f9d8
    ":person_surfing:": "icon_person_surfing", # v6  \u1f3c4
    ":person_swimming:": "icon_person_swimming", # v6  \u1f3ca
    ":person_playing_water_polo:": "icon_person_playing_water_polo", # v9  \u1f93d
    ":person_rowing_boat:": "icon_person_rowing_boat", # v6  \u1f6a3
    ":person_climbing:": "icon_person_climbing", # v10  \u1f9d7
    ":person_mountain_biking:": "icon_person_mountain_biking", # v6  \u1f6b5
    ":person_biking:": "icon_person_biking", # v6  \u1f6b4
    ":trophy:": "icon_trophy", # v6  \u1f3c6
    ":first_place:": "icon_first_place", # v9  \u1f947
    ":second_place:": "icon_second_place", # v9  \u1f948
    ":third_place:": "icon_third_place", # v9  \u1f949
    ":medal:": "icon_medal", # v7  \u1f3c5
    ":military_medal:": "icon_military_medal", # v7  \u1f396
    ":rosette:": "icon_rosette", # v7  \u1f3f5
    ":reminder_ribbon:": "icon_reminder_ribbon", # v7  \u1f397
    ":ticket:": "icon_ticket", # v6  \u1f3ab
    ":tickets:": "icon_tickets", # v7  \u1f39f
    ":circus_tent:": "icon_circus_tent", # v6  \u1f3aa
    ":person_juggling:": "icon_person_juggling", # v9  \u1f939
    ":performing_arts:": "icon_performing_arts", # v6  \u1f3ad
    ":clapper:": "icon_clapper", # v6  \u1f3ac
    ":microphone:": "icon_microphone", # v6  \u1f3a4
    ":headphones:": "icon_headphones", # v6  \u1f3a7
    ":musical_score:": "icon_musical_score", # v6  \u1f3bc
    ":musical_keyboard:": "icon_musical_keyboard", # v6  \u1f3b9
    ":drum:": "icon_drum", # v9  \u1f941
    ":saxophone:": "icon_saxophone", # v6  \u1f3b7
    ":trumpet:": "icon_trumpet", # v6  \u1f3ba
    ":guitar:": "icon_guitar", # v6  \u1f3b8
    ":violin:": "icon_violin", # v6  \u1f3bb
    ":game_die:": "icon_game_die", # v6  \u1f3b2
    ":dart:": "icon_dart", # v6  \u1f3af
    ":bowling:": "icon_bowling", # v6  \u1f3b3
    ":video_game:": "icon_video_game", # v6  \u1f3ae
    ":slot_machine:": "icon_slot_machine", # v6  \u1f3b0
    ":iphone:": "icon_iphone", # v6  \u1f4f1
    ":calling:": "icon_calling", # v6  \u1f4f2
    ":computer:": "icon_computer", # v6  \u1f4bb
    ":desktop:": "icon_desktop", # v7  \u1f5a5
    ":printer:": "icon_printer", # v7  \u1f5a8
    ":mouse_three_button:": "icon_mouse_three_button", # v7  \u1f5b1
    ":trackball:": "icon_trackball", # v7  \u1f5b2
    ":joystick:": "icon_joystick", # v7  \u1f579
    ":jigsaw:": "icon_jigsaw", # v11  \u1f9e9
    ":compression:": "icon_compression", # v7  \u1f5dc
    ":minidisc:": "icon_minidisc", # v6  \u1f4bd
    ":floppy_disk:": "icon_floppy_disk", # v6  \u1f4be
    ":camera:": "icon_camera", # v6  \u1f4f7
    ":camera_with_flash:": "icon_camera_with_flash", # v7  \u1f4f8
    ":video_camera:": "icon_video_camera", # v6  \u1f4f9
    ":movie_camera:": "icon_movie_camera", # v6  \u1f3a5
    ":projector:": "icon_projector", # v7  \u1f4fd
    ":film_frames:": "icon_film_frames", # v7  \u1f39e
    ":telephone_receiver:": "icon_telephone_receiver", # v6  \u1f4de
    ":pager:": "icon_pager", # v6  \u1f4df
    ":radio:": "icon_radio", # v6  \u1f4fb
    ":microphone2:": "icon_microphone2", # v7  \u1f399
    ":level_slider:": "icon_level_slider", # v7  \u1f39a
    ":control_knobs:": "icon_control_knobs", # v7  \u1f39b
    ":clock:": "icon_clock", # v7  \u1f570
    ":satellite:": "icon_satellite", # v6  \u1f4e1
    ":compass:": "icon_compass", # v11  \u1f9ed
    ":battery:": "icon_battery", # v6  \u1f50b
    ":electric_plug:": "icon_electric_plug", # v6  \u1f50c
    ":magnet:": "icon_magnet", # v11  \u1f9f2
    ":bulb:": "icon_bulb", # v6  \u1f4a1
    ":flashlight:": "icon_flashlight", # v6  \u1f526
    ":candle:": "icon_candle", # v7  \u1f56f
    ":fire_extinguisher:": "icon_fire_extinguisher", # v11  \u1f9ef
    ":wastebasket:": "icon_wastebasket", # v7  \u1f5d1
    ":money_with_wings:": "icon_money_with_wings", # v6  \u1f4b8
    ":dollar:": "icon_dollar", # v6  \u1f4b5
    ":euro:": "icon_euro", # v6  \u1f4b6
    ":pound:": "icon_pound", # v6  \u1f4b7
    ":moneybag:": "icon_moneybag", # v6  \u1f4b0
    ":credit_card:": "icon_credit_card", # v6  \u1f4b3
    ":nazar_amulet:": "icon_nazar_amulet", # v11  \u1f9ff
    ":bricks:": "icon_bricks", # v11  \u1f9f1
    ":toolbox:": "icon_toolbox", # v11  \u1f9f0
    ":wrench:": "icon_wrench", # v6  \u1f527
    ":hammer:": "icon_hammer", # v6  \u1f528
    ":tools:": "icon_tools", # v7  \u1f6e0
    ":nut_and_bolt:": "icon_nut_and_bolt", # v6  \u1f529
    ":bomb:": "icon_bomb", # v6  \u1f4a3
    ":knife:": "icon_knife", # v6  \u1f52a
    ":dagger:": "icon_dagger", # v7  \u1f5e1
    ":shield:": "icon_shield", # v7  \u1f6e1
    ":smoking:": "icon_smoking", # v6  \u1f6ac
    ":amphora:": "icon_amphora", # v8  \u1f3fa
    ":crystal_ball:": "icon_crystal_ball", # v6  \u1f52e
    ":prayer_beads:": "icon_prayer_beads", # v8  \u1f4ff
    ":barber:": "icon_barber", # v6  \u1f488
    ":test_tube:": "icon_test_tube", # v11  \u1f9ea
    ":petri_dish:": "icon_petri_dish", # v11  \u1f9eb
    ":abacus:": "icon_abacus", # v11  \u1f9ee
    ":telescope:": "icon_telescope", # v6  \u1f52d
    ":microscope:": "icon_microscope", # v6  \u1f52c
    ":hole:": "icon_hole", # v7  \u1f573
    ":pill:": "icon_pill", # v6  \u1f48a
    ":syringe:": "icon_syringe", # v6  \u1f489
    ":thermometer:": "icon_thermometer", # v7  \u1f321
    ":toilet:": "icon_toilet", # v6  \u1f6bd
    ":potable_water:": "icon_potable_water", # v6  \u1f6b0
    ":shower:": "icon_shower", # v6  \u1f6bf
    ":bathtub:": "icon_bathtub", # v6  \u1f6c1
    ":bath:": "icon_bath", # v6  \u1f6c0
    ":broom:": "icon_broom", # v11  \u1f9f9
    ":basket:": "icon_basket", # v11  \u1f9fa
    ":roll_of_paper:": "icon_roll_of_paper", # v11  \u1f9fb
    ":soap:": "icon_soap", # v11  \u1f9fc
    ":sponge:": "icon_sponge", # v11  \u1f9fd
    ":squeeze_bottle:": "icon_squeeze_bottle", # v11  \u1f9f4
    ":thread:": "icon_thread", # v11  \u1f9f5
    ":yarn:": "icon_yarn", # v11  \u1f9f6
    ":bellhop:": "icon_bellhop", # v7  \u1f6ce
    ":key2:": "icon_key2", # v7  \u1f5dd
    ":door:": "icon_door", # v6  \u1f6aa
    ":couch:": "icon_couch", # v7  \u1f6cb
    ":sleeping_accommodation:": "icon_sleeping_accommodation", # v7  \u1f6cc
    ":teddy_bear:": "icon_teddy_bear", # v11  \u1f9f8
    ":frame_photo:": "icon_frame_photo", # v7  \u1f5bc
    ":shopping_bags:": "icon_shopping_bags", # v7  \u1f6cd
    ":shopping_cart:": "icon_shopping_cart", # v9  \u1f6d2
    ":gift:": "icon_gift", # v6  \u1f381
    ":balloon:": "icon_balloon", # v6  \u1f388
    ":flags:": "icon_flags", # v6  \u1f38f
    ":ribbon:": "icon_ribbon", # v6  \u1f380
    ":confetti_ball:": "icon_confetti_ball", # v6  \u1f38a
    ":tada:": "icon_tada", # v6  \u1f389
    ":dolls:": "icon_dolls", # v6  \u1f38e
    ":izakaya_lantern:": "icon_izakaya_lantern", # v6  \u1f3ee
    ":wind_chime:": "icon_wind_chime", # v6  \u1f390
    ":red_envelope:": "icon_red_envelope", # v11  \u1f9e7
    ":envelope_with_arrow:": "icon_envelope_with_arrow", # v6  \u1f4e9
    ":incoming_envelope:": "icon_incoming_envelope", # v6  \u1f4e8
    ":e_mail:": "icon_e_mail", # v6  \u1f4e7
    ":love_letter:": "icon_love_letter", # v6  \u1f48c
    ":inbox_tray:": "icon_inbox_tray", # v6  \u1f4e5
    ":outbox_tray:": "icon_outbox_tray", # v6  \u1f4e4
    ":package:": "icon_package", # v6  \u1f4e6
    ":label:": "icon_label", # v7  \u1f3f7
    ":mailbox_closed:": "icon_mailbox_closed", # v6  \u1f4ea
    ":mailbox:": "icon_mailbox", # v6  \u1f4eb
    ":mailbox_with_mail:": "icon_mailbox_with_mail", # v6  \u1f4ec
    ":mailbox_with_no_mail:": "icon_mailbox_with_no_mail", # v6  \u1f4ed
    ":postbox:": "icon_postbox", # v6  \u1f4ee
    ":postal_horn:": "icon_postal_horn", # v6  \u1f4ef
    ":scroll:": "icon_scroll", # v6  \u1f4dc
    ":page_with_curl:": "icon_page_with_curl", # v6  \u1f4c3
    ":page_facing_up:": "icon_page_facing_up", # v6  \u1f4c4
    ":receipt:": "icon_receipt", # v11  \u1f9fe
    ":bookmark_tabs:": "icon_bookmark_tabs", # v6  \u1f4d1
    ":bar_chart:": "icon_bar_chart", # v6  \u1f4ca
    ":chart_with_upwards_trend:": "icon_chart_with_upwards_trend", # v6  \u1f4c8
    ":chart_with_downwards_trend:": "icon_chart_with_downwards_trend", # v6  \u1f4c9
    ":notepad_spiral:": "icon_notepad_spiral", # v7  \u1f5d2
    ":calendar_spiral:": "icon_calendar_spiral", # v7  \u1f5d3
    ":calendar:": "icon_calendar", # v6  \u1f4c6
    ":date:": "icon_date", # v6  \u1f4c5
    ":card_index:": "icon_card_index", # v6  \u1f4c7
    ":card_box:": "icon_card_box", # v7  \u1f5c3
    ":ballot_box:": "icon_ballot_box", # v7  \u1f5f3
    ":file_cabinet:": "icon_file_cabinet", # v7  \u1f5c4
    ":clipboard:": "icon_clipboard", # v6  \u1f4cb
    ":file_folder:": "icon_file_folder", # v6  \u1f4c1
    ":open_file_folder:": "icon_open_file_folder", # v6  \u1f4c2
    ":dividers:": "icon_dividers", # v7  \u1f5c2
    ":newspaper2:": "icon_newspaper2", # v7  \u1f5de
    ":newspaper:": "icon_newspaper", # v6  \u1f4f0
    ":notebook:": "icon_notebook", # v6  \u1f4d3
    ":notebook_with_decorative_cover:": "icon_notebook_with_decorative_cover", # v6  \u1f4d4
    ":ledger:": "icon_ledger", # v6  \u1f4d2
    ":closed_book:": "icon_closed_book", # v6  \u1f4d5
    ":green_book:": "icon_green_book", # v6  \u1f4d7
    ":blue_book:": "icon_blue_book", # v6  \u1f4d8
    ":orange_book:": "icon_orange_book", # v6  \u1f4d9
    ":books:": "icon_books", # v6  \u1f4da
    ":book:": "icon_book", # v6  \u1f4d6
    ":bookmark:": "icon_bookmark", # v6  \u1f516
    ":link:": "icon_link", # v6  \u1f517
    ":paperclip:": "icon_paperclip", # v6  \u1f4ce
    ":paperclips:": "icon_paperclips", # v7  \u1f587
    ":triangular_ruler:": "icon_triangular_ruler", # v6  \u1f4d0
    ":straight_ruler:": "icon_straight_ruler", # v6  \u1f4cf
    ":safety_pin:": "icon_safety_pin", # v11  \u1f9f7
    ":pushpin:": "icon_pushpin", # v6  \u1f4cc
    ":round_pushpin:": "icon_round_pushpin", # v6  \u1f4cd
    ":pen_ballpoint:": "icon_pen_ballpoint", # v7  \u1f58a
    ":pen_fountain:": "icon_pen_fountain", # v7  \u1f58b
    ":paintbrush:": "icon_paintbrush", # v7  \u1f58c
    ":crayon:": "icon_crayon", # v7  \u1f58d
    ":pencil:": "icon_pencil", # v6  \u1f4dd
    ":mag_right:": "icon_mag_right", # v6  \u1f50e
    ":lock_with_ink_pen:": "icon_lock_with_ink_pen", # v6  \u1f50f
    ":closed_lock_with_key:": "icon_closed_lock_with_key", # v6  \u1f510
    ":mouse:": "icon_mouse", # v6  \u1f42d
    ":hamster:": "icon_hamster", # v6  \u1f439
    ":rabbit:": "icon_rabbit", # v6  \u1f430
    ":raccoon:": "icon_raccoon", # v11  \u1f99d
    ":bear:": "icon_bear", # v6  \u1f43b
    ":panda_face:": "icon_panda_face", # v6  \u1f43c
    ":kangaroo:": "icon_kangaroo", # v11  \u1f998
    ":badger:": "icon_badger", # v11  \u1f9a1
    ":koala:": "icon_koala", # v6  \u1f428
    ":tiger:": "icon_tiger", # v6  \u1f42f
    ":lion_face:": "icon_lion_face", # v8  \u1f981
    ":pig_nose:": "icon_pig_nose", # v6  \u1f43d
    ":frog:": "icon_frog", # v6  \u1f438
    ":monkey_face:": "icon_monkey_face", # v6  \u1f435
    ":see_no_evil:": "icon_see_no_evil", # v6  \u1f648
    ":hear_no_evil:": "icon_hear_no_evil", # v6  \u1f649
    ":speak_no_evil:": "icon_speak_no_evil", # v6  \u1f64a
    ":monkey:": "icon_monkey", # v6  \u1f412
    ":chicken:": "icon_chicken", # v6  \u1f414
    ":penguin:": "icon_penguin", # v6  \u1f427
    ":bird:": "icon_bird", # v6  \u1f426
    ":baby_chick:": "icon_baby_chick", # v6  \u1f424
    ":hatching_chick:": "icon_hatching_chick", # v6  \u1f423
    ":hatched_chick:": "icon_hatched_chick", # v6  \u1f425
    ":duck:": "icon_duck", # v9  \u1f986
    ":swan:": "icon_swan", # v11  \u1f9a2
    ":eagle:": "icon_eagle", # v9  \u1f985
    ":parrot:": "icon_parrot", # v11  \u1f99c
    ":peacock:": "icon_peacock", # v11  \u1f99a
    ":wolf:": "icon_wolf", # v6  \u1f43a
    ":boar:": "icon_boar", # v6  \u1f417
    ":horse:": "icon_horse", # v6  \u1f434
    ":unicorn:": "icon_unicorn", # v8  \u1f984
    ":butterfly:": "icon_butterfly", # v9  \u1f98b
    ":snail:": "icon_snail", # v6  \u1f40c
    ":shell:": "icon_shell", # v6  \u1f41a
    ":beetle:": "icon_beetle", # v6  \u1f41e
    ":cricket:": "icon_cricket", # v10  \u1f997
    ":spider:": "icon_spider", # v7  \u1f577
    ":spider_web:": "icon_spider_web", # v7  \u1f578
    ":scorpion:": "icon_scorpion", # v8  \u1f982
    ":mosquito:": "icon_mosquito", # v11  \u1f99f
    ":microbe:": "icon_microbe", # v11  \u1f9a0
    ":turtle:": "icon_turtle", # v6  \u1f422
    ":snake:": "icon_snake", # v6  \u1f40d
    ":lizard:": "icon_lizard", # v9  \u1f98e
    ":t_rex:": "icon_t_rex", # v10  \u1f996
    ":sauropod:": "icon_sauropod", # v10  \u1f995
    ":octopus:": "icon_octopus", # v6  \u1f419
    ":squid:": "icon_squid", # v9  \u1f991
    ":shrimp:": "icon_shrimp", # v9  \u1f990
    ":crab:": "icon_crab", # v8  \u1f980
    ":lobster:": "icon_lobster", # v11  \u1f99e
    ":blowfish:": "icon_blowfish", # v6  \u1f421
    ":tropical_fish:": "icon_tropical_fish", # v6  \u1f420
    ":fish:": "icon_fish", # v6  \u1f41f
    ":dolphin:": "icon_dolphin", # v6  \u1f42c
    ":whale:": "icon_whale", # v6  \u1f433
    ":whale2:": "icon_whale2", # v6  \u1f40b
    ":shark:": "icon_shark", # v9  \u1f988
    ":crocodile:": "icon_crocodile", # v6  \u1f40a
    ":tiger2:": "icon_tiger2", # v6  \u1f405
    ":leopard:": "icon_leopard", # v6  \u1f406
    ":zebra:": "icon_zebra", # v10  \u1f993
    ":gorilla:": "icon_gorilla", # v9  \u1f98d
    ":elephant:": "icon_elephant", # v6  \u1f418
    ":rhino:": "icon_rhino", # v9  \u1f98f
    ":hippopotamus:": "icon_hippopotamus", # v11  \u1f99b
    ":dromedary_camel:": "icon_dromedary_camel", # v6  \u1f42a
    ":camel:": "icon_camel", # v6  \u1f42b
    ":giraffe:": "icon_giraffe", # v10  \u1f992
    ":llama:": "icon_llama", # v11  \u1f999
    ":water_buffalo:": "icon_water_buffalo", # v6  \u1f403
    ":cow2:": "icon_cow2", # v6  \u1f404
    ":racehorse:": "icon_racehorse", # v6  \u1f40e
    ":pig2:": "icon_pig2", # v6  \u1f416
    ":sheep:": "icon_sheep", # v6  \u1f411
    ":goat:": "icon_goat", # v6  \u1f410
    ":deer:": "icon_deer", # v9  \u1f98c
    ":dog2:": "icon_dog2", # v6  \u1f415
    ":poodle:": "icon_poodle", # v6  \u1f429
    ":cat2:": "icon_cat2", # v6  \u1f408
    ":rooster:": "icon_rooster", # v6  \u1f413
    ":turkey:": "icon_turkey", # v8  \u1f983
    ":dove:": "icon_dove", # v7  \u1f54a
    ":rabbit2:": "icon_rabbit2", # v6  \u1f407
    ":mouse2:": "icon_mouse2", # v6  \u1f401
    ":chipmunk:": "icon_chipmunk", # v7  \u1f43f
    ":hedgehog:": "icon_hedgehog", # v10  \u1f994
    ":feet:": "icon_feet", # v6  \u1f43e
    ":dragon:": "icon_dragon", # v6  \u1f409
    ":dragon_face:": "icon_dragon_face", # v6  \u1f432
    ":cactus:": "icon_cactus", # v6  \u1f335
    ":christmas_tree:": "icon_christmas_tree", # v6  \u1f384
    ":evergreen_tree:": "icon_evergreen_tree", # v6  \u1f332
    ":deciduous_tree:": "icon_deciduous_tree", # v6  \u1f333
    ":palm_tree:": "icon_palm_tree", # v6  \u1f334
    ":seedling:": "icon_seedling", # v6  \u1f331
    ":herb:": "icon_herb", # v6  \u1f33f
    ":four_leaf_clover:": "icon_four_leaf_clover", # v6  \u1f340
    ":bamboo:": "icon_bamboo", # v6  \u1f38d
    ":tanabata_tree:": "icon_tanabata_tree", # v6  \u1f38b
    ":leaves:": "icon_leaves", # v6  \u1f343
    ":fallen_leaf:": "icon_fallen_leaf", # v6  \u1f342
    ":maple_leaf:": "icon_maple_leaf", # v6  \u1f341
    ":mushroom:": "icon_mushroom", # v6  \u1f344
    ":ear_of_rice:": "icon_ear_of_rice", # v6  \u1f33e
    ":bouquet:": "icon_bouquet", # v6  \u1f490
    ":tulip:": "icon_tulip", # v6  \u1f337
    ":rose:": "icon_rose", # v6  \u1f339
    ":wilted_rose:": "icon_wilted_rose", # v9  \u1f940
    ":hibiscus:": "icon_hibiscus", # v6  \u1f33a
    ":cherry_blossom:": "icon_cherry_blossom", # v6  \u1f338
    ":blossom:": "icon_blossom", # v6  \u1f33c
    ":sunflower:": "icon_sunflower", # v6  \u1f33b
    ":sun_with_face:": "icon_sun_with_face", # v6  \u1f31e
    ":full_moon_with_face:": "icon_full_moon_with_face", # v6  \u1f31d
    ":first_quarter_moon_with_face:": "icon_first_quarter_moon_with_face", # v6  \u1f31b
    ":last_quarter_moon_with_face:": "icon_last_quarter_moon_with_face", # v6  \u1f31c
    ":new_moon_with_face:": "icon_new_moon_with_face", # v6  \u1f31a
    ":full_moon:": "icon_full_moon", # v6  \u1f315
    ":waning_gibbous_moon:": "icon_waning_gibbous_moon", # v6  \u1f316
    ":last_quarter_moon:": "icon_last_quarter_moon", # v6  \u1f317
    ":waning_crescent_moon:": "icon_waning_crescent_moon", # v6  \u1f318
    ":new_moon:": "icon_new_moon", # v6  \u1f311
    ":waxing_crescent_moon:": "icon_waxing_crescent_moon", # v6  \u1f312
    ":first_quarter_moon:": "icon_first_quarter_moon", # v6  \u1f313
    ":waxing_gibbous_moon:": "icon_waxing_gibbous_moon", # v6  \u1f314
    ":crescent_moon:": "icon_crescent_moon", # v6  \u1f319
    ":earth_americas:": "icon_earth_americas", # v6  \u1f30e
    ":earth_africa:": "icon_earth_africa", # v6  \u1f30d
    ":earth_asia:": "icon_earth_asia", # v6  \u1f30f
    ":dizzy:": "icon_dizzy", # v6  \u1f4ab
    ":star2:": "icon_star2", # v6  \u1f31f
    ":boom:": "icon_boom", # v6  \u1f4a5
    ":fire:": "icon_fire", # v6  \u1f525
    ":cloud_tornado:": "icon_cloud_tornado", # v7  \u1f32a
    ":rainbow:": "icon_rainbow", # v6  \u1f308
    ":white_sun_small_cloud:": "icon_white_sun_small_cloud", # v7  \u1f324
    ":white_sun_cloud:": "icon_white_sun_cloud", # v7  \u1f325
    ":white_sun_rain_cloud:": "icon_white_sun_rain_cloud", # v7  \u1f326
    ":cloud_rain:": "icon_cloud_rain", # v7  \u1f327
    ":cloud_lightning:": "icon_cloud_lightning", # v7  \u1f329
    ":cloud_snow:": "icon_cloud_snow", # v7  \u1f328
    ":wind_blowing_face:": "icon_wind_blowing_face", # v7  \u1f32c
    ":dash:": "icon_dash", # v6  \u1f4a8
    ":droplet:": "icon_droplet", # v6  \u1f4a7
    ":sweat_drops:": "icon_sweat_drops", # v6  \u1f4a6
    ":ocean:": "icon_ocean", # v6  \u1f30a
    ":green_apple:": "icon_green_apple", # v6  \u1f34f
    ":apple:": "icon_apple", # v6  \u1f34e
    ":pear:": "icon_pear", # v6  \u1f350
    ":tangerine:": "icon_tangerine", # v6  \u1f34a
    ":lemon:": "icon_lemon", # v6  \u1f34b
    ":banana:": "icon_banana", # v6  \u1f34c
    ":watermelon:": "icon_watermelon", # v6  \u1f349
    ":grapes:": "icon_grapes", # v6  \u1f347
    ":strawberry:": "icon_strawberry", # v6  \u1f353
    ":melon:": "icon_melon", # v6  \u1f348
    ":cherries:": "icon_cherries", # v6  \u1f352
    ":peach:": "icon_peach", # v6  \u1f351
    ":mango:": "icon_mango", # v11  \u1f96d
    ":pineapple:": "icon_pineapple", # v6  \u1f34d
    ":coconut:": "icon_coconut", # v10  \u1f965
    ":kiwi:": "icon_kiwi", # v9  \u1f95d
    ":tomato:": "icon_tomato", # v6  \u1f345
    ":eggplant:": "icon_eggplant", # v6  \u1f346
    ":avocado:": "icon_avocado", # v9  \u1f951
    ":broccoli:": "icon_broccoli", # v10  \u1f966
    ":leafy_green:": "icon_leafy_green", # v11  \u1f96c
    ":cucumber:": "icon_cucumber", # v9  \u1f952
    ":hot_pepper:": "icon_hot_pepper", # v7  \u1f336
    ":corn:": "icon_corn", # v6  \u1f33d
    ":carrot:": "icon_carrot", # v9  \u1f955
    ":potato:": "icon_potato", # v9  \u1f954
    ":sweet_potato:": "icon_sweet_potato", # v6  \u1f360
    ":croissant:": "icon_croissant", # v9  \u1f950
    ":bread:": "icon_bread", # v6  \u1f35e
    ":french_bread:": "icon_french_bread", # v9  \u1f956
    ":pretzel:": "icon_pretzel", # v10  \u1f968
    ":bagel:": "icon_bagel", # v11  \u1f96f
    ":cheese:": "icon_cheese", # v8  \u1f9c0
    ":cooking:": "icon_cooking", # v6  \u1f373
    ":pancakes:": "icon_pancakes", # v9  \u1f95e
    ":bacon:": "icon_bacon", # v9  \u1f953
    ":cut_of_meat:": "icon_cut_of_meat", # v10  \u1f969
    ":poultry_leg:": "icon_poultry_leg", # v6  \u1f357
    ":meat_on_bone:": "icon_meat_on_bone", # v6  \u1f356
    ":hotdog:": "icon_hotdog", # v8  \u1f32d
    ":hamburger:": "icon_hamburger", # v6  \u1f354
    ":fries:": "icon_fries", # v6  \u1f35f
    ":pizza:": "icon_pizza", # v6  \u1f355
    ":sandwich:": "icon_sandwich", # v10  \u1f96a
    ":stuffed_flatbread:": "icon_stuffed_flatbread", # v9  \u1f959
    ":taco:": "icon_taco", # v8  \u1f32e
    ":burrito:": "icon_burrito", # v8  \u1f32f
    ":salad:": "icon_salad", # v9  \u1f957
    ":shallow_pan_of_food:": "icon_shallow_pan_of_food", # v9  \u1f958
    ":canned_food:": "icon_canned_food", # v10  \u1f96b
    ":spaghetti:": "icon_spaghetti", # v6  \u1f35d
    ":ramen:": "icon_ramen", # v6  \u1f35c
    ":stew:": "icon_stew", # v6  \u1f372
    ":curry:": "icon_curry", # v6  \u1f35b
    ":sushi:": "icon_sushi", # v6  \u1f363
    ":bento:": "icon_bento", # v6  \u1f371
    ":fried_shrimp:": "icon_fried_shrimp", # v6  \u1f364
    ":rice_ball:": "icon_rice_ball", # v6  \u1f359
    ":rice:": "icon_rice", # v6  \u1f35a
    ":rice_cracker:": "icon_rice_cracker", # v6  \u1f358
    ":fish_cake:": "icon_fish_cake", # v6  \u1f365
    ":fortune_cookie:": "icon_fortune_cookie", # v10  \u1f960
    ":oden:": "icon_oden", # v6  \u1f362
    ":dango:": "icon_dango", # v6  \u1f361
    ":shaved_ice:": "icon_shaved_ice", # v6  \u1f367
    ":ice_cream:": "icon_ice_cream", # v6  \u1f368
    ":icecream:": "icon_icecream", # v6  \u1f366
    ":cake:": "icon_cake", # v6  \u1f370
    ":birthday:": "icon_birthday", # v6  \u1f382
    ":moon_cake:": "icon_moon_cake", # v11  \u1f96e
    ":cupcake:": "icon_cupcake", # v11  \u1f9c1
    ":custard:": "icon_custard", # v6  \u1f36e
    ":lollipop:": "icon_lollipop", # v6  \u1f36d
    ":candy:": "icon_candy", # v6  \u1f36c
    ":chocolate_bar:": "icon_chocolate_bar", # v6  \u1f36b
    ":popcorn:": "icon_popcorn", # v8  \u1f37f
    ":salt:": "icon_salt", # v11  \u1f9c2
    ":doughnut:": "icon_doughnut", # v6  \u1f369
    ":dumpling:": "icon_dumpling", # v10  \u1f95f
    ":cookie:": "icon_cookie", # v6  \u1f36a
    ":chestnut:": "icon_chestnut", # v6  \u1f330
    ":peanuts:": "icon_peanuts", # v9  \u1f95c
    ":honey_pot:": "icon_honey_pot", # v6  \u1f36f
    ":milk:": "icon_milk", # v9  \u1f95b
    ":baby_bottle:": "icon_baby_bottle", # v6  \u1f37c
    ":cup_with_straw:": "icon_cup_with_straw", # v10  \u1f964
    ":sake:": "icon_sake", # v6  \u1f376
    ":beer:": "icon_beer", # v6  \u1f37a
    ":beers:": "icon_beers", # v6  \u1f37b
    ":champagne_glass:": "icon_champagne_glass", # v9  \u1f942
    ":wine_glass:": "icon_wine_glass", # v6  \u1f377
    ":tumbler_glass:": "icon_tumbler_glass", # v9  \u1f943
    ":cocktail:": "icon_cocktail", # v6  \u1f378
    ":tropical_drink:": "icon_tropical_drink", # v6  \u1f379
    ":champagne:": "icon_champagne", # v8  \u1f37e
    ":spoon:": "icon_spoon", # v9  \u1f944
    ":fork_and_knife:": "icon_fork_and_knife", # v6  \u1f374
    ":fork_knife_plate:": "icon_fork_knife_plate", # v7  \u1f37d
    ":bowl_with_spoon:": "icon_bowl_with_spoon", # v10  \u1f963
    ":takeout_box:": "icon_takeout_box", # v10  \u1f961
    ":chopsticks:": "icon_chopsticks", # v10  \u1f962
    ":grinning:": "icon_grinning", # v6.1  \u1f600
    ":smiley:": "icon_smiley", # v6  \u1f603
    ":smile:": "icon_smile", # v6  \u1f604
    ":grin:": "icon_grin", # v6  \u1f601
    ":laughing:": "icon_laughing", # v6  \u1f606
    ":sweat_smile:": "icon_sweat_smile", # v6  \u1f605
    ":rofl:": "icon_rofl", # v9  \u1f923
    ":blush:": "icon_blush", # v6  \u1f60a
    ":innocent:": "icon_innocent", # v6  \u1f607
    ":slight_smile:": "icon_slight_smile", # v7  \u1f642
    ":upside_down:": "icon_upside_down", # v8  \u1f643
    ":wink:": "icon_wink", # v6  \u1f609
    ":relieved:": "icon_relieved", # v6  \u1f60c
    ":heart_eyes:": "icon_heart_eyes", # v6  \u1f60d
    ":kissing_heart:": "icon_kissing_heart", # v6  \u1f618
    ":smiling_face_with_3_hearts:": "icon_smiling_face_with_3_hearts", # v11  \u1f970
    ":kissing:": "icon_kissing", # v6.1  \u1f617
    ":kissing_smiling_eyes:": "icon_kissing_smiling_eyes", # v6.1  \u1f619
    ":kissing_closed_eyes:": "icon_kissing_closed_eyes", # v6  \u1f61a
    ":stuck_out_tongue:": "icon_stuck_out_tongue", # v6.1  \u1f61b
    ":stuck_out_tongue_closed_eyes:": "icon_stuck_out_tongue_closed_eyes", # v6  \u1f61d
    ":stuck_out_tongue_winking_eye:": "icon_stuck_out_tongue_winking_eye", # v6  \u1f61c
    ":zany_face:": "icon_zany_face", # v10  \u1f92a
    ":face_with_raised_eyebrow:": "icon_face_with_raised_eyebrow", # v10  \u1f928
    ":face_with_monocle:": "icon_face_with_monocle", # v10  \u1f9d0
    ":nerd:": "icon_nerd", # v8  \u1f913
    ":sunglasses:": "icon_sunglasses", # v6  \u1f60e
    ":star_struck:": "icon_star_struck", # v10  \u1f929
    ":partying_face:": "icon_partying_face", # v11  \u1f973
    ":smirk:": "icon_smirk", # v6  \u1f60f
    ":unamused:": "icon_unamused", # v6  \u1f612
    ":disappointed:": "icon_disappointed", # v6  \u1f61e
    ":pensive:": "icon_pensive", # v6  \u1f614
    ":worried:": "icon_worried", # v6.1  \u1f61f
    ":confused:": "icon_confused", # v6.1  \u1f615
    ":slight_frown:": "icon_slight_frown", # v7  \u1f641
    ":persevere:": "icon_persevere", # v6  \u1f623
    ":confounded:": "icon_confounded", # v6  \u1f616
    ":tired_face:": "icon_tired_face", # v6  \u1f62b
    ":weary:": "icon_weary", # v6  \u1f629
    ":triumph:": "icon_triumph", # v6  \u1f624
    ":angry:": "icon_angry", # v6  \u1f620
    ":rage:": "icon_rage", # v6  \u1f621
    ":face_with_symbols_over_mouth:": "icon_face_with_symbols_over_mouth", # v10  \u1f92c
    ":exploding_head:": "icon_exploding_head", # v10  \u1f92f
    ":flushed:": "icon_flushed", # v6  \u1f633
    ":scream:": "icon_scream", # v6  \u1f631
    ":fearful:": "icon_fearful", # v6  \u1f628
    ":cold_sweat:": "icon_cold_sweat", # v6  \u1f630
    ":hot_face:": "icon_hot_face", # v11  \u1f975
    ":cold_face:": "icon_cold_face", # v11  \u1f976
    ":pleading_face:": "icon_pleading_face", # v11  \u1f97a
    ":disappointed_relieved:": "icon_disappointed_relieved", # v6  \u1f625
    ":sweat:": "icon_sweat", # v6  \u1f613
    ":hugging:": "icon_hugging", # v8  \u1f917
    ":thinking:": "icon_thinking", # v8  \u1f914
    ":face_with_hand_over_mouth:": "icon_face_with_hand_over_mouth", # v10  \u1f92d
    ":shushing_face:": "icon_shushing_face", # v10  \u1f92b
    ":lying_face:": "icon_lying_face", # v9  \u1f925
    ":no_mouth:": "icon_no_mouth", # v6  \u1f636
    ":neutral_face:": "icon_neutral_face", # v6  \u1f610
    ":expressionless:": "icon_expressionless", # v6.1  \u1f611
    ":grimacing:": "icon_grimacing", # v6.1  \u1f62c
    ":rolling_eyes:": "icon_rolling_eyes", # v8  \u1f644
    ":hushed:": "icon_hushed", # v6.1  \u1f62f
    ":frowning:": "icon_frowning", # v6.1  \u1f626
    ":anguished:": "icon_anguished", # v6.1  \u1f627
    ":open_mouth:": "icon_open_mouth", # v6.1  \u1f62e
    ":astonished:": "icon_astonished", # v6  \u1f632
    ":sleeping:": "icon_sleeping", # v6.1  \u1f634
    ":drooling_face:": "icon_drooling_face", # v9  \u1f924
    ":sleepy:": "icon_sleepy", # v6  \u1f62a
    ":dizzy_face:": "icon_dizzy_face", # v6  \u1f635
    ":zipper_mouth:": "icon_zipper_mouth", # v8  \u1f910
    ":woozy_face:": "icon_woozy_face", # v11  \u1f974
    ":nauseated_face:": "icon_nauseated_face", # v9  \u1f922
    ":face_vomiting:": "icon_face_vomiting", # v10  \u1f92e
    ":sneezing_face:": "icon_sneezing_face", # v9  \u1f927
    ":mask:": "icon_mask", # v6  \u1f637
    ":thermometer_face:": "icon_thermometer_face", # v8  \u1f912
    ":head_bandage:": "icon_head_bandage", # v8  \u1f915
    ":money_mouth:": "icon_money_mouth", # v8  \u1f911
    ":cowboy:": "icon_cowboy", # v9  \u1f920
    ":smiling_imp:": "icon_smiling_imp", # v6  \u1f608
    ":japanese_ogre:": "icon_japanese_ogre", # v6  \u1f479
    ":japanese_goblin:": "icon_japanese_goblin", # v6  \u1f47a
    ":clown:": "icon_clown", # v9  \u1f921
    ":poop:": "icon_poop", # v6  \u1f4a9
    ":ghost:": "icon_ghost", # v6  \u1f47b
    ":skull:": "icon_skull", # v6  \u1f480
    ":alien:": "icon_alien", # v6  \u1f47d
    ":space_invader:": "icon_space_invader", # v6  \u1f47e
    ":robot:": "icon_robot", # v8  \u1f916
    ":jack_o_lantern:": "icon_jack_o_lantern", # v6  \u1f383
    ":smiley_cat:": "icon_smiley_cat", # v6  \u1f63a
    ":smile_cat:": "icon_smile_cat", # v6  \u1f638
    ":joy_cat:": "icon_joy_cat", # v6  \u1f639
    ":heart_eyes_cat:": "icon_heart_eyes_cat", # v6  \u1f63b
    ":smirk_cat:": "icon_smirk_cat", # v6  \u1f63c
    ":kissing_cat:": "icon_kissing_cat", # v6  \u1f63d
    ":scream_cat:": "icon_scream_cat", # v6  \u1f640
    ":crying_cat_face:": "icon_crying_cat_face", # v6  \u1f63f
    ":pouting_cat:": "icon_pouting_cat", # v6  \u1f63e
    ":palms_up_together:": "icon_palms_up_together", # v10  \u1f932
    ":open_hands:": "icon_open_hands", # v6  \u1f450
    ":raised_hands:": "icon_raised_hands", # v6  \u1f64c
    ":clap:": "icon_clap", # v6  \u1f44f
    ":handshake:": "icon_handshake", # v9  \u1f91d
    ":thumbsup:": "icon_thumbsup", # v6  \u1f44d
    ":thumbsdown:": "icon_thumbsdown", # v6  \u1f44e
    ":punch:": "icon_punch", # v6  \u1f44a
    ":left_facing_fist:": "icon_left_facing_fist", # v9  \u1f91b
    ":right_facing_fist:": "icon_right_facing_fist", # v9  \u1f91c
    ":fingers_crossed:": "icon_fingers_crossed", # v9  \u1f91e
    ":love_you_gesture:": "icon_love_you_gesture", # v10  \u1f91f
    ":metal:": "icon_metal", # v8  \u1f918
    ":ok_hand:": "icon_ok_hand", # v6  \u1f44c
    ":point_left:": "icon_point_left", # v6  \u1f448
    ":point_right:": "icon_point_right", # v6  \u1f449
    ":point_up_2:": "icon_point_up_2", # v6  \u1f446
    ":point_down:": "icon_point_down", # v6  \u1f447
    ":raised_back_of_hand:": "icon_raised_back_of_hand", # v9  \u1f91a
    ":hand_splayed:": "icon_hand_splayed", # v7  \u1f590
    ":vulcan:": "icon_vulcan", # v7  \u1f596
    ":wave:": "icon_wave", # v6  \u1f44b
    ":call_me:": "icon_call_me", # v9  \u1f919
    ":muscle:": "icon_muscle", # v6  \u1f4aa
    ":foot:": "icon_foot", # v11  \u1f9b6
    ":middle_finger:": "icon_middle_finger", # v7  \u1f595
    ":pray:": "icon_pray", # v6  \u1f64f
    ":ring:": "icon_ring", # v6  \u1f48d
    ":lipstick:": "icon_lipstick", # v6  \u1f484
    ":kiss:": "icon_kiss", # v6  \u1f48b
    ":lips:": "icon_lips", # v6  \u1f444
    ":tongue:": "icon_tongue", # v6  \u1f445
    ":nose:": "icon_nose", # v6  \u1f443
    ":footprints:": "icon_footprints", # v6  \u1f463
    ":eyes:": "icon_eyes", # v6  \u1f440
    ":brain:": "icon_brain", # v10  \u1f9e0
    ":bone:": "icon_bone", # v11  \u1f9b4
    ":tooth:": "icon_tooth", # v11  \u1f9b7
    ":speaking_head:": "icon_speaking_head", # v7  \u1f5e3
    ":bust_in_silhouette:": "icon_bust_in_silhouette", # v6  \u1f464
    ":busts_in_silhouette:": "icon_busts_in_silhouette", # v6  \u1f465
    ":baby:": "icon_baby", # v6  \u1f476
    ":girl:": "icon_girl", # v6  \u1f467
    ":child:": "icon_child", # v10  \u1f9d2
    ":woman:": "icon_woman", # v6  \u1f469
    ":adult:": "icon_adult", # v10  \u1f9d1
    ":blond_haired_person:": "icon_blond_haired_person", # v6  \u1f471
    ":bearded_person:": "icon_bearded_person", # v10  \u1f9d4
    ":older_woman:": "icon_older_woman", # v6  \u1f475
    ":older_adult:": "icon_older_adult", # v10  \u1f9d3
    ":older_man:": "icon_older_man", # v6  \u1f474
    ":man_with_chinese_cap:": "icon_man_with_chinese_cap", # v6  \u1f472
    ":person_wearing_turban:": "icon_person_wearing_turban", # v6  \u1f473
    ":woman_with_headscarf:": "icon_woman_with_headscarf", # v10  \u1f9d5
    ":police_officer:": "icon_police_officer", # v6  \u1f46e
    ":construction_worker:": "icon_construction_worker", # v6  \u1f477
    ":guard:": "icon_guard", # v6  \u1f482
    ":detective:": "icon_detective", # v7  \u1f575
    ":bride_with_veil:": "icon_bride_with_veil", # v6  \u1f470
    ":man_in_tuxedo:": "icon_man_in_tuxedo", # v9  \u1f935
    ":princess:": "icon_princess", # v6  \u1f478
    ":prince:": "icon_prince", # v9  \u1f934
    ":mrs_claus:": "icon_mrs_claus", # v9  \u1f936
    ":santa:": "icon_santa", # v6  \u1f385
    ":superhero:": "icon_superhero", # v11  \u1f9b8
    ":supervillain:": "icon_supervillain", # v11  \u1f9b9
    ":mage:": "icon_mage", # v10  \u1f9d9
    ":vampire:": "icon_vampire", # v10  \u1f9db
    ":zombie:": "icon_zombie", # v10  \u1f9df
    ":genie:": "icon_genie", # v10  \u1f9de
    ":merperson:": "icon_merperson", # v10  \u1f9dc
    ":fairy:": "icon_fairy", # v10  \u1f9da
    ":angel:": "icon_angel", # v6  \u1f47c
    ":pregnant_woman:": "icon_pregnant_woman", # v9  \u1f930
    ":breast_feeding:": "icon_breast_feeding", # v10  \u1f931
    ":person_bowing:": "icon_person_bowing", # v6  \u1f647
    ":person_tipping_hand:": "icon_person_tipping_hand", # v6  \u1f481
    ":person_gesturing_no:": "icon_person_gesturing_no", # v6  \u1f645
    ":person_gesturing_ok:": "icon_person_gesturing_ok", # v6  \u1f646
    ":person_raising_hand:": "icon_person_raising_hand", # v6  \u1f64b
    ":person_facepalming:": "icon_person_facepalming", # v9  \u1f926
    ":person_shrugging:": "icon_person_shrugging", # v9  \u1f937
    ":person_pouting:": "icon_person_pouting", # v6  \u1f64e
    ":person_frowning:": "icon_person_frowning", # v6  \u1f64d
    ":person_getting_haircut:": "icon_person_getting_haircut", # v6  \u1f487
    ":person_getting_massage:": "icon_person_getting_massage", # v6  \u1f486
    ":person_in_steamy_room:": "icon_person_in_steamy_room", # v10  \u1f9d6
    ":nail_care:": "icon_nail_care", # v6  \u1f485
    ":selfie:": "icon_selfie", # v9  \u1f933
    ":dancer:": "icon_dancer", # v6  \u1f483
    ":man_dancing:": "icon_man_dancing", # v9  \u1f57a
    ":people_with_bunny_ears_partying:": "icon_people_with_bunny_ears_partying", # v6  \u1f46f
    ":levitate:": "icon_levitate", # v7  \u1f574
    ":person_walking:": "icon_person_walking", # v6  \u1f6b6
    ":person_running:": "icon_person_running", # v6  \u1f3c3
    ":couple:": "icon_couple", # v6  \u1f46b
    ":two_women_holding_hands:": "icon_two_women_holding_hands", # v6  \u1f46d
    ":two_men_holding_hands:": "icon_two_men_holding_hands", # v6  \u1f46c
    ":couple_with_heart:": "icon_couple_with_heart", # v6  \u1f491
    ":couplekiss:": "icon_couplekiss", # v6  \u1f48f
    ":family:": "icon_family", # v6  \u1f46a
    ":coat:": "icon_coat", # v10  \u1f9e5
    ":womans_clothes:": "icon_womans_clothes", # v6  \u1f45a
    ":shirt:": "icon_shirt", # v6  \u1f455
    ":jeans:": "icon_jeans", # v6  \u1f456
    ":necktie:": "icon_necktie", # v6  \u1f454
    ":dress:": "icon_dress", # v6  \u1f457
    ":bikini:": "icon_bikini", # v6  \u1f459
    ":kimono:": "icon_kimono", # v6  \u1f458
    ":lab_coat:": "icon_lab_coat", # v11  \u1f97c
    ":high_heel:": "icon_high_heel", # v6  \u1f460
    ":sandal:": "icon_sandal", # v6  \u1f461
    ":boot:": "icon_boot", # v6  \u1f462
    ":mans_shoe:": "icon_mans_shoe", # v6  \u1f45e
    ":athletic_shoe:": "icon_athletic_shoe", # v6  \u1f45f
    ":hiking_boot:": "icon_hiking_boot", # v11  \u1f97e
    ":womans_flat_shoe:": "icon_womans_flat_shoe", # v11  \u1f97f
    ":socks:": "icon_socks", # v10  \u1f9e6
    ":gloves:": "icon_gloves", # v10  \u1f9e4
    ":scarf:": "icon_scarf", # v10  \u1f9e3
    ":tophat:": "icon_tophat", # v6  \u1f3a9
    ":billed_cap:": "icon_billed_cap", # v10  \u1f9e2
    ":womans_hat:": "icon_womans_hat", # v6  \u1f452
    ":mortar_board:": "icon_mortar_board", # v6  \u1f393
    ":crown:": "icon_crown", # v6  \u1f451
    ":pouch:": "icon_pouch", # v6  \u1f45d
    ":purse:": "icon_purse", # v6  \u1f45b
    ":handbag:": "icon_handbag", # v6  \u1f45c
    ":briefcase:": "icon_briefcase", # v6  \u1f4bc
    ":school_satchel:": "icon_school_satchel", # v6  \u1f392
    ":eyeglasses:": "icon_eyeglasses", # v6  \u1f453
    ":dark_sunglasses:": "icon_dark_sunglasses", # v7  \u1f576
    ":goggles:": "icon_goggles", # v11  \u1f97d
    ":closed_umbrella:": "icon_closed_umbrella", # v6  \u1f302
    ":red_haired:": "icon_red_haired", # v11  \u1f9b0
    ":curly_haired:": "icon_curly_haired", # v11  \u1f9b1
    ":white_haired:": "icon_white_haired", # v11  \u1f9b3
    ":bald:": "icon_bald", # v11  \u1f9b2
    ":regional_indicator_z:": "icon_regional_indicator_z", # v6  \u1f1ff
    ":regional_indicator_y:": "icon_regional_indicator_y", # v6  \u1f1fe
    ":regional_indicator_x:": "icon_regional_indicator_x", # v6  \u1f1fd
    ":regional_indicator_w:": "icon_regional_indicator_w", # v6  \u1f1fc
    ":regional_indicator_v:": "icon_regional_indicator_v", # v6  \u1f1fb
    ":regional_indicator_u:": "icon_regional_indicator_u", # v6  \u1f1fa
    ":regional_indicator_t:": "icon_regional_indicator_t", # v6  \u1f1f9
    ":regional_indicator_s:": "icon_regional_indicator_s", # v6  \u1f1f8
    ":regional_indicator_r:": "icon_regional_indicator_r", # v6  \u1f1f7
    ":regional_indicator_q:": "icon_regional_indicator_q", # v6  \u1f1f6
    ":regional_indicator_p:": "icon_regional_indicator_p", # v6  \u1f1f5
    ":regional_indicator_o:": "icon_regional_indicator_o", # v6  \u1f1f4
    ":regional_indicator_n:": "icon_regional_indicator_n", # v6  \u1f1f3
    ":regional_indicator_m:": "icon_regional_indicator_m", # v6  \u1f1f2
    ":regional_indicator_l:": "icon_regional_indicator_l", # v6  \u1f1f1
    ":regional_indicator_k:": "icon_regional_indicator_k", # v6  \u1f1f0
    ":regional_indicator_j:": "icon_regional_indicator_j", # v6  \u1f1ef
    ":regional_indicator_i:": "icon_regional_indicator_i", # v6  \u1f1ee
    ":regional_indicator_h:": "icon_regional_indicator_h", # v6  \u1f1ed
    ":regional_indicator_g:": "icon_regional_indicator_g", # v6  \u1f1ec
    ":regional_indicator_f:": "icon_regional_indicator_f", # v6  \u1f1eb
    ":regional_indicator_e:": "icon_regional_indicator_e", # v6  \u1f1ea
    ":regional_indicator_d:": "icon_regional_indicator_d", # v6  \u1f1e9
    ":regional_indicator_c:": "icon_regional_indicator_c", # v6  \u1f1e8
    ":regional_indicator_b:": "icon_regional_indicator_b", # v6  \u1f1e7
    ":regional_indicator_a:": "icon_regional_indicator_a", # v6  \u1f1e6
    ":red_car:": "icon_red_car", # v6  \u1f697
    ":taxi:": "icon_taxi", # v6  \u1f695
    ":blue_car:": "icon_blue_car", # v6  \u1f699
    ":trolleybus:": "icon_trolleybus", # v6  \u1f68e
    ":race_car:": "icon_race_car", # v7  \u1f3ce
    ":police_car:": "icon_police_car", # v6  \u1f693
    ":ambulance:": "icon_ambulance", # v6  \u1f691
    ":fire_engine:": "icon_fire_engine", # v6  \u1f692
    ":minibus:": "icon_minibus", # v6  \u1f690
    ":truck:": "icon_truck", # v6  \u1f69a
    ":articulated_lorry:": "icon_articulated_lorry", # v6  \u1f69b
    ":tractor:": "icon_tractor", # v6  \u1f69c
    ":scooter:": "icon_scooter", # v9  \u1f6f4
    ":bike:": "icon_bike", # v6  \u1f6b2
    ":motor_scooter:": "icon_motor_scooter", # v9  \u1f6f5
    ":motorcycle:": "icon_motorcycle", # v7  \u1f3cd
    ":rotating_light:": "icon_rotating_light", # v6  \u1f6a8
    ":oncoming_police_car:": "icon_oncoming_police_car", # v6  \u1f694
    ":oncoming_bus:": "icon_oncoming_bus", # v6  \u1f68d
    ":oncoming_automobile:": "icon_oncoming_automobile", # v6  \u1f698
    ":oncoming_taxi:": "icon_oncoming_taxi", # v6  \u1f696
    ":aerial_tramway:": "icon_aerial_tramway", # v6  \u1f6a1
    ":mountain_cableway:": "icon_mountain_cableway", # v6  \u1f6a0
    ":suspension_railway:": "icon_suspension_railway", # v6  \u1f69f
    ":railway_car:": "icon_railway_car", # v6  \u1f683
    ":train:": "icon_train", # v6  \u1f68b
    ":mountain_railway:": "icon_mountain_railway", # v6  \u1f69e
    ":monorail:": "icon_monorail", # v6  \u1f69d
    ":bullettrain_side:": "icon_bullettrain_side", # v6  \u1f684
    ":bullettrain_front:": "icon_bullettrain_front", # v6  \u1f685
    ":light_rail:": "icon_light_rail", # v6  \u1f688
    ":steam_locomotive:": "icon_steam_locomotive", # v6  \u1f682
    ":train2:": "icon_train2", # v6  \u1f686
    ":metro:": "icon_metro", # v6  \u1f687
    ":tram:": "icon_tram", # v6  \u1f68a
    ":station:": "icon_station", # v6  \u1f689
    ":airplane_departure:": "icon_airplane_departure", # v7  \u1f6eb
    ":airplane_arriving:": "icon_airplane_arriving", # v7  \u1f6ec
    ":airplane_small:": "icon_airplane_small", # v7  \u1f6e9
    ":seat:": "icon_seat", # v6  \u1f4ba
    ":luggage:": "icon_luggage", # v11  \u1f9f3
    ":satellite_orbital:": "icon_satellite_orbital", # v7  \u1f6f0
    ":rocket:": "icon_rocket", # v6  \u1f680
    ":flying_saucer:": "icon_flying_saucer", # v10  \u1f6f8
    ":helicopter:": "icon_helicopter", # v6  \u1f681
    ":canoe:": "icon_canoe", # v9  \u1f6f6
    ":speedboat:": "icon_speedboat", # v6  \u1f6a4
    ":motorboat:": "icon_motorboat", # v7  \u1f6e5
    ":cruise_ship:": "icon_cruise_ship", # v7  \u1f6f3
    ":ship:": "icon_ship", # v6  \u1f6a2
    ":construction:": "icon_construction", # v6  \u1f6a7
    ":vertical_traffic_light:": "icon_vertical_traffic_light", # v6  \u1f6a6
    ":traffic_light:": "icon_traffic_light", # v6  \u1f6a5
    ":busstop:": "icon_busstop", # v6  \u1f68f
    ":moyai:": "icon_moyai", # v6  \u1f5ff
    ":statue_of_liberty:": "icon_statue_of_liberty", # v6  \u1f5fd
    ":tokyo_tower:": "icon_tokyo_tower", # v6  \u1f5fc
    ":european_castle:": "icon_european_castle", # v6  \u1f3f0
    ":japanese_castle:": "icon_japanese_castle", # v6  \u1f3ef
    ":stadium:": "icon_stadium", # v7  \u1f3df
    ":ferris_wheel:": "icon_ferris_wheel", # v6  \u1f3a1
    ":roller_coaster:": "icon_roller_coaster", # v6  \u1f3a2
    ":carousel_horse:": "icon_carousel_horse", # v6  \u1f3a0
    ":beach:": "icon_beach", # v7  \u1f3d6
    ":island:": "icon_island", # v7  \u1f3dd
    ":desert:": "icon_desert", # v7  \u1f3dc
    ":volcano:": "icon_volcano", # v6  \u1f30b
    ":mountain_snow:": "icon_mountain_snow", # v7  \u1f3d4
    ":mount_fuji:": "icon_mount_fuji", # v6  \u1f5fb
    ":camping:": "icon_camping", # v7  \u1f3d5
    ":house:": "icon_house", # v6  \u1f3e0
    ":house_with_garden:": "icon_house_with_garden", # v6  \u1f3e1
    ":homes:": "icon_homes", # v7  \u1f3d8
    ":house_abandoned:": "icon_house_abandoned", # v7  \u1f3da
    ":construction_site:": "icon_construction_site", # v7  \u1f3d7
    ":factory:": "icon_factory", # v6  \u1f3ed
    ":office:": "icon_office", # v6  \u1f3e2
    ":department_store:": "icon_department_store", # v6  \u1f3ec
    ":post_office:": "icon_post_office", # v6  \u1f3e3
    ":european_post_office:": "icon_european_post_office", # v6  \u1f3e4
    ":hospital:": "icon_hospital", # v6  \u1f3e5
    ":bank:": "icon_bank", # v6  \u1f3e6
    ":hotel:": "icon_hotel", # v6  \u1f3e8
    ":convenience_store:": "icon_convenience_store", # v6  \u1f3ea
    ":school:": "icon_school", # v6  \u1f3eb
    ":love_hotel:": "icon_love_hotel", # v6  \u1f3e9
    ":wedding:": "icon_wedding", # v6  \u1f492
    ":classical_building:": "icon_classical_building", # v7  \u1f3db
    ":mosque:": "icon_mosque", # v8  \u1f54c
    ":synagogue:": "icon_synagogue", # v8  \u1f54d
    ":kaaba:": "icon_kaaba", # v8  \u1f54b
    ":railway_track:": "icon_railway_track", # v7  \u1f6e4
    ":motorway:": "icon_motorway", # v7  \u1f6e3
    ":japan:": "icon_japan", # v6  \u1f5fe
    ":rice_scene:": "icon_rice_scene", # v6  \u1f391
    ":park:": "icon_park", # v7  \u1f3de
    ":sunrise:": "icon_sunrise", # v6  \u1f305
    ":sunrise_over_mountains:": "icon_sunrise_over_mountains", # v6  \u1f304
    ":stars:": "icon_stars", # v6  \u1f320
    ":sparkler:": "icon_sparkler", # v6  \u1f387
    ":fireworks:": "icon_fireworks", # v6  \u1f386
    ":firecracker:": "icon_firecracker", # v11  \u1f9e8
    ":city_sunset:": "icon_city_sunset", # v6  \u1f307
    ":city_dusk:": "icon_city_dusk", # v6  \u1f306
    ":cityscape:": "icon_cityscape", # v7  \u1f3d9
    ":night_with_stars:": "icon_night_with_stars", # v6  \u1f303
    ":milky_way:": "icon_milky_way", # v6  \u1f30c
    ":bridge_at_night:": "icon_bridge_at_night", # v6  \u1f309
    ":lock:": "icon_lock", # v6  \u1f512
    ":unlock:": "icon_unlock", # v6  \u1f513
    ":foggy:": "icon_foggy", # v6  \u1f301
    ":flag_white:": "icon_flag_white", # v7  \u1f3f3
    ":flag_black:": "icon_flag_black", # v7  \u1f3f4
    ":checkered_flag:": "icon_checkered_flag", # v6  \u1f3c1
    ":triangular_flag_on_post:": "icon_triangular_flag_on_post", # v6  \u1f6a9
    ":crossed_flags:": "icon_crossed_flags"  # v6  \u1f38c
  }

type
  TokType = enum
    tkEof, tkIndent, tkWhite, tkWord, tkAdornment, tkPunct, tkOther
  Token = object              # a RST token
    kind*: TokType            # the type of the token
    ival*: int                # the indentation or parsed integer value
    symbol*: string           # the parsed symbol as string
    line*, col*: int          # line and column of the token

  TokenSeq = seq[Token]
  Lexer = object of RootObj
    buf*: cstring
    bufpos*: int
    line*, col*, baseIndent*: int
    skipPounds*: bool

proc getThing(L: var Lexer, tok: var Token, s: set[char]) =
  tok.kind = tkWord
  tok.line = L.line
  tok.col = L.col
  var pos = L.bufpos
  while true:
    add(tok.symbol, L.buf[pos])
    inc(pos)
    if L.buf[pos] notin s: break
  inc(L.col, pos - L.bufpos)
  L.bufpos = pos

proc getAdornment(L: var Lexer, tok: var Token) =
  tok.kind = tkAdornment
  tok.line = L.line
  tok.col = L.col
  var pos = L.bufpos
  var c = L.buf[pos]
  while true:
    add(tok.symbol, L.buf[pos])
    inc(pos)
    if L.buf[pos] != c: break
  inc(L.col, pos - L.bufpos)
  L.bufpos = pos

proc getBracket(L: var Lexer, tok: var Token) =
  tok.kind = tkPunct
  tok.line = L.line
  tok.col = L.col
  add(tok.symbol, L.buf[L.bufpos])
  inc L.col
  inc L.bufpos

proc getIndentAux(L: var Lexer, start: int): int =
  var pos = start
  # skip the newline (but include it in the token!)
  if L.buf[pos] == '\x0D':
    if L.buf[pos + 1] == '\x0A': inc(pos, 2)
    else: inc(pos)
  elif L.buf[pos] == '\x0A':
    inc(pos)
  if L.skipPounds:
    if L.buf[pos] == '#': inc(pos)
    if L.buf[pos] == '#': inc(pos)
  while true:
    case L.buf[pos]
    of ' ', '\x0B', '\x0C':
      inc(pos)
      inc(result)
    of '\x09':
      inc(pos)
      result = result - (result mod 8) + 8
    else:
      break                   # EndOfFile also leaves the loop
  if L.buf[pos] == '\0':
    result = 0
  elif (L.buf[pos] == '\x0A') or (L.buf[pos] == '\x0D'):
    # look at the next line for proper indentation:
    result = getIndentAux(L, pos)
  L.bufpos = pos              # no need to set back buf

proc getIndent(L: var Lexer, tok: var Token) =
  tok.col = 0
  tok.kind = tkIndent         # skip the newline (but include it in the token!)
  tok.ival = getIndentAux(L, L.bufpos)
  inc L.line
  tok.line = L.line
  L.col = tok.ival
  tok.ival = max(tok.ival - L.baseIndent, 0)
  tok.symbol = "\n" & spaces(tok.ival)

proc rawGetTok(L: var Lexer, tok: var Token) =
  tok.symbol = ""
  tok.ival = 0
  var c = L.buf[L.bufpos]
  case c
  of 'a'..'z', 'A'..'Z', '\x80'..'\xFF', '0'..'9':
    getThing(L, tok, SymChars)
  of ' ', '\x09', '\x0B', '\x0C':
    getThing(L, tok, {' ', '\x09'})
    tok.kind = tkWhite
    if L.buf[L.bufpos] in {'\x0D', '\x0A'}:
      rawGetTok(L, tok)       # ignore spaces before \n
  of '\x0D', '\x0A':
    getIndent(L, tok)
  of '!', '\"', '#', '$', '%', '&', '\'',  '*', '+', ',', '-', '.',
     '/', ':', ';', '<', '=', '>', '?', '@', '\\', '^', '_', '`',
     '|', '~':
    getAdornment(L, tok)
    if len(tok.symbol) <= 3: tok.kind = tkPunct
  of '(', ')', '[', ']', '{', '}':
    getBracket(L, tok)
  else:
    tok.line = L.line
    tok.col = L.col
    if c == '\0':
      tok.kind = tkEof
    else:
      tok.kind = tkOther
      add(tok.symbol, c)
      inc(L.bufpos)
      inc(L.col)
  tok.col = max(tok.col - L.baseIndent, 0)

proc getTokens(buffer: string, skipPounds: bool, tokens: var TokenSeq): int =
  var L: Lexer
  var length = len(tokens)
  L.buf = cstring(buffer)
  L.line = 0                  # skip UTF-8 BOM
  if (L.buf[0] == '\xEF') and (L.buf[1] == '\xBB') and (L.buf[2] == '\xBF'):
    inc(L.bufpos, 3)
  L.skipPounds = skipPounds
  if skipPounds:
    if L.buf[L.bufpos] == '#':
      inc(L.bufpos)
      inc(result)
    if L.buf[L.bufpos] == '#':
      inc(L.bufpos)
      inc(result)
    L.baseIndent = 0
    while L.buf[L.bufpos] == ' ':
      inc(L.bufpos)
      inc(L.baseIndent)
      inc(result)
  while true:
    inc(length)
    setLen(tokens, length)
    rawGetTok(L, tokens[length - 1])
    if tokens[length - 1].kind == tkEof: break
  if tokens[0].kind == tkWhite:
    # BUGFIX
    tokens[0].ival = len(tokens[0].symbol)
    tokens[0].kind = tkIndent

type
  LevelMap = array[char, int]
  Substitution = object
    key*: string
    value*: PRstNode

  SharedState = object
    options: RstParseOptions    # parsing options
    uLevel, oLevel: int         # counters for the section levels
    subs: seq[Substitution]     # substitutions
    refs: seq[Substitution]     # references
    underlineToLevel: LevelMap  # Saves for each possible title adornment
                                # character its level in the
                                # current document.
                                # This is for single underline adornments.
    overlineToLevel: LevelMap   # Saves for each possible title adornment
                                # character its level in the current
                                # document.
                                # This is for over-underline adornments.
    msgHandler: MsgHandler      # How to handle errors.
    findFile: FindFileHandler   # How to find files.

  PSharedState = ref SharedState
  RstParser = object of RootObj
    idx*: int
    tok*: TokenSeq
    s*: PSharedState
    indentStack*: seq[int]
    filename*: string
    line*, col*: int
    hasToc*: bool

  EParseError* = object of ValueError

proc whichMsgClass*(k: MsgKind): MsgClass =
  ## returns which message class `k` belongs to.
  case ($k)[1]
  of 'e', 'E': result = mcError
  of 'w', 'W': result = mcWarning
  of 'h', 'H': result = mcHint
  else: assert false, "msgkind does not fit naming scheme"

proc defaultMsgHandler*(filename: string, line, col: int, msgkind: MsgKind,
                        arg: string) {.procvar.} =
  let mc = msgkind.whichMsgClass
  let a = messages[msgkind] % arg
  let message = "$1($2, $3) $4: $5" % [filename, $line, $col, $mc, a]
  if mc == mcError: raise newException(EParseError, message)
  else: writeLine(stdout, message)

proc defaultFindFile*(filename: string): string {.procvar.} =
  if existsFile(filename): result = filename
  else: result = ""

proc newSharedState(options: RstParseOptions,
                    findFile: FindFileHandler,
                    msgHandler: MsgHandler): PSharedState =
  new(result)
  result.subs = @[]
  result.refs = @[]
  result.options = options
  result.msgHandler = if not isNil(msgHandler): msgHandler else: defaultMsgHandler
  result.findFile = if not isNil(findFile): findFile else: defaultFindFile

proc findRelativeFile(p: RstParser; filename: string): string =
  result = p.filename.splitFile.dir / filename
  if not existsFile(result):
    result = p.s.findFile(filename)

proc rstMessage(p: RstParser, msgKind: MsgKind, arg: string) =
  p.s.msgHandler(p.filename, p.line + p.tok[p.idx].line,
                             p.col + p.tok[p.idx].col, msgKind, arg)

proc rstMessage(p: RstParser, msgKind: MsgKind, arg: string, line, col: int) =
  p.s.msgHandler(p.filename, p.line + line,
                             p.col + col, msgKind, arg)

proc rstMessage(p: RstParser, msgKind: MsgKind) =
  p.s.msgHandler(p.filename, p.line + p.tok[p.idx].line,
                             p.col + p.tok[p.idx].col, msgKind,
                             p.tok[p.idx].symbol)

proc currInd(p: RstParser): int =
  result = p.indentStack[high(p.indentStack)]

proc pushInd(p: var RstParser, ind: int) =
  add(p.indentStack, ind)

proc popInd(p: var RstParser) =
  if len(p.indentStack) > 1: setLen(p.indentStack, len(p.indentStack) - 1)

proc initParser(p: var RstParser, sharedState: PSharedState) =
  p.indentStack = @[0]
  p.tok = @[]
  p.idx = 0
  p.filename = ""
  p.hasToc = false
  p.col = 0
  p.line = 1
  p.s = sharedState

proc addNodesAux(n: PRstNode, result: var string) =
  if n.kind == rnLeaf:
    add(result, n.text)
  else:
    for i in countup(0, len(n) - 1): addNodesAux(n.sons[i], result)

proc addNodes(n: PRstNode): string =
  result = ""
  addNodesAux(n, result)

proc rstnodeToRefnameAux(n: PRstNode, r: var string, b: var bool) =
  template special(s) =
    if b:
      add(r, '-')
      b = false
    add(r, s)

  if n == nil: return
  if n.kind == rnLeaf:
    for i in countup(0, len(n.text) - 1):
      case n.text[i]
      of '0'..'9':
        if b:
          add(r, '-')
          b = false
        if len(r) == 0: add(r, 'Z')
        add(r, n.text[i])
      of 'a'..'z', '\128'..'\255':
        if b:
          add(r, '-')
          b = false
        add(r, n.text[i])
      of 'A'..'Z':
        if b:
          add(r, '-')
          b = false
        add(r, chr(ord(n.text[i]) - ord('A') + ord('a')))
      of '$': special "dollar"
      of '%': special "percent"
      of '&': special "amp"
      of '^': special "roof"
      of '!': special "emark"
      of '?': special "qmark"
      of '*': special "star"
      of '+': special "plus"
      of '-': special "minus"
      of '/': special "slash"
      of '\\': special "backslash"
      of '=': special "eq"
      of '<': special "lt"
      of '>': special "gt"
      of '~': special "tilde"
      of ':': special "colon"
      of '.': special "dot"
      of '@': special "at"
      of '|': special "bar"
      else:
        if len(r) > 0: b = true
  else:
    for i in countup(0, len(n) - 1): rstnodeToRefnameAux(n.sons[i], r, b)

proc rstnodeToRefname(n: PRstNode): string =
  result = ""
  var b = false
  rstnodeToRefnameAux(n, result, b)

proc findSub(p: var RstParser, n: PRstNode): int =
  var key = addNodes(n)
  # the spec says: if no exact match, try one without case distinction:
  for i in countup(0, high(p.s.subs)):
    if key == p.s.subs[i].key:
      return i
  for i in countup(0, high(p.s.subs)):
    if cmpIgnoreStyle(key, p.s.subs[i].key) == 0:
      return i
  result = -1

proc setSub(p: var RstParser, key: string, value: PRstNode) =
  var length = len(p.s.subs)
  for i in countup(0, length - 1):
    if key == p.s.subs[i].key:
      p.s.subs[i].value = value
      return
  setLen(p.s.subs, length + 1)
  p.s.subs[length].key = key
  p.s.subs[length].value = value

proc setRef(p: var RstParser, key: string, value: PRstNode) =
  var length = len(p.s.refs)
  for i in countup(0, length - 1):
    if key == p.s.refs[i].key:
      if p.s.refs[i].value.addNodes != value.addNodes:
        rstMessage(p, mwRedefinitionOfLabel, key)

      p.s.refs[i].value = value
      return
  setLen(p.s.refs, length + 1)
  p.s.refs[length].key = key
  p.s.refs[length].value = value

proc findRef(p: var RstParser, key: string): PRstNode =
  for i in countup(0, high(p.s.refs)):
    if key == p.s.refs[i].key:
      return p.s.refs[i].value

proc newLeaf(p: var RstParser): PRstNode =
  result = newRstNode(rnLeaf, p.tok[p.idx].symbol)

proc getReferenceName(p: var RstParser, endStr: string): PRstNode =
  var res = newRstNode(rnInner)
  while true:
    case p.tok[p.idx].kind
    of tkWord, tkOther, tkWhite:
      add(res, newLeaf(p))
    of tkPunct:
      if p.tok[p.idx].symbol == endStr:
        inc(p.idx)
        break
      else:
        add(res, newLeaf(p))
    else:
      rstMessage(p, meExpected, endStr)
      break
    inc(p.idx)
  result = res

proc untilEol(p: var RstParser): PRstNode =
  result = newRstNode(rnInner)
  while not (p.tok[p.idx].kind in {tkIndent, tkEof}):
    add(result, newLeaf(p))
    inc(p.idx)

proc expect(p: var RstParser, tok: string) =
  if p.tok[p.idx].symbol == tok: inc(p.idx)
  else: rstMessage(p, meExpected, tok)

proc isInlineMarkupEnd(p: RstParser, markup: string): bool =
  result = p.tok[p.idx].symbol == markup
  if not result:
    return                    # Rule 3:
  result = not (p.tok[p.idx - 1].kind in {tkIndent, tkWhite})
  if not result:
    return                    # Rule 4:
  result = (p.tok[p.idx + 1].kind in {tkIndent, tkWhite, tkEof}) or
      (p.tok[p.idx + 1].symbol[0] in
      {'\'', '\"', ')', ']', '}', '>', '-', '/', '\\', ':', '.', ',', ';', '!',
       '?', '_'})
  if not result:
    return                    # Rule 7:
  if p.idx > 0:
    if (markup != "``") and (p.tok[p.idx - 1].symbol == "\\"):
      result = false

proc isInlineMarkupStart(p: RstParser, markup: string): bool =
  var d: char
  result = p.tok[p.idx].symbol == markup
  if not result:
    return                    # Rule 1:
  result = (p.idx == 0) or (p.tok[p.idx - 1].kind in {tkIndent, tkWhite}) or
      (p.tok[p.idx - 1].symbol[0] in
      {'\'', '\"', '(', '[', '{', '<', '-', '/', ':', '_'})
  if not result:
    return                    # Rule 2:
  result = not (p.tok[p.idx + 1].kind in {tkIndent, tkWhite, tkEof})
  if not result:
    return                    # Rule 5 & 7:
  if p.idx > 0:
    if p.tok[p.idx - 1].symbol == "\\":
      result = false
    else:
      var c = p.tok[p.idx - 1].symbol[0]
      case c
      of '\'', '\"': d = c
      of '(': d = ')'
      of '[': d = ']'
      of '{': d = '}'
      of '<': d = '>'
      else: d = '\0'
      if d != '\0': result = p.tok[p.idx + 1].symbol[0] != d

proc match(p: RstParser, start: int, expr: string): bool =
  # regular expressions are:
  # special char     exact match
  # 'w'              tkWord
  # ' '              tkWhite
  # 'a'              tkAdornment
  # 'i'              tkIndent
  # 'p'              tkPunct
  # 'T'              always true
  # 'E'              whitespace, indent or eof
  # 'e'              tkWord or '#' (for enumeration lists)
  var i = 0
  var j = start
  var last = len(expr) - 1
  while i <= last:
    case expr[i]
    of 'w': result = p.tok[j].kind == tkWord
    of ' ': result = p.tok[j].kind == tkWhite
    of 'i': result = p.tok[j].kind == tkIndent
    of 'p': result = p.tok[j].kind == tkPunct
    of 'a': result = p.tok[j].kind == tkAdornment
    of 'o': result = p.tok[j].kind == tkOther
    of 'T': result = true
    of 'E': result = p.tok[j].kind in {tkEof, tkWhite, tkIndent}
    of 'e':
      result = (p.tok[j].kind == tkWord) or (p.tok[j].symbol == "#")
      if result:
        case p.tok[j].symbol[0]
        of 'a'..'z', 'A'..'Z', '#': result = len(p.tok[j].symbol) == 1
        of '0'..'9': result = allCharsInSet(p.tok[j].symbol, {'0'..'9'})
        else: result = false
    else:
      var c = expr[i]
      var length = 0
      while (i <= last) and (expr[i] == c):
        inc(i)
        inc(length)
      dec(i)
      result = (p.tok[j].kind in {tkPunct, tkAdornment}) and
          (len(p.tok[j].symbol) == length) and (p.tok[j].symbol[0] == c)
    if not result: return
    inc(j)
    inc(i)
  result = true

proc fixupEmbeddedRef(n, a, b: PRstNode) =
  var sep = - 1
  for i in countdown(len(n) - 2, 0):
    if n.sons[i].text == "<":
      sep = i
      break
  var incr = if (sep > 0) and (n.sons[sep - 1].text[0] == ' '): 2 else: 1
  for i in countup(0, sep - incr): add(a, n.sons[i])
  for i in countup(sep + 1, len(n) - 2): add(b, n.sons[i])

proc parsePostfix(p: var RstParser, n: PRstNode): PRstNode =
  result = n
  if isInlineMarkupEnd(p, "_") or isInlineMarkupEnd(p, "__"):
    inc(p.idx)
    if p.tok[p.idx-2].symbol == "`" and p.tok[p.idx-3].symbol == ">":
      var a = newRstNode(rnInner)
      var b = newRstNode(rnInner)
      fixupEmbeddedRef(n, a, b)
      if len(a) == 0:
        result = newRstNode(rnStandaloneHyperlink)
        add(result, b)
      else:
        result = newRstNode(rnHyperlink)
        add(result, a)
        add(result, b)
        setRef(p, rstnodeToRefname(a), b)
    elif n.kind == rnInterpretedText:
      n.kind = rnRef
    else:
      result = newRstNode(rnRef)
      add(result, n)
  elif match(p, p.idx, ":w:"):
    # a role:
    if p.tok[p.idx + 1].symbol == "idx":
      n.kind = rnIdx
    elif p.tok[p.idx + 1].symbol == "literal":
      n.kind = rnInlineLiteral
    elif p.tok[p.idx + 1].symbol == "strong":
      n.kind = rnStrongEmphasis
    elif p.tok[p.idx + 1].symbol == "emphasis":
      n.kind = rnEmphasis
    elif (p.tok[p.idx + 1].symbol == "sub") or
        (p.tok[p.idx + 1].symbol == "subscript"):
      n.kind = rnSub
    elif (p.tok[p.idx + 1].symbol == "sup") or
        (p.tok[p.idx + 1].symbol == "supscript"):
      n.kind = rnSup
    else:
      result = newRstNode(rnGeneralRole)
      n.kind = rnInner
      add(result, n)
      add(result, newRstNode(rnLeaf, p.tok[p.idx + 1].symbol))
    inc(p.idx, 3)

proc matchVerbatim(p: RstParser, start: int, expr: string): int =
  result = start
  var j = 0
  while j < expr.len and result < p.tok.len and
        continuesWith(expr, p.tok[result].symbol, j):
    inc j, p.tok[result].symbol.len
    inc result
  if j < expr.len: result = 0

proc parseSmiley(p: var RstParser): PRstNode =
  if p.tok[p.idx].symbol[0] notin SmileyStartChars: return
  for key, val in items(Smilies):
    let m = matchVerbatim(p, p.idx, key)
    if m > 0:
      p.idx = m
      result = newRstNode(rnSmiley)
      result.text = val
      return

when false:
  const
    urlChars = {'A'..'Z', 'a'..'z', '0'..'9', ':', '#', '@', '%', '/', ';',
                 '$', '(', ')', '~', '_', '?', '+', '-', '=', '\\', '.', '&',
                 '\128'..'\255'}

proc isUrl(p: RstParser, i: int): bool =
  result = (p.tok[i+1].symbol == ":") and (p.tok[i+2].symbol == "//") and
    (p.tok[i+3].kind == tkWord) and
    (p.tok[i].symbol in ["http", "https", "ftp", "telnet", "file"])

proc parseUrl(p: var RstParser, father: PRstNode) =
  #if p.tok[p.idx].symbol[strStart] == '<':
  if isUrl(p, p.idx):
    var n = newRstNode(rnStandaloneHyperlink)
    while true:
      case p.tok[p.idx].kind
      of tkWord, tkAdornment, tkOther: discard
      of tkPunct:
        if p.tok[p.idx+1].kind notin {tkWord, tkAdornment, tkOther, tkPunct}:
          break
      else: break
      add(n, newLeaf(p))
      inc(p.idx)
    add(father, n)
  else:
    var n = newLeaf(p)
    inc(p.idx)
    if p.tok[p.idx].symbol == "_": n = parsePostfix(p, n)
    add(father, n)

proc parseBackslash(p: var RstParser, father: PRstNode) =
  assert(p.tok[p.idx].kind == tkPunct)
  if p.tok[p.idx].symbol == "\\\\":
    add(father, newRstNode(rnLeaf, "\\"))
    inc(p.idx)
  elif p.tok[p.idx].symbol == "\\":
    # XXX: Unicode?
    inc(p.idx)
    if p.tok[p.idx].kind != tkWhite: add(father, newLeaf(p))
    if p.tok[p.idx].kind != tkEof: inc(p.idx)
  else:
    add(father, newLeaf(p))
    inc(p.idx)

when false:
  proc parseAdhoc(p: var RstParser, father: PRstNode, verbatim: bool) =
    if not verbatim and isURL(p, p.idx):
      var n = newRstNode(rnStandaloneHyperlink)
      while true:
        case p.tok[p.idx].kind
        of tkWord, tkAdornment, tkOther: nil
        of tkPunct:
          if p.tok[p.idx+1].kind notin {tkWord, tkAdornment, tkOther, tkPunct}:
            break
        else: break
        add(n, newLeaf(p))
        inc(p.idx)
      add(father, n)
    elif not verbatim and roSupportSmilies in p.sharedState.options:
      let n = parseSmiley(p)
      if s != nil:
        add(father, n)
    else:
      var n = newLeaf(p)
      inc(p.idx)
      if p.tok[p.idx].symbol == "_": n = parsePostfix(p, n)
      add(father, n)

proc parseUntil(p: var RstParser, father: PRstNode, postfix: string,
                interpretBackslash: bool) =
  let
    line = p.tok[p.idx].line
    col = p.tok[p.idx].col
  inc p.idx
  while true:
    case p.tok[p.idx].kind
    of tkPunct:
      if isInlineMarkupEnd(p, postfix):
        inc(p.idx)
        break
      elif interpretBackslash:
        parseBackslash(p, father)
      else:
        add(father, newLeaf(p))
        inc(p.idx)
    of tkAdornment, tkWord, tkOther:
      add(father, newLeaf(p))
      inc(p.idx)
    of tkIndent:
      add(father, newRstNode(rnLeaf, " "))
      inc(p.idx)
      if p.tok[p.idx].kind == tkIndent:
        rstMessage(p, meExpected, postfix, line, col)
        break
    of tkWhite:
      add(father, newRstNode(rnLeaf, " "))
      inc(p.idx)
    else: rstMessage(p, meExpected, postfix, line, col)

proc parseMarkdownCodeblock(p: var RstParser): PRstNode =
  var args = newRstNode(rnDirArg)
  if p.tok[p.idx].kind == tkWord:
    add(args, newLeaf(p))
    inc(p.idx)
  else:
    args = nil
  var n = newRstNode(rnLeaf, "")
  while true:
    case p.tok[p.idx].kind
    of tkEof:
      rstMessage(p, meExpected, "```")
      break
    of tkPunct:
      if p.tok[p.idx].symbol == "```":
        inc(p.idx)
        break
      else:
        add(n.text, p.tok[p.idx].symbol)
        inc(p.idx)
    else:
      add(n.text, p.tok[p.idx].symbol)
      inc(p.idx)
  var lb = newRstNode(rnLiteralBlock)
  add(lb, n)
  result = newRstNode(rnCodeBlock)
  add(result, args)
  add(result, PRstNode(nil))
  add(result, lb)

proc parseMarkdownLink(p: var RstParser; father: PRstNode): bool =
  result = true
  var desc, link = ""
  var i = p.idx

  template parse(endToken, dest) =
    inc i # skip begin token
    while true:
      if p.tok[i].kind in {tkEof, tkIndent}: return false
      if p.tok[i].symbol == endToken: break
      dest.add p.tok[i].symbol
      inc i
    inc i # skip end token

  parse("]", desc)
  if p.tok[i].symbol != "(": return false
  parse(")", link)
  let child = newRstNode(rnHyperlink)
  child.add desc
  child.add link
  # only commit if we detected no syntax error:
  father.add child
  p.idx = i
  result = true

proc parseInline(p: var RstParser, father: PRstNode) =
  case p.tok[p.idx].kind
  of tkPunct:
    if isInlineMarkupStart(p, "***"):
      var n = newRstNode(rnTripleEmphasis)
      parseUntil(p, n, "***", true)
      add(father, n)
    elif isInlineMarkupStart(p, "**"):
      var n = newRstNode(rnStrongEmphasis)
      parseUntil(p, n, "**", true)
      add(father, n)
    elif isInlineMarkupStart(p, "*"):
      var n = newRstNode(rnEmphasis)
      parseUntil(p, n, "*", true)
      add(father, n)
    elif roSupportMarkdown in p.s.options and p.tok[p.idx].symbol == "```":
      inc(p.idx)
      add(father, parseMarkdownCodeblock(p))
    elif isInlineMarkupStart(p, "``"):
      var n = newRstNode(rnInlineLiteral)
      parseUntil(p, n, "``", false)
      add(father, n)
    elif isInlineMarkupStart(p, "`"):
      var n = newRstNode(rnInterpretedText)
      parseUntil(p, n, "`", true)
      n = parsePostfix(p, n)
      add(father, n)
    elif isInlineMarkupStart(p, "|"):
      var n = newRstNode(rnSubstitutionReferences)
      parseUntil(p, n, "|", false)
      add(father, n)
    elif roSupportMarkdown in p.s.options and
        p.tok[p.idx].symbol == "[" and p.tok[p.idx+1].symbol != "[" and
        parseMarkdownLink(p, father):
      discard "parseMarkdownLink already processed it"
    else:
      if roSupportSmilies in p.s.options:
        let n = parseSmiley(p)
        if n != nil:
          add(father, n)
          return
      parseBackslash(p, father)
  of tkWord:
    if roSupportSmilies in p.s.options:
      let n = parseSmiley(p)
      if n != nil:
        add(father, n)
        return
    parseUrl(p, father)
  of tkAdornment, tkOther, tkWhite:
    if roSupportSmilies in p.s.options:
      let n = parseSmiley(p)
      if n != nil:
        add(father, n)
        return
    add(father, newLeaf(p))
    inc(p.idx)
  else: discard

proc getDirective(p: var RstParser): string =
  if p.tok[p.idx].kind == tkWhite and p.tok[p.idx+1].kind == tkWord:
    var j = p.idx
    inc(p.idx)
    result = p.tok[p.idx].symbol
    inc(p.idx)
    while p.tok[p.idx].kind in {tkWord, tkPunct, tkAdornment, tkOther}:
      if p.tok[p.idx].symbol == "::": break
      add(result, p.tok[p.idx].symbol)
      inc(p.idx)
    if p.tok[p.idx].kind == tkWhite: inc(p.idx)
    if p.tok[p.idx].symbol == "::":
      inc(p.idx)
      if (p.tok[p.idx].kind == tkWhite): inc(p.idx)
    else:
      p.idx = j               # set back
      result = ""             # error
  else:
    result = ""

proc parseComment(p: var RstParser): PRstNode =
  case p.tok[p.idx].kind
  of tkIndent, tkEof:
    if p.tok[p.idx].kind != tkEof and p.tok[p.idx + 1].kind == tkIndent:
      inc(p.idx)              # empty comment
    else:
      var indent = p.tok[p.idx].ival
      while true:
        case p.tok[p.idx].kind
        of tkEof:
          break
        of tkIndent:
          if (p.tok[p.idx].ival < indent): break
        else:
          discard
        inc(p.idx)
  else:
    while p.tok[p.idx].kind notin {tkIndent, tkEof}: inc(p.idx)
  result = nil

type
  DirKind = enum             # must be ordered alphabetically!
    dkNone, dkAuthor, dkAuthors, dkCode, dkCodeBlock, dkContainer, dkContents,
    dkFigure, dkImage, dkInclude, dkIndex, dkRaw, dkTitle

const
  DirIds: array[0..12, string] = ["", "author", "authors", "code",
    "code-block", "container", "contents", "figure", "image", "include",
    "index", "raw", "title"]

proc getDirKind(s: string): DirKind =
  let i = find(DirIds, s)
  if i >= 0: result = DirKind(i)
  else: result = dkNone

proc parseLine(p: var RstParser, father: PRstNode) =
  while true:
    case p.tok[p.idx].kind
    of tkWhite, tkWord, tkOther, tkPunct: parseInline(p, father)
    else: break

proc parseUntilNewline(p: var RstParser, father: PRstNode) =
  while true:
    case p.tok[p.idx].kind
    of tkWhite, tkWord, tkAdornment, tkOther, tkPunct: parseInline(p, father)
    of tkEof, tkIndent: break

proc parseSection(p: var RstParser, result: PRstNode) {.gcsafe.}
proc parseField(p: var RstParser): PRstNode =
  ## Returns a parsed rnField node.
  ##
  ## rnField nodes have two children nodes, a rnFieldName and a rnFieldBody.
  result = newRstNode(rnField)
  var col = p.tok[p.idx].col
  var fieldname = newRstNode(rnFieldName)
  parseUntil(p, fieldname, ":", false)
  var fieldbody = newRstNode(rnFieldBody)
  if p.tok[p.idx].kind != tkIndent: parseLine(p, fieldbody)
  if p.tok[p.idx].kind == tkIndent:
    var indent = p.tok[p.idx].ival
    if indent > col:
      pushInd(p, indent)
      parseSection(p, fieldbody)
      popInd(p)
  add(result, fieldname)
  add(result, fieldbody)

proc parseFields(p: var RstParser): PRstNode =
  ## Parses fields for a section or directive block.
  ##
  ## This proc may return nil if the parsing doesn't find anything of value,
  ## otherwise it will return a node of rnFieldList type with children.
  result = nil
  var atStart = p.idx == 0 and p.tok[0].symbol == ":"
  if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx + 1].symbol == ":") or
      atStart:
    var col = if atStart: p.tok[p.idx].col else: p.tok[p.idx].ival
    result = newRstNode(rnFieldList)
    if not atStart: inc(p.idx)
    while true:
      add(result, parseField(p))
      if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col) and
          (p.tok[p.idx + 1].symbol == ":"):
        inc(p.idx)
      else:
        break

proc getFieldValue*(n: PRstNode): string =
  ## Returns the value of a specific ``rnField`` node.
  ##
  ## This proc will assert if the node is not of the expected type. The empty
  ## string will be returned as a minimum. Any value in the rst will be
  ## stripped form leading/trailing whitespace.
  assert n.kind == rnField
  assert n.len == 2
  assert n.sons[0].kind == rnFieldName
  assert n.sons[1].kind == rnFieldBody
  result = addNodes(n.sons[1]).strip

proc getFieldValue(n: PRstNode, fieldname: string): string =
  result = ""
  if n.sons[1] == nil: return
  if (n.sons[1].kind != rnFieldList):
    #InternalError("getFieldValue (2): " & $n.sons[1].kind)
    # We don't like internal errors here anymore as that would break the forum!
    return
  for i in countup(0, len(n.sons[1]) - 1):
    var f = n.sons[1].sons[i]
    if cmpIgnoreStyle(addNodes(f.sons[0]), fieldname) == 0:
      result = addNodes(f.sons[1])
      if result == "": result = "\x01\x01" # indicates that the field exists
      return

proc getArgument(n: PRstNode): string =
  if n.sons[0] == nil: result = ""
  else: result = addNodes(n.sons[0])

proc parseDotDot(p: var RstParser): PRstNode {.gcsafe.}
proc parseLiteralBlock(p: var RstParser): PRstNode =
  result = newRstNode(rnLiteralBlock)
  var n = newRstNode(rnLeaf, "")
  if p.tok[p.idx].kind == tkIndent:
    var indent = p.tok[p.idx].ival
    inc(p.idx)
    while true:
      case p.tok[p.idx].kind
      of tkEof:
        break
      of tkIndent:
        if (p.tok[p.idx].ival < indent):
          break
        else:
          add(n.text, "\n")
          add(n.text, spaces(p.tok[p.idx].ival - indent))
          inc(p.idx)
      else:
        add(n.text, p.tok[p.idx].symbol)
        inc(p.idx)
  else:
    while not (p.tok[p.idx].kind in {tkIndent, tkEof}):
      add(n.text, p.tok[p.idx].symbol)
      inc(p.idx)
  add(result, n)

proc getLevel(map: var LevelMap, lvl: var int, c: char): int =
  if map[c] == 0:
    inc(lvl)
    map[c] = lvl
  result = map[c]

proc tokenAfterNewline(p: RstParser): int =
  result = p.idx
  while true:
    case p.tok[result].kind
    of tkEof:
      break
    of tkIndent:
      inc(result)
      break
    else: inc(result)

proc isLineBlock(p: RstParser): bool =
  var j = tokenAfterNewline(p)
  result = (p.tok[p.idx].col == p.tok[j].col) and (p.tok[j].symbol == "|") or
      (p.tok[j].col > p.tok[p.idx].col)

proc predNL(p: RstParser): bool =
  result = true
  if p.idx > 0:
    result = p.tok[p.idx-1].kind == tkIndent and
        p.tok[p.idx-1].ival == currInd(p)

proc isDefList(p: RstParser): bool =
  var j = tokenAfterNewline(p)
  result = (p.tok[p.idx].col < p.tok[j].col) and
      (p.tok[j].kind in {tkWord, tkOther, tkPunct}) and
      (p.tok[j - 2].symbol != "::")

proc isOptionList(p: RstParser): bool =
  result = match(p, p.idx, "-w") or match(p, p.idx, "--w") or
           match(p, p.idx, "/w") or match(p, p.idx, "//w")

proc isMarkdownHeadlinePattern(s: string): bool =
  if s.len >= 1 and s.len <= 6:
    for c in s:
      if c != '#': return false
    result = true

proc isMarkdownHeadline(p: RstParser): bool =
  if roSupportMarkdown in p.s.options:
    if isMarkdownHeadlinePattern(p.tok[p.idx].symbol) and p.tok[p.idx+1].kind == tkWhite:
      if p.tok[p.idx+2].kind in {tkWord, tkOther, tkPunct}:
        result = true

proc whichSection(p: RstParser): RstNodeKind =
  case p.tok[p.idx].kind
  of tkAdornment:
    if match(p, p.idx + 1, "ii"): result = rnTransition
    elif match(p, p.idx + 1, " a"): result = rnTable
    elif match(p, p.idx + 1, "i"): result = rnOverline
    elif isMarkdownHeadline(p):
      result = rnHeadline
    else:
      result = rnLeaf
  of tkPunct:
    if isMarkdownHeadline(p):
      result = rnHeadline
    elif match(p, tokenAfterNewline(p), "ai"):
      result = rnHeadline
    elif p.tok[p.idx].symbol == "::":
      result = rnLiteralBlock
    elif predNL(p) and
        ((p.tok[p.idx].symbol == "+") or (p.tok[p.idx].symbol == "*") or
        (p.tok[p.idx].symbol == "-")) and (p.tok[p.idx + 1].kind == tkWhite):
      result = rnBulletList
    elif (p.tok[p.idx].symbol == "|") and isLineBlock(p):
      result = rnLineBlock
    elif (p.tok[p.idx].symbol == "..") and predNL(p):
      result = rnDirective
    elif match(p, p.idx, ":w:") and predNL(p):
      # (p.tok[p.idx].symbol == ":")
      result = rnFieldList
    elif match(p, p.idx, "(e) ") or match(p, p.idx, "e. "):
      result = rnEnumList
    elif match(p, p.idx, "+a+"):
      result = rnGridTable
      rstMessage(p, meGridTableNotImplemented)
    elif isDefList(p):
      result = rnDefList
    elif isOptionList(p):
      result = rnOptionList
    else:
      result = rnParagraph
  of tkWord, tkOther, tkWhite:
    if match(p, tokenAfterNewline(p), "ai"): result = rnHeadline
    elif match(p, p.idx, "e) ") or match(p, p.idx, "e. "): result = rnEnumList
    elif isDefList(p): result = rnDefList
    else: result = rnParagraph
  else: result = rnLeaf

proc parseLineBlock(p: var RstParser): PRstNode =
  result = nil
  if p.tok[p.idx + 1].kind == tkWhite:
    var col = p.tok[p.idx].col
    result = newRstNode(rnLineBlock)
    pushInd(p, p.tok[p.idx + 2].col)
    inc(p.idx, 2)
    while true:
      var item = newRstNode(rnLineBlockItem)
      parseSection(p, item)
      add(result, item)
      if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col) and
          (p.tok[p.idx + 1].symbol == "|") and
          (p.tok[p.idx + 2].kind == tkWhite):
        inc(p.idx, 3)
      else:
        break
    popInd(p)

proc parseParagraph(p: var RstParser, result: PRstNode) =
  while true:
    case p.tok[p.idx].kind
    of tkIndent:
      if p.tok[p.idx + 1].kind == tkIndent:
        inc(p.idx)
        break
      elif (p.tok[p.idx].ival == currInd(p)):
        inc(p.idx)
        case whichSection(p)
        of rnParagraph, rnLeaf, rnHeadline, rnOverline, rnDirective:
          add(result, newRstNode(rnLeaf, " "))
        of rnLineBlock:
          addIfNotNil(result, parseLineBlock(p))
        else: break
      else:
        break
    of tkPunct:
      if (p.tok[p.idx].symbol == "::") and
          (p.tok[p.idx + 1].kind == tkIndent) and
          (currInd(p) < p.tok[p.idx + 1].ival):
        add(result, newRstNode(rnLeaf, ":"))
        inc(p.idx)            # skip '::'
        add(result, parseLiteralBlock(p))
        break
      else:
        parseInline(p, result)
    of tkWhite, tkWord, tkAdornment, tkOther:
      parseInline(p, result)
    else: break

proc parseHeadline(p: var RstParser): PRstNode =
  result = newRstNode(rnHeadline)
  if isMarkdownHeadline(p):
    result.level = p.tok[p.idx].symbol.len
    assert(p.tok[p.idx+1].kind == tkWhite)
    inc p.idx, 2
    parseUntilNewline(p, result)
  else:
    parseUntilNewline(p, result)
    assert(p.tok[p.idx].kind == tkIndent)
    assert(p.tok[p.idx + 1].kind == tkAdornment)
    var c = p.tok[p.idx + 1].symbol[0]
    inc(p.idx, 2)
    result.level = getLevel(p.s.underlineToLevel, p.s.uLevel, c)

type
  IntSeq = seq[int]

proc tokEnd(p: RstParser): int =
  result = p.tok[p.idx].col + len(p.tok[p.idx].symbol) - 1

proc getColumns(p: var RstParser, cols: var IntSeq) =
  var L = 0
  while true:
    inc(L)
    setLen(cols, L)
    cols[L - 1] = tokEnd(p)
    assert(p.tok[p.idx].kind == tkAdornment)
    inc(p.idx)
    if p.tok[p.idx].kind != tkWhite: break
    inc(p.idx)
    if p.tok[p.idx].kind != tkAdornment: break
  if p.tok[p.idx].kind == tkIndent: inc(p.idx)
  # last column has no limit:
  cols[L - 1] = 32000

proc parseDoc(p: var RstParser): PRstNode {.gcsafe.}

proc parseSimpleTable(p: var RstParser): PRstNode =
  var
    cols: IntSeq
    row: seq[string]
    i, last, line: int
    c: char
    q: RstParser
    a, b: PRstNode
  result = newRstNode(rnTable)
  cols = @[]
  row = @[]
  a = nil
  c = p.tok[p.idx].symbol[0]
  while true:
    if p.tok[p.idx].kind == tkAdornment:
      last = tokenAfterNewline(p)
      if p.tok[last].kind in {tkEof, tkIndent}:
        # skip last adornment line:
        p.idx = last
        break
      getColumns(p, cols)
      setLen(row, len(cols))
      if a != nil:
        for j in 0..len(a)-1: a.sons[j].kind = rnTableHeaderCell
    if p.tok[p.idx].kind == tkEof: break
    for j in countup(0, high(row)): row[j] = ""
    # the following while loop iterates over the lines a single cell may span:
    line = p.tok[p.idx].line
    while true:
      i = 0
      while not (p.tok[p.idx].kind in {tkIndent, tkEof}):
        if (tokEnd(p) <= cols[i]):
          add(row[i], p.tok[p.idx].symbol)
          inc(p.idx)
        else:
          if p.tok[p.idx].kind == tkWhite: inc(p.idx)
          inc(i)
      if p.tok[p.idx].kind == tkIndent: inc(p.idx)
      if tokEnd(p) <= cols[0]: break
      if p.tok[p.idx].kind in {tkEof, tkAdornment}: break
      for j in countup(1, high(row)): add(row[j], '\x0A')
    a = newRstNode(rnTableRow)
    for j in countup(0, high(row)):
      initParser(q, p.s)
      q.col = cols[j]
      q.line = line - 1
      q.filename = p.filename
      q.col += getTokens(row[j], false, q.tok)
      b = newRstNode(rnTableDataCell)
      add(b, parseDoc(q))
      add(a, b)
    add(result, a)

proc parseTransition(p: var RstParser): PRstNode =
  result = newRstNode(rnTransition)
  inc(p.idx)
  if p.tok[p.idx].kind == tkIndent: inc(p.idx)
  if p.tok[p.idx].kind == tkIndent: inc(p.idx)

proc parseOverline(p: var RstParser): PRstNode =
  var c = p.tok[p.idx].symbol[0]
  inc(p.idx, 2)
  result = newRstNode(rnOverline)
  while true:
    parseUntilNewline(p, result)
    if p.tok[p.idx].kind == tkIndent:
      inc(p.idx)
      if p.tok[p.idx - 1].ival > currInd(p):
        add(result, newRstNode(rnLeaf, " "))
      else:
        break
    else:
      break
  result.level = getLevel(p.s.overlineToLevel, p.s.oLevel, c)
  if p.tok[p.idx].kind == tkAdornment:
    inc(p.idx)                # XXX: check?
    if p.tok[p.idx].kind == tkIndent: inc(p.idx)

proc parseBulletList(p: var RstParser): PRstNode =
  result = nil
  if p.tok[p.idx + 1].kind == tkWhite:
    var bullet = p.tok[p.idx].symbol
    var col = p.tok[p.idx].col
    result = newRstNode(rnBulletList)
    pushInd(p, p.tok[p.idx + 2].col)
    inc(p.idx, 2)
    while true:
      var item = newRstNode(rnBulletItem)
      parseSection(p, item)
      add(result, item)
      if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col) and
          (p.tok[p.idx + 1].symbol == bullet) and
          (p.tok[p.idx + 2].kind == tkWhite):
        inc(p.idx, 3)
      else:
        break
    popInd(p)

proc parseOptionList(p: var RstParser): PRstNode =
  result = newRstNode(rnOptionList)
  while true:
    if isOptionList(p):
      var a = newRstNode(rnOptionGroup)
      var b = newRstNode(rnDescription)
      var c = newRstNode(rnOptionListItem)
      if match(p, p.idx, "//w"): inc(p.idx)
      while not (p.tok[p.idx].kind in {tkIndent, tkEof}):
        if (p.tok[p.idx].kind == tkWhite) and (len(p.tok[p.idx].symbol) > 1):
          inc(p.idx)
          break
        add(a, newLeaf(p))
        inc(p.idx)
      var j = tokenAfterNewline(p)
      if (j > 0) and (p.tok[j - 1].kind == tkIndent) and
          (p.tok[j - 1].ival > currInd(p)):
        pushInd(p, p.tok[j - 1].ival)
        parseSection(p, b)
        popInd(p)
      else:
        parseLine(p, b)
      if (p.tok[p.idx].kind == tkIndent): inc(p.idx)
      add(c, a)
      add(c, b)
      add(result, c)
    else:
      break

proc parseDefinitionList(p: var RstParser): PRstNode =
  result = nil
  var j = tokenAfterNewline(p) - 1
  if (j >= 1) and (p.tok[j].kind == tkIndent) and
      (p.tok[j].ival > currInd(p)) and (p.tok[j - 1].symbol != "::"):
    var col = p.tok[p.idx].col
    result = newRstNode(rnDefList)
    while true:
      j = p.idx
      var a = newRstNode(rnDefName)
      parseLine(p, a)
      if (p.tok[p.idx].kind == tkIndent) and
          (p.tok[p.idx].ival > currInd(p)) and
          (p.tok[p.idx + 1].symbol != "::") and
          not (p.tok[p.idx + 1].kind in {tkIndent, tkEof}):
        pushInd(p, p.tok[p.idx].ival)
        var b = newRstNode(rnDefBody)
        parseSection(p, b)
        var c = newRstNode(rnDefItem)
        add(c, a)
        add(c, b)
        add(result, c)
        popInd(p)
      else:
        p.idx = j
        break
      if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col):
        inc(p.idx)
        j = tokenAfterNewline(p) - 1
        if j >= 1 and p.tok[j].kind == tkIndent and p.tok[j].ival > col and
            p.tok[j-1].symbol != "::" and p.tok[j+1].kind != tkIndent:
          discard
        else:
          break
    if len(result) == 0: result = nil

proc parseEnumList(p: var RstParser): PRstNode =
  const
    wildcards: array[0..2, string] = ["(e) ", "e) ", "e. "]
    wildpos: array[0..2, int] = [1, 0, 0]
  result = nil
  var w = 0
  while w <= 2:
    if match(p, p.idx, wildcards[w]): break
    inc(w)
  if w <= 2:
    var col = p.tok[p.idx].col
    result = newRstNode(rnEnumList)
    inc(p.idx, wildpos[w] + 3)
    var j = tokenAfterNewline(p)
    if (p.tok[j].col == p.tok[p.idx].col) or match(p, j, wildcards[w]):
      pushInd(p, p.tok[p.idx].col)
      while true:
        var item = newRstNode(rnEnumItem)
        parseSection(p, item)
        add(result, item)
        if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col) and
            match(p, p.idx + 1, wildcards[w]):
          inc(p.idx, wildpos[w] + 4)
        else:
          break
      popInd(p)
    else:
      dec(p.idx, wildpos[w] + 3)
      result = nil

proc sonKind(father: PRstNode, i: int): RstNodeKind =
  result = rnLeaf
  if i < len(father): result = father.sons[i].kind

proc parseSection(p: var RstParser, result: PRstNode) =
  while true:
    var leave = false
    assert(p.idx >= 0)
    while p.tok[p.idx].kind == tkIndent:
      if currInd(p) == p.tok[p.idx].ival:
        inc(p.idx)
      elif p.tok[p.idx].ival > currInd(p):
        pushInd(p, p.tok[p.idx].ival)
        var a = newRstNode(rnBlockQuote)
        parseSection(p, a)
        add(result, a)
        popInd(p)
      else:
        leave = true
        break
    if leave or p.tok[p.idx].kind == tkEof: break
    var a: PRstNode = nil
    var k = whichSection(p)
    case k
    of rnLiteralBlock:
      inc(p.idx)              # skip '::'
      a = parseLiteralBlock(p)
    of rnBulletList: a = parseBulletList(p)
    of rnLineBlock: a = parseLineBlock(p)
    of rnDirective: a = parseDotDot(p)
    of rnEnumList: a = parseEnumList(p)
    of rnLeaf: rstMessage(p, meNewSectionExpected)
    of rnParagraph: discard
    of rnDefList: a = parseDefinitionList(p)
    of rnFieldList:
      if p.idx > 0: dec(p.idx)
      a = parseFields(p)
    of rnTransition: a = parseTransition(p)
    of rnHeadline: a = parseHeadline(p)
    of rnOverline: a = parseOverline(p)
    of rnTable: a = parseSimpleTable(p)
    of rnOptionList: a = parseOptionList(p)
    else:
      #InternalError("rst.parseSection()")
      discard
    if a == nil and k != rnDirective:
      a = newRstNode(rnParagraph)
      parseParagraph(p, a)
    addIfNotNil(result, a)
  if sonKind(result, 0) == rnParagraph and sonKind(result, 1) != rnParagraph:
    result.sons[0].kind = rnInner

proc parseSectionWrapper(p: var RstParser): PRstNode =
  result = newRstNode(rnInner)
  parseSection(p, result)
  while (result.kind == rnInner) and (len(result) == 1):
    result = result.sons[0]

proc `$`(t: Token): string =
  result = $t.kind & ' ' & t.symbol

proc parseDoc(p: var RstParser): PRstNode =
  result = parseSectionWrapper(p)
  if p.tok[p.idx].kind != tkEof:
    when false:
      assert isAllocatedPtr(cast[pointer](p.tok))
      for i in 0 .. high(p.tok):
        assert isNil(p.tok[i].symbol) or
               isAllocatedPtr(cast[pointer](p.tok[i].symbol))
      echo "index: ", p.idx, " length: ", high(p.tok), "##",
          p.tok[p.idx-1], p.tok[p.idx], p.tok[p.idx+1]
    #assert isAllocatedPtr(cast[pointer](p.indentStack))
    rstMessage(p, meGeneralParseError)

type
  DirFlag = enum
    hasArg, hasOptions, argIsFile, argIsWord
  DirFlags = set[DirFlag]
  SectionParser = proc (p: var RstParser): PRstNode {.nimcall.}

proc parseDirective(p: var RstParser, flags: DirFlags): PRstNode =
  ## Parses arguments and options for a directive block.
  ##
  ## A directive block will always have three sons: the arguments for the
  ## directive (rnDirArg), the options (rnFieldList) and the block
  ## (rnLineBlock). This proc parses the two first nodes, the block is left to
  ## the outer `parseDirective` call.
  ##
  ## Both rnDirArg and rnFieldList children nodes might be nil, so you need to
  ## check them before accessing.
  result = newRstNode(rnDirective)
  var args: PRstNode = nil
  var options: PRstNode = nil
  if hasArg in flags:
    args = newRstNode(rnDirArg)
    if argIsFile in flags:
      while true:
        case p.tok[p.idx].kind
        of tkWord, tkOther, tkPunct, tkAdornment:
          add(args, newLeaf(p))
          inc(p.idx)
        else: break
    elif argIsWord in flags:
      while p.tok[p.idx].kind == tkWhite: inc(p.idx)
      if p.tok[p.idx].kind == tkWord:
        add(args, newLeaf(p))
        inc(p.idx)
      else:
        args = nil
    else:
      parseLine(p, args)
  add(result, args)
  if hasOptions in flags:
    if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival >= 3) and
        (p.tok[p.idx + 1].symbol == ":"):
      options = parseFields(p)
  add(result, options)

proc indFollows(p: RstParser): bool =
  result = p.tok[p.idx].kind == tkIndent and p.tok[p.idx].ival > currInd(p)

proc parseDirective(p: var RstParser, flags: DirFlags,
                    contentParser: SectionParser): PRstNode =
  ## Returns a generic rnDirective tree.
  ##
  ## The children are rnDirArg, rnFieldList and rnLineBlock. Any might be nil.
  result = parseDirective(p, flags)
  if not isNil(contentParser) and indFollows(p):
    pushInd(p, p.tok[p.idx].ival)
    var content = contentParser(p)
    popInd(p)
    add(result, content)
  else:
    add(result, PRstNode(nil))

proc parseDirBody(p: var RstParser, contentParser: SectionParser): PRstNode =
  if indFollows(p):
    pushInd(p, p.tok[p.idx].ival)
    result = contentParser(p)
    popInd(p)

proc dirInclude(p: var RstParser): PRstNode =
  #
  #The following options are recognized:
  #
  #start-after : text to find in the external data file
  #    Only the content after the first occurrence of the specified text will
  #    be included.
  #end-before : text to find in the external data file
  #    Only the content before the first occurrence of the specified text
  #    (but after any after text) will be included.
  #literal : flag (empty)
  #    The entire included text is inserted into the document as a single
  #    literal block (useful for program listings).
  #encoding : name of text encoding
  #    The text encoding of the external data file. Defaults to the document's
  #    encoding (if specified).
  #
  result = nil
  var n = parseDirective(p, {hasArg, argIsFile, hasOptions}, nil)
  var filename = strip(addNodes(n.sons[0]))
  var path = p.findRelativeFile(filename)
  if path == "":
    rstMessage(p, meCannotOpenFile, filename)
  else:
    # XXX: error handling; recursive file inclusion!
    if getFieldValue(n, "literal") != "":
      result = newRstNode(rnLiteralBlock)
      add(result, newRstNode(rnLeaf, readFile(path)))
    else:
      var q: RstParser
      initParser(q, p.s)
      q.filename = path
      q.col += getTokens(readFile(path), false, q.tok)
      # workaround a GCC bug; more like the interior pointer bug?
      #if find(q.tok[high(q.tok)].symbol, "\0\x01\x02") > 0:
      #  InternalError("Too many binary zeros in include file")
      result = parseDoc(q)

proc dirCodeBlock(p: var RstParser, nimExtension = false): PRstNode =
  ## Parses a code block.
  ##
  ## Code blocks are rnDirective trees with a `kind` of rnCodeBlock. See the
  ## description of ``parseDirective`` for further structure information.
  ##
  ## Code blocks can come in two forms, the standard `code directive
  ## <http://docutils.sourceforge.net/docs/ref/rst/directives.html#code>`_ and
  ## the nim extension ``.. code-block::``. If the block is an extension, we
  ## want the default language syntax highlighting to be Nim, so we create a
  ## fake internal field to comminicate with the generator. The field is named
  ## ``default-language``, which is unlikely to collide with a field specified
  ## by any random rst input file.
  ##
  ## As an extension this proc will process the ``file`` extension field and if
  ## present will replace the code block with the contents of the referenced
  ## file.
  result = parseDirective(p, {hasArg, hasOptions}, parseLiteralBlock)
  var filename = strip(getFieldValue(result, "file"))
  if filename != "":
    var path = p.findRelativeFile(filename)
    if path == "": rstMessage(p, meCannotOpenFile, filename)
    var n = newRstNode(rnLiteralBlock)
    add(n, newRstNode(rnLeaf, readFile(path)))
    result.sons[2] = n

  # Extend the field block if we are using our custom extension.
  if nimExtension:
    # Create a field block if the input block didn't have any.
    if result.sons[1].isNil: result.sons[1] = newRstNode(rnFieldList)
    assert result.sons[1].kind == rnFieldList
    # Hook the extra field and specify the Nim language as value.
    var extraNode = newRstNode(rnField)
    extraNode.add(newRstNode(rnFieldName))
    extraNode.add(newRstNode(rnFieldBody))
    extraNode.sons[0].add(newRstNode(rnLeaf, "default-language"))
    extraNode.sons[1].add(newRstNode(rnLeaf, "Nim"))
    result.sons[1].add(extraNode)

  result.kind = rnCodeBlock

proc dirContainer(p: var RstParser): PRstNode =
  result = parseDirective(p, {hasArg}, parseSectionWrapper)
  assert(result.kind == rnDirective)
  assert(len(result) == 3)
  result.kind = rnContainer

proc dirImage(p: var RstParser): PRstNode =
  result = parseDirective(p, {hasOptions, hasArg, argIsFile}, nil)
  result.kind = rnImage

proc dirFigure(p: var RstParser): PRstNode =
  result = parseDirective(p, {hasOptions, hasArg, argIsFile},
                          parseSectionWrapper)
  result.kind = rnFigure

proc dirTitle(p: var RstParser): PRstNode =
  result = parseDirective(p, {hasArg}, nil)
  result.kind = rnTitle

proc dirContents(p: var RstParser): PRstNode =
  result = parseDirective(p, {hasArg}, nil)
  result.kind = rnContents

proc dirIndex(p: var RstParser): PRstNode =
  result = parseDirective(p, {}, parseSectionWrapper)
  result.kind = rnIndex

proc dirRawAux(p: var RstParser, result: var PRstNode, kind: RstNodeKind,
               contentParser: SectionParser) =
  var filename = getFieldValue(result, "file")
  if filename.len > 0:
    var path = p.findRelativeFile(filename)
    if path.len == 0:
      rstMessage(p, meCannotOpenFile, filename)
    else:
      var f = readFile(path)
      result = newRstNode(kind)
      add(result, newRstNode(rnLeaf, f))
  else:
    result.kind = kind
    add(result, parseDirBody(p, contentParser))

proc dirRaw(p: var RstParser): PRstNode =
  #
  #The following options are recognized:
  #
  #file : string (newlines removed)
  #    The local filesystem path of a raw data file to be included.
  #
  # html
  # latex
  result = parseDirective(p, {hasOptions, hasArg, argIsWord})
  if result.sons[0] != nil:
    if cmpIgnoreCase(result.sons[0].sons[0].text, "html") == 0:
      dirRawAux(p, result, rnRawHtml, parseLiteralBlock)
    elif cmpIgnoreCase(result.sons[0].sons[0].text, "latex") == 0:
      dirRawAux(p, result, rnRawLatex, parseLiteralBlock)
    else:
      rstMessage(p, meInvalidDirective, result.sons[0].sons[0].text)
  else:
    dirRawAux(p, result, rnRaw, parseSectionWrapper)

proc parseDotDot(p: var RstParser): PRstNode =
  result = nil
  var col = p.tok[p.idx].col
  inc(p.idx)
  var d = getDirective(p)
  if d != "":
    pushInd(p, col)
    case getDirKind(d)
    of dkInclude: result = dirInclude(p)
    of dkImage: result = dirImage(p)
    of dkFigure: result = dirFigure(p)
    of dkTitle: result = dirTitle(p)
    of dkContainer: result = dirContainer(p)
    of dkContents: result = dirContents(p)
    of dkRaw:
      if roSupportRawDirective in p.s.options:
        result = dirRaw(p)
      else:
        rstMessage(p, meInvalidDirective, d)
    of dkCode: result = dirCodeBlock(p)
    of dkCodeBlock: result = dirCodeBlock(p, nimExtension = true)
    of dkIndex: result = dirIndex(p)
    else: rstMessage(p, meInvalidDirective, d)
    popInd(p)
  elif match(p, p.idx, " _"):
    # hyperlink target:
    inc(p.idx, 2)
    var a = getReferenceName(p, ":")
    if p.tok[p.idx].kind == tkWhite: inc(p.idx)
    var b = untilEol(p)
    setRef(p, rstnodeToRefname(a), b)
  elif match(p, p.idx, " |"):
    # substitution definitions:
    inc(p.idx, 2)
    var a = getReferenceName(p, "|")
    var b: PRstNode
    if p.tok[p.idx].kind == tkWhite: inc(p.idx)
    if cmpIgnoreStyle(p.tok[p.idx].symbol, "replace") == 0:
      inc(p.idx)
      expect(p, "::")
      b = untilEol(p)
    elif cmpIgnoreStyle(p.tok[p.idx].symbol, "image") == 0:
      inc(p.idx)
      b = dirImage(p)
    else:
      rstMessage(p, meInvalidDirective, p.tok[p.idx].symbol)
    setSub(p, addNodes(a), b)
  elif match(p, p.idx, " ["):
    # footnotes, citations
    inc(p.idx, 2)
    var a = getReferenceName(p, "]")
    if p.tok[p.idx].kind == tkWhite: inc(p.idx)
    var b = untilEol(p)
    setRef(p, rstnodeToRefname(a), b)
  else:
    result = parseComment(p)

proc resolveSubs(p: var RstParser, n: PRstNode): PRstNode =
  result = n
  if n == nil: return
  case n.kind
  of rnSubstitutionReferences:
    var x = findSub(p, n)
    if x >= 0:
      result = p.s.subs[x].value
    else:
      var key = addNodes(n)
      var e = getEnv(key)
      if e != "": result = newRstNode(rnLeaf, e)
      else: rstMessage(p, mwUnknownSubstitution, key)
  of rnRef:
    var y = findRef(p, rstnodeToRefname(n))
    if y != nil:
      result = newRstNode(rnHyperlink)
      n.kind = rnInner
      add(result, n)
      add(result, y)
  of rnLeaf:
    discard
  of rnContents:
    p.hasToc = true
  else:
    for i in countup(0, len(n) - 1): n.sons[i] = resolveSubs(p, n.sons[i])

proc rstParse*(text, filename: string,
               line, column: int, hasToc: var bool,
               options: RstParseOptions,
               findFile: FindFileHandler = nil,
               msgHandler: MsgHandler = nil): PRstNode =
  var p: RstParser
  initParser(p, newSharedState(options, findFile, msgHandler))
  p.filename = filename
  p.line = line
  p.col = column + getTokens(text, roSkipPounds in options, p.tok)
  result = resolveSubs(p, parseDoc(p))
  hasToc = p.hasToc
