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
@@ LinkHints.activateOpenInNewTab: "Open a link in a new tab",             (regular-e)
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

Vomnibar.activate: "Open URL, bookmark, or history entry",
Vomnibar.activateBookmarks: "Open a bookmark",
Vomnibar.activateBookmarksInNewTab: "Open a bookmark in a new tab",
Vomnibar.activateEditUrl: "Edit the current URL",
Vomnibar.activateEditUrlInNewTab: "Edit the current URL and open in a new tab",
Vomnibar.activateHistory: "Open a history",
Vomnibar.activateHistoryInNewTab: "Open a history in a new tab",
Vomnibar.activateInNewTab: "Open URL, history, … in a new tab",
Vomnibar.activateTabs: "Search through your open tabs",
addBookmark: "Add tabs into a bookmark folder",
autoCopy: "Copy selected text or current frame's title or URL",
autoOpen: "Open selected or copied text in a new tab",
blank: "Do nothing",
captureTab: "Capture visible area of current tab",
clearContentSettings: "Clear extension's content settings",
clearFindHistory: "Clear find mode history",
closeDownloadBar: "Close the bottom download bar elegantly",
closeOtherTabs: "Close all other tabs",
closeSomeOtherTabs: "Close other tabs",
closeTabsOnLeft: "Close all tabs on the left",
closeTabsOnRight: "Close all tabs on the right",
confirm: "Display confirmation dialog and wait",
copyCurrentTitle: "Copy current tab's title",
copyCurrentUrl: "Copy page's info",
copyWindowInfo: "Copy title/URL info of a current window",
createTab: "Create new tabs",
debugBackground: "Debug the background page",
discardTab: "Discard some other tabs",
dispatchEvent: "Simulate dipatching arbitrary DOM event",
duplicateTab: "Duplicate current tab for N times",
editText: "Send editing action to browser",
enableContentSettingTemp: "Enable the site's ContentSetting in incognito window",
enterFindMode: "Enter find mode",
enterInsertMode: "Enter insert mode",
enterVisualLineMode: "Enter visual line mode",
enterVisualMode: "Enter visual mode",
firstTab: "Go to the first N-th tab",
focusInput: "Focus the N-th visible text box on the page and cycle using tab",
focusOrLaunch: "Focus a tab with given URL or open it",
goBack: "Go back in history",
goForward: "Go forward in history",
goNext: "Follow the link labeled next or \">\"",
goPrevious: "Follow the link labeled previous or \"<\"",
goToRoot: "Go to root of current URL hierarchy",
goUp: "Go up the URL hierarchy",
joinTabs: "Collect all tabs into current window",
lastTab: "Go to the last N-th tab",
mainFrame: "Select the tab's main/top frame",
moveTabLeft: "Move tab to the left",
moveTabRight: "Move tab to the right",
moveTabToIncognito: "Make tab in incognito window",
moveTabToNewWindow: "Move N tabs to new window",
moveTabToNextWindow: "Move tab to next window",
nextFrame: "Cycle forward to the next frame on the page",
nextTab: "Go one tab right",
openBookmark: "Open a bookmark (folder)",
openCopiedUrlInCurrentTab: "Open the clipboard's URL in the current tab",
openCopiedUrlInNewTab: "Open the clipboard's URL in N new tabs",
openUrl: "Open URL",
parentFrame: "Focus a parent frame",
passNextKey: "Pass the next keys to the page",
performAnotherFind: "Find the second or even earlier query words",
performBackwardsFind: "Cycle backward to the previous find match",
performFind: "Cycle forward to the next find match",
previousTab: "Go one tab left",
reload: "Reload current frame",
reloadGivenTab: "Reload N-th tab",
reloadTab: "Reload N tabs",
removeRightTab: "Close N-th tab on the right",
removeTab: "Close N tabs",
reopenTab: "Reopen current page",
reset: "reset to normal mode",
restoreGivenTab: "Restore the last N-th tab",
restoreTab: "Restore closed tabs",
runKey: "Select and run another mapped key sequence",
scrollDown: "Scroll down",
scrollFullPageDown: "Scroll a full page down",
scrollFullPageUp: "Scroll a full page up",
scrollLeft: "Scroll left",
scrollPageDown: "Scroll a page down",
scrollPageUp: "Scroll a page up",
scrollPxDown: "Scroll 1px down",
scrollPxLeft: "Scroll 1px left",
scrollPxRight: "Scroll 1px right",
scrollPxUp: "Scroll 1px up",
scrollRight: "Scroll right",
scrollSelect: "Switch in items of a (closed) selection box",
scrollTo: "Scroll to custom position",
scrollToBottom: "Scroll to the bottom of the page",
scrollToLeft: "Scroll all the way to the left",
scrollToRight: "Scroll all the way to the right",
scrollToTop: "Scroll to the top of the page",
scrollUp: "Scroll up",
searchAs: "Search selected or copied text using current search engine",
searchInAnother: "Redo search in another search engine",
sendToExtension: "Send message to another extension",
showHelp: "Show help",
showTip: "Show a tip on the HUD",
simulateBackspace: "Simulate backspace once if focused",
sortTabs: "Sort all tabs in current window",
switchFocus: "Blur activeElement or refocus it",
toggleContentSetting: "Toggle the site's content settings",
toggleLinkHintCharacters: "Toggle the other link hints",
toggleMuteTab: "Mute or unmute current tab",
togglePinTab: "Pin or unpin N tabs",
toggleReaderMode: "Toggle reader view",
toggleStyle: "Add or disable CSS styles",
toggleSwitchTemp: "Toggle switch only on current page",
toggleUrl: "Modify the URL of the current tab page and visit",
toggleViewSource: "View page source",
toggleVomnibarStyle: "Toggle styles of vomnibar page",
toggleWindow: "Change window status",
visitPreviousTab: "Go to previously-visited tab on current window",
zoom: "Make a current tab zoom",
zoomIn: "Make a current tab zoom in",
zoomOut: "Make a current tab zoom out",
zoomReset: "Reset zoom level"

## Addditional shortcuts with no description

Number of shortcuts: 179 (04/08/2024)
If this number changes (179), it means that there are new shortcuts to add to
the list.

[commands](https://github.com/gdh1995/vimium-c/blob/master/background/typed_commands.d.ts#L323)

LinkHints.activateMode *
LinkHints.activateModeToCopyImage *
LinkHints.activateModeToCopyLinkText *
LinkHints.activateModeToCopyLinkUrl *
LinkHints.activateModeToDownloadImage *
LinkHints.activateModeToDownloadLink *
LinkHints.activateModeToEdit *
LinkHints.activateModeToFocus *
LinkHints.activateModeToHover *
LinkHints.activateModeToLeave *
LinkHints.activateModeToOpenImage *
LinkHints.activateModeToOpenIncognito *
LinkHints.activateModeToOpenInNewForegroundTab *
LinkHints.activateModeToOpenInNewTab *
LinkHints.activateModeToOpenUrl *
LinkHints.activateModeToOpenVomnibar *
LinkHints.activateModeToSearchLinkText *
LinkHints.activateModeToSelect *
LinkHints.activateModeToUnhover *
LinkHints.activateModeWithQueue *
LinkHints.activateUnhover *
Marks.activateCreateMode *
Marks.activateGoto *
Marks.activateGotoMode *
Vomnibar.activateTabSelection *
Vomnibar.activateUrl *
Vomnibar.activateUrlInNewTab *
clearContentSetting   *
clearCS *
enableCSTemp *
newTab *
quickNext *
showHud *
showHUD *
simBackspace *
toggleCS *
wait *
