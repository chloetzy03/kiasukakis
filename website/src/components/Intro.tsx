import { useEffect, useState } from 'react'
import gsap from 'gsap'
import { base } from '../content'

// Short wordmark reveal. Skipped for reduced-motion users and on repeat visits in the same session.
export function Intro({ onDone }: { onDone: () => void }) {
  const [gone, setGone] = useState(false)
  useEffect(() => {
    const tl = gsap.timeline({ onComplete: () => { setGone(true); onDone() } })
    tl.from('.intro-letter', { yPercent: 120, rotate: 8, duration: 0.7, ease: 'power4.out', stagger: 0.04 })
      .from('.intro-icon', { scale: 0, rotate: -40, duration: 0.6, ease: 'back.out(2)' }, 0.1)
      .to('.intro-tag', { opacity: 1, y: 0, duration: 0.4 }, '-=0.2')
      .to('.intro', { yPercent: -100, duration: 0.85, ease: 'expo.inOut' }, '+=0.35')
    // Safety net: never leave the visitor stuck behind the overlay on a slow device.
    const bail = setTimeout(() => { tl.progress(1) }, 6000)
    return () => { clearTimeout(bail); tl.kill() }
  }, [onDone])
  if (gone) return null
  const word = 'kiasu kakis'.split('')
  return (
    <div className="intro" aria-hidden>
      <img className="intro-icon" src={`${base}icon/icon-dark.png`} alt="" width="84" height="84" />
      <div className="intro-word">
        {word.map((c, i) => <span key={i} className="intro-mask"><span className="intro-letter">{c === ' ' ? '\u00a0' : c}</span></span>)}
      </div>
      <p className="intro-tag">life's too short to queue</p>
    </div>
  )
}
