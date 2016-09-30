nim e install_nimble.nims
nim e tests/test_nimscript.nims
nimble update
nimble install -y zip opengl sdl1 jester@#head niminst
