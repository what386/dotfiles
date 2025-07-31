## Core features

+ Translucent UI
+ Dynamic music widget
+ Session management 
+ Low-battery hibernate
+ Notification center
+ Dynamic wallpaper
+ Global search, like the Windows start menu
+ Weather (OpenWeatherMap) 
+ Quake terminal
+ Hardware monitor
+ Various dynamic widgets 

## Installation and usage

1. Install the [required dependencies](#required-dependencies). Note that there's also [optional dependencies](#optional-dependencies) for full functionality.
2. Clone this repository.

	```bash
	git clone --depth 1 https://github.com/what386/dotfiles/
	```

3. Make sure to create a backup of your old config (if applicable)
4. Copy the contents of the folder to your `"${HOME}"/.config/`.:

	```bash
	cp -r dotfiles/awesome $HOME/.config/awesome
	```

4. Add your specific hardware (like wireless interfaces) to `$HOME/.config/awesome/config/user/machine.lua`).
5. Add your API keys to `$HOME/.config/awesome/config/user/credentials.lua`.
6. Change the global configuration in `$HOME/.config/awesome/config/user/preferences.lua` to your liking.
7. Reload AwesomeWM by pressing <kbd>Super + Shift + r</kbd>.
8. Enjoy! (hopefully)

## Required dependencies

| Name | Description | Why? |
| --- | --- | --- |
| [`awesome-git`](https://github.com/awesomeWM/awesome) |  Highly configurable lua window manager | Hopefully, you know why |
| [`rofi`](https://github.com/davatorium/rofi) | Window switcher, app launcher, dmenu replacement | App launcher and menu framework |
| [`picom-git`](https://github.com/yshui/picom) | Compositor for X11 | Compositor with kawase-blur |

## Optional dependencies

### CLI tools (CANNOT be replaced without widget rewrite)

| Name | Description | Why? |
| --- | --- | --- |
| redshift | Blue light blocker | Blue light widget |
| xprop | X11 property display | Custom titlebars |
| xdg-user-dirs | Manage /home/*, like Documents | XDG widgets |
| iproute2, iw | Network connection managers | Network widgets |
| xclip | X11 Clipboard CLI | Clipboard manager module, and for screenshots |
| flameshot | Screenshot manager | Tool to take screenshots |
| patctl | Audio manager | Audio and microphone widgets |
| brightnessctl | Brightness manager | Brightness widgets |
| acpi | Manages power settings | Battery widget, and hibernate module |

### Default applications (easily replaced in config file)

| Name | Description | Why? |
| --- | --- | --- |
| blueman | Bluetooth manager | Default bluetooth manager |
| gnome-power-statistics | Gnome GUI power info | Default power manager |
| mintinstall | Mint's software manager | Default software manager |
| mintupdate | Mint's update manager | Default update manager |
| cinnamon-settings | Settings for Cinnamon DE | Default everything-else manager|
| [`kitty`](https://github.com/kovidgoyal/kitty) | GPU-accelerated terminal emulator | Quake terminal | 

## TODO:

+ Custom lua lockscreen
+ Clipboard manager
+ Try and prevent camera light from appearing via the auto-brightness module 
