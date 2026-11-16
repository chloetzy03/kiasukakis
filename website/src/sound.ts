// Tiny synthesised chime (no audio files). Only plays when the visitor switches sound on.
let ctx: AudioContext | null = null
export const sound = { on: false }

export function chime() {
  if (!sound.on) return
  try {
    ctx = ctx ?? new AudioContext()
    const now = ctx.currentTime
    ;[659.25, 880, 1318.5].forEach((f, i) => {
      const o = ctx!.createOscillator(), g = ctx!.createGain()
      o.type = 'sine'; o.frequency.value = f
      g.gain.setValueAtTime(0.0001, now + i * 0.12)
      g.gain.exponentialRampToValueAtTime(0.18, now + i * 0.12 + 0.02)
      g.gain.exponentialRampToValueAtTime(0.0001, now + i * 0.12 + 0.6)
      o.connect(g).connect(ctx!.destination)
      o.start(now + i * 0.12); o.stop(now + i * 0.12 + 0.65)
    })
  } catch { /* audio unavailable */ }
}
