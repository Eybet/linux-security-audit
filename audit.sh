#!/usr/bin/env bash
#
# audit.sh — Linux Security Audit Tool
# Lit la configuration de securite d'une machine Linux et genere un rapport
# Markdown avec un score. LECTURE SEULE : ne modifie jamais le systeme.
#
set -uo pipefail

# ---------------------------------------------------------------------------
# Variables globales
# ---------------------------------------------------------------------------
REPORT="audit_report.md"     # fichier de sortie
SCORE=100                    # le score part de 100
declare -a ROWS              # tableau qui stocke les lignes de resultat

# ---------------------------------------------------------------------------
# record : enregistre le resultat d'un controle et ajuste le score
#   $1 = statut   (PASS | FAIL | NA)
#   $2 = gravite  (critique | moyen | faible | -)
#   $3 = titre court
#   $4 = detail / recommandation
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Controle 1 : droits de /etc/passwd et /etc/shadow
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Generation du rapport Markdown
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Programme principal
# ---------------------------------------------------------------------------
main() {
    check_file_permissions
    # les prochains controles s'ajouteront ici
    generate_report
}

main "$@"
