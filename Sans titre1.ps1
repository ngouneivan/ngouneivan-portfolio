# Chemin du portfolio
$root = "C:\Users\LACASTA\Desktop\PORTFOLIO"

# Création des dossiers principaux
New-Item -ItemType Directory -Path $root -Force
New-Item -ItemType Directory -Path "$root\assets" -Force
New-Item -ItemType Directory -Path "$root\assets\css" -Force
New-Item -ItemType Directory -Path "$root\assets\js" -Force
New-Item -ItemType Directory -Path "$root\assets\img" -Force
New-Item -ItemType Directory -Path "$root\assets\img\projects" -Force
New-Item -ItemType Directory -Path "$root\assets\img\portraits" -Force
New-Item -ItemType Directory -Path "$root\assets\img\logos" -Force
New-Item -ItemType Directory -Path "$root\assets\fonts" -Force

# Dossier data
New-Item -ItemType Directory -Path "$root\data" -Force

# Création des fichiers HTML
New-Item -ItemType File -Path "$root\index.html" -Force
New-Item -ItemType File -Path "$root\about.html" -Force
New-Item -ItemType File -Path "$root\skills.html" -Force
New-Item -ItemType File -Path "$root\projects.html" -Force
New-Item -ItemType File -Path "$root\experience.html" -Force
New-Item -ItemType File -Path "$root\contact.html" -Force

# Création des fichiers CSS
New-Item -ItemType File -Path "$root\assets\css\style.css" -Force
New-Item -ItemType File -Path "$root\assets\css\dark-mode.css" -Force
New-Item -ItemType File -Path "$root\assets\css\animations.css" -Force

# Création des fichiers JS
New-Item -ItemType File -Path "$root\assets\js\main.js" -Force
New-Item -ItemType File -Path "$root\assets\js\theme.js" -Force
New-Item -ItemType File -Path "$root\assets\js\carousels.js" -Force
New-Item -ItemType File -Path "$root\assets\js\stats.js" -Force
New-Item -ItemType File -Path "$root\assets\js\projects.js" -Force

# Création des fichiers JSON
New-Item -ItemType File -Path "$root\data\projects.json" -Force
New-Item -ItemType File -Path "$root\data\stats.json" -Force

# README
New-Item -ItemType File -Path "$root\README.md" -Force

Write-Host "Structure du portfolio créée avec succès !" -ForegroundColor Green