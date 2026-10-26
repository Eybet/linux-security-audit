#!/usr/bin/env bash
#
# audit.sh — Linux Security Audit Tool
# Lit la configuration de securite d'une machine Linux et genere un rapport
# Markdown avec un score. LECTURE SEULE : ne modifie jamais le systeme.
#
set -uo pipefail

REPORT="audit_report.md"
SCORE=100
declare -a ROWS

# record : enregistre un resultat et ajuste le score
#   $1 statut (PASS|FAIL|NA)  $2 gravite  $3 titre  $4 detail
record() {
    local statut="$1" gravite="$2" titre="$3" detail="$4"
    if [[ "$statut" == "FAIL" ]]; then
        case "$gravite" in
            critique) SCORE=$((SCORE - 20)) ;;
            moyen)    SCORE=$((SCORE - 10)) ;;
            faible)   SCORE=$((SCORE - 5))  ;;
        esac
    fi
    ROWS+=("| $statut | $gravite | $titre | $detail |")
}

# ---- Controle 1 : droits de /etc/passwd et /etc/shadow ----
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
  comptes=$(awk -F: '$3==0 {print $1}' /etc/passwd)

  if [["$comptes" == "root"]] then
   record "PASS" "-" "Un seul compte UID 0 " "root uniquement"
  else
    record "FAIL" "critique" "Comptes UID 0 multiples" "Trouves : $comptes"
    fi
}

checkSSH(){
    local file="/etc/ssh/sshd_config"
    if[[! -f ${file}]] then
     record "NA" "_" "ssh configuration" "sshd non installe"
     
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
    generate_report
}

main "$@"
