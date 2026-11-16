import { useLayoutEffect, useRef, useState } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { Phone } from './Phone'
import { Scene, scenes } from './Scenery'
import { useReducedMotion } from '../hooks'
import { chime } from '../sound'

gsap.registerPlugin(ScrollTrigger)
const shots = ['ticket1', 'ticket2', 'ticket3']
const status = ['3 groups ahead', '1 group ahead', 'Your turn!']

export function Waiting() {
  const root = useRef<HTMLElement>(null)
  const reduced = useReducedMotion()
  const [env, setEnv] = useState(0)
  const [shot, setShot] = useState(0)
  const rang = useRef(false)

  useLayoutEffect(() => {
    if (reduced) return
    const ctx = gsap.context(() => {
      const n = scenes.length
      gsap.set('.wt5-env', { autoAlpha: 0 })
      gsap.set('.wt5-env-0', { autoAlpha: 1 })
      const tl = gsap.timeline({
        defaults: { ease: 'none' },
        scrollTrigger: {
          trigger: root.current, start: 'top top', end: `+=${n * 100 + 80}%`, pin: '.wt5-pin', scrub: 0.8, anticipatePin: 1,
          onUpdate: (st) => {
            const p = st.progress
            setEnv(Math.min(n - 1, Math.floor(p * 1.15 * n)))
            setShot(p < 0.38 ? 0 : p < 0.7 ? 1 : 2)
            if (p > 0.86 && !rang.current) { rang.current = true; chime() }
            if (p < 0.8) rang.current = false
          },
        },
      })
      for (let i = 1; i < n; i++) tl.to(`.wt5-env-${i}`, { autoAlpha: 1, duration: 0.4 }, i * 1 - 0.2)
      tl.to('.par-1', { xPercent: -14, duration: n }, 0)
      tl.to('.par-2', { xPercent: -26, duration: n }, 0)
      tl.to('.wt5-phone', { y: -18, rotate: 3, duration: n / 2, yoyo: true, repeat: 1 }, 0)
      tl.fromTo('.wt5-burst', { clipPath: 'circle(0% at 50% 62%)' }, { clipPath: 'circle(150% at 50% 62%)', duration: 0.9, ease: 'power2.in' }, n)
      tl.fromTo('.wt5-burst-text span', { yPercent: 110 }, { yPercent: 0, duration: 0.5, stagger: 0.1, ease: 'power4.out' }, n + 0.6)
      tl.to({}, { duration: 0.5 })
    }, root)
    return () => ctx.revert()
  }, [reduced])

  return (
    <section className="wt5" ref={root} aria-labelledby="wait-title">
      {reduced ? (
        <div className="queue-static">
          <h2 id="wait-title" className="mega">Go do literally anything else.</h2>
          <p className="lead">Browse the shops, stroll the neighbourhood, grab a drink. Kiasu Kakis tells you when it&rsquo;s close.</p>
          <p className="mega brandtext">Your turn, kaki!</p>
        </div>
      ) : (
        <div className="wt5-pin">
          {scenes.map((s, i) => <div key={s.key} className={`wt5-env wt5-env-${i}`}><Scene node={s.node} /></div>)}
          <div className="wt5-veil" aria-hidden />
          <div className="wt5-top">
            <p className="eyebrow light">While you wait</p>
            <h2 id="wait-title" className="wt5-title">Go do literally<br />anything else.</h2>
            <p className="wt5-label" aria-live="polite">{scenes[env].label}</p>
          </div>
          <div className="wt5-phone"><Phone shots={shots} active={shot} /></div>
          <div className="wt5-chip" aria-hidden><i className="dot o" />{status[shot]}</div>
          <div className="wt5-burst" aria-hidden><p className="wt5-burst-text mega"><span>Your turn,</span><span>kaki!</span></p></div>
        </div>
      )}
    </section>
  )
}
