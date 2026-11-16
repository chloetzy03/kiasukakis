import { useEffect, useState } from 'react'
import { sound } from '../sound'
import { base } from '../content'

export function Nav() {
  const [dark, setDark] = useState(() => document.documentElement.dataset.theme === 'dark')
  const [snd, setSnd] = useState(false)
  useEffect(() => {
    document.documentElement.dataset.theme = dark ? 'dark' : 'light'
  }, [dark])
  return (
    <header className="nav">
      <a className="nav-logo" href="#top" aria-label="Kiasu Kakis, back to top">
        <img src={`${base}icon/${dark ? 'icon-dark' : 'icon-light'}.png`} alt="" width="30" height="30" />
        <span>kiasu kakis</span>
      </a>
      <nav aria-label="Primary" className="nav-links">
        <a href="#story">The queue</a>
        <a href="#meet">The app</a>
        <a href="#demo">Demo</a>
        <a href="#features">Features</a>
      </nav>
      <div className="nav-tools">
        <button className="chip-btn" aria-pressed={snd} onClick={() => { sound.on = !snd; setSnd(!snd) }} aria-label="Sound effects">{snd ? 'Sound on' : 'Sound off'}</button>
        <button className="chip-btn" aria-pressed={dark} onClick={() => { localStorage.setItem('kk-theme', dark ? 'light' : 'dark'); setDark(!dark) }} aria-label="Dark mode">{dark ? '☾ Dark' : '☀ Light'}</button>
      </div>
    </header>
  )
}
