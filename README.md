# spoonfish

A half-baked re-implementation of the major parts of
[sdorfehs](https://github.com/jcs/sdorfehs)
in
[Hammerspoon](https://www.hammerspoon.org/).

## Usage

Fetch spoonfish:

	cd ~/.hammerspoon
	git clone https://github.com/jcs/spoonfish.git

Then add it to your ~/.hammerspoon/init.lua script, along with any startup
configuration/commands:

	local spoonfish = require("spoonfish/init")

	spoonfish.apps_to_watch = {
	  "^" .. spoonfish.terminal,
	  "^Firefox",
	  "^Music",
	  "^Photos",
	  "^Xcode",
	  "^Android Studio",
	}
	table.insert(spoonfish.windows_to_ignore, "Extension: (Open in Browser)")

	spoonfish.start()

	local cs = hs.spaces.activeSpaceOnScreen()
	spoonfish.frame_vertical_split(cs, 1)
	spoonfish.frame_horizontal_split(cs, 2)
	spoonfish.frame_focus(cs, 1, true)

## Screenshot

[![Screenshot](https://deskto.ps/u/jcs/d/ulofmj/image)](https://deskto.ps/u/jcs/d/ulofmj)
