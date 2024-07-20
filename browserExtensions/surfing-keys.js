// ====================
// 15/07/2024
// I decided to ditch Surfing Keys for this annoying bug:
// If you click on a YouTube video and then scroll using j/k d/u, the scroll will be stuck in that frame.
// You have to click outside the frame and then scroll again.
// Also, Vimium-c is way more maintained, and I'm not losing any interesting features from Surfing Keys.
// ====================

// an example to create a new mapping `ctrl-y`
api.mapkey("<ctrl-y>", "Show me the money", function () {
  Front.showPopup(
    "a well-known phrase uttered by characters in the 1996 film Jerry Maguire (Escape to close).",
  );
});

// an example to replace `T` with `gt`, click `Default mappings` to see how `T` works.
api.map("gt", "T");

// an example to remove mapkey `Ctrl-i`
api.iunmap("<Ctrl-f>");

api.map("<Ctrl-f>", "<Ctrl-6>");

// multiple sites:
// settings.blocklistPattern = /(youtube|udemy).com/i;
settings.blocklistPattern = /(codesandbox).io/i;

// set theme
settings.theme = `
.sk_theme {
    font-family: Input Sans Condensed, Charcoal, sans-serif;
    font-size: 13pt;
    background: #191A1F;
    color: #D1D1D1;
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
    background: #24272e;
}
.sk_theme #sk_omnibarSearchResult ul li.focused {
    background: #3e4452;
}
#sk_status, #sk_find {
    font-size: 20pt;
}`;
// click `Save` button to make above settings to take effect.</ctrl-i></ctrl-y>

// ====================================
api.Hints.style(
  "font-family: Arial; font-size: 13px; background: initial; background-color: #D4B122;",
);
settings.tabsThreshold = 0;
settings.smoothScroll = false;
settings.scrollStepSize = 140;
settings.hintAlign = "left";
// ====================================
// Consideration:
// api.Hints.setCharacters("ioewafqpsdvm");
// api.map("J", "S");
// api.map("K", "D");
// api.map("e", "T");
// api.map("F", "C");
// api.map("C", "cf");
