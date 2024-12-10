# Vimium-C Info

- List of all commands: [138]
    https://github.com/gdh1995/vimium-c/wiki/List-of-all-commands
- typed_commands.d.ts: [179]
    https://github.com/gdh1995/vimium-c/blob/master/background/typed_commands.d.ts#L323
- English: [142/172]
    https://github.com/gdh1995/vimium-c/blob/master/i18n/en/help_dialog.json

[commands](https://github.com/gdh1995/vimium-c/blob/master/i18n/en/help_dialog.json)

semicolon: ";",
period: ".",
question: "?",
NS: " ",
addons: "Firefox Add-ons",
webstore: "Chrome Web Store",
edgestore: "MS Edge Add-ons",
cmdList: "List of Commands",
tipClickToCopy: "Tip: Click a command name to copy it to the clipboard.",
cmdParams: " (use *)",
browserHelp: "Browser shortcuts",
pageNav: "Navigating the page",
useVomnibar: "Using the Vomnibar",
useFind: "Using find",
historyNav: "Navigating history",
changeTabs: "Manipulating tabs",
misc: "Miscellaneous",
advCmd: " advanced commands",
VerIs: "Version ",
HStar: "Star it on GitHub",
HStar2: "Star it on Gitee",
HReview: "Review on ",
HReview_2: "",
ifBug: "Found a bug? ",
HReport: "Report it here",
HCredits: "Credits: ",
HOriginal: " (the original project), ",
HBy: " by ",
HAnd: " and ",
HEnd: ".",

https://github.com/gdh1995/vimium-c#custom-key-mappings

podrias crear un f para links y uno para inputs, asi reducimos las opciones.

@@ LinkHints.activate: "Open a link in the current tab",                 (regular-f)
@@ LinkHints.activateCopyImage: "Copy image to the clipboard",           (yi (fails))
@@ LinkHints.activateCopyLinkText: "Copy a link text to the clipboard",  (useless)
@@ LinkHints.activateCopyLinkUrl: "Copy a link URL to the clipboard",    (yl)
@@ LinkHints.activateDownloadImage: "Download image, video and audio",   (yI)
@@ LinkHints.activateDownloadLink: "Download link URL",                  (not working)
@@ LinkHints.activateEdit: "Select an editable area",                    (f makes-the-job)
@@ LinkHints.activateFocus: "Focus an element",                          (useless)
@@ LinkHints.activateHover: "Select an element and hover",               (useless)
@@ LinkHints.activateLeave: "Let mouse leave link",                      (useless)
@@ LinkHints.activateOpenImage: "Show image in a new tab",               (useless)
@@ LinkHints.activateOpenIncognito: "Open a link in incognito window",   (useless)
@@ LinkHints.activateOpenInNewForegroundTab: "Open a link in a new tab and switch to it", (regular-F)
@@ LinkHints.activateOpenInNewTab: "Open a link in a new tab",           (regular-e)
@@ LinkHints.activateOpenUrl: "Open a URL directly without simulating mouse actions", (like regular-F, but selects only links no inputs)
@@ LinkHints.activateOpenVomnibar: "Edit a link text on Vomnibar",       (useless)
@@ LinkHints.activateSearchLinkText: "Open or search a link text",       (useless)
@@ LinkHints.activateSelect: "Select text and enter visual mode",        (regular-s)
@@ LinkHints.activateWithQueue: "Open multiple links in a new tab",      (regular-q)
@@ LinkHints.click: "Click selected text, focused element or the nearest clicked", (useless)
@@ LinkHints.unhoverLast: "Stop hovering at last location",              (useless)
@@ Marks.activate: "Go to a mark",                                       (regular-')
@@ Marks.activateCreate: "Create a new mark",                            (regular-m)
@@ Marks.clearGlobal: "Remove all global marks",                         (useless)
@@ Marks.clearLocal: "Remove all local marks for this site",             (useless)
@@ Vomnibar.activate: "Open URL, bookmark, or history entry"              (regular-o)
@@ Vomnibar.activateBookmarks: "Open a bookmark",                         (regular-b)
@@ Vomnibar.activateBookmarksInNewTab: "Open a bookmark in a new tab",    (regular-B)
@@ Vomnibar.activateEditUrl: "Edit the current URL",                      (regular-ge)
@@ Vomnibar.activateEditUrlInNewTab: "Edit the current URL and open in a new tab", (regular-gE)
@@ Vomnibar.activateHistory: "Open a history"                             (useless)
@@ Vomnibar.activateHistoryInNewTab: "Open a history in a new tab",       (useless)
@@ Vomnibar.activateInNewTab: "Open URL, history, … in a new tab",        (regular-O)
@@ Vomnibar.activateTabs: "Search through your open tabs",                (regular-T)
@@ addBookmark: "Add tabs into a bookmark folder",                        (useless)
@@ autoCopy: "Copy selected text or current frame's title or URL",        (Y)
@@ autoOpen: "Open selected or copied text in a new tab",                 (yo)
@@ blank: "Do nothing",                                                   (useless)
@@ captureTab: "Capture visible area of current tab",                     (useless)
@@ clearContentSettings: "Clear extension's content settings",            (useless)
@@ clearFindHistory: "Clear find mode history",                           (useless)
@@ closeDownloadBar: "Close the bottom download bar elegantly",           (useless)
@@ closeOtherTabs: "Close all other tabs",                                (X)
@@ closeSomeOtherTabs: "Close other tabs",                                (x)
@@ closeTabsOnLeft: "Close all tabs on the left",                         (<<)
@@ closeTabsOnRight: "Close all tabs on the right                         (>>)
@@ confirm: "Display confirmation dialog and wait",
@@ copyCurrentTitle: "Copy current tab's title",
@@ copyCurrentUrl: "Copy page's info",                                    (yy)
@@ copyWindowInfo: "Copy title/URL info of a current window",
@@ createTab: "Create new tabs",                                          (t)
@@ debugBackground: "Debug the background page",
@@ discardTab: "Discard some other tabs",                                 (??)
@@ dispatchEvent: "Simulate dipatching arbitrary DOM event",              (??)
@@ duplicateTab: "Duplicate current tab for N times",                     (yt)
@@ editText: "Send editing action to browser",                            (??)
@@ enableContentSettingTemp: "Enable the site's ContentSetting in incognito window",
@@ enterFindMode: "Enter find mode",                                      (/)
@@ enterInsertMode: "Enter insert mode",                                  (i)
@@ enterVisualLineMode: "Enter visual line mode",                         (V)
@@ enterVisualMode: "Enter visual mode",                                  (v)
@@ firstTab: "Go to the first N-th tab",
@@ focusInput: "Focus the N-th visible text box on the page and cycle using tab", (a)
@@ focusOrLaunch: "Focus a tab with given URL or open it",
@@ goBack: "Go back in history",                                          (S,J)
@@ goForward: "Go forward in history",                                    (D,K)
@@ goNext: "Follow the link labeled next or \">\"",
@@ goPrevious: "Follow the link labeled previous or \"<\"",
@@ goToRoot: "Go to root of current URL hierarchy",                       (gU)
@@ goUp: "Go up the URL hierarchy",                                       (gu)
@@ joinTabs: "Collect all tabs into current window",
@@ lastTab: "Go to the last N-th tab",
@@ mainFrame: "Select the tab's main/top frame",                          (??)
@@ moveTabLeft: "Move tab to the left",                                   (H)
@@ moveTabRight: "Move tab to the right",                                 (L)
@@ moveTabToIncognito: "Make tab in incognito window",
@@ moveTabToNewWindow: "Move N tabs to new window",
@@ moveTabToNextWindow: "Move tab to next window",                           (W)
@@ nextFrame: "Cycle forward to the next frame on the page",                 (gf)
@@ nextTab: "Go one tab right",                                              (R)
@@ openBookmark: "Open a bookmark (folder)",                             (useless)
@@ openCopiedUrlInCurrentTab: "Open the clipboard's URL in the current tab",(p)
@@ openCopiedUrlInNewTab: "Open the clipboard's URL in N new tabs",         (P)
@@ openUrl: "Open URL",                                                   (same as new tab)
@@ parentFrame: "Focus a parent frame",
@@ passNextKey: "Pass the next keys to the page",                          (;)
@@ performAnotherFind: "Find the second or even earlier query words",
@@ performBackwardsFind: "Cycle backward to the previous find match",      (N)
@@ performFind: "Cycle forward to the next find match",                    (n)
@@ previousTab: "Go one tab left",                                         (E)
@@ reload: "Reload current frame",                                         (r)
@@ reloadGivenTab: "Reload N-th tab",
@@ reloadTab: "Reload N tabs",                                             (r)
@@ removeRightTab: "Close N-th tab on the right",
@@ removeTab: "Close N tabs",                                              (w)
@@ reopenTab: "Reopen current page",
@@ reset: "reset to normal mode",
@@ restoreGivenTab: "Restore the last N-th tab",
@@ restoreTab: "Restore closed tabs",                                      (X)
@@ runKey: "Select and run another mapped key sequence",                   (interesting)
@@ scrollDown: "Scroll down",                                              (j)
@@ scrollFullPageDown: "Scroll a full page down",
@@ scrollFullPageUp: "Scroll a full page up",
@@ scrollLeft: "Scroll left",                                              (h)
@@ scrollPageDown: "Scroll a page down",                                   (d)
@@ scrollPageUp: "Scroll a page up",                                       (u)
@@ scrollPxDown: "Scroll 1px down",
@@ scrollPxLeft: "Scroll 1px left",
@@ scrollPxRight: "Scroll 1px right",
@@ scrollPxUp: "Scroll 1px up",
@@ scrollRight: "Scroll right",                                            (l)
@@ scrollSelect: "Switch in items of a (closed) selection box",
@@ scrollTo: "Scroll to custom position",
@@ scrollToBottom: "Scroll to the bottom of the page",                     (G)
@@ scrollToLeft: "Scroll all the way to the left",                         (zH)
@@ scrollToRight: "Scroll all the way to the right",                       (zL)
@@ scrollToTop: "Scroll to the top of the page",                           (gg)
@@ scrollUp: "Scroll up",                                                  (k)
@@ searchAs: "Search selected or copied text using current search engine", (gy)
@@ searchInAnother: "Redo search in another search engine",
@@ sendToExtension: "Send message to another extension",
@@ showHelp: "Show help",                                                  (?)
@@ showTip: "Show a tip on the HUD",
@@ simulateBackspace: "Simulate backspace once if focused",                (f1)
@@ sortTabs: "Sort all tabs in current window",
@@ switchFocus: "Blur activeElement or refocus it",
@@ toggleContentSetting: "Toggle the site's content settings",
@@ toggleLinkHintCharacters: "Toggle the other link hints",
@@ toggleMuteTab: "Mute or unmute current tab",
@@ togglePinTab: "Pin or unpin N tabs",                                    (gp)
@@ toggleReaderMode: "Toggle reader view",
@@ toggleStyle: "Add or disable CSS styles",
@@ toggleSwitchTemp: "Toggle switch only on current page",
@@ toggleUrl: "Modify the URL of the current tab page and visit",
@@ toggleViewSource: "View page source",
@@ toggleVomnibarStyle: "Toggle styles of vomnibar page",
@@ toggleWindow: "Change window status",
@@ visitPreviousTab: "Go to previously-visited tab on current window",     (c-g/F)
@@ zoom: "Make a current tab zoom",
@@ zoomIn: "Make a current tab zoom in",                                   (zi)
@@ zoomOut: "Make a current tab zoom out",                                 (zo)
@@ zoomReset: "Reset zoom level"                                           (zr)

## Addditional shortcuts with no description

Number of shortcuts: 179 (04/08/2024)
If this number changes (179), it means that there are new shortcuts to add to
the list.
