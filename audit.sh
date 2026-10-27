#!/usr/bin/env bash

set -uo pipefail

if [[ -t 1 ]]; then
    BOLD=$'\e[1m'; DIM=$'\e[2m'; RESET=$'\e[0m'
    GREEN=$'\e[32m'; RED=$'\e[31m'; YELLOW=$'\e[33m'; CYAN=$'\e[36m'
else
    BOLD=""; DIM=""; RESET=""; GREEN=""; RED=""; YELLOW=""; CYAN=""
fi

  print_header() {
    printf '\n%s%s  Audit de securite — %s%s\n\n' "$BOLD" "$CYAN" "$(hostname)" "$RESET"
    printf '%s  %-6s %-9s %s%s\n' "$DIM" "STATUT" "GRAVITE" "CONTROLE" "$RESET"
    printf '%s  %s%s\n' "$DIM" "$(printf '─%.0s' $(seq 1 50))" "$RESET"
}


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
    local color
    case "$statut" in
        PASS) color="$GREEN" ;;
        FAIL) color="$RED"   ;;
        *)    color="$YELLOW" ;;
    esac
    printf '  %s%-6s%s %-9s %s\n' "$color" "$statut" "$RESET" "$gravite" "$titre"
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

  if [[ "$comptes" == "root" ]]; then
   record "PASS" "-" "Un seul compte UID 0 " "root uniquement"
  else
    record "FAIL" "critique" "Comptes UID 0 multiples" "Trouves : $comptes"
  fi
}


checkSSH(){
    local file
    file="/etc/ssh/sshd_config"
    
    if [[ ! -f "$file" ]]; then
        record "NA" "_" "ssh configuration" "sshd non installe"
    else
        if grep -Eiq '^[[:space:]]*PermitRootLogin[[:space:]]+yes' "$file"; then
            record "FAIL" "critique" "SSH PermitRootLogin yes" "Mettre PermitRootLogin no"
        else
            record "PASS" "-" "SSH root login" "Non autorise"
        fi 
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
    
    local ports
    ports=$(ss -tuln | awk  'NR>1 {print $5}'  | sort -u | tr '\n' ',' | sed 's/,$//')
    if [[ -z "$ports" ]]; then
        record "NA" "_" "Ports ouverts" "Aucun port ouvert"
    else
    record "PASS" "_" "Ports ouverts" "Ports ouverts : $ports"

    fi


    }

  check_world_writable(){
    local files
    files=$(sudo find / -xdev -type f -perm -0002 \
                   -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null )
    
    if [[ -z "$files" ]]; then
    record "PASS" "_" "Fichiers world-writable" "Aucun fichier"

    else
     local nb
     nb=$( echo "$files" | wc -l)
     local liste
     liste=$(echo "$files" | head -3 |  tr '\n' ',' | sed 's/,$//')
     record "FAIL" "moyen" "$nb Fichier world-writable" "Exemples . $liste"
    
    fi
  }

  print_summary() {
    local color="$GREEN"
    (( SCORE < 80 )) && color="$YELLOW"
    (( SCORE < 50 )) && color="$RED"
    local filled=$(( SCORE / 5 ))          
    printf '\n  Score : %s%s%d/100%s  [' "$BOLD" "$color" "$SCORE" "$RESET"
    (( filled > 0 )) && printf '%s' "$color" && printf '█%.0s' $(seq 1 $filled)
    (( filled < 20 )) && printf '%s' "$DIM" && printf '░%.0s' $(seq 1 $((20-filled)))
    printf '%s]\n\n' "$RESET"
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
    print_header
    check_file_permissions
    checkUID0
    checkSSH
    checkUFW
    check_open_ports
    check_world_writable
    print_summary
    generate_report
}

main "$@"
