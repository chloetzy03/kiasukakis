import { useEffect, useMemo, useRef } from 'react'
import { Canvas, useFrame, useLoader } from '@react-three/fiber'
import * as THREE from 'three'
import { screen } from '../content'

function roundedShape(w: number, h: number, r: number) {
  const s = new THREE.Shape()
  const x = -w / 2, y = -h / 2
  s.moveTo(x + r, y)
  s.lineTo(x + w - r, y); s.absarc(x + w - r, y + r, r, -Math.PI / 2, 0, false)
  s.lineTo(x + w, y + h - r); s.absarc(x + w - r, y + h - r, r, 0, Math.PI / 2, false)
  s.lineTo(x + r, y + h); s.absarc(x + r, y + h - r, r, Math.PI / 2, Math.PI, false)
  s.lineTo(x, y + r); s.absarc(x + r, y + r, r, Math.PI, Math.PI * 1.5, false)
  return s
}

function Phone({ pointer, shot }: { pointer: React.MutableRefObject<{ x: number; y: number }>; shot: string }) {
  const group = useRef<THREE.Group>(null!)
  const tex = useLoader(THREE.TextureLoader, screen(shot))
  tex.colorSpace = THREE.SRGBColorSpace
  tex.anisotropy = 4

  const body = useMemo(() => {
    const g = new THREE.ExtrudeGeometry(roundedShape(1.04, 2.2, 0.18), { depth: 0.09, bevelEnabled: true, bevelSize: 0.012, bevelThickness: 0.02, bevelSegments: 3, curveSegments: 16 })
    g.translate(0, 0, -0.045)
    return g
  }, [])
  const face = useMemo(() => {
    const w = 1.0, h = 2.16
    const g = new THREE.ShapeGeometry(roundedShape(w, h, 0.165), 16)
    const p = g.attributes.position, uv = g.attributes.uv
    for (let i = 0; i < p.count; i++) uv.setXY(i, p.getX(i) / w + 0.5, p.getY(i) / h + 0.5)
    return g
  }, [])

  useFrame((s, dt) => {
    const t = s.clock.elapsedTime
    const g = group.current
    const k = 1 - Math.exp(-dt * 4)
    g.rotation.y += ((-0.32 + pointer.current.x * 0.4) - g.rotation.y) * k
    g.rotation.x += ((0.08 - pointer.current.y * 0.25) - g.rotation.x) * k
    g.position.y = Math.sin(t * 1.2) * 0.04
    g.rotation.z = Math.sin(t * 0.8) * 0.012 - 0.02
  })

  return (
    <group ref={group} scale={1.18}>
      <mesh geometry={body}><meshStandardMaterial color="#4a3f42" metalness={0.6} roughness={0.35} /></mesh>
      <mesh geometry={face} position={[0, 0, 0.066]}><meshBasicMaterial map={tex} toneMapped={false} /></mesh>
    </group>
  )
}

export default function Phone3D({ shot = 'map', active }: { shot?: string; active: boolean }) {
  const pointer = useRef({ x: 0, y: 0 })
  useEffect(() => {
    const f = (e: PointerEvent) => { pointer.current.x = (e.clientX / innerWidth) * 2 - 1; pointer.current.y = (e.clientY / innerHeight) * 2 - 1 }
    addEventListener('pointermove', f, { passive: true })
    return () => removeEventListener('pointermove', f)
  }, [])
  return (
    <Canvas dpr={[1, 1.5]} frameloop={active ? 'always' : 'never'} camera={{ position: [0, 0, 5.4], fov: 32 }} gl={{ antialias: true, alpha: true, powerPreference: 'high-performance' }} aria-hidden>
      <ambientLight intensity={1.1} />
      <directionalLight position={[3, 4, 5]} intensity={2.2} />
      <directionalLight position={[-4, -1, 2]} intensity={0.8} color="#ff8a8a" />
      <Phone pointer={pointer} shot={shot} />
    </Canvas>
  )
}
