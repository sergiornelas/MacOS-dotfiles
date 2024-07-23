# Browser mappings

> [!NOTE]
> Surfing keys/Vimium-c puede mapear arrow keys para ejecutar alguna función
> interna de la extension o emular otro keymap que ejecute alguna acción
> ("map <down> f"), pero no viceversa: mapear maps a arrow keys o keyboard
> output directo: ("map <c-j> <down>")
> Por lo tanto no podemos obtener el efecto de arrow keys desde estas
> extensiones. Es necesario hacerlo directamente desde Karabiner:
> (<ctrl-shift-h/j/k/l>).

## Ctrl+shift+key

### Normal mode:

Some sites have defined mappings, for example outlook ctrl-shift-1/2/3/...

### Insert mode:

e,a | Visual select insert mode far left/right
f,b | Visual select insert mode one char left/right
n,p | Visual select insert mode up/down
v   | Selects visual to very bottom

### Karabiner mapped

[h,j,k,l]     -> Arrow keys
[spacebar]    -> Dev tools
[t]           -> Reopen tab
[m]           -> Enter + shift

## Ctrl+key

### Normal mode:

Some sites have defined mappings, for example outlook ctrl-r/p/,/.

### Insert mode:

e,a | Move end/start of line
f,b | Move move one char
n,p | Move up/down of line
v   | Goes to the last bottom (lost it for c-v in DefaultKeyBinding.Dict)
----+-------------------
t   | Inverts next chat (lost it for karabiner)
y   | Does some shit ?? Research what it does
k   | Deletes right text
h   | Deletes one char left
d   | Deletes one char right
o   | Moves one char left (like b)

### Karabiner mapped

[spacebar]          -> New tab
[t,g]               -> Next/prev tab
[,.]                -> Move tab left/right
[]                -> Next/prev history
[l]                 -> Refresh tab
[q]                 -> Close tab
[s]                 -> Find word
[j]                 -> Enter
[z]                 -> Undo (cmd+z)

## Ctrl+number

[1,2,3,4,5,6,7,8,9] -> Go to # tab

>> Open a link in new background tab - ⌘ + Click a link
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

## ReDo AGAIN

T
---------------
c = previous match
i = move tab insert mode
w = top window

G
---------------
c = next match

R
---------------
n = undo

L
---------------
w = right window
console clean (⌘ + k solves it)

;
-------
LIBRE

Z
-------
undo

X
-------
n = decrease number

M
-------
n = move below and keep align
Q -------
w = close window

---

## Score

prev tab     <c-t/g>  | <cmd-i/o>  ❌
new tab      <c-space>| ⌘ + t      ❌

reload       <c-l>    | ⌘ + r      ❌
close tab    <c-q>    | ⌘ + w      ❌

find word    <c-s>    | ⌘ + f      ❌

back history <c-\[>   | ⌘ + \]
forward hist <c-]>    | ⌘ + [
re-open tab  <c-s-t>  | ⌘ + s + t

ganas all ctrl insert              ✅✅
u, w, c, v
y el resto...
f,b,a,e

compatiblidad con neovim/terminal  ✅

ganas codesandbox                  ✅

select all   <c-s-a>    | ⌘ + a    ❌

TODO: use native browser go for tab (cmd+shift+a)?
TODO: c-l global map | unable it in

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
a       | select all
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
b       | leo chat (brave)
n       | new window
m       | minimize
,       | settings

### Verdict

I use the terminal and neovim extensively, so if I return to native command I
will have a conflict between the terminal and the browser using the ctrl
commands: (e, f, n, y, k, h, d, u, w, a, b, p).
That's why I decided to keep using right cmd as control.
*Alfred* and *Slack* use ctrl commands quite often.

I decided to ditch the keymaps for codesandbox compatibility because:
- Codesandbox mappings are already broken by you (no ctrl+l (c-w-l), no
ctrl+g/t), so it's not like a real improvement.
- It's better to use your native neovim, downloading the repo is quite fast
if you found an interesting project that you want to work on.
- Gain better maps for browser navigation and more keymaps available.
- I barely use codesandbox, so it's not a big deal.

q___________
 ____g____;
  ______m__
  spacebar

TODO: Try <c-i/o> for next/prev tab, check if feels confortable
if not: - <c-g/t> for next/prev tab
        - spacebar for new tab
        - c-i/o will be free

TODO: Add the remaining mappings to karabiner

My map   |Default⌘ | Action
---------|---------|-------
✅ c-i/o | []      | next/prev tab
✅ c-s-t | t       | reopen closed tab
         | a       | select tab from list (good)
         | g       | jump to previous match
         | c       | dev tools select element
✅ c-#   | numbers | switch to # tab
✅ c-0   | 0       | reset font size
✅ -/+   | -/+     | zoom in/out
✅ c-l   | w       | close tab
✅ c-r   | r       | reload page
✅ c-t   | t       | new tab
✅ c-[]  | []      | next,previous tab history
         | d       | bookmark add
✅ c-s   | f       | find
         | g       | find next
         | l       | jump to address bar

✅ c-z   | z       | undo
✅ c-x   | x       | cut
✅ c-c   | c       | copy
✅ c-v   | v       | paste

✅ c-u   | c-return| delete all text left
✅ c-w   | opt-del | delete prev word
✅ c-j   | enter   | return or enter
✅ c-,   | c-s-PgUp| move tab right
✅ c-.   | c-s-PgDw| move tab left
✅c-s-spa| ⌘+Optn+i| developer tools
         | space   | Scroll down a webpage, a screen at a time
         | S+Space | Scroll up a webpage, a screen at a time

Also move next/backward word?
Option + Left arrow
Option + Right arrow
