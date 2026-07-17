LOVE = /Applications/love.app/Contents/MacOS/love
LOVE_FILE = lcad.love


build:
	cd game && zip -r ../$(LOVE_FILE) .

run:
	$(LOVE) game

test:
	cd game && lua ../tests/test_all.lua

csv2png:
	$(LOVE) tools/csv2png tools/csv2png/icon.csv game/assets/icon.png FFFFFF 1

reset:
	git reset --hard HEAD
	git clean -fd
