import { useCallback, useState } from 'react'
import { Nav } from './components/Nav'
import { Intro } from './components/Intro'
import { Hero } from './components/Hero'
import { QueueScene } from './components/QueueScene'
import { Walkthrough } from './components/Walkthrough'
import { Demo } from './components/Demo'
import { Waiting } from './components/Waiting'
import { Features } from './components/Features'
import { Final } from './components/Final'
import { useReducedMotion } from './hooks'

export default function App() {
  const reduced = useReducedMotion()
  const seen = typeof sessionStorage !== 'undefined' && sessionStorage.getItem('kk-intro') === '1'
  const showIntro = !reduced && !seen
  const [ready, setReady] = useState(!showIntro)
  const done = useCallback(() => { sessionStorage.setItem('kk-intro', '1'); setReady(true) }, [])

  return (
    <>
      <a className="skip" href="#story">Skip to content</a>
      {showIntro && <Intro onDone={done} />}
      <Nav />
      <main>
        <Hero ready={ready} />
        <QueueScene />
        <Walkthrough />
        <Demo />
        <Waiting />
        <Features />
        <Final />
      </main>
    </>
  )
}
