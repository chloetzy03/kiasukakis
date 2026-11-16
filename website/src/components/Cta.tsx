import { launch } from '../launch'
import { Magnetic } from './Magnetic'

// Single place that decides what the main call-to-action says and does.
export function PrimaryCta({ light = false }: { light?: boolean }) {
  const cls = `btn ${light ? 'btn-light' : 'btn-brand'}`
  if (launch.released && launch.appStoreUrl) {
    return <Magnetic><a className={cls} href={launch.appStoreUrl}>{launch.releasedLabel}</a></Magnetic>
  }
  return <Magnetic><span className={`${cls} btn-static`} role="status">{launch.comingSoonLabel}</span></Magnetic>
}

export function DemoCta({ light = false }: { light?: boolean }) {
  return <Magnetic><a className={`btn ${light ? 'btn-ghost-light' : 'btn-ghost'}`} href="#demo">Try the interactive demo</a></Magnetic>
}
