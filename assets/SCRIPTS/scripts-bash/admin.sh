#!/bin/bash

# Fonction pour afficher en vert
print_green() {
    echo -e "\e[32m$1\e[0m"
}

# Fonction pour afficher en orange
print_orange() {
    echo -e "\e[33m$1\e[0m"
}

# Fonction pour afficher en rouge
print_red() {
    echo -e "\e[31m$1\e[0m"
}

# Fonction pour afficher en bleu
print_blue() {
    echo -e "\e[34m$1\e[0m"
}

# Fonction pour installer un paquet
install_package() {
    sudo apt-get install -y $1
    return $?
}

# Fonction pour effectuer la configuration
configure() {
    case $1 in
        1)
            # Exécution du script de configuration IP
            /home/lacasta/Documents/scripts/conf
            ;;
        2)
            # Ajoutez ici les commandes de configuration pour le DNS (Bind9)
            ;;
        3)
            # Exécution du script DHCP
            /home/lacasta/Documents/scripts/dhcp
            ;;
        4)
            # Ajoutez ici les commandes de configuration pour Apache
            ;;
        6)
            # Ajoutez ici les commandes de configuration pour SSH
            ;;
        *)
            echo "Choix invalide."
            ;;
    esac
}

# Fonction pour afficher les options de configuration disponibles en fonction des rôles installés
display_configure_options() {
    print_orange "Voici la liste des configurations disponibles :"
    
    # Vérifier si le script de configuration IP existe
    if [ -f "/home/lacasta/Documents/scripts/conf" ]; then
        print_blue "1. Configuration IP"
    fi
    
    # Vérifier si le script de configuration DHCP existe
    if [ -f "/home/lacasta/Documents/scripts/dhcp" ]; then
        print_blue "3. DHCP"
    fi
    
    # Vérifier si SSH est installé et en cours d'exécution
    if systemctl is-active --quiet ssh.service; then
        print_blue "6. SSH"
    fi

    # Vérifier si Apache2 est installé et en cours d'exécution
    if systemctl is-active --quiet apache2.service; then
        print_blue "4. Apache"
    fi

    # Vérifier si Bind9 est installé et en cours d'exécution
    if systemctl is-active --quiet bind9.service; then
        print_blue "2. DNS (Bind9)"
    fi
}

# Récupération de l'action choisie
selected=$(whiptail --title "Actions à effectuer" --menu "Que voulez-vous faire ?" 15 50 3 \
    "1" "Installer les rôles" \
    "2" "Configurer les rôles" \
    "3" "Gérer les utilisateurs et groupes" \
    3>&1 1>&2 2>&3)

# Si Annuler est pressé ou rien n'est sélectionné
if [ $? -ne 0 ] || [ -z "$selected" ]; then
    print_orange "Aucune action sélectionnée. Fin du programme."
    exit
fi

# En fonction de l'action choisie
case $selected in
    "1")
        # Exécution du script d'installation des rôles
        print_orange "Exécution du script d'installation des rôles..."
        /home/lacasta/Documents/scripts/install
        ;;
    "2")
        # Afficher les options de configuration et demander à l'utilisateur de choisir
        display_configure_options
        read -p "Choisissez le numéro de configuration à exécuter : " config_number

        # Exécuter la configuration sélectionnée
        configure $config_number
        print_green "Configuration effectuée avec succès."
        ;;
    "3")
        # Exécution du script pour gérer les utilisateurs et groupes
        print_orange "Exécution du script pour gérer les utilisateurs et groupes..."
        /home/lacasta/Documents/scripts/user
        ;;
esac
