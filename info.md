# Info configuration

## Default shell in macOS

Update 29/11/2024:
<https://mmazzarolo.com/blog/2023-11-16-my-fish-shell-setup-on-macos/>
You have to reboot to apply changes

If fish updates:
Best way: System Settings/Users & Groups/{your user} advanced options/Login
shell.

28/09/2025:
Remember that yabai wasn't working until you updated the updated fish version
default shell:

/opt/homebrew/Cellar/fish/4.1.0/bin/fish

## Mac OS Key-Repeat Tester

<https://mac-key-repeat.zaymon.dev/>
defaults write -g InitialKeyRepeat -int 14
defaults write -g KeyRepeat -int 1
defaults write -g ApplePressAndHoldEnabled -bool false

## Install Nerd Fonts

brew install --cask font-hack-nerd-font
That's all you need to show the cool emoticons on sketchybar

Iosevka font doesn't support the emoticons

## How to fix Homebrew

Error: Permission denied @ apply2files - /usr/local/lib/docker/cli-plugins
>> mkdir -p /Applications/Docker.app/Contents/Resources/cli-plugins
>> brew cleanup

## Install gSwitch for toggling between battery dynamic and gpu power mode

<https://github.com/CodySchrank/gSwitch>

## Don't forget to turn off Automatically rearrange Spaces based on most recent use when implementing Yabai

System settings / Desktop & Dock / Automatically rearrange Spaces based on
most recent use (at the bottom)

## Yabai doesn't work if you disable Displays have separate Spaces

Desktop & Dock > At the bottom
This option makes the displays (builting and external) combine into just big one
Has conflicts with Yabai (M4)

## Change/add chromium extension keymaps

chrome://extensions/shortcuts

## Chrome extension that enables changing the new tab site

New Tab Redirect
<https://chromewebstore.google.com/detail/new-tab-redirect/icpgjfneehieebagbmdbhnlpiopdcmna>

## Kitty yank vim mode

<https://github.com/yurikhan/kitty_grab>

## Yabai borders

<https://github.com/FelixKratz/JankyBorders>

## Custom cursor

1. Restore the cursor:
System settings > Accessibility > display > Scroll down to pointer and
click reset colors
2. <https://github.com/alexzielenski/Mousecape/releases>
download Mousecape_1813.zip
3. select cursor
<http://www.rw-designer.com/gallery?search=&by=>
4. tests cursor here
<https://www.w3schools.com/cssref/tryit.php?filename=trycss_cursor>
5. For adding Mousecape in the Background:
Open mousecape app -> Install helper tool -> Sweet
A pop up must show.
If that doesn't work, go to System Settings, Privacy & Security, Accessibility
Then plus sign and add Mousecape

## Keyboard-only operation of macOS apps

<https://shortcat.app/>

## Add personal git user as owner in the PR's in my repos

📁.git/config
At bottom:

```gitconfig
[user]
 name = sergiornelas
 email = sergio.ornelas.92@outlook.com
```

## Global gitignore

<https://www.squash.io/how-to-git-ignore-node-modules-folder-everywhere>

touch ~/.gitignore_global
Add: node_modules/
git config --global core.excludesfile ~/.gitignore_global

## Rich oldschool fonts

<https://int10h.org/oldschool-pc-fonts/fontlist/>

## Doom in terminal

1. >> brew install zig
2. Clone this repo: <https://github.com/cryptocode/terminal-doom>
3. Move into the repo's directory (terminal-doom)
4. Execute the building and run commmands in the repo's README:

>> zig build -Doptimize=ReleaseFast
>> zig-out/bin/terminal-doom

## Alfred karabiner mappings make it work

Alfred Preferences > Appearance > Options > Focusing to "Compatibility Mode"

## Brave browser not blocking youtube ads

Check for update or all components:

brave://components/

If this is not working, clear cache

## Mousecape Tahoe OS

<https://github.com/AdamWawrzynkowskiGF/Mousecape-TahoeSupport/releases/tag/PreRelease-v01>

## Add music to Iphone

1. Descarga la cancion con el comando
2. En la app de Music, presiona cmd + o, selecciona la cancion descargada
2.1 _Repite el proceso con todas las canciones que quieras_
4. En finder, selecciona el Iphone, busca la seccion de Musica, y sincroniza
   todas las canciones.

## Adult site DNS for chrome settings (no blocks reddit)

<https://family.cloudflare-dns.com/dns-query>

- Al archivo 'aquel', no cambiarle los permisos (chmod 777)
Se corrompe el archivo y hay que volver a descargarlo.
Incluso los DNS del browser configurados dejan de funcionar

- El archivo, si se encripta (vim -x), deja de funcionar (se corrompe).

- En el file, no olvides poner todas las vertientes:
<www.site.com>
0.0.0.0 site.com
0.0.0.0 <www.site.com>
site.com
