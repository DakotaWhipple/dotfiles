// Rice Tab — clock + bookmarks bar, colored by the generated theme.css.

function tick() {
  const now = new Date();
  document.getElementById("clock").textContent = now.toLocaleTimeString([], {
    hour: "2-digit", minute: "2-digit", hour12: false,
  });
  document.getElementById("date").textContent = now.toLocaleDateString([], {
    weekday: "long", month: "long", day: "numeric",
  });
}
tick();
setInterval(tick, 10_000);

const vibe = getComputedStyle(document.documentElement)
  .getPropertyValue("--vibe").replaceAll('"', "").trim();
document.getElementById("vibe").textContent = vibe;

function favicon(url) {
  const u = new URL(chrome.runtime.getURL("/_favicon/"));
  u.searchParams.set("pageUrl", url);
  u.searchParams.set("size", "32");
  return u.href;
}

function renderLinks(nodes) {
  const div = document.createElement("div");
  div.className = "links";
  for (const n of nodes.filter((n) => n.url)) {
    const a = document.createElement("a");
    a.href = n.url;
    const img = document.createElement("img");
    img.src = favicon(n.url);
    a.append(img, document.createTextNode(n.title || n.url));
    div.append(a);
  }
  return div;
}

chrome.bookmarks.getTree((tree) => {
  const bar = tree[0].children.find((c) => c.id === "1") ?? tree[0].children[0];
  const root = document.getElementById("bookmarks");

  const loose = bar.children.filter((n) => n.url);
  if (loose.length) root.append(renderLinks(loose));

  for (const folder of bar.children.filter((n) => n.children)) {
    const sec = document.createElement("div");
    sec.className = "folder";
    const h = document.createElement("h2");
    h.textContent = folder.title;
    sec.append(h, renderLinks(folder.children));
    root.append(sec);
  }
});
