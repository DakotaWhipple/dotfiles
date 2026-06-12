// rice-clock — big thin clock + date + vibe + palette strip, bottom-left.
// Desktop sibling of the Chrome new tab header and `home` in the terminal.
// Colors come from the active vibe; `theme set` refreshes Übersicht.

export const command = `
  . "$HOME/.config/theme/colors.sh"
  date +%H:%M
  date '+%A, %B %-d'
  echo "$THEME_NAME"
  echo "$ACCENT $ACCENT_ALT $FG $FG_MUTED $BG_DARK $BORDER_ACTIVE"
  echo "$RED $YELLOW $GREEN $CYAN $BLUE $MAGENTA"
`;

export const refreshFrequency = 10000;

export const className = { left: 44, bottom: 44 };

const mono = "'JetBrains Mono', Menlo, monospace";

export const render = ({ output }) => {
  const [time, date, vibe, roles = "", ansi = ""] = (output || "").trim().split("\n");
  if (!vibe) return null;
  const [accent, alt, fg, muted, bgDark, border] = roles.split(" ").map((c) => "#" + c);
  const strip = [...ansi.split(" "), accent.slice(1), alt.slice(1)];

  return (
    <div style={{
      fontFamily: mono,
      background: `${bgDark}b8`,
      border: `1px solid ${border}66`,
      borderRadius: 14,
      padding: "18px 26px 16px",
      color: fg,
    }}>
      <div style={{ fontSize: 64, fontWeight: 200, letterSpacing: -2, lineHeight: 1, color: fg }}>
        {time}
      </div>
      <div style={{ fontSize: 13, color: muted, marginTop: 8 }}>{date}</div>
      <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 12 }}>
        <span style={{ fontSize: 12, color: accent }}>● {vibe}</span>
        <span style={{ display: "flex", gap: 4 }}>
          {strip.map((c, i) => (
            <i key={i} style={{
              width: 12, height: 12, borderRadius: 3,
              background: c.startsWith("#") ? c : "#" + c, display: "inline-block",
            }} />
          ))}
        </span>
      </div>
    </div>
  );
};
