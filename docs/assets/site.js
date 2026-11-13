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
  cycle($('#heroScreens'), 3400);
  var ticketText = ['Waiting · 3 groups ahead', 'Waiting · 2 groups ahead', 'Called · it\u2019s your turn!'];
  cycle($('#ticketScreens'), 2600, function (i) { $('#ticketStatus').textContent = ticketText[i]; });

  /* ---------- Queue of little people ---------- */
  var line = $('#queueLine');
  for (var n = 0; n < 16; n++) {
    var person = document.createElement('i');
    person.style.animationDelay = (n * 0.15) + 's';
    line.appendChild(person);
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
      var pupil = svgEl('g', { style: 'transition: transform .12s linear' }, g);
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
      e.pupil.style.transform = 'translate(' + (dx / dist * travel) + 'px,' + (dy / dist * travel) + 'px)';
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
  // The pupils' transform needs the SVG's own unit scale, so the helper above reads r in SVG units.

  // Food that changes with the time of day, wearing the same eyes
  var foods = [
    { name: 'toast', hours: [5, 10], eyes: [515, 470, 80, 56], hello: 'Good morning. Save your spot.', label: 'a slice of kaya toast' },
    { name: 'bowl', hours: [11, 14], eyes: [512, 630, 86, 58], hello: 'Lunch crowd? We got you.', label: 'a bowl of noodles' },
    { name: 'boba', hours: [15, 17], eyes: [512, 590, 86, 58], hello: 'Boba run? Check the queue first.', label: 'a bubble tea' },
    { name: 'chilli', hours: [18, 21], eyes: [585, 500, 72, 52], hello: 'Dinner rush. Be first in line.', label: 'a chilli' },
    { name: 'dumpling', hours: [22, 4], eyes: [512, 630, 88, 60], hello: 'Late-night craving? We got you.', label: 'a dumpling' }
  ];
  function foodFor(hour) {
    for (var i = 0; i < foods.length; i++) {
      var h = foods[i].hours;
      if (h[0] <= h[1] ? (hour >= h[0] && hour <= h[1]) : (hour >= h[0] || hour <= h[1])) return foods[i];
    }
    return foods[0];
  }
  var foodSvg = $('#foodSvg');
  var currentFood = null;
  function clock12(h) { return ((h + 11) % 12 + 1) + ':00 ' + (h < 12 ? 'am' : 'pm'); }
  function showFood(hour) {
    var food = foodFor(hour);
    $('#hourLabel').textContent = clock12(hour);
    if (food === currentFood) return;
    currentFood = food;
    // Drop old eye sets that belonged to the previous food drawing
    eyeSets = eyeSets.filter(function (e) { return e.svg !== foodSvg; });
    while (foodSvg.firstChild) foodSvg.removeChild(foodSvg.firstChild);
    svgEl('image', { href: 'assets/food/' + food.name + '.png', x: 0, y: 0, width: 1024, height: 1024 }, foodSvg);
    drawEyes(svgEl('g', {}, foodSvg), food.eyes[0], food.eyes[1], food.eyes[2], food.eyes[3]);
    foodSvg.setAttribute('aria-label', 'A character made of ' + food.label + ', wearing the Kiasu Kakis eyes');
    $('#foodGreeting').textContent = food.hello;
    if (!reduceMotion) { foodSvg.classList.add('pop'); setTimeout(function () { foodSvg.classList.remove('pop'); }, 350); }
  }
  var hourInput = $('#hour');
  hourInput.value = new Date().getHours();
  showFood(+hourInput.value);
  hourInput.addEventListener('input', function () { showFood(+hourInput.value); });

  // When nobody is moving the mouse, the eyes glance around by themselves.
  if (!reduceMotion) {
    setInterval(function () {
      if (pointer && Date.now() - (pointer.timeStamp ? performance.timeOrigin + pointer.timeStamp : 0) < 3500) return;
      var rect = foodSvg.getBoundingClientRect();
      var spots = [[0.2, 0.4], [0.8, 0.45], [0.5, 0.2], [0.5, 0.7]];
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

  /* ---------- Count-up numbers ---------- */
  var statsEl = $('.stats');
  new IntersectionObserver(function (entries, obs) {
    if (!entries[0].isIntersecting) return;
    obs.disconnect();
    $$('[data-count]', statsEl).forEach(function (el) {
      var target = +el.dataset.count;
      if (reduceMotion || target === 0) { el.textContent = target.toLocaleString(); return; }
      var start = performance.now(), dur = 1300;
      (function tick(now) {
        var p = Math.min(1, (now - start) / dur);
        el.textContent = Math.round(target * (1 - Math.pow(1 - p, 3))).toLocaleString();
        if (p < 1) requestAnimationFrame(tick);
      })(start);
    });
  }, { threshold: 0.4 }).observe(statsEl);
})();
