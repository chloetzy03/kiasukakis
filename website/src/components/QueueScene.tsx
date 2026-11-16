import { useLayoutEffect, useRef } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { base } from '../content'
import { useReducedMotion } from '../hooks'

gsap.registerPlugin(ScrollTrigger)

const lines = [
  { text: 'Queue for lunch.', icon: 'FoodBowl', wait: 25 },
  { text: 'Queue for bubble tea.', icon: 'FoodBoba', wait: 38 },
  { text: 'Queue for the latest drop.', icon: 'FoodToast', wait: 52 },
  { text: 'Queue until when sia?', icon: 'FoodChilli', wait: 74 },
]
const palette = ['#bd091c', '#f5a623', '#1f7a44', '#1d6fa5', '#c2410c', '#6e5f5a']
const people = Array.from({ length: 44 }, (_, i) => ({ c: palette[(i * 7 + (i % 3)) % palette.length], h: 40 + ((i * 13) % 14) }))

function Kaki({ c, h, i }: { c: string; h: number; i: number }) {
  return (
    <svg className="kaki" style={{ animationDelay: `${(i % 7) * -0.3}s` }} width="54" height="96" viewBox="0 0 54 96" aria-hidden>
      <circle cx="27" cy="18" r="13" fill="#2a1b1d" />
      <circle cx="27" cy="18" r="11" fill="#f4c9a6" />
      <path d="M16 14 Q27 2 38 14 Q27 8 16 14Z" fill="#2a1b1d" />
      <rect x="9" y="34" width="36" height={h + 8} rx="16" fill={c} />
      <rect x="14" y={34 + h} width="10" height={96 - 34 - h} rx="5" fill="#2a1b1d" />
      <rect x="30" y={34 + h} width="10" height={96 - 34 - h} rx="5" fill="#2a1b1d" />
    </svg>
  )
}

export function QueueScene() {
  const root = useRef<HTMLElement>(null)
  const reduced = useReducedMotion()

  useLayoutEffect(() => {
    if (reduced) return
    const ctx = gsap.context(() => {
      const counter = { v: 0 }
      const out = document.querySelector<HTMLElement>('.q-count')!
      const brand = getComputedStyle(document.documentElement).getPropertyValue('--brand').trim()
      const tl = gsap.timeline({
        defaults: { ease: 'none' },
        scrollTrigger: { trigger: root.current, start: 'top top', end: '+=420%', pin: '.queue-pin', scrub: 0.6, anticipatePin: 1 },
      })
      gsap.set('.q-line', { autoAlpha: 0 })
      gsap.set('.q-line > span', { yPercent: 110 })
      gsap.set('.q-icon', { autoAlpha: 0, scale: 0.6 })
      gsap.set('.q-ask', { autoAlpha: 0 })
      gsap.set('.q-ask .q-mask > span', { yPercent: 110 })
      gsap.set('.kaki', { autoAlpha: 0, y: 40 })

      lines.forEach((l, i) => {
        const t = i * 1.2
        tl.set(`.q-line-${i}`, { autoAlpha: 1 }, t)
        tl.to(`.q-line-${i} > span`, { yPercent: 0, duration: 0.35, ease: 'power3.out' }, t)
        tl.to(`.q-icon-${i}`, { autoAlpha: 1, scale: 1, duration: 0.3, ease: 'back.out(2)' }, t)
        tl.to(counter, { v: l.wait, duration: 1.1, onUpdate: () => { out.textContent = `${Math.round(counter.v)}` } }, t)
        tl.to(`.kaki:nth-child(-n+${[10, 22, 34, 44][i]})`, { autoAlpha: 1, y: 0, duration: 0.5, stagger: 0.025, ease: 'back.out(1.4)' }, t + 0.05)
        if (i < lines.length - 1) {
          tl.to(`.q-line-${i} > span`, { yPercent: -110, duration: 0.3, ease: 'power3.in' }, t + 0.9)
          tl.to(`.q-icon-${i}`, { autoAlpha: 0, scale: 0.6, duration: 0.25 }, t + 0.95)
        }
      })
      tl.to('.queue-row', { x: () => -(document.querySelector<HTMLElement>('.queue-row')!.scrollWidth - innerWidth * 0.55), duration: lines.length * 1.2 }, 0)
      const end = lines.length * 1.2
      tl.to('.q-line-3 > span', { yPercent: -110, duration: 0.3, ease: 'power3.in' }, end - 0.1)
      tl.to('.q-icon-3, .queue-track', { autoAlpha: 0, duration: 0.4 }, end - 0.1)
      tl.to('.queue-pin', { backgroundColor: brand, color: '#fff', duration: 0.5 }, end)
      tl.to('.q-count-wrap', { autoAlpha: 0.0, duration: 0.3 }, end)
      tl.set('.q-ask', { autoAlpha: 1 }, end + 0.15)
      tl.to('.q-ask .q-mask > span', { yPercent: 0, duration: 0.6, stagger: 0.12, ease: 'power4.out' }, end + 0.2)
      tl.to({}, { duration: 0.8 })
    }, root)
    return () => ctx.revert()
  }, [reduced])

  return (
    <section id="story" className="queue" ref={root} aria-labelledby="story-title">
      <h2 id="story-title" className="sr-only">Queueing in Singapore</h2>
      {reduced ? (
        <div className="queue-static">
          {lines.map((l) => <p key={l.text} className="mega">{l.text}</p>)}
          <p className="mega brandtext">What if you didn&rsquo;t have to stand there?</p>
        </div>
      ) : (
        <div className="queue-pin">
          <div className="q-count-wrap" aria-hidden><span className="q-count">0</span><small>min waiting&hellip;</small></div>
          <div className="q-lines">
            {lines.map((l, i) => <p key={l.text} className={`mega q-line q-line-${i}`}><span>{l.text}</span></p>)}
            <p className="mega q-ask">{['What if you', 'didn\u2019t have to', 'stand there?'].map((t) => <span key={t} className="q-mask"><span>{t}</span></span>)}</p>
          </div>
          <div className="q-icons" aria-hidden>
            {lines.map((l, i) => <img key={l.icon} className={`q-icon q-icon-${i}`} src={`${base}icon/${l.icon}.png`} alt="" />)}
          </div>
          <div className="queue-track" aria-hidden>
            <div className="queue-row">{people.map((p, i) => <Kaki key={i} i={i} {...p} />)}</div>
          </div>
        </div>
      )}
    </section>
  )
}
