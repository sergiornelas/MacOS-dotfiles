// an example to create a new mapping `ctrl-y`
api.mapkey("<ctrl-y>", "Show me the money", function () {
  Front.showPopup(
    "a well-known phrase uttered by characters in the 1996 film Jerry Maguire (Escape to close)."
  );
});

// an example to replace `T` with `gt`, click `Default mappings` to see how `T` works.
api.map("gt", "T");

// an example to remove mapkey `Ctrl-i`
api.unmap("<ctrl-i>");

// set theme
settings.theme = `
.sk_theme {
    font-family: Input Sans Condensed, Charcoal, sans-serif;
    font-size: 10pt;
    background: #24272e;
    color: #abb2bf;
}
.sk_theme tbody {
    /*color: #fff;*/
    color: #C70039;
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
// click `Save` button to make above settings to take effect.</ctrl-i></ctrl-y>
settings.smoothScroll = false;
settings.scrollStepSize = 140;

//settings.useNeovim = true;
api.mapkey("<Ctrl-y>", "Show me the money", function () {
  //Front.showPopup('a well-known phrase uttered by characters in the 1996 film Jerry Maguire (Escape to close).');
  console.log("sergio es grande");
});

// api.map("<Ctrl-j>", "E"); //not necessary, I mapped ctrl+j to ctrl+shift in Karabiner
// api.map("<Ctrl-k>", "R");
// api.map("<Ctrl-t>", "T");
api.map("t", "T");
api.map("J", "S");
api.map("K", "D");
api.map("F", "C");
api.map("p", "u");
api.map("<Ctrl-j>", "<Ctrl-t>");
api.map("<Alt-p>", "<Command-p>"); //pin/unpin?

// cf open multiple links in a new tab
// on open new tab
// g$ go last tab
// g0 go first tab
// zi zoom in
// zo zoom out
// zr zoom reset
