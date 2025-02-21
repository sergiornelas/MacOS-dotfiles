# Browser mappings

> [!NOTE]
> Surfing keys/Vimium-c puede mapear arrow keys para ejecutar alguna función
> interna de la extension o emular otro keymap que ejecute alguna acción
> ("map <down> f"), pero no viceversa: mapear maps a arrow keys o keyboard
> output directo: ("map <c-j> <down>")
> Por lo tanto no podemos obtener el efecto de arrow keys desde estas
> extensiones. Es necesario hacerlo directamente desde Karabiner:
> (<ctrl-n/p/f/b>).

## Ctrl+shift+key

### Normal mode

Some sites have defined mappings, for example outlook ctrl-shift-1/2/3/...

### Insert mode

e,a | Visual select insert mode far left/right
f,b | Visual select insert mode one char left/right
n,p | Visual select insert mode up/down
v   | Selects visual to very bottom

### Karabiner mapped

[j]           -> Enter + shift
[t]           -> Reopen tab
[spacebar]    -> Dev tools
[]          -> Visual next/prev word

## Ctrl+key

### Normal mode

Some sites have defined mappings, for example outlook ctrl-r/p/,/.
c   | Copy (mapped in DefaultKeyBinding.Dict)

### Insert mode

e,a | Move end/start of line
f,b | Move move one char *
n,p | Move up/down of line*
v   | Goes to the last bottom *(DefaultKeyBinding.Dict)
----+-------------------
c   | *Copy*                      (DefaultKeyBinding.Dict)
w   | *Delete word left*          (DefaultKeyBinding.Dict)
u   | *Delete all left*           (DefaultKeyBinding.Dict)
t   | Inverts next chat*
y   | Emacs kill ring
k   | Deletes right text
h   | Deletes one char left
d   | Deletes one char right
o   | Moves one char left *

### Karabiner mapped

[f,b,n,p]           -> Arrow keys
[t]                 -> New tab
[i,o]               -> Next/prev tab
[r]                 -> Refresh tab
[l]                 -> Close tab
[,.]                -> Move tab left/right
[j]                 -> Enter
[s]                 -> Search word
[z]                 -> Undo (cmd+z)
[]                -> Next/prev word
[spacebar]          -> Open native tab navigation (?)

## Ctrl+number

[1,2,3,4,5,6,7,8,9] -> Go to # tab

>> Total karabiner browser mappings: 29

## Thinks that are interestig in surfing keys

- Visual mode and sg (search google)
- Visual mode and zz
- Vim editor
- Passthrough mode (alt-i) (suspend extension during a time)
- Omnibar: ctrl-. ctrl-, next/prev page results
- Omnibar: ctrl-d delete item (tab, interesting)
- Omnibar: add page to bookmark
- Omnibar: om check all marks
- ;u url using vim menu

## Score

prev tab     <c-i/o>  | ⌘-i/o      =
new tab      <c-t>    | ⌘ + t      =
reload       <c-r>    | ⌘ + r      =
close tab    <c-l>    | ⌘ + w     +1
find word    <c-s>    | ⌘ + f     -1
back/for history JK*  | ⌘ + []    -1
re-open tab  <c-s-t>  | ⌘ + s + t  =
ganas all ctrl insert             +3
u, w, c, v
y el resto...
f,b,a,e
compatiblidad con neovim/terminal +2
pierdes codesandbox               -1
select all   <c-s-a>    | ⌘ + a   -1

Result = +2 win ✅

---

> [!NOTE]
> All *cmd+shift* and *cmd* mappings are used in normal and 'insert' mode.

## cmd+shift

numbers | screenshot/ video/ etc
delete  | delete browser data
[]      | next/prev tab
q       | quit all applications and logout
w       | close current window
r       | reload current page, ignoring cache content
t       | reopen closed tab
i       | create email with link current page
a       | select tab from list (good)
d       | bookmark all tabs
g       | jump to previous match
h       | open home page in current page
j       | open downloads page
;       | spelling and grammar
c       | dev tools select element
b       | toggle bookmarks bar
n       | new private tab
m       | log in different user

## cmd

numbers | switch to # tab
0       | reset font size
-/+     | zoom in/out
delete  | delete all text (like ctrl+u)
q       | quit
w       | close tab
e       | while find bar open, search current selection
r       | reload page
t       | new tab
y       | history
o       | open file
p       | print
[]      | next,previous tab history
a       | select all (good)
s       | save in finder page
d       | bookmark add
f       | find
g       | find next
h       | hide
l       | open location url
`       | next browser window
z       | undo
x       | cut
c       | copy
v       | paste
b       | leo chat (brave) (good)
n       | new window
m       | minimize
,       | settings

### Verdict

I use the terminal and neovim extensively, so if I return to native command I
will have a conflict between the terminal and the browser using the ctrl
commands: (e, f, n, k, h, d, u, w, a, b, p).
That's why I decided to keep using right cmd as control.
*Alfred* and *Slack* use ctrl commands quite often.

I decided to ditch the keymaps for codesandbox compatibility because:

- Codesandbox mappings are already broken by you (no ctrl+l (c-w-l), no
ctrl+g/t), so it's not like a real improvement.
- It's better to use your native neovim, downloading the repo is quite fast
if you found an interesting project that you want to work on.
- Gain better maps for browser navigation and more keymaps available.
- I barely use codesandbox, so it's not a big deal.

---

21/02/2025

Y
 ____G____;
  *X_____**
  Spacebar

## REMAINING (and interesting)

0       | reset font size
-/+     | zoom in/out
d       | bookmark add
l       | open location url
tab/s-tb| Browse clickable items moving forward/back
a       | select all

## Vimium C discoveries

### Caret mode

when you are in visual mode, press c

### Link hints

If you type the hints in upper case, the link will open in a new tab.

### Activate link hints with digits

- [x] Use the link's name and characters for link-hint filtering

is more similiat to flash, you type the word then enter
