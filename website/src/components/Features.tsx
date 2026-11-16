import { motion } from 'motion/react'
import { features, screen } from '../content'

export function Features() {
  return (
    <section id="features" className="features" aria-labelledby="feat-title">
      <p className="eyebrow">What&rsquo;s in the app</p>
      <h2 id="feat-title" className="h2">Made for queues.<br />Not another map.</h2>
      <div className="feat-grid">
        {features.map((f, i) => (
          <motion.article key={f.img} className={`feat feat-${i}`} initial={{ opacity: 0, y: 60 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: '-10%' }} transition={{ duration: 0.6, delay: (i % 3) * 0.08 }} whileHover={{ y: -8 }}>
            <div className="feat-shot"><img src={screen(f.img)} alt={`${f.title} screen in the Kiasu Kakis app`} loading="lazy" draggable={false} /></div>
            <h3>{f.title}</h3>
            <p>{f.body}</p>
          </motion.article>
        ))}
      </div>
      <div className="status-row">
        <div className="status now"><b>In the app today</b><p>Map of food places, wait-coloured pins, queue list, place details, joining a virtual queue (2 at a time), ticket tracking, saved places, search, dark mode, VoiceOver and Dynamic Type.</p></div>
        <div className="status soon"><b>On the way</b><p>Real queue data from restaurants. For now the places are real but the queues are simulated, because Singapore has no public queue data. The app is built so real data can slot in later.</p></div>
      </div>
    </section>
  )
}
