# Exemple de rapport généré

Ce fichier est un **vrai rapport** produit par `audit.sh`, lancé sur le serveur de test
dans l'état **vulnerable** (les 4 failles volontaires en place). Il est reproduit tel quel,
sans retouche, pour montrer le format de sortie.

Score obtenu : **50 / 100** (deux failles critiques à −20, une faille moyenne à −10).

---

# Rapport d'audit de securite

- Machine : srv-entreprise
- Date : 2026-10-27 21:58
- Score : **50 / 100**

| Statut | Gravite | Controle | Detail |
|--------|---------|----------|--------|
| PASS | - | /etc/passwd en 644 | Droits corrects |
| PASS | - | /etc/shadow en 640 | Droits corrects |
| FAIL | critique | Comptes UID 0 multiples | Trouves : root,admin2 |
| FAIL | critique | SSH PermitRootLogin yes | Mettre PermitRootLogin no |
| NA | absence | firewall not installed | manque de ufw |
| PASS | _ | Ports ouverts | Ports ouverts : 0.0.0.0:22,0.0.0.0:53130,0.0.0.0:5353,127.0.0.1:631,[::1]:631,[::]:22,[::]:50469,[::]:5353 |
| FAIL | moyen | 1 Fichier world-writable | Exemples . /srv/compta/budget.txt |

---

À titre de comparaison, sur l'état **propre** (sans faille), le même script affiche
**100 / 100**, tous les contrôles en PASS. Voir les captures dans
[../docs/screenshots/](../docs/screenshots/).
