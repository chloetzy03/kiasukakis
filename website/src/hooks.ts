import { useEffect, useState } from 'react'

const query = (q: string) => (typeof matchMedia === 'undefined' ? false : matchMedia(q).matches)

export function useMedia(q: string) {
  const [v, set] = useState(() => query(q))
  useEffect(() => {
    const m = matchMedia(q)
    const f = () => set(m.matches)
    m.addEventListener('change', f)
    return () => m.removeEventListener('change', f)
  }, [q])
  return v
}

export const useReducedMotion = () => useMedia('(prefers-reduced-motion: reduce)')
export const useDesktop = () => useMedia('(min-width: 900px)')

export function hasWebGL() {
  try {
    const c = document.createElement('canvas')
    return !!(c.getContext('webgl2') || c.getContext('webgl'))
  } catch { return false }
}
