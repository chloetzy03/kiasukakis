import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { venues, base } from '../content'
import { chime } from '../sound'

type V = (typeof venues)[number]
type Stage = 'map' | 'sheet' | 'join' | 'ticket'
const waitClass = (m: number) => (m <= 15 ? 'g' : m < 30 ? 'a' : 'o')
const steps = ['Explore', 'Pick a place', 'Join', 'Track your ticket']
const phases = ['Waiting', 'Almost', 'Called', 'Done']

export function Demo() {
  const [stage, setStage] = useState<Stage>('map')
  const [venue, setVenue] = useState<V | null>(null)
  const [party, setParty] = useState(2)
  const [ahead, setAhead] = useState(0)
  const [done, setDone] = useState(false)
  const [num] = useState(() => 14 + Math.floor(Math.random() * 80))
  const calledOnce = useRef(false)

  const phase = done ? 3 : ahead <= 0 ? 2 : ahead === 1 ? 1 : 0

  useEffect(() => {
    if (stage !== 'ticket' || done || ahead <= 0) return
    const t = setTimeout(() => setAhead((a) => Math.max(0, a - 1)), 2600)
    return () => clearTimeout(t)
  }, [stage, ahead, done])

  useEffect(() => {
    if (stage === 'ticket' && phase === 2 && !calledOnce.current) { calledOnce.current = true; chime() }
  }, [stage, phase])

  const reset = () => { setStage('map'); setVenue(null); setDone(false); setParty(2); calledOnce.current = false }
  const join = () => { setAhead(venue!.ahead > 3 ? 3 : venue!.ahead); setDone(false); calledOnce.current = false; setStage('ticket') }
  const stepIdx = stage === 'map' ? 0 : stage === 'sheet' ? 1 : stage === 'join' ? 2 : 3
  const pad = String(num).padStart(3, '0')

  return (
    <section id="demo" className="demo" aria-labelledby="demo-title">
      <div className="demo-copy">
        <p className="eyebrow">Try it · Interactive demo</p>
        <h2 id="demo-title" className="h2">Join a queue. <em>Without joining a queue.</em></h2>
        <p className="lead">Poke around the way the app works. Everything here is <strong>demonstration data</strong>: no real reservations, no real businesses, no live queue feed.</p>
        <ol className="demo-steps">
          {steps.map((s, i) => <li key={s} className={i === stepIdx ? 'on' : i < stepIdx ? 'past' : ''}><span>{i + 1}</span>{s}</li>)}
        </ol>
        <button className="btn btn-ghost" onClick={reset}>Reset demo</button>
      </div>

      <div className="demo-device">
        <div className="phone demo-phone"><div className="phone-body"><div className="phone-screen dscreen">
          <div className="dstatus"><b>9:41</b><i className="notch" /></div>

          {stage !== 'ticket' && (
            <div className="dmap" role="group" aria-label="Simulated map of food places">
              <svg viewBox="0 0 100 130" preserveAspectRatio="none" aria-hidden>
                <rect width="100" height="130" fill="var(--map-land)" />
                <path d="M62 80 C75 70 92 82 100 78 L100 130 L50 130 C48 110 55 90 62 80Z" fill="var(--map-water)" />
                <ellipse cx="22" cy="30" rx="16" ry="11" fill="var(--map-park)" />
                <ellipse cx="78" cy="22" rx="14" ry="9" fill="var(--map-park)" />
                <ellipse cx="14" cy="92" rx="10" ry="12" fill="var(--map-park)" />
                {['M0 50 L100 40', 'M30 0 L44 130', 'M0 100 L70 70', 'M70 0 L60 70'].map((d) => <path key={d} d={d} stroke="var(--map-road)" strokeWidth="1.6" fill="none" />)}
              </svg>
              {venues.map((v) => (
                <motion.button key={v.id} className={`dpin ${waitClass(v.mins)} ${venue?.id === v.id ? 'sel' : ''}`} style={{ left: `${v.x}%`, top: `${v.y}%` }}
                  onClick={() => { setVenue(v); setStage('sheet') }} whileHover={{ scale: 1.12 }} whileTap={{ scale: 0.94 }} aria-label={`${v.name}, about ${v.mins} minutes`}>
                  {v.mins}m
                </motion.button>
              ))}
              {stage === 'map' && <p className="dhint">Tap a pin</p>}
            </div>
          )}
          <div className="dchips" aria-hidden={stage === 'ticket'} hidden={stage === 'ticket'}><span className="on">All</span><span>Hawker</span><span>Restaurant</span><span>Café</span></div>

          <AnimatePresence>
            {stage === 'sheet' && venue && (
              <motion.div key="sheet" className="dsheet" initial={{ y: '100%' }} animate={{ y: 0 }} exit={{ y: '100%' }} transition={{ type: 'spring', stiffness: 260, damping: 28 }}>
                <button className="dx" onClick={() => setStage('map')} aria-label="Close">×</button>
                <h3>{venue.name}</h3>
                <p className="muted">{venue.kind} · {venue.area}</p>
                <p className="dwait"><i className={`dot ${waitClass(venue.mins)}`} /> {venue.mins} min</p>
                <p><b>About {venue.ahead} groups ahead</b></p>
                <p className="muted small">Simulated · demo data</p>
                <button className="dbtn" onClick={() => setStage('join')}>Join queue</button>
              </motion.div>
            )}
            {stage === 'join' && venue && (
              <motion.div key="join" className="djoin" initial={{ y: '100%' }} animate={{ y: 0 }} exit={{ y: '100%' }} transition={{ type: 'spring', stiffness: 260, damping: 30 }}>
                <header><button className="dx" onClick={() => setStage('sheet')} aria-label="Back">←</button><b>Join queue</b></header>
                <h3>{venue.name}</h3>
                <div className="dcard"><small>QUEUE CONDITIONS</small><p className="dwait"><i className={`dot ${waitClass(venue.mins)}`} /> {venue.mins} min</p><p>About {venue.ahead} groups ahead</p><small>Source: Simulated</small></div>
                <div className="dcard row"><div><small>PARTY SIZE</small><p>{party} {party === 1 ? 'person' : 'people'}</p></div>
                  <div className="stepper"><button onClick={() => setParty(Math.max(1, party - 1))} aria-label="Fewer people">−</button><button onClick={() => setParty(Math.min(8, party + 1))} aria-label="More people">+</button></div></div>
                <button className="dbtn" onClick={join}>Confirm and join</button>
              </motion.div>
            )}
            {stage === 'ticket' && venue && (
              <motion.div key="ticket" className="dticket" initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }}>
                <b className="ttl">My ticket</b>
                <div className="dcard center">
                  <h3>{venue.name}</h3>
                  <motion.p key={phase} className="tnum" initial={{ scale: 0.8 }} animate={{ scale: 1 }}>#{pad}</motion.p>
                  <span className={`pill p${phase}`}>{phases[phase]}</span>
                </div>
                <div className="bars">{phases.map((p, i) => <div key={p}><i className={i <= phase ? `on p${phase}` : ''} /><small className={i === phase ? 'cur' : ''}>{p}</small></div>)}</div>
                <p className="center msg">{phase === 0 ? 'You\u2019re in the queue. Go do something else.' : phase === 1 ? 'Almost your turn. Start heading over.' : phase === 2 ? 'It\u2019s your turn! Please go to the venue now.' : 'All done. Hope it was shiok.'}</p>
                <div className="dcard rows">
                  <p><span>Position</span><b>{phase >= 2 ? 'It\u2019s your turn' : `${ahead} group${ahead === 1 ? '' : 's'} ahead`}</b></p>
                  <p><span>Party size</span><b>{party} {party === 1 ? 'person' : 'people'}</b></p>
                </div>
                {phase < 2 && <button className="dlink" onClick={() => setAhead((a) => Math.max(0, a - 1))}>Skip ahead (demo)</button>}
                {phase === 2 && <button className="dlink" onClick={() => setDone(true)}>Mark as served</button>}
                {phase === 3 && <button className="dbtn" onClick={reset}>Start again</button>}
                <AnimatePresence>
                  {phase === 2 && (
                    <motion.div className="notif" role="status" initial={{ y: -80, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -80, opacity: 0 }} transition={{ type: 'spring', stiffness: 300, damping: 20 }}>
                      <img src={`${base}icon/favicon.png`} alt="" width="28" height="28" /><div><b>Your turn, kaki!</b><span>{venue.name} is ready for you.</span></div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            )}
          </AnimatePresence>
        </div></div></div>
        <p className="demo-label">Demo data · nothing here is real</p>
      </div>
    </section>
  )
}
