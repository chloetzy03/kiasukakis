// Original, brand-coloured SVG scenes for the "what you can do while waiting" sequence.
const W = 1600, H = 900

function Shops() {
  const cols = ['#f5a623', '#bd091c', '#1f7a44', '#1d6fa5', '#c2410c', '#f4c9a6']
  return (
    <g>
      <rect width={W} height={H} fill="#ffe9c9" />
      <g className="par par-1">
        {Array.from({ length: 9 }, (_, i) => (
          <g key={i} transform={`translate(${i * 230 - 60} 250)`}>
            <rect width="210" height="520" rx="10" fill={cols[i % 6]} opacity=".92" />
            <rect x="20" y="40" width="50" height="80" rx="25" fill="#fff8" /><rect x="140" y="40" width="50" height="80" rx="25" fill="#fff8" />
            <rect x="20" y="170" width="50" height="80" rx="25" fill="#fff8" /><rect x="140" y="170" width="50" height="80" rx="25" fill="#fff8" />
            <path d="M0 330 h210 v60 h-210z" fill="#2a1b1d" opacity=".85" />
            {Array.from({ length: 7 }, (_, k) => <rect key={k} x={k * 30} y="330" width="15" height="60" fill="#fffcf7" />)}
            <rect x="60" y="400" width="90" height="120" rx="6" fill="#2a1b1d" opacity=".3" />
          </g>
        ))}
      </g>
      <rect y="770" width={W} height="130" fill="#e4c9a1" />
    </g>
  )
}
function Estate() {
  return (
    <g>
      <rect width={W} height={H} fill="#cdeee0" />
      <circle cx="1250" cy="170" r="90" fill="#fff6d6" />
      <g className="par par-1">
        {Array.from({ length: 5 }, (_, i) => (
          <g key={i} transform={`translate(${i * 380 - 90} ${180 + (i % 2) * 60})`}>
            <rect width="260" height="600" fill={i % 2 ? '#f6e3c4' : '#fbf4ea'} />
            {Array.from({ length: 10 }, (_, r) => Array.from({ length: 5 }, (_, c) => <rect key={`${r}${c}`} x={22 + c * 46} y={30 + r * 56} width="26" height="34" fill={(r + c) % 4 === 0 ? '#f5a623' : '#6e5f5a'} opacity=".55" />))}
            <rect y="0" width="260" height="14" fill="#bd091c" />
          </g>
        ))}
      </g>
      <g className="par par-2">{Array.from({ length: 8 }, (_, i) => <g key={i} transform={`translate(${i * 260} 650)`}><rect x="-8" y="60" width="16" height="140" fill="#6b4a2f" /><circle r="70" cy="40" fill="#1f7a44" /><circle r="48" cx="-40" cy="70" fill="#2a9a58" /></g>)}</g>
      <rect y="780" width={W} height="120" fill="#7fb98e" />
    </g>
  )
}
function Drink() {
  return (
    <g>
      <rect width={W} height={H} fill="#ffd6dc" />
      <g className="par par-1" transform="translate(620 90)">
        <path d="M60 120 H320 L290 700 Q285 740 245 740 H135 Q95 740 90 700Z" fill="#fffcf7" stroke="#2a1b1d" strokeWidth="8" />
        <path d="M80 330 H300 L290 700 Q285 740 245 740 H135 Q95 740 90 700Z" fill="#c98a5b" />
        <rect x="190" y="-40" width="26" height="320" rx="10" fill="#bd091c" transform="rotate(12 190 120)" />
        {Array.from({ length: 22 }, (_, i) => <circle key={i} cx={125 + (i * 37) % 150} cy={640 - Math.floor(i / 5) * 40} r="17" fill="#2a1b1d" />)}
        <rect x="40" y="90" width="300" height="40" rx="20" fill="#fffcf7" stroke="#2a1b1d" strokeWidth="8" />
      </g>
      <g className="par par-2">{Array.from({ length: 12 }, (_, i) => <circle key={i} cx={(i * 211) % W} cy={150 + (i * 97) % 600} r={14 + (i % 4) * 8} fill="#fff" opacity=".6" />)}</g>
    </g>
  )
}
function Bay() {
  return (
    <g>
      <rect width={W} height={H} fill="#bfe3ff" />
      <circle cx="260" cy="190" r="100" fill="#fff4c4" />
      <rect y="640" width={W} height="260" fill="#6fb2e8" />
      <g className="par par-1">
        {[0, 1, 2].map((i) => <rect key={i} x={640 + i * 150} y="250" width="80" height="400" rx="6" fill="#f4efe6" stroke="#2a1b1d" strokeWidth="6" />)}
        <rect x="560" y="200" width="560" height="56" rx="28" fill="#bd091c" stroke="#2a1b1d" strokeWidth="6" />
        {[120, 270, 420].map((x, i) => <rect key={i} x={x} y={470 - i * 50} width="100" height={170 + i * 50} rx="6" fill="#fffcf7" stroke="#2a1b1d" strokeWidth="5" />)}
        {[1180, 1300, 1420].map((x, i) => <rect key={i} x={x} y={500 - i * 30} width="90" height={140 + i * 30} rx="6" fill="#fffcf7" stroke="#2a1b1d" strokeWidth="5" />)}
      </g>
      <g className="par par-2">{Array.from({ length: 9 }, (_, i) => <path key={i} d={`M${i * 190} ${700 + (i % 3) * 40} q40 -22 80 0 t80 0`} stroke="#fff" strokeWidth="6" fill="none" opacity=".7" />)}</g>
    </g>
  )
}

export const scenes = [
  { key: 'shops', label: 'Browse the shops', node: <Shops /> },
  { key: 'estate', label: 'Stroll the neighbourhood', node: <Estate /> },
  { key: 'drink', label: 'Grab a drink', node: <Drink /> },
  { key: 'bay', label: 'Explore somewhere new', node: <Bay /> },
]

export function Scene({ node }: { node: React.ReactNode }) {
  return <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="xMidYMid slice" aria-hidden>{node}</svg>
}
