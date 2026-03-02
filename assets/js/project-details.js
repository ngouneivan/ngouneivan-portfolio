/* ============================================================
   PROJECT DETAILS — VERSION PREMIUM + LIGHTBOX
============================================================ */
console.log("🔥 JS chargé !");
const params = new URLSearchParams(window.location.search);
const projectId = params.get("id");

const headerContainer = document.getElementById("project-header");
const contentContainer = document.getElementById("project-content");

if (!projectId) {
    headerContainer.innerHTML = `
        <p class="text-muted">Aucun projet sélectionné.</p>
        <a href="projects.html" class="btn btn-ghost mt-3">← Retour aux projets</a>
    `;
    throw new Error("ID manquant");
}

fetch("assets/data/projects.json")
    .then(res => res.json())
    .then(data => {
        const project = data.projects.find(p => String(p.id) === String(projectId));

        if (!project) {
            headerContainer.innerHTML = `
                <p class="text-muted">Projet introuvable.</p>
                <a href="projects.html" class="btn btn-ghost mt-3">← Retour</a>
            `;
            return;
        }

        /* Gestion multi-images */
        const images = project.images || [project.image];
        const mainImage = images[0] ? `assets/img/${images[0]}` : "assets/img/default.jpg";

        /* HEADER */
        headerContainer.innerHTML = `
            <h1 class="fade-in">${project.titre}</h1>
            <p class="project-date fade-in">${project.date} — ${project.type}</p>

            <img class="project-image-large fade-in lightbox-trigger"
                 src="${mainImage}"
                 data-index="0"
                 alt="${project.titre}">
        `;

        /* CONTENU */
        contentContainer.innerHTML = `
            <h2 class="fade-in">Pourquoi ce projet ?</h2>
            <p class="fade-in">${project.pourquoi}</p>

            <h2 class="fade-in">Description</h2>
            <p class="fade-in">${project.descriptionLongue}</p>

            <h2 class="fade-in">Résultats</h2>
            <ul class="fade-in">
                ${project.resultats.map(r => `<li>${r}</li>`).join("")}
            </ul>

            <h2 class="fade-in">Technologies utilisées</h2>
            <div class="project-tags fade-in">
                ${project.technologies.map(t => `<span class="tag">${t}</span>`).join("")}
            </div>

            <h2 class="fade-in">Compétences développées</h2>
            <div class="project-tags fade-in">
                ${project.competences.map(c => `<span class="tag">${c}</span>`).join("")}
            </div>

            ${images.length > 1 ? `
                <h2 class="fade-in">Galerie</h2>
                <div class="project-gallery fade-in">
                    ${images.map((img, i) => `
                        <img src="assets/img/${img}" 
                             class="gallery-thumb lightbox-trigger"
                             data-index="${i}">
                    `).join("")}
                </div>
            ` : ""}
        `;

        /* FADE-IN */
        document.querySelectorAll(".fade-in").forEach((el, i) =>
            setTimeout(() => el.classList.add("visible"), 120 * i)
        );

        /* LIGHTBOX */
        const lightbox = document.getElementById("lightbox");
        const lightboxImg = document.getElementById("lightbox-img");
        const btnPrev = document.getElementById("lightbox-prev");
        const btnNext = document.getElementById("lightbox-next");
        const btnClose = document.getElementById("lightbox-close");

        let currentIndex = 0;

        function openLightbox(index) {
            currentIndex = index;
            lightboxImg.src = `assets/img/${images[currentIndex]}`;
            lightbox.classList.remove("hidden");
        }

        function closeLightbox() {
            lightbox.classList.add("hidden");
        }

        function nextImage() {
            currentIndex = (currentIndex + 1) % images.length;
            openLightbox(currentIndex);
        }

        function prevImage() {
            currentIndex = (currentIndex - 1 + images.length) % images.length;
            openLightbox(currentIndex);
        }

        document.querySelectorAll(".lightbox-trigger").forEach(el => {
            el.addEventListener("click", () => openLightbox(Number(el.dataset.index)));
        });

        btnClose.onclick = closeLightbox;
        btnNext.onclick = nextImage;
        btnPrev.onclick = prevImage;

        lightbox.onclick = e => {
            if (e.target === lightbox) closeLightbox();
        };
    });
