/* ============================================================
   SCRIPTS.JS — VERSION FINALE PREMIUM
   Chargement des scripts + affichage des détails
   ============================================================ */

/* ------------------------------------------------------------
   1) Affichage de la liste des scripts (scripts.html)
   ------------------------------------------------------------ */
async function loadScripts() {
    try {
        const req = await fetch("assets/data/scripts.json");
        if (!req.ok) throw new Error("Impossible de charger scripts.json");

        const data = await req.json();
        const container = document.getElementById("scripts-container");
        if (!container) return;

        data.scripts.forEach(script => {
            const card = document.createElement("div");
            card.classList.add("script-card");

            card.innerHTML = `
                <h3>${script.nom}</h3>
                <p>${script.description}</p>
                <span class="badge">${script.categorie}</span>
                <br>
                <a href="script-details.html?id=${script.id}" class="btn-script">Voir le script</a>
            `;

            container.appendChild(card);
        });

    } catch (error) {
        console.error("Erreur lors du chargement des scripts :", error);
    }
}

/* ------------------------------------------------------------
   2) Affichage d’un script en détail (script-details.html)
   ------------------------------------------------------------ */
async function loadScriptDetails() {
    try {
        const params = new URLSearchParams(window.location.search);
        const id = params.get("id");
        if (!id) return;

        const req = await fetch("assets/data/scripts.json");
        if (!req.ok) throw new Error("Impossible de charger scripts.json");

        const data = await req.json();
        const script = data.scripts.find(s => s.id === id);

        const title = document.getElementById("script-title");
        const description = document.getElementById("script-description");
        const meta = document.getElementById("script-meta");
        const codeContainer = document.getElementById("script-code");
        const downloadBtn = document.getElementById("download-btn");

        if (!script) {
            title.textContent = "Script introuvable";
            return;
        }

        title.textContent = script.nom;
        description.textContent = script.description;

        meta.innerHTML = `
            <strong>Catégorie :</strong> ${script.categorie} • 
            <strong>Type :</strong> ${script.type}
        `;

        const code = await fetch(script.fichier).then(r => r.text());
        codeContainer.textContent = code;

        downloadBtn.href = script.fichier;

        const copyBtn = document.getElementById("copy-btn");
        copyBtn.addEventListener("click", () => {
            navigator.clipboard.writeText(code);
            copyBtn.textContent = "Copié !";
            setTimeout(() => copyBtn.textContent = "Copier", 1500);
        });

    } catch (error) {
        console.error("Erreur lors du chargement du script :", error);
    }
}

/* ------------------------------------------------------------
   3) Exécution automatique
   ------------------------------------------------------------ */
document.addEventListener("DOMContentLoaded", () => {
    loadScripts();
    loadScriptDetails();
});