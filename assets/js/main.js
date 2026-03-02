/* ============================================================
   MAIN.JS — VERSION PREMIUM DÉFINITIVE
============================================================ */

/* ===========================
   MENU RESPONSIVE
=========================== */
const navToggle = document.getElementById("nav-toggle");
const navLinks = document.getElementById("nav-links");

if (navToggle && navLinks) {
    navToggle.addEventListener("click", () => {
        navToggle.classList.toggle("active");
        navLinks.classList.toggle("open");
    });

    navLinks.querySelectorAll("a").forEach(link => {
        link.addEventListener("click", () => {
            navToggle.classList.remove("active");
            navLinks.classList.remove("open");
        });
    });
}


/* ===========================
   HEADER STICKY
=========================== */
const header = document.getElementById("header");

if (header) {
    window.addEventListener("scroll", () => {
        if (window.scrollY > 50) header.classList.add("scrolled");
        else header.classList.remove("scrolled");
    });
}


/* ===========================
   SMOOTH SCROLL
=========================== */
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener("click", function (e) {
        const target = document.querySelector(this.getAttribute("href"));
        if (target) {
            e.preventDefault();
            target.scrollIntoView({ behavior: "smooth" });
        }
    });
});


/* ===========================
   IMPRESSIONS LINKEDIN (depuis JSON)
=========================== */
fetch("assets/data/projects.json")
    .then(res => res.json())
    .then(data => {
        const total = data.projects.reduce((sum, p) => sum + (p.impressions || 0), 0);
        const impressionsEl = document.getElementById("impressions-total");

        if (impressionsEl) {
            impressionsEl.textContent = "+" + total.toLocaleString("fr-FR");
        }
    })
    .catch(() => {
        const impressionsEl = document.getElementById("impressions-total");
        if (impressionsEl) impressionsEl.textContent = "+0";
    });


/* ===========================
   ANIMATIONS GSAP (intelligentes, sécurisées)
=========================== */
if (window.gsap) {

    const animateIfExists = (selector, animation) => {
        if (document.querySelector(selector)) gsap.from(selector, animation);
    };

    // Header
    animateIfExists("header", {
        y: -50,
        opacity: 0,
        duration: 0.8,
        ease: "power3.out"
    });

    // HERO
    animateIfExists(".hero-title", {
        x: -40,
        opacity: 0,
        duration: 1,
        delay: 0.2,
        ease: "power3.out"
    });

    animateIfExists(".hero-subtitle", {
        x: -40,
        opacity: 0,
        duration: 1,
        delay: 0.4,
        ease: "power3.out"
    });

    animateIfExists(".hero-buttons", {
        y: 20,
        opacity: 0,
        duration: 1,
        delay: 0.6,
        ease: "power3.out"
    });

    animateIfExists(".hero-photo img", {
        scale: 0.7,
        opacity: 0,
        duration: 1.2,
        delay: 0.3,
        ease: "power3.out"
    });

    // Stats
    animateIfExists(".stats-grid .card", {
        opacity: 0,
        y: 30,
        duration: 0.8,
        stagger: 0.15,
        delay: 0.8,
        ease: "power3.out"
    });

    // Services
    animateIfExists(".service-card", {
        opacity: 0,
        y: 30,
        duration: 0.8,
        stagger: 0.15,
        delay: 1.2,
        ease: "power3.out"
    });

    // About page
    animateIfExists(".about-text", {
        opacity: 0,
        x: -40,
        duration: 1,
        delay: 0.2,
        ease: "power3.out"
    });

    animateIfExists(".about-photo img", {
        opacity: 0,
        scale: 0.7,
        duration: 1.2,
        delay: 0.4,
        ease: "power3.out"
    });

    // ❌ SUPPRIMÉ : animation globale des timeline-item
    // animateIfExists(".timeline-item", {...});

    animateIfExists(".certifications-grid .card", {
        opacity: 0,
        y: 20,
        duration: 0.8,
        stagger: 0.1,
        delay: 1,
        ease: "power3.out"
    });

    // Skills page
    animateIfExists(".skill-card", {
        opacity: 0,
        y: 30,
        duration: 0.8,
        stagger: 0.15,
        delay: 0.3,
        ease: "power3.out"
    });

    animateIfExists(".tool-card", {
        opacity: 0,
        scale: 0.8,
        duration: 0.8,
        stagger: 0.1,
        delay: 0.6,
        ease: "power3.out"
    });
}


/* ===========================
   GLOW DIRECTIONNEL GLOBAL
=========================== */
document.querySelectorAll(".card, .project-card, .section-card, .service-card, .skill-card")
    .forEach(card => {
        card.addEventListener("mousemove", e => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            card.style.setProperty("--x", `${x}px`);
            card.style.setProperty("--y", `${y}px`);
        });
    });


/* ===========================
   LIENS MASQUÉS ANTI-SPAM
=========================== */
document.querySelectorAll(".masked-link").forEach(el => {
    el.addEventListener("click", () => {
        const url = el.dataset.url;
        window.open(url, "_blank");
    });
});


/* ===========================
   ANIMATION GSAP — TIMELINE EXPÉRIENCE
=========================== */
document.addEventListener("DOMContentLoaded", () => {

    const timeline = document.querySelector(".timeline");
    const items = document.querySelectorAll(".timeline-item");

    if (!timeline || items.length === 0) return;

    // Observer pour activer la ligne verticale
    const observer = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                timeline.classList.add("visible");
            }
        });
    }, { threshold: 0.3 });

    observer.observe(timeline);

    // Animation des items
    gsap.from(items, {
        opacity: 0,
        x: -30,
        duration: 0.6,
        stagger: 0.25,
        ease: "power2.out",
        onStart: () => {
            items.forEach(item => item.classList.add("visible"));
        }
    });

});


/* ===========================
   ANIMATION GSAP — PAGE CONTACT
=========================== */
document.addEventListener("DOMContentLoaded", () => {

    if (!document.querySelector(".contact-form")) return;

    const tl = gsap.timeline({
        defaults: { duration: 0.6, ease: "power2.out" }
    });

    tl.from(".section-title", { opacity: 0, y: -20 })
      .from(".section-subtitle", { opacity: 0, y: -15 }, "-=0.4");

    tl.from(".contact-info", { opacity: 0, y: 30 })
      .from(".contact-form", { opacity: 0, y: 30 }, "-=0.3");

    gsap.from(".contact-form input, .contact-form textarea", {
        opacity: 0,
        y: 20,
        stagger: 0.15,
        duration: 0.5,
        ease: "power2.out",
        delay: 1.2
    });

    gsap.fromTo(
        ".contact-form button",
        { opacity: 0, scale: 0.8 },
        {
            opacity: 1,
            scale: 1,
            duration: 0.5,
            ease: "back.out(1.7)",
            delay: 1.6
        }
    );

});


/* ===========================
   ANIMATION GSAP — LIENS MASQUÉS
=========================== */
document.querySelectorAll(".masked-link").forEach(el => {
    el.addEventListener("click", () => {
        const url = el.dataset.url;

        gsap.fromTo(el,
            { scale: 1, opacity: 1 },
            {
                scale: 1.12,
                opacity: 1,
                duration: 0.18,
                ease: "power2.out",
                yoyo: true,
                repeat: 1
            }
        );

        setTimeout(() => {
            window.open(url, "_blank");
        }, 220);
    });
});


document.querySelectorAll(".masked-link").forEach(link => {
    link.addEventListener("click", () => {
        const url = link.getAttribute("data-url");
        if (url) window.open(url, "_blank");
    });
});
