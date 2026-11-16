import { forwardRef } from 'react'
import { screen } from '../content'

// CSS phone: used wherever a 3D scene would be overkill (and as the no-WebGL fallback).
export const Phone = forwardRef<HTMLDivElement, { shots: string[]; active?: number; className?: string; children?: React.ReactNode }>(
  ({ shots, active = 0, className = '', children }, ref) => (
    <div ref={ref} className={`phone ${className}`}>
      <div className="phone-body">
        <div className="phone-screen">
          {shots.map((s, i) => (
            <img key={s} src={screen(s)} alt={i === active ? `Kiasu Kakis app screen: ${s}` : ''} aria-hidden={i !== active} className={i === active ? 'on' : ''} draggable={false} loading="lazy" />
          ))}
          {children}
        </div>
      </div>
    </div>
  ),
)
