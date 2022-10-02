// set theme
settings.theme = `
.sk_theme {
    font-family: Input Sans Condensed, Charcoal, sans-serif;
    font-size: 10pt;
    background: #24272e;
    color: #abb2bf;
}
.sk_theme tbody {
    color: #fff;
}
.sk_theme input {
    color: #d0d0d0;
}
.sk_theme .url {
    color: #61afef;
}
.sk_theme .annotation {
    color: #56b6c2;
}
.sk_theme .omnibar_highlight {
    color: #528bff;
}
.sk_theme .omnibar_timestamp {
    color: #e5c07b;
}
.sk_theme .omnibar_visitcount {
    color: #98c379;
}
.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
    background: #303030;
}
.sk_theme #sk_omnibarSearchResult ul li.focused {
    background: #3e4452;
}
#sk_status, #sk_find {
    font-size: 20pt;
}`;

api.map("J", "S");
api.map("K", "D");
api.map("e", "T");
api.map("F", "C");
api.map("C", "cf");

api.Hints.setCharacters("ioewafqpsdvm");
settings.scrollStepSize = 140;
settings.smoothScroll = false;
settings.tabsThreshold = 0;

// -----------------------------------------------
// an example to create a new mapping `ctrl-y`
// api.mapkey('<ctrl-y>', 'Show me the money', function() {
//    Front.showPopup('a well-known phrase uttered by characters in the 1996 film Jerry Maguire (Escape to close).');
// });

// an example to replace `T` with `gt`, click `Default mappings` to see how `T` works.
// api.map('gt', 'T');

// an example to remove mapkey `Ctrl-i`
// api.unmap('<ctrl-i>');

// -----------------------------------------------
// OMNIBAR
// t      | to search bookmarks/history
// b      | bookmarks
// og     | search on google
//    ctrl+enter | multiple searches (omnibar doesn't close)
//    ctrl+,/.   | show results next/prev page
// ab     | add bookmark

// MARKS
// ma | create mark a
// 'a | go to mark a
// om | check all marks

// SESSION
// ZZ | will save all current tabs into a session named LAST then quit
// ZR | will restore the session named LAST
// ZQ | will just quit
// :  | createSession work
// :  | openSession work
// :  | listSession
// :  | deleteSession work

// URL
// ;u | open vim editor to edit current URL
// yy | copy url

// TAB
// gp | go to playing tab
// gU | Go to root of current URL hierarchy

// MISC
// af     | open new link and direct to new link
// q      | click on an image or a button
// :      | commands you can run calculator there
// V      | selection line block. f,zz works
// sg     | google result registered text
// ctrl-b | insert mode move on char prev
// 3<<    | move tab 3 pages prev (numbers work!)
// I      | input vim mode
// ;e     | open settings editor
// ;pm    | markdown preview
// yg     | copy image
// /      | remember you transform to caret mode
//    ctrl+enter | find exact whole word
