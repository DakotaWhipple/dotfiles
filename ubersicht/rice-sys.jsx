// rice-sys — quiet system glance, bottom-right: load, memory, disk, uptime.
// Same card language as rice-clock / the Chrome new tab.

export const command = `
  . "$HOME/.config/theme/colors.sh"
  echo "$ACCENT $ACCENT_ALT $FG $FG_MUTED $BG_DARK $BORDER_ACTIVE $GREEN $YELLOW $RED"
  sysctl -n vm.loadavg | awk '{print $2}'
  sysctl -n hw.ncpu
  ps -A -o rss | awk -v t="$(sysctl -n hw.memsize)" '{s+=$1} END {printf "%.0f %.0f", s*1024/1073741824, t/1073741824}'
  echo
  df -h / | awk 'NR==2 {gsub("%","",$5); print $4, $5}'
  b=$(sysctl -n kern.boottime | sed 's/.*{ sec = \\([0-9]*\\),.*/\\1/')
  s=$(( $(date +%s) - b ))
  printf '%dd %dh' $((s / 86400)) $(( (s % 86400) / 3600 ))
`;

export const refreshFrequency = 20000;

export const className = { right: 44, bottom: 44 };

const mono = "'JetBrains Mono', Menlo, monospace";

const Meter = ({ frac, color, track }) => (
  <div style={{ background: track, borderRadius: 3, height: 5, width: 130, marginTop: 4 }}>
    <div style={{
      background: color, borderRadius: 3, height: 5,
      width: `${Math.min(100, Math.round(frac * 100))}%`,
    }} />
  </div>
);

export const render = ({ output }) => {
  const lines = (output || "").trim().split("\n");
  if (lines.length < 5) return null;
  const [accent, alt, fg, muted, bgDark, border, green, yellow, red] =
    lines[0].split(" ").map((c) => "#" + c);
  const load = parseFloat(lines[1]);
  const ncpu = parseInt(lines[2], 10);
  const [memUsed, memTotal] = lines[3].split(" ").map(Number);
  const [diskFree, diskPct] = lines[4].split(" ");
  const up = lines[5];
  const track = `${border}40`;
  const grade = (f) => (f < 0.6 ? green : f < 0.85 ? yellow : red);

  const row = { display: "flex", justifyContent: "space-between", gap: 24, marginTop: 10 };
  const label = { color: muted, fontSize: 11 };
  const val = { color: fg, fontSize: 12, textAlign: "right" };

  return (
    <div style={{
      fontFamily: mono,
      background: `${bgDark}b8`,
      border: `1px solid ${border}66`,
      borderRadius: 14,
      padding: "14px 20px 16px",
      minWidth: 210,
    }}>
      <div style={{ fontSize: 12, color: accent, marginBottom: 2 }}>sys</div>
      <div style={row}>
        <span style={label}>load</span>
        <span style={val}>{load.toFixed(2)}<Meter frac={load / ncpu} color={grade(load / ncpu)} track={track} /></span>
      </div>
      <div style={row}>
        <span style={label}>mem</span>
        <span style={val}>{memUsed}/{memTotal}G<Meter frac={memUsed / memTotal} color={grade(memUsed / memTotal)} track={track} /></span>
      </div>
      <div style={row}>
        <span style={label}>disk</span>
        <span style={val}>{diskFree} free<Meter frac={diskPct / 100} color={grade(diskPct / 100)} track={track} /></span>
      </div>
      <div style={row}>
        <span style={label}>up</span>
        <span style={{ ...val, color: alt }}>{up}</span>
      </div>
    </div>
  );
};
