import { useLayoutEffect, useRef } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { Phone } from './Phone'
import { PrimaryCta, DemoCta } from './Cta'
import { launch } from '../launch'
import { base } from '../content'
import { useReducedMotion } from '../hooks'

gsap.registerPlugin(ScrollTrigger)

export function Final() {
  const root = useRef<HTMLElement>(null)
  const reduced = useReducedMotion()
  useLayoutEffect(() => {
    if (reduced) return
    const ctx = gsap.context(() => {
      gsap.from('.fin-line > span', { yPercent: 110, duration: 1, stagger: 0.12, ease: 'power4.out', scrollTrigger: { trigger: root.current, start: 'top 60%' } })
      gsap.from('.fin-sub, .fin-actions', { y: 30, opacity: 0, duration: 0.8, stagger: 0.12, scrollTrigger: { trigger: root.current, start: 'top 40%' } })
      gsap.from('.fin-phone', { yPercent: 40, rotate: -8, duration: 1.2, ease: 'power3.out', scrollTrigger: { trigger: root.current, start: 'top 50%' } })
      gsap.to('.fin-phone', { yPercent: -12, ease: 'none', scrollTrigger: { trigger: root.current, start: 'top bottom', end: 'bottom top', scrub: 0.8 } })
      gsap.from('.fin-brand', { scale: 0, rotate: -90, duration: 0.9, ease: 'back.out(2)', scrollTrigger: { trigger: '.fin-brand', start: 'top 90%' } })
    }, root)
    return () => ctx.revert()
  }, [reduced])

  return (
    <section className="final" ref={root} aria-labelledby="fin-title">
      <div className="fin-copy">
        <h2 id="fin-title" aria-label="Be kiasu about your time.">
          {['Be kiasu', 'about your', 'time.'].map((l) => <span key={l} className="fin-line" aria-hidden><span>{l}</span></span>)}
        </h2>
        <p className="fin-sub">Less waiting. More living.</p>
        <div className="fin-actions"><PrimaryCta light /><DemoCta light /></div>
      </div>
      <div className="fin-phone"><Phone shots={['ticket3']} /></div>
      <footer className="foot">
        <img className="fin-brand" src={`${base}icon/icon-dark.png`} alt="" width="64" height="64" />
        <p>kiasu kakis · made in Singapore</p>
        <p className="fine">Kiasu Kakis is a student project and is still in development. It is not yet on the App Store. Places are real; queue times are simulated. This site&rsquo;s demo uses fictional data and does not connect to any business.</p>
        <p className="fine"><a href={launch.codeUrl}>View the code on GitHub</a> · <a href="#top">Back to top</a></p>
      </footer>
    </section>
  )
}
