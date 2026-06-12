// rice-cal — month calendar, top-right (under sketchybar), today in accent.

export const command = `
  . "$HOME/.config/theme/colors.sh"
  echo "$ACCENT $FG $FG_MUTED $BG_DARK $BORDER_ACTIVE"
  date +%-d
  cal
`;

export const refreshFrequency = 3600000;

export const className = { right: 44, top: 50 };

const mono = "'JetBrains Mono', Menlo, monospace";

export const render = ({ output }) => {
  const lines = (output || "").trimEnd().split("\n");
  if (lines.length < 4) return null;
  const [accent, fg, muted, bgDark, border] = lines[0].split(" ").map((c) => "#" + c);
  const today = lines[1].trim();
  const [title, weekdays, ...weeks] = lines.slice(2);

  const mark = (line) => {
    // each day is a right-aligned 2-char cell; match today's once, word-bounded
    const re = new RegExp(`(^|\\s)(${today})(?=\\s|$)`);
    const m = line.match(re);
    if (!m) return [line];
    const i = m.index + m[1].length;
    return [
      line.slice(0, i),
      <span key="t" style={{ color: bgDark, background: accent, borderRadius: 3 }}>{today}</span>,
      line.slice(i + today.length),
    ];
  };

  return (
    <div style={{
      fontFamily: mono,
      background: `${bgDark}b8`,
      border: `1px solid ${border}66`,
      borderRadius: 14,
      padding: "14px 18px",
      fontSize: 12,
      lineHeight: 1.7,
      color: fg,
    }}>
      <pre style={{ fontFamily: mono, margin: 0 }}>
        <span style={{ color: accent }}>{title}{"\n"}</span>
        <span style={{ color: muted }}>{weekdays}{"\n"}</span>
        {weeks.map((w, i) => <span key={i}>{mark(w)}{"\n"}</span>)}
      </pre>
    </div>
  );
};
