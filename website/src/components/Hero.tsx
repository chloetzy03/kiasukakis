import { lazy, Suspense, useEffect, useRef, useState } from 'react'
import gsap from 'gsap'
import { hasWebGL, useDesktop, useReducedMotion } from '../hooks'
import { Phone } from './Phone'
import { PrimaryCta, DemoCta } from './Cta'

const Phone3D = lazy(() => import('./Phone3D'))

const lines = ['Life\u2019s too', 'short to', 'queue.']

export function Hero({ ready }: { ready: boolean }) {
  const root = useRef<HTMLElement>(null)
  const desktop = useDesktop()
  const reduced = useReducedMotion()
  const [visible, setVisible] = useState(true)
  const [gl] = useState(hasWebGL)
  const use3D = desktop && !reduced && gl && ready

  useEffect(() => {
    const io = new IntersectionObserver(([e]) => setVisible(e.isIntersecting), { threshold: 0 })
    io.observe(root.current!)
    return () => io.disconnect()
  }, [])

  useEffect(() => {
    if (!ready || reduced) return
    const ctx = gsap.context(() => {
      gsap.timeline({ defaults: { ease: 'power4.out' } })
        .from('.hero-line > span', { yPercent: 110, duration: 1.1, stagger: 0.12 })
        .from('.hero-sub, .hero-actions', { y: 24, opacity: 0, duration: 0.8, stagger: 0.1 }, '-=0.6')
        .from('.hero-stage', { scale: 0.85, opacity: 0, y: 60, duration: 1.2 }, 0.2)
        .from('.float', { scale: 0, rotate: -20, opacity: 0, duration: 0.8, stagger: 0.12, ease: 'back.out(1.8)' }, 0.9)
    }, root)
    return () => ctx.revert()
  }, [ready, reduced])

  const onMove = (e: React.PointerEvent) => {
    if (reduced || e.pointerType !== 'mouse') return
    const r = root.current!.getBoundingClientRect()
    const x = (e.clientX - r.left) / r.width - 0.5, y = (e.clientY - r.top) / r.height - 0.5
    root.current!.style.setProperty('--mx', `${(x + 0.5) * 100}%`)
    root.current!.style.setProperty('--my', `${(y + 0.5) * 100}%`)
    gsap.to('.float', { x: (i) => x * (24 + i * 18), y: (i) => y * (24 + i * 14), duration: 0.8, overwrite: 'auto' })
  }

  return (
    <section id="top" className="hero" ref={root} onPointerMove={onMove}>
      <div className="hero-glow" aria-hidden />
      <div className="hero-copy">
        <p className="eyebrow">An iPhone app for Singapore</p>
        <h1 className="hero-title" aria-label="Life's too short to queue.">
          {lines.map((l) => <span key={l} className="hero-line" aria-hidden><span>{l}</span></span>)}
        </h1>
        <p className="hero-sub">Discover nearby queues. Join virtually. Go live your life, lah.</p>
        <div className="hero-actions"><PrimaryCta /><DemoCta /></div>
        <p className="fine">Still in development. Queue times in this site and the app are simulated.</p>
      </div>
      <div className="hero-stage">
        {use3D ? (
          <Suspense fallback={<Phone shots={['map']} />}><Phone3D active={visible} shot="map" /></Suspense>
        ) : (
          <Phone shots={['map']} className="hero-css-phone" />
        )}
        <div className="float f1" aria-hidden><b>#023</b><span>Waiting</span></div>
        <div className="float f2" aria-hidden><i className="dot g" />8 min</div>
        <div className="float f3" aria-hidden><i className="dot o" />35 min</div>
        <div className="float f4" aria-hidden>Your turn, kaki!</div>
      </div>
      <a className="scroll-cue" href="#story" aria-label="Scroll to the story"><span /></a>
    </section>
  )
}
