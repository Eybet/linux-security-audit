#!/usr/bin/env bash
#
# vulnerable_setup.sh
# Introduit volontairement des failles de sécurité sur une VM de TEST,
# afin de vérifier que audit.sh les détecte bien.
#
# !!! NE JAMAIS LANCER CE SCRIPT SUR UNE MACHINE RÉELLE OU DE PRODUCTION !!!
# Il affaiblit délibérément la sécurité du système.
#
# Garde-fou : le script refuse de s'exécuter si la variable I_UNDERSTAND
# n'est pas positionnée. Usage :
#   sudo I_UNDERSTAND=yes ./tests/vulnerable_setup.sh
#
set -uo pipefail

if [[ "${I_UNDERSTAND:-}" != "yes" ]]; then
    echo "Refus : relancez avec  sudo I_UNDERSTAND=yes $0" >&2
    echo "Ce script affaiblit la sécurité et ne doit servir que sur une VM de test." >&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être lancé avec les droits root (sudo)." >&2
    exit 1
fi

echo "[*] Faille 1 : compte caché avec UID 0 (admin2)"
if ! awk -F: '$1=="admin2"' /etc/passwd | grep -q admin2; then
    useradd -o -u 0 -g 0 -M -s /bin/bash admin2
    echo "    -> admin2 créé"
else
    echo "    -> admin2 existe déjà"
fi

echo "[*] Faille 2 : fichier modifiable par tous (/srv/compta/budget.txt)"
mkdir -p /srv/compta
touch /srv/compta/budget.txt
chmod 666 /srv/compta/budget.txt
echo "    -> budget.txt en 666"

echo "[*] Faille 3 : connexion SSH root autorisée (PermitRootLogin yes)"
if grep -Eiq '^\s*PermitRootLogin' /etc/ssh/sshd_config; then
    sed -i -E 's/^\s*#?\s*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
else
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
echo "    -> PermitRootLogin yes"

echo "[*] Faille 4 : pare-feu désactivé"
ufw disable 2>/dev/null || true
echo "    -> ufw inactif"

echo
echo "[OK] Failles en place. Lancez maintenant :  sudo ./audit.sh"
echo "Pour revenir à un état sain, restaurez le snapshot VirtualBox 'propre'."
