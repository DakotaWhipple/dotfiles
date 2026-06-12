// Rice Tab — themed dashboard over chrome.bookmarks.
// One-time migration (see bookmarks-data.js): the old bookmarks bar is moved
// into Other Bookmarks → archive, then the curated structure is created.
// Keys: "/" filter, "a" add (lands in inbox by default), esc clear.

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

let folders = []; // top-level folders of the bar, for the add-dialog + filing

function link(n, inboxOf) {
  const a = document.createElement("a");
  a.href = n.url;
  const img = document.createElement("img");
  img.src = favicon(n.url);
  const label = document.createElement("span");
  label.textContent = n.title || n.url;
  a.append(img, label);
  a.dataset.text = `${n.title} ${n.url}`.toLowerCase();
  if (inboxOf) {
    // file-out control: visible on hover, moves the bookmark out of inbox
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

async function render() {
  const bar = await bookmarksBar();
  folders = bar.children.filter((n) => n.children);

  const daily = $("daily");
  daily.replaceChildren(...bar.children.filter((n) => n.url).map((n) => link(n)));

  const root = $("bookmarks");
  root.replaceChildren();
  const ordered = [...folders].sort((a, b) =>
    (b.title === "inbox" && b.children.length) - (a.title === "inbox" && a.children.length));
  for (const folder of ordered) {
    if (folder.title === "inbox" && !folder.children.length) continue;
    const sec = document.createElement("div");
    sec.className = "folder" + (folder.title === "inbox" ? " inbox" : "");
    const h = document.createElement("h2");
    h.textContent = folder.title;
    const count = document.createElement("small");
    count.textContent = folder.title === "inbox" ? "file me ▸" : folder.children.length;
    h.append(count);
    const div = document.createElement("div");
    div.className = "links";
    div.append(...folder.children.filter((n) => n.url)
      .map((n) => link(n, folder.title === "inbox")));
    sec.append(h, div);
    root.append(sec);
  }

  // fill the add-dialog folder list (inbox first = default target)
  const sel = $("add-folder");
  sel.replaceChildren();
  for (const f of [...folders].sort((a, b) => (b.title === "inbox") - (a.title === "inbox"))) {
    sel.append(new Option(`→ ${f.title}`, f.id));
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

// ---- quick add -----------------------------------------------------------
function openAdd() {
  $("add-overlay").hidden = false;
  $("add-url").focus();
}
function closeAdd() {
  $("add-overlay").hidden = true;
  $("add-form").reset();
}
$("add-btn").addEventListener("click", openAdd);
$("add-cancel").addEventListener("click", closeAdd);
$("add-overlay").addEventListener("click", (e) => {
  if (e.target === $("add-overlay")) closeAdd();
});
$("add-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  let url = $("add-url").value.trim();
  if (!/^[a-z]+:\/\//i.test(url)) url = "https://" + url;
  let title = $("add-title").value.trim();
  try { title ||= new URL(url).hostname.replace(/^www\./, ""); } catch { /* keep as-is */ }
  const sel = $("add-folder");
  await chrome.bookmarks.create({ parentId: sel.value, title, url });
  closeAdd();
  toast(`added to ${sel.options[sel.selectedIndex].text}`);
  render();
});

// ---- keys / toast ----------------------------------------------------------
document.addEventListener("keydown", (e) => {
  const typing = /INPUT|SELECT|TEXTAREA/.test(document.activeElement?.tagName);
  if (!$("add-overlay").hidden) {
    if (e.key === "Escape") closeAdd();
    return;
  }
  if (typing) return;
  if (e.key === "/") { e.preventDefault(); $("search").focus(); }
  if (e.key === "a") { e.preventDefault(); openAdd(); }
});

let toastTimer;
function toast(msg) {
  $("toast").textContent = msg;
  $("toast").hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { $("toast").hidden = true; }, 3500);
}

migrateOnce().then(render);
