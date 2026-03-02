/* ============================================================
   STATS.JS — VERSION FINALE PREMIUM
   Gestion dynamique et animée des compteurs de la page d'accueil
   ============================================================ */

/* ------------------------------------------------------------
   1) Récupération du nombre total de scripts
   ------------------------------------------------------------ */
async function getScriptsCount() {
    try {
        const response = await fetch("assets/data/scripts.json");
        if (!response.ok) throw new Error("Impossible de charger scripts.json");

        const data = await response.json();
        return data.scripts.length;
    } catch (error) {
        console.error("Erreur lors du chargement des scripts :", error);
        return 0;
    }
}

/* ------------------------------------------------------------
   2) Récupération du nombre total de projets
   ------------------------------------------------------------ */
async function getProjectsCount() {
    try {
        const response = await fetch("assets/data/projects.json");
        if (!response.ok) throw new Error("Impossible de charger projects.json");

        const data = await response.json();
        return data.projects.length;
    } catch (error) {
        console.error("Erreur lors du chargement des projets :", error);
        return 0;
    }
}

/* ------------------------------------------------------------
   3) Animation premium des compteurs
   ------------------------------------------------------------ */
function animateCounter(element, target, duration = 900) {
    if (!element) return;

    let start = 0;
    const increment = Math.ceil(target / (duration / 16)); // 60 FPS approx.

    const interval = setInterval(() => {
        start += increment;
        if (start >= target) {
            start = target;
            clearInterval(interval);
        }
        element.textContent = `+${start}`;
    }, 16);
}

/* ------------------------------------------------------------
   4) Mise à jour des compteurs de la page d'accueil
   ------------------------------------------------------------ */
async function updateHomeStats() {
    const scriptsCountElement = document.getElementById("scripts-count");
    const projectsCountElement = document.getElementById("projects-count");
    const linkedinCountElement = document.getElementById("linkedin-count");

    const scriptsCount = await getScriptsCount();
    const projectsCount = await getProjectsCount();

    if (scriptsCountElement) animateCounter(scriptsCountElement, scriptsCount);
    if (projectsCountElement) animateCounter(projectsCountElement, projectsCount);

    if (linkedinCountElement) linkedinCountElement.textContent = "+19 250";
}

/* ------------------------------------------------------------
   5) Exécution automatique au chargement
   ------------------------------------------------------------ */
document.addEventListener("DOMContentLoaded", updateHomeStats);
