/* ============================================================
   PROJECTS PAGE — VERSION PREMIUM
   Chargement dynamique + glow + animations + sécurité
============================================================ */

fetch("assets/data/projects.json")
  .then(res => res.json())
  .then(data => {
    const container = document.getElementById("projects-grid");
    if (!container) return;

    /* ============================================
       1. Suppression des doublons (sécurité)
    ============================================ */
    const uniques = Array.from(
      new Map(data.projects.map(p => [p.id, p])).values()
    );

    /* ============================================
       2. Tri par date DESC
    ============================================ */
    const sorted = uniques.sort((a, b) => b.date.localeCompare(a.date));

    /* ============================================
       3. Génération des cartes
    ============================================ */
    sorted.forEach(project => {
      const card = document.createElement("article");
      card.className = "card project-card fade-in";

      const imagePath = project.image
        ? `assets/img/${project.image}`
        : "assets/img/default.jpg";

      card.innerHTML = `
        <img class="project-image" src="${imagePath}" alt="${project.titre}">
        <div class="project-type-badge">${project.type}</div>

        <div class="project-header">
          <h3>${project.titre}</h3>
          <p class="project-date">${project.date}</p>
        </div>

        <p class="project-desc">${project.descriptionCourte}</p>

        <div class="project-tags">
          ${project.technologies.map(t => `<span class="tag">${t}</span>`).join("")}
        </div>
      `;

      /* ============================================
         4. Glow directionnel intelligent
      ============================================ */
      card.addEventListener("mousemove", e => {
        const rect = card.getBoundingClientRect();
        card.style.setProperty("--x", `${e.clientX - rect.left}px`);
        card.style.setProperty("--y", `${e.clientY - rect.top}px`);
      });

      /* ============================================
         5. Redirection vers la page détaillée (FIX)
      ============================================ */
      card.addEventListener("click", () => {
        window.location.href = `project-details.html?id=${project.id}`;
      });

      container.appendChild(card);
    });

    /* ============================================
       6. Animation fade‑in progressive
    ============================================ */
    const cards = document.querySelectorAll(".fade-in");
    cards.forEach((el, i) => {
      setTimeout(() => {
        el.classList.add("visible");
      }, 80 * i);
    });
  })
  .catch(err => {
    console.error("Erreur lors du chargement des projets :", err);
  });