# Info configuration

## Default shell in macOS

If fish updates:
Best way: System Settings/Users & Groups/{your user} advanced options/Login
shell. Or:
Terminal/Preferences/General/Shells open with: Command (complete path):
/usr/local/bin/fish

06/12/2023:
Remember that yabai wasn't working until you updated the updated fish version
default shell:
/usr/local/Cellar/fish/3.6.1/bin/fish ->
/usr/local/Cellar/fish/3.6.4/bin/fish

## Mac OS Key-Repeat Tester

https://mac-key-repeat.zaymon.dev/
defaults write -g InitialKeyRepeat -int 14
defaults write -g KeyRepeat -int 1
defaults write -g ApplePressAndHoldEnabled -bool false

## Install Nerd Fonts

https://www.geekbits.io/how-to-install-nerd-fonts-on-mac/
https://www.youtube.com/watch?v=mQdB_kHyZn8

## How to fix Homebrew:

Error: Permission denied @ apply2files - /usr/local/lib/docker/cli-plugins
>> mkdir -p /Applications/Docker.app/Contents/Resources/cli-plugins
>> brew cleanup

## Install gSwitch for toggling between battery dynamic and gpu power mode:

https://github.com/CodySchrank/gSwitch

## Don't forget to turn off Automatically rearrange Spaces based on most recent use when implementing Yabai:

System settings / Desktop & Dock / Automatically rearrange Spaces based on
most recent use (at the bottom)

## Change/add chromium extension keymaps:

chrome://extensions/shortcuts

## Chrome extension that enables changing the new tab site

New Tab Redirect
https://chromewebstore.google.com/detail/new-tab-redirect/icpgjfneehieebagbmdbhnlpiopdcmna

## Kitty yank vim mode

https://github.com/yurikhan/kitty_grab

## Yabai borders

https://github.com/FelixKratz/JankyBorders

## Custom cursor

1. Restore the cursor:
System settings > Accessibility > display > Scroll down to pointer and
click reset colors
2. https://github.com/alexzielenski/Mousecape/releases
download Mousecape_1813.zip
3. select cursor
http://www.rw-designer.com/gallery?search=&by=
4. tests cursor here
https://www.w3schools.com/cssref/tryit.php?filename=trycss_cursor

## Keyboard-only operation of macOS apps

https://shortcat.app/

## Add personal git user as owner in the PR's in my repos

📁.git/config
At bottom:
```gitconfig
[user]
	name = sergiornelas
	email = sergio.ornelas.92@outlook.com
```

## Rich oldschool fonts

https://int10h.org/oldschool-pc-fonts/fontlist/

## Doom in terminal

1. >> brew install zig
2. Clone this repo: https://github.com/cryptocode/terminal-doom
3. Move into the repo's directory (terminal-doom)
4. Execute the building and run commmands in the repo's README:
>> zig build -Doptimize=ReleaseFast
>> zig-out/bin/terminal-doom

