#!/usr/bin/env bash

set -uo pipefail

REPORT="audit_report.md"
SCORE=100
declare -a ROWS


record() {
    local statut="$1" gravite="$2" titre="$3" detail="$4"
    if [[ "$statut" == "FAIL" ]]; then
        case "$gravite" in
            critique) SCORE=$((SCORE - 20)) ;;
            moyen)    SCORE=$((SCORE - 10)) ;;
            faible)   SCORE=$((SCORE - 5))  ;;
            absence)  SCORE=$((SCORE -2)) ;;
        esac
    fi
    ROWS+=("| $statut | $gravite | $titre | $detail |")
}


check_file_permissions() {
    local perm_passwd perm_shadow
    perm_passwd=$(stat -c '%a' /etc/passwd 2>/dev/null)
    if [[ "$perm_passwd" == "644" ]]; then
        record "PASS" "-" "/etc/passwd en 644" "Droits corrects"
    else
        record "FAIL" "moyen" "/etc/passwd en $perm_passwd" "Attendu 644"
    fi
    perm_shadow=$(stat -c '%a' /etc/shadow 2>/dev/null)
    if [[ "$perm_shadow" == "640" || "$perm_shadow" == "600" ]]; then
        record "PASS" "-" "/etc/shadow en $perm_shadow" "Droits corrects"
    else
        record "FAIL" "critique" "/etc/shadow en $perm_shadow" "Trop permissif, attendu 640"
    fi
}


checkUID0(){
  local comptes
  comptes=$(awk -F: '$3==0 {print $1}' /etc/passwd | paste -sd ',' -)

  if [[" $comptes" == "root" ]]; then
   record "PASS" "-" "Un seul compte UID 0 " "root uniquement"
  else
    record "FAIL" "critique" "Comptes UID 0 multiples" "Trouves : $comptes"
  fi
}


checkSSH(){
    local file="/etc/ssh/sshd_config"
    if[[! -f ${file}]] then
     record "NA" "_" "ssh configuration" "sshd non installe"
      if grep -Eiq '^[[:space:]]*PermitRootLogin[[:space:]]+yes' "$file"; then
        record "FAIL" "critique" "SSH PermitRootLogin yes" "Mettre PermitRootLogin no"
    else
        record "PASS" "-" "SSH root login" "Non autorise"
    fi
}


checkUFW() { 
    if ! command -v ufw >/dev/null 2>&1; then
     record "NA" "absence" "firewall not installed" "manque de ufw"
     return
    fi
    if ufw status 2>/dev/null | grep -qi "Status: active"; then
     record "PASS" "_" "ufw trouvé et actif" "ufw active"

    else 
      record "FAIL" "moyen" "Pare-feu incatif" "Activer : ufw enable"
    fi
}


check_open_ports(){
    if ! command -v ss >/dev/null 2>&1; then 
     record "NA" "_" "ss non installe" "ss non installe"
     return
     fi
    
    local ports=$(ss -tuln | awk  'NR>1 {print $5}'  | paste -sd '' -)
    if [[ -z "$ports" ]]; then
        record "NA" "_" "Ports ouverts" "Aucun port ouvert"
    else
    record "PASS" "_" "Ports ouverts" "Ports ouverts : $ports"

    fi


    }

  check_world_writable(){
    local files
    files==$(sudo find / -xdev -type f -perm -0002 \
                   -not -path '/proc/*' -not -path '/sys/*' 2>/dev/nul )
    
    if [[ -z "$files" ]]; then
    record "PASS" "_" "Fichiers world-writable" "Aucun fichier"

    else
     local nb=$( echo "$files" | wc -l)
     local liste=$(echo "$files" | head -3 | paste -sd ',' -)
     record "FAIL" "moyen" "$nb Fichier world-writable" "Exemples . $liste"
    
    fi
  }




generate_report() {
    {
        echo "# Rapport d'audit de securite"
        echo
        echo "- Machine : $(hostname)"
        echo "- Date : $(date '+%Y-%m-%d %H:%M')"
        echo "- Score : **$SCORE / 100**"
        echo
        echo "| Statut | Gravite | Controle | Detail |"
        echo "|--------|---------|----------|--------|"
        printf '%s\n' "${ROWS[@]}"
    } > "$REPORT"
    echo "Rapport genere : $REPORT  (score $SCORE/100)"
}

main() {
    check_file_permissions
    checkUID0
    checkSSH
    checkUFW
    check_open_ports
    check_world_writable
    generate_report
}

main "$@"
