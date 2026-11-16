export const base = import.meta.env.BASE_URL
export const screen = (n: string) => `${base}screens/${n}.jpg`

// Features that exist in the app today (from the iOS project).
export const walkthrough = [
  { img: 'map', kicker: '01 · Explore', title: 'Opens on queues, not places.', body: 'Colour-coded pins show the wait in minutes. Only food spots: hawker, restaurant, café, dessert, bar.', hot: { x: 84, y: 39, label: 'Wait in minutes' } },
  { img: 'summary', kicker: '02 · Tap a pin', title: 'See the wait before you walk over.', body: 'A quick summary with groups ahead and a Join button, right on the map.', hot: { x: 50, y: 81, label: 'Join queue' } },
  { img: 'joinform', kicker: '03 · Join', title: 'Pick your party. Tap join.', body: 'Two queues at a time, one per place, so nobody hogs every line.', hot: { x: 50, y: 52, label: 'Confirm and join' } },
  { img: 'ticket1', kicker: '04 · Your ticket', title: 'Your ticket moves. You don\u2019t have to.', body: 'Waiting, almost, called, done. Watch it progress while you do literally anything else.', hot: { x: 50, y: 25, label: 'Your number' } },
] as const

export const features = [
  { img: 'list', title: 'Ranked, shortest first', body: 'The queue list sorts itself so the quick wins float to the top.' },
  { img: 'details', title: 'Real place details', body: 'Google rating, hours and a photo, so you know it is worth it.' },
  { img: 'search', title: 'Smart search', body: 'Find a stall or a craving without leaving the queue view.' },
  { img: 'saved', title: 'Saved places', body: 'Bookmark favourites and filter them by category.' },
  { img: 'myqueues', title: 'My Queues', body: 'Every active ticket in one tab. Up to two at a time.' },
  { img: 'darklist', title: 'Dark mode', body: 'Warm, easy on the eyes, matches your phone.' },
] as const

export const venues = [
  { id: 'yk', name: 'Ya Kun Kaya Toast', kind: 'Café', area: 'Far East Square', mins: 8, ahead: 2, x: 24, y: 46 },
  { id: 'sf', name: 'Song Fa Bak Kut Teh', kind: 'Restaurant', area: 'Clarke Quay', mins: 35, ahead: 7, x: 56, y: 20 },
  { id: 'lj', name: 'Bubble Tea Corner', kind: 'Dessert', area: 'Orchard', mins: 15, ahead: 4, x: 76, y: 38 },
  { id: 'hk', name: "Uncle's Chicken Rice", kind: 'Hawker', area: 'Chinatown', mins: 45, ahead: 11, x: 40, y: 58 },
] as const
