/* Kiasu Kakis site behaviour. Plain JavaScript, no libraries. */
(function () {
  'use strict';

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var $$ = function (sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); };
  var NS = 'http://www.w3.org/2000/svg';

  function svgEl(name, attrs, parent) {
    var el = document.createElementNS(NS, name);
    Object.keys(attrs || {}).forEach(function (k) { el.setAttribute(k, attrs[k]); });
    if (parent) parent.appendChild(el);
    return el;
  }

  /* ---------- Theme ---------- */
  $('#themeToggle').addEventListener('click', function () {
    var next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('kk-theme', next);
  });

  /* ---------- Reveal on scroll ---------- */
  var revealObserver = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) { entry.target.classList.add('in'); revealObserver.unobserve(entry.target); }
    });
  }, { threshold: 0.15 });
  $$('.reveal').forEach(function (el) { revealObserver.observe(el); });

  /* ---------- Cross-fading screenshots ---------- */
  function cycle(container, ms, onChange) {
    var imgs = $$('img', container);
    if (imgs.length < 2 || reduceMotion) return;
    var i = 0;
    setInterval(function () {
      imgs[i].classList.remove('is-on');
      i = (i + 1) % imgs.length;
      imgs[i].classList.add('is-on');
      if (onChange) onChange(i);
    }, ms);
  }

  /* ---------- Ticker with drifting waits ---------- */
  var places = [
    ['Tian Tian Chicken Rice', 35, 20, 55], ['Song Fa Bak Kut Teh', 15, 6, 28], ['Din Tai Fung', 30, 15, 50],
    ['Ya Kun Kaya Toast', 8, 3, 16], ['Tiong Bahru Bakery', 10, 3, 20], ['Jumbo Seafood', 25, 12, 45],
    ['Mei Heong Yuen', 12, 4, 22], ['Hawker Chan', 30, 18, 50], ['Tai Hwa Pork Noodle', 45, 30, 70], ['KOI Th\u00e9', 15, 6, 30]
  ];
  function waitClass(m) { return m < 15 ? 'g' : (m < 30 ? 'a' : 'o'); }
  var track = $('#marqueeTrack');
  var ticks = [];
  places.concat(places).forEach(function (p) {
    var el = document.createElement('span');
    el.className = 'tick';
    el.innerHTML = '<span></span><b></b>';
    el.firstChild.textContent = p[0];
    track.appendChild(el);
    ticks.push({ el: el, badge: el.lastChild, wait: p[1], lo: p[2], hi: p[3], base: p[1] });
  });
  function paintTick(t) {
    t.badge.textContent = Math.round(t.wait) + ' min';
    t.badge.className = waitClass(t.wait);
  }
  ticks.forEach(paintTick);
  if (!reduceMotion) {
    setInterval(function () {
      ticks.forEach(function (t) {
        if (Math.random() < 0.4) {
          t.wait = Math.min(t.hi, Math.max(t.lo, t.wait + (t.base - t.wait) * 0.12 + (Math.random() * 3 - 1.5)));
          paintTick(t);
        }
      });
    }, 1800);
  }

  /* ---------- Feature tour ---------- */
  var tabs = $$('#tourTabs button');
  var tourImg = $('#tourImg');
  var userPicked = false;
  var tourIndex = 0;
  function showTab(i, fromUser) {
    var tab = tabs[i];
    tourIndex = i;
    tabs.forEach(function (t) { t.setAttribute('aria-selected', t === tab ? 'true' : 'false'); t.tabIndex = t === tab ? 0 : -1; });
    tourImg.style.opacity = 0;
    setTimeout(function () {
      tourImg.src = 'assets/screens/' + tab.dataset.img + '.jpg';
      tourImg.alt = tab.dataset.title;
      tourImg.style.opacity = 1;
    }, reduceMotion ? 0 : 180);
    $('#tourTitle').textContent = tab.dataset.title;
    $('#tourText').textContent = tab.dataset.text;
    if (fromUser) userPicked = true;
  }
  tabs.forEach(function (tab, i) {
    tab.tabIndex = i === 0 ? 0 : -1;
    tab.addEventListener('click', function () { showTab(i, true); });
    tab.addEventListener('keydown', function (e) {
      var next = e.key === 'ArrowDown' || e.key === 'ArrowRight' ? 1 : (e.key === 'ArrowUp' || e.key === 'ArrowLeft' ? -1 : 0);
      if (!next) return;
      e.preventDefault();
      var j = (i + next + tabs.length) % tabs.length;
      showTab(j, true);
      tabs[j].focus();
    });
  });
  tourImg.style.transition = 'opacity 0.25s';
  var tourVisible = false;
  new IntersectionObserver(function (e) { tourVisible = e[0].isIntersecting; }, { threshold: 0.3 }).observe($('.tour'));
  if (!reduceMotion) {
    setInterval(function () {
      if (tourVisible && !userPicked) showTab((tourIndex + 1) % tabs.length, false);
    }, 4500);
  }

  /* ---------- Eyes that follow the pointer ---------- */
  var INK = '#2a1215';
  var eyeSets = [];

  // Draws a pair of eyes into an SVG group. Coordinates are in the SVG's own units.
  function drawEyes(parent, cx, cy, gap, r, browColor) {
    var g = svgEl('g', { 'class': 'eyes-g' }, parent);
    [-1, 1].forEach(function (side) {
      var x = cx + side * gap;
      svgEl('circle', { cx: x, cy: cy, r: r, fill: '#fffdf8', stroke: INK, 'stroke-width': r * 0.1 }, g);
      var pupil = svgEl('g', {}, g);
      svgEl('circle', { cx: x, cy: cy, r: r * 0.52, fill: INK }, pupil);
      svgEl('circle', { cx: x + r * 0.16, cy: cy - r * 0.18, r: r * 0.15, fill: '#fffdf8' }, pupil);
      var by = cy - r * 1.38;
      svgEl('path', {
        d: 'M' + (x + side * r * 0.95) + ' ' + (by - r * 0.12) + ' L' + (x - side * r * 0.95) + ' ' + (by + r * 0.12),
        stroke: browColor || INK, 'stroke-width': r * 0.3, 'stroke-linecap': 'round', fill: 'none', 'class': 'brow'
      }, g);
      eyeSets.push({ svg: parent.ownerSVGElement || parent, pupil: pupil, x: x, y: cy, r: r });
    });
    return g;
  }

  var pointer = null;
  var lastScrollAt = -9999;
  function lookAt(clientX, clientY) {
    eyeSets.forEach(function (e) {
      if (!e.svg.isConnected) return;
      var ctm = e.svg.getScreenCTM();
      if (!ctm) return;
      var pt = e.svg.createSVGPoint();
      pt.x = clientX; pt.y = clientY;
      var local = pt.matrixTransform(ctm.inverse());
      var dx = local.x - e.x, dy = local.y - e.y;
      var dist = Math.hypot(dx, dy) || 1;
      var travel = Math.min(e.r * 0.42, dist);
      e.pupil.setAttribute('transform', 'translate(' + (dx / dist * travel) + ' ' + (dy / dist * travel) + ')');
    });
  }
  var frame = 0;
  window.addEventListener('pointermove', function (ev) {
    pointer = ev;
    if (frame) return;
    frame = requestAnimationFrame(function () { frame = 0; lookAt(pointer.clientX, pointer.clientY); });
  }, { passive: true });

  // Hero eyes (peeking over the phone)
  var heroEyes = $('#heroEyes');
  var heroGroup = svgEl('g', {}, heroEyes);
  drawEyes(heroGroup, 160, 70, 52, 34, 'var(--ink)');
  var footEyes = $('#footEyes');
  drawEyes(svgEl('g', {}, footEyes), 160, 70, 52, 34, 'var(--ink)');

  // When nobody is moving the mouse, the hero eyes glance around by themselves.
  if (!reduceMotion) {
    setInterval(function () {
      if (pointer && performance.now() - pointer.timeStamp < 3500) return;
      if (performance.now() - lastScrollAt < 1200) return;
      var rect = heroEyes.getBoundingClientRect();
      var spots = [[-0.6, 0.6], [1.6, 0.7], [0.5, -2], [0.5, 4]];
      var s = spots[Math.floor(Math.random() * spots.length)];
      lookAt(rect.left + rect.width * s[0], rect.top + rect.height * s[1]);
    }, 2400);
    // Blink now and then
    setInterval(function () {
      $$('.eyes-g').forEach(function (g) {
        g.style.transformBox = 'fill-box'; g.style.transformOrigin = 'center';
        g.style.transition = 'transform .08s'; g.style.transform = 'scaleY(0.12)';
        setTimeout(function () { g.style.transform = 'scaleY(1)'; }, 110);
      });
    }, 5200);
  }

  /* ---------- Scroll-driven animation ---------- */
  var clamp = function (v, lo, hi) { return Math.min(hi, Math.max(lo, v)); };
  var ease = function (t) { return t * t * (3 - 2 * t); };
  var lerp = function (a, b, t) { return a + (b - a) * t; };
  var vh = function () { return window.innerHeight; };
  var narrow = function () { return window.innerWidth <= 900; };
  // Progress of a tall track whose child is pinned: 0 when it starts pinning, 1 when it lets go.
  function trackProgress(track) {
    var r = track.getBoundingClientRect();
    return clamp(-(r.top - 64) / (r.height - vh() + 64), 0, 1);
  }

  /* Word-by-word text */
  var words = $('#probTitle'), wordEls = [];
  (function splitWords(node, accent) {
    Array.prototype.slice.call(node.childNodes).forEach(function (child) {
      if (child.nodeType === 3) {
        var frag = document.createDocumentFragment();
        child.textContent.split(/(\s+)/).forEach(function (part) {
          if (!part) return;
          if (/^\s+$/.test(part)) { frag.appendChild(document.createTextNode(' ')); return; }
          var w = document.createElement('span');
          w.className = 'w' + (accent ? ' accent' : '');
          w.textContent = part;
          wordEls.push(w); frag.appendChild(w);
        });
        node.replaceChild(frag, child);
      } else if (child.nodeType === 1) {
        splitWords(child, true);
        child.classList.remove('accent');
      }
    });
  })(words, false);

  /* Ticket stubs */
  var stubsEl = $('#stubs'), stubs = [];
  for (var n = 0; n < 11; n++) {
    var stub = document.createElement('i');
    stub.className = 'stub' + (n === 10 ? ' you' : '');
    stub.textContent = n === 10 ? 'You' : '#' + String(11 + n).padStart(3, '0');
    stubsEl.appendChild(stub); stubs.push(stub);
  }

  var heroWrap = $('#heroWrap'), heroPhone = $('.phone-hero'), heroScreen = $('#heroScreens');
  var heroMap = $('#heroMap'), heroSummary = $('#heroSummary'), heroCopy = $('.hero-copy'), heroTags = $$('.hero-tag');
  var pills = $$('.float-pill'), peek = $('#heroEyes');
  var problemTrack = $('#problem'), bigNum = $('#bigNum'), bigUnit = $('#bigUnit'), bigCap = $('#bigCap');
  var howTrack = $('#howTrack'), howScreens = $$('#howScreens img'), howSteps = $$('#howSteps li'), howDots = $$('#howDots i');
  var paper = $('#paperTicket'), paperText = $('#paperText');
  var screenStep = [0, 1, 1, 2, 2, 2];
  var paperLines = ['Waiting · 3 groups ahead', 'Waiting · 2 groups ahead', 'Called · your turn!'];

  // Where things sit at rest, as offsets from the hero box so they stay right wherever the page is scrolled.
  var heroBox = $('#hero');
  var rest = null;
  function measureHero() {
    var saved = heroPhone.style.transform;
    heroPhone.style.transform = 'none';
    var box = heroBox.getBoundingClientRect(), phone = heroPhone.getBoundingClientRect(), screen = heroScreen.getBoundingClientRect();
    rest = {
      final: Math.min(1.12, box.height * 0.92 / phone.height),
      pin: { x: screen.left + screen.width * 0.75 - box.left, y: screen.top + screen.height * 0.44 - box.top },
      center: { x: phone.left + phone.width / 2 - box.left, y: phone.top + phone.height / 2 - box.top }
    };
    heroPhone.style.transform = saved;
  }

  var ZOOM = 2.2;
  function renderHero(p) {
    if (narrow() || !rest) return;
    var box = heroBox.getBoundingClientRect();
    var pin = { x: box.left + rest.pin.x, y: box.top + rest.pin.y };
    var mid = { x: box.left + rest.center.x, y: box.top + rest.center.y };
    var vp = { x: window.innerWidth / 2, y: box.top + box.height / 2 };
    var e1 = ease(clamp(p / 0.42, 0, 1)), e2 = ease(clamp((p - 0.5) / 0.32, 0, 1));
    var s = lerp(lerp(1, ZOOM, e1), rest.final, e2);
    // f is the point of the phone we keep pinned to `aim` on screen: first the pin, then the phone's centre.
    var f = { x: lerp(pin.x, mid.x, e2), y: lerp(pin.y, mid.y, e2) };
    var aim = { x: lerp(f.x, vp.x, e1), y: lerp(f.y, vp.y, e1) };
    var tx = aim.x - mid.x - s * (f.x - mid.x);
    var ty = aim.y - mid.y - s * (f.y - mid.y);
    heroPhone.style.transform = 'translate(' + tx + 'px,' + ty + 'px) scale(' + s + ')';
  }

  var state = { hero: 0, problem: 0, how: 0 };
  var target = { hero: 0, problem: 0, how: 0 };
  var lastHow = -1, wasWon = null;

  function paintHero(p) {
    var gone = clamp(p / 0.2, 0, 1);
    heroCopy.style.opacity = 1 - gone;
    heroCopy.style.transform = 'translateX(' + (-40 * ease(gone)) + 'px)';
    pills.forEach(function (el) { el.style.opacity = 1 - gone; });
    peek.style.opacity = 1 - gone;
    var swap = ease(clamp((p - 0.38) / 0.2, 0, 1));
    heroMap.style.opacity = 1 - swap;
    heroSummary.style.opacity = swap;
    var tag = clamp((p - 0.84) / 0.12, 0, 1);
    heroTags.forEach(function (el, i) {
      el.style.opacity = tag;
      el.style.transform = 'translate(' + ((i ? 24 : -24) * (1 - tag)) + 'px, -50%)';
    });
    renderHero(p);
  }

  function paintProblem(p) {
    var wordP = clamp(p / 0.4, 0, 1) * (wordEls.length + 0.5);
    wordEls.forEach(function (w, i) { w.classList.toggle('on', i < wordP); });
    var climb = clamp((p - 0.1) / 0.62, 0, 1);
    var fix = clamp((p - 0.84) / 0.12, 0, 1);
    var wait = Math.round(lerp(50 * climb, 0, ease(fix)));
    bigNum.textContent = wait;
    bigNum.className = fix > 0.5 ? 'won' : (wait < 15 ? '' : (wait < 30 ? 'amber' : 'hot'));
    var won = fix > 0.5;
    if (won !== wasWon) {
      wasWon = won;
      bigUnit.textContent = won ? 'min standing' : 'min waiting';
      bigCap.textContent = won ? 'With Kiasu Kakis you sit down. Your ticket does the standing.' : 'You only find out once you\u2019re already in line.';
    }
    var count = Math.round(climb * stubs.length);
    stubs.forEach(function (st, i) { st.classList.toggle('on', i < count); });
    stubsEl.classList.toggle('gone', fix > 0.05);
  }

  function paintHow(p) {
    var idx = Math.floor(clamp(p, 0, 0.999) * howScreens.length);
    if (idx === lastHow) return;
    lastHow = idx;
    howScreens.forEach(function (img, i) { img.classList.toggle('is-on', i === idx); });
    var step = screenStep[idx];
    howSteps.forEach(function (li, i) { li.classList.toggle('is-active', i === step); });
    howDots.forEach(function (d, i) { d.classList.toggle('on', i === step); });
    var show = idx >= 3;
    paper.style.opacity = show ? 1 : 0;
    paper.style.transform = show ? 'translate(0,0) rotate(-4deg)' : 'translate(-60px, 30px) rotate(-12deg)';
    paper.style.transition = 'opacity .4s, transform .5s cubic-bezier(.3,1.4,.5,1)';
    paperText.textContent = paperLines[clamp(idx - 3, 0, 2)];
  }

  // Eased catch-up gives the scroll a smooth, weighty feel without hijacking the scrollbar.
  var running = false;
  function loop() {
    var moving = false;
    ['hero', 'problem', 'how'].forEach(function (k) {
      var d = target[k] - state[k];
      if (Math.abs(d) > 0.0004) { state[k] += d * 0.14; moving = true; } else { state[k] = target[k]; }
    });
    paintHero(state.hero); paintProblem(state.problem); paintHow(state.how);
    if (moving) requestAnimationFrame(loop); else running = false;
  }
  function kick() { if (!running) { running = true; requestAnimationFrame(loop); } }

  var lastY = window.scrollY;
  function onScroll() {
    var dy = window.scrollY - lastY;
    lastY = window.scrollY;
    if (Math.abs(dy) > 2) {
      lastScrollAt = performance.now();
      var er = peek.getBoundingClientRect();
      lookAt(er.left + er.width / 2, dy > 0 ? er.top + 600 : er.top - 600);
    }
    if (reduceMotion) return;
    target.hero = narrow() ? 0 : trackProgress(heroWrap);
    target.problem = trackProgress(problemTrack);
    target.how = trackProgress(howTrack);
    paintHero(state.hero);
    kick();
  }
  var scrollFrame = 0;
  window.addEventListener('scroll', function () {
    if (scrollFrame) return;
    scrollFrame = requestAnimationFrame(function () { scrollFrame = 0; onScroll(); });
  }, { passive: true });
  window.addEventListener('resize', function () { measureHero(); lastHow = -1; onScroll(); });

  if (reduceMotion) {
    wordEls.forEach(function (w) { w.classList.add('on'); });
    bigNum.textContent = '0'; bigNum.className = 'won'; bigUnit.textContent = 'min standing';
    bigCap.textContent = 'With Kiasu Kakis you sit down. Your ticket does the standing.';
    heroMap.style.opacity = 1;
  } else {
    measureHero();
    state.hero = target.hero = narrow() ? 0 : trackProgress(heroWrap);
    state.problem = target.problem = trackProgress(problemTrack);
    state.how = target.how = trackProgress(howTrack);
    paintHero(state.hero); paintProblem(state.problem); paintHow(state.how);
  }
})();
