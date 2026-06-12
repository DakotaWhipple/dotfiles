// Curated bookmark structure applied by newtab.js (the old bar is moved
// wholesale into Other Bookmarks → "archive (pre-rice 2026-06)", never deleted).
// Loose BAR links render as the daily pill row; folders render as cards.
// Add-only sync: new entries here are created on already-migrated profiles
// too, so this file stays the source of truth for the curated set.

const RICE_ARCHIVE_TITLE = "archive (pre-rice 2026-06)";

const RICE_BAR = [
  ["hacker news", "https://news.ycombinator.com/"],
  ["reddit", "https://www.reddit.com/"],
  ["youtube", "https://www.youtube.com/"],
  ["gmail", "https://mail.google.com/"],
  ["gemini", "https://gemini.google.com/"],
  ["whatsapp", "https://web.whatsapp.com/"],
  ["random wiki", "https://en.wikipedia.org/wiki/Special:Random"],
];

const RICE_FOLDERS = [
  ["dev", [
    ["github", "https://github.com/"],
    ["mdn", "https://developer.mozilla.org/"],
    ["devdocs", "https://devdocs.io/"],
    ["go packages", "https://pkg.go.dev/"],
    ["crates.io", "https://crates.io/"],
    ["grep.app — code search", "https://grep.app/"],
    ["regex101", "https://regex101.com/"],
    ["excalidraw", "https://excalidraw.com/"],
    ["jj docs", "https://jj-vcs.github.io/jj/latest/"],
    ["lazyvim", "https://www.lazyvim.org/"],
    ["kitty docs", "https://sw.kovidgoyal.net/kitty/"],
    ["tldr pages", "https://tldr.inbrowser.app/"],
    ["man pages — mankier", "https://www.mankier.com/"],
    ["charm", "https://charm.sh/"],
  ]],
  ["interview", [
    ["leetcode top 150", "https://leetcode.com/studyplan/top-interview-150/"],
    ["neetcode roadmap", "https://neetcode.io/roadmap"],
    ["company-wise problems", "https://github.com/liquidslr/interview-company-wise-problems"],
    ["amazon sde iii prep", "https://amazon.jobs/content/en/how-we-hire/sde-iii-interview-prep"],
    ["faang resume guide", "https://www.reddit.com/r/leetcode/comments/1lrukwz/a_straightforward_guide_to_building_a_faang_ready/"],
    ["levels.fyi", "https://www.levels.fyi/"],
    ["advent of code", "https://adventofcode.com/"],
  ]],
  ["reading", [
    ["lobsters", "https://lobste.rs/"],
    ["drew devault", "https://drewdevault.com/"],
    ["josh comeau", "https://www.joshwcomeau.com/"],
    ["bartosz ciechanowski", "https://ciechanow.ski/"],
    ["luminousmen", "https://luminousmen.com/"],
    ["paul graham essays", "https://paulgraham.com/articles.html"],
    ["sre book", "https://sre.google/sre-book/table-of-contents/"],
    ["book of shaders", "https://thebookofshaders.com/"],
  ]],
  ["design", [
    ["oklch picker", "https://oklch.com/"],
    ["realtime colors", "https://www.realtimecolors.com/"],
    ["dribbble", "https://dribbble.com/"],
    ["behance", "https://www.behance.net/"],
    ["the bézier game", "https://bezier.method.ac/"],
    ["atomic design", "https://atomicdesign.bradfrost.com/"],
    ["palettum", "https://palettum.com/"],
    ["coolors", "https://coolors.co/"],
  ]],
  ["streaming", [
    ["netflix", "https://www.netflix.com/"],
    ["twitch", "https://www.twitch.tv/"],
    ["prime video", "https://www.primevideo.com/"],
    ["hbo max", "https://play.hbomax.com/"],
    ["disney+", "https://www.disneyplus.com/"],
    ["hulu", "https://www.hulu.com/"],
    ["crunchyroll", "https://www.crunchyroll.com/"],
  ]],
  ["tools & media", [
    ["anna's archive", "https://annas-archive.li/"],
    ["freemediaheckyeah", "https://www.reddit.com/r/FREEMEDIAHECKYEAH/wiki/index/"],
    ["wayback machine", "https://web.archive.org/"],
    ["cobalt — save media", "https://cobalt.tools/"],
    ["monkeytype", "https://monkeytype.com/"],
    ["product hunt", "https://www.producthunt.com/"],
  ]],
  ["inbox", []],
];
