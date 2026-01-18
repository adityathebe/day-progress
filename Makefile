.PHONY: local-install
local-install:
	./scripts/build_app.sh
	rm -rf /Applications/DayProgressMenubar.app
	ditto build/DayProgressMenubar.app /Applications/DayProgressMenubar.app
