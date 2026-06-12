// Rice Tab — themed dashboard over chrome.bookmarks.
// One-time migration (see bookmarks-data.js): the old bookmarks bar is moved
// into Other Bookmarks → archive, then the curated structure is created.
// After that, ensureCurated() syncs new bookmarks-data.js entries in (add-only).
// Saving is Chrome's own ★ star — new saves surface in the "recent" card,
// where they can be filed into folders. Keys: "/" filter, esc clear.

const $ = (id) => document.getElementById(id);

// ---- clock / vibe motif --------------------------------------------------
function tick() {
  const now = new Date();
  $("clock").textContent = now.toLocaleTimeString([], {
    hour: "2-digit", minute: "2-digit", hour12: false,
  });
  $("date").textContent = now.toLocaleDateString([], {
    weekday: "long", month: "long", day: "numeric",
  });
}
tick();
setInterval(tick, 10_000);

const css = getComputedStyle(document.documentElement);
$("vibe").textContent = css.getPropertyValue("--vibe").replaceAll('"', "").trim();
for (const v of ["--red", "--yellow", "--green", "--cyan", "--blue", "--magenta", "--accent", "--alt"]) {
  const dot = document.createElement("i");
  dot.style.background = `var(${v})`;
  $("palette").append(dot);
}

// ---- bookmarks -----------------------------------------------------------
function favicon(url) {
  const u = new URL(chrome.runtime.getURL("/_favicon/"));
  u.searchParams.set("pageUrl", url);
  u.searchParams.set("size", "32");
  return u.href;
}

async function bookmarksBar() {
  const tree = await chrome.bookmarks.getTree();
  return tree[0].children.find((c) => c.id === "1") ?? tree[0].children[0];
}

async function migrateOnce() {
  const tree = await chrome.bookmarks.getTree();
  const bar = tree[0].children.find((c) => c.id === "1") ?? tree[0].children[0];
  const other = tree[0].children.find((c) => c.id === "2") ?? tree[0].children[1];
  const done = bar.children.some((c) => c.children && c.title === "inbox") ||
    other.children.some((c) => c.title === RICE_ARCHIVE_TITLE);
  if (done) return;

  const arch = await chrome.bookmarks.create({ parentId: other.id, title: RICE_ARCHIVE_TITLE });
  for (const c of [...bar.children]) {
    await chrome.bookmarks.move(c.id, { parentId: arch.id });
  }
  for (const [title, url] of RICE_BAR) {
    await chrome.bookmarks.create({ parentId: bar.id, title, url });
  }
  for (const [name, links] of RICE_FOLDERS) {
    const f = await chrome.bookmarks.create({ parentId: bar.id, title: name });
    for (const [title, url] of links) {
      await chrome.bookmarks.create({ parentId: f.id, title, url });
    }
  }
  toast(`bookmarks reorganized — old set kept in “${RICE_ARCHIVE_TITLE}”`);
}

// add-only sync: anything new in bookmarks-data.js (a pill, a folder, a link
// inside a folder) is created on profiles that already migrated. Never deletes.
async function ensureCurated() {
  const bar = await bookmarksBar();
  const barUrls = new Set(bar.children.filter((n) => n.url).map((n) => n.url));
  for (const [title, url] of RICE_BAR) {
    if (!barUrls.has(url)) await chrome.bookmarks.create({ parentId: bar.id, title, url });
  }
  for (const [name, links] of RICE_FOLDERS) {
    const f = bar.children.find((n) => n.children && n.title === name) ??
      await chrome.bookmarks.create({ parentId: bar.id, title: name });
    const urls = new Set((f.children ?? []).map((n) => n.url));
    for (const [title, url] of links) {
      if (!urls.has(url)) await chrome.bookmarks.create({ parentId: f.id, title, url });
    }
  }
}

let folders = []; // top-level folders of the bar, for filing + rediscover

function link(n, withFile) {
  const a = document.createElement("a");
  a.href = n.url;
  const img = document.createElement("img");
  img.src = favicon(n.url);
  const label = document.createElement("span");
  label.textContent = n.title || n.url;
  a.append(img, label);
  a.dataset.text = `${n.title} ${n.url}`.toLowerCase();
  if (withFile) {
    // file control: visible on hover, moves the bookmark into a folder
    const sel = document.createElement("select");
    sel.append(new Option("file ▸", ""));
    for (const f of folders.filter((f) => f.title !== "inbox")) {
      sel.append(new Option(f.title, f.id));
    }
    sel.addEventListener("change", async () => {
      if (!sel.value) return;
      await chrome.bookmarks.move(n.id, { parentId: sel.value });
      toast(`filed under ${sel.options[sel.selectedIndex].text}`);
      render();
    });
    a.append(sel);
    a.addEventListener("click", (e) => { if (e.target === sel) e.preventDefault(); });
  }
  return a;
}

