import { useLayoutEffect, useRef, useState } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { AnimatePresence, motion } from 'motion/react'
import { walkthrough } from '../content'
import { Phone } from './Phone'
import { useDesktop, useReducedMotion } from '../hooks'

gsap.registerPlugin(ScrollTrigger)
const shots = walkthrough.map((w) => w.img) as string[]

function Hot({ x, y, label }: { x: number; y: number; label: string }) {
  return (
    <div className={`hot${x >= 50 ? ' flip' : ''}`} style={{ left: `${x}%`, top: `${y}%` }}>
      <motion.div className="hot-in" initial={{ scale: 0, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0, opacity: 0 }} transition={{ type: 'spring', stiffness: 260, damping: 16, delay: 0.25 }}>
        <i /><b>{label}</b>
      </motion.div>
    </div>
  )
}

export function Walkthrough() {
  const root = useRef<HTMLElement>(null)
  const [idx, setIdx] = useState(0)
  const desktop = useDesktop()
  const reduced = useReducedMotion()
  const pinned = desktop && !reduced

  useLayoutEffect(() => {
    if (!pinned) return
    const ctx = gsap.context(() => {
      const n = walkthrough.length
      const tl = gsap.timeline({
        defaults: { ease: 'none' },
        scrollTrigger: {
          trigger: root.current, start: 'top top', end: `+=${n * 90}%`, pin: '.wt-pin', scrub: 0.8, anticipatePin: 1,
          onUpdate: (st) => setIdx(Math.min(n - 1, Math.floor(st.progress * n))),
        },
      })
      tl.fromTo('.wt-phone', { rotateY: -24, rotateX: 8, scale: 0.9, xPercent: 0 }, { rotateY: 18, rotateX: -4, scale: 1.04, xPercent: 12, duration: 1 })
        .to('.wt-phone', { rotateY: -14, rotateX: 6, scale: 0.98, xPercent: -8, duration: 1 })
        .to('.wt-phone', { rotateY: 10, rotateX: 0, scale: 1.06, xPercent: 8, duration: 1 })
        .to('.wt-phone', { rotateY: 0, rotateX: 0, scale: 1.1, xPercent: 0, duration: 1 })
      tl.fromTo('.wt-sheen', { backgroundPosition: '0% 0%' }, { backgroundPosition: '100% 100%', duration: 4 }, 0)
    }, root)
    return () => ctx.revert()
  }, [pinned])

  const cur = walkthrough[idx]
  return (
    <section id="meet" className="wt" ref={root} aria-labelledby="meet-title">
      {pinned ? (
        <div className="wt-pin">
          <div className="wt-head">
            <p className="eyebrow">Meet Kiasu Kakis</p>
            <h2 id="meet-title" className="wt-title">Your kaki for queues.</h2>
          </div>
          <div className="wt-copy">
            <AnimatePresence mode="wait">
              <motion.div key={cur.img} initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -30 }} transition={{ duration: 0.35 }}>
                <p className="eyebrow">{cur.kicker}</p>
                <h3 className="wt-h">{cur.title}</h3>
                <p className="lead">{cur.body}</p>
              </motion.div>
            </AnimatePresence>
            <ol className="wt-dots" aria-label="Walkthrough progress">
              {walkthrough.map((w, i) => <li key={w.img} className={i === idx ? 'on' : ''} />)}
            </ol>
          </div>
          <div className="wt-stage">
            <div className="wt-phone">
              <Phone shots={shots} active={idx}>
                <div className="wt-sheen" aria-hidden />
                <AnimatePresence mode="wait"><Hot key={cur.img} {...cur.hot} /></AnimatePresence>
              </Phone>
            </div>
          </div>
        </div>
      ) : (
        <div className="wt-stack">
          <p className="eyebrow">Meet Kiasu Kakis</p>
          <h2 id="meet-title" className="wt-title">Your kaki for queues.</h2>
          {walkthrough.map((w, i) => (
            <motion.article key={w.img} className="wt-step" initial={reduced ? false : { opacity: 0, y: 50 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: '-15%' }} transition={{ duration: 0.6 }}>
              <div><p className="eyebrow">{w.kicker}</p><h3 className="wt-h">{w.title}</h3><p className="lead">{w.body}</p></div>
              <Phone shots={[w.img]} active={0} className="small">
                <Hot {...w.hot} />
              </Phone>
              <span className="sr-only">Step {i + 1}</span>
            </motion.article>
          ))}
        </div>
      )}
    </section>
  )
}
