// Gravity — tiny dependency-free carousel. Advances one slide at a time,
// works for 1-up (mobile) and multi-up (desktop) based on measured slide width.
(function () {
  function initCarousel(root) {
    var track = root.querySelector('.carousel-track');
    var slides = Array.prototype.slice.call(root.querySelectorAll('.carousel-slide'));
    var dotsWrap = root.querySelector('.carousel-dots');
    var prev = root.querySelector('.carousel-prev');
    var next = root.querySelector('.carousel-next');
    if (!track || slides.length === 0) return;

    var index = 0;
    var timer = null;
    var delay = parseInt(root.getAttribute('data-autoplay'), 10) || 0;

    function visibleCount() {
      var sw = slides[0].getBoundingClientRect().width;
      var vw = root.querySelector('.carousel-viewport').getBoundingClientRect().width;
      return Math.max(1, Math.round(vw / sw));
    }
    function maxIndex() { return Math.max(0, slides.length - visibleCount()); }

    function render() {
      var sw = slides[0].getBoundingClientRect().width;
      track.style.transform = 'translateX(' + (-index * sw) + 'px)';
      if (dotsWrap) {
        Array.prototype.forEach.call(dotsWrap.children, function (d, i) {
          d.setAttribute('aria-current', i === index ? 'true' : 'false');
        });
      }
    }
    function go(i) {
      var mx = maxIndex();
      index = i > mx ? 0 : (i < 0 ? mx : i);
      render();
    }
    function buildDots() {
      if (!dotsWrap) return;
      dotsWrap.innerHTML = '';
      for (var i = 0; i <= maxIndex(); i++) {
        var b = document.createElement('button');
        b.type = 'button';
        (function (n) { b.addEventListener('click', function () { go(n); restart(); }); })(i);
        dotsWrap.appendChild(b);
      }
    }
    function restart() { if (!delay) return; clearInterval(timer); timer = setInterval(function () { go(index + 1); }, delay); }

    if (prev) prev.addEventListener('click', function () { go(index - 1); restart(); });
    if (next) next.addEventListener('click', function () { go(index + 1); restart(); });
    root.addEventListener('mouseenter', function () { clearInterval(timer); });
    root.addEventListener('mouseleave', restart);
    window.addEventListener('resize', function () { if (index > maxIndex()) index = maxIndex(); buildDots(); render(); });

    buildDots();
    render();
    restart();
  }
  document.addEventListener('DOMContentLoaded', function () {
    Array.prototype.forEach.call(document.querySelectorAll('[data-carousel]'), initCarousel);
  });
})();