function card(title, nodes, { cls = "", hint = "", file = false } = {}) {
  const sec = document.createElement("div");
  sec.className = `folder ${cls}`.trim();
  const h = document.createElement("h2");
  h.textContent = title;
  const small = document.createElement("small");
  small.textContent = hint || nodes.length;
  h.append(small);
  const div = document.createElement("div");
  div.className = "links";
  div.append(...nodes.map((n) => link(n, file)));
  sec.append(h, div);
  return sec;
}

// last saves anywhere (chrome's ★ included), minus the pre-rice archive —
// this is how new links enter the page without any custom add dialog
async function recentAdds(n = 8) {
  const [tree, recent] = await Promise.all([
    chrome.bookmarks.getTree(), chrome.bookmarks.getRecent(50),
  ]);
  const archived = new Set();
  (function mark(node, inArch) {
    if (inArch) archived.add(node.id);
    for (const c of node.children ?? []) {
      mark(c, inArch || node.title === RICE_ARCHIVE_TITLE);
    }
  })(tree[0], false);
  return recent.filter((b) => !archived.has(b.id)).slice(0, n);
}

// three random picks from the deep catalog — resurfaces links you forgot
function rediscover() {
  const pool = folders.filter((f) => f.title !== "inbox")
    .flatMap((f) => f.children.filter((n) => n.url));
  const row = $("rediscover");
  row.replaceChildren();
  if (pool.length < 6) return;
  const tag = document.createElement("span");
  tag.textContent = "rediscover ▸";
  const picks = [...pool].sort(() => Math.random() - 0.5).slice(0, 3);
  row.append(tag, ...picks.map((n) => link(n)));
}

async function render() {
  const bar = await bookmarksBar();
  folders = bar.children.filter((n) => n.children);

  $("daily").replaceChildren(...bar.children.filter((n) => n.url).map((n) => link(n)));
  rediscover();

  const root = $("bookmarks");
  root.replaceChildren();

  const recent = await recentAdds();
  if (recent.length) {
    root.append(card("recent", recent, { cls: "recent", hint: "★ lands here — file ▸", file: true }));
  }
  const inbox = folders.find((f) => f.title === "inbox");
  if (inbox?.children.length) {
    root.append(card("inbox", inbox.children.filter((n) => n.url),
      { cls: "inbox", hint: "file me ▸", file: true }));
  }
  for (const f of folders) {
    if (f.title === "inbox") continue;
    root.append(card(f.title, f.children.filter((n) => n.url)));
  }
  applyFilter();
}

// ---- filter --------------------------------------------------------------
function applyFilter() {
  const q = $("search").value.trim().toLowerCase();
  let first = null;
  for (const a of document.querySelectorAll("#bookmarks a, #daily a")) {
    const hit = !q || a.dataset.text.includes(q);
    a.classList.toggle("hidden", !hit);
    a.classList.remove("hit");
    if (hit && q && !first) first = a;
  }
  for (const sec of document.querySelectorAll(".folder")) {
    sec.classList.toggle("hidden", q && !sec.querySelector(".links a:not(.hidden)"));
  }
  $("rediscover").classList.toggle("hidden", !!q);
  if (first) first.classList.add("hit");
  return first;
}

$("search").addEventListener("input", applyFilter);
$("search").addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    const q = $("search").value.trim();
    const first = applyFilter();
    if (first) location.href = first.href;
    else if (q) location.href = "https://www.google.com/search?q=" + encodeURIComponent(q);
  } else if (e.key === "Escape") {
    $("search").value = "";
    applyFilter();
    $("search").blur();
  }
});

// ---- keys / toast ----------------------------------------------------------
document.addEventListener("keydown", (e) => {
  if (/INPUT|SELECT|TEXTAREA/.test(document.activeElement?.tagName)) return;
  if (e.key === "/") { e.preventDefault(); $("search").focus(); }
});

let toastTimer;
function toast(msg) {
  $("toast").textContent = msg;
  $("toast").hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { $("toast").hidden = true; }, 3500);
}

migrateOnce().then(ensureCurated).then(render);
