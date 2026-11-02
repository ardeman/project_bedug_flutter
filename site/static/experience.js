// Progressive enhancement: content is visible before scripts run and when
// observers or animation APIs are unavailable. Scroll only toggles header state.
const motion = window.matchMedia("(prefers-reduced-motion: reduce)");
const animations = new Set();

function reveal(element, delay = 0) {
  if (motion.matches || !element.animate) return;
  const animation = element.animate(
    [
      { opacity: 0, transform: "translateY(24px)" },
      { opacity: 1, transform: "translateY(0)" },
    ],
    { duration: 650, delay, easing: "cubic-bezier(0.2, 0.7, 0.2, 1)", fill: "backwards" },
  );
  animations.add(animation);
  animation.finished.catch(() => {}).finally(() => animations.delete(animation));
}

motion.addEventListener("change", () => {
  if (motion.matches) {
    for (const animation of animations) animation.cancel();
    animations.clear();
  }
});

// Only animate the entrance when the visitor starts at the top of the page.
if (!window.location.hash && window.scrollY < 80) {
  document.querySelectorAll(".hero-copy > *, .hero-stage").forEach((element, i) => {
    reveal(element, Math.min(i * 70, 280));
  });
}

if ("IntersectionObserver" in window) {
  const reveals = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      reveal(entry.target);
      reveals.unobserve(entry.target);
    }
  }, { threshold: 0.08 });
  document.querySelectorAll(".features-intro, .feature, .facts > div, .pledge-inner, .stores > li, .plan > div")
    .forEach((element) => reveals.observe(element));

  function trackSections(selector, followTab = false) {
    const links = [...document.querySelectorAll(selector)];
    const visible = new Set();
    let previous;
    const sections = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) visible.add(entry.target.id);
        else visible.delete(entry.target.id);
      }
      const current = links.find((link) => visible.has(link.hash.slice(1)));
      for (const link of links) {
        if (link === current) link.setAttribute("aria-current", "location");
        else link.removeAttribute("aria-current");
      }
      if (followTab && current && current !== previous) {
        const menu = current.parentElement;
        const bounds = menu.getBoundingClientRect();
        const tab = current.getBoundingClientRect();
        if (tab.left < bounds.left || tab.right > bounds.right) {
          // Scroll only the menu. scrollIntoView can also move the page;
          // physical rectangle offsets work in both LTR and RTL layouts.
          menu.scrollBy({
            left: tab.left - bounds.left - (bounds.width - tab.width) / 2,
            behavior: motion.matches ? "instant" : "smooth",
          });
        }
      }
      previous = current;
    }, { rootMargin: "-20% 0px -45% 0px", threshold: 0 });
    for (const link of links) {
      const section = document.getElementById(link.hash.slice(1));
      if (section) sections.observe(section);
    }
  }
  trackSections('.top-nav a[href^="#"]');
  trackSections('.feature-links a[href^="#"]', true);
}

const language = document.querySelector(".lang");
if (language) {
  document.addEventListener("click", (event) => {
    if (!language.contains(event.target)) language.open = false;
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && language.open) {
      language.open = false;
      language.querySelector("summary").focus();
    }
  });
}

// The home hero owns the first screen; inner pages keep their regular header.
const homeHeader = document.querySelector('.top-home');
if (homeHeader) {
  function updateHeader() {
    const atTop = window.scrollY <= 16;
    homeHeader.classList.toggle('is-at-top', atTop);
    homeHeader.inert = atTop;
  }
  updateHeader();
  window.addEventListener('scroll', updateHeader, { passive: true });
}
