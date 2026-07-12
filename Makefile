LOVE = /Applications/love.app/Contents/MacOS/love
LOVE_FILE = lcad.love


build:
	cd game && zip -r ../$(LOVE_FILE) .

run:
	$(LOVE) game

test:
	cd game && lua ../tests/test_all.lua

