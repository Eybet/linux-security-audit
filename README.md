# Linux Security Audit Tool

Un script Bash qui audite la configuration de sécurité d'une machine Linux et génère un
rapport Markdown avec un **score** et des **recommandations**. Projet d'apprentissage en
cybersécurité, construit pas à pas et testé dans une VM et un conteneur Docker.

> **Statut : en cours de construction.** Le laboratoire de test est prêt et documenté
> (VM Debian, utilisateurs, dossiers par service, failles volontaires, audit manuel validé).
> Le script `audit.sh` est la prochaine étape — voir [Avancement](#avancement).

![Architecture du laboratoire](docs/screenshots/architecture.png)

## Les contrôles

| # | Contrôle | Gravité |
|---|---|---|
| 1 | Droits de `/etc/passwd` et `/etc/shadow` | Critique |
| 2 | Comptes avec UID 0 (root cachés) | Critique |
| 3 | Configuration SSH (root login, mots de passe) | Critique / Moyen |
| 4 | Pare-feu actif | Moyen |
| 5 | Ports ouverts | Faible |
| 6 | Fichiers modifiables par tous (world-writable) | Moyen |

Détail de chaque contrôle, commande et logique de score : [docs/checks.md](docs/checks.md).

## Utilisation (prévue)

```bash
git clone https://github.com/TON_PSEUDO/linux-security-audit.git
cd linux-security-audit
chmod +x audit.sh
sudo ./audit.sh
```

Le script lira l'état du système et écrira `audit_report.md`. Il ne modifie jamais la machine.

## Le laboratoire de test

Les tests se font sur une VM Debian 13 qui simule un petit serveur d'entreprise :

| Utilisateur | Groupe | Rôle |
|---|---|---|
| `alice` | `sudo` | Administratrice système |
| `bob` | `compta` | Comptable |
| `claire` | `rh` | Ressources humaines |
| `stagiaire` | `stagiaire` | Accès minimal |

Construction complète, pas à pas et avec captures : [docs/lab-setup.md](docs/lab-setup.md).
Un guide PDF complet est disponible dans [docs/lab-report.pdf](docs/lab-report.pdf).

![Connexion SSH au serveur de test](docs/screenshots/05-ssh-connected.png)

## Structure du dépôt

```
linux-security-audit/
├── audit.sh                # le script d'audit (à venir)
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── lab-setup.md        # construction de la VM et des comptes
│   ├── checks.md           # les contrôles et leur logique de score
│   ├── journal.md          # journal de bord du projet
│   ├── lab-report.pdf      # guide complet en PDF
│   └── screenshots/
├── tests/
│   └── vulnerable_setup.sh # recrée les failles volontaires pour tester
├── docker/
│   └── Dockerfile          # lancer l'audit dans un conteneur (à venir)
└── examples/
    └── sample_report.md    # exemple de rapport généré (à venir)
```

## Avancement

- [x] VM Debian installée, interface graphique retirée, SSH fonctionnel
- [x] Groupes, utilisateurs et dossiers par service
- [x] Snapshots `propre` et `vulnerable`
- [x] Failles volontaires + audit manuel validé
- [x] Documentation (lab-setup, checks, journal) et rapport PDF
- [ ] Script `audit.sh` (un contrôle à la fois)
- [ ] Rapport Markdown avec score
- [ ] Test dans un conteneur Docker
- [ ] Rapport d'exemple

Le journal détaillé est dans [docs/journal.md](docs/journal.md).

## Avertissement

À utiliser **uniquement** sur des machines dont vous êtes propriétaire, ou que vous avez
l'autorisation explicite d'auditer. Le script est conçu pour **lire** l'état du système, jamais
le modifier. Le script `tests/vulnerable_setup.sh` affaiblit volontairement la sécurité : il ne
doit tourner que sur une VM de test jetable.

## Licence

Distribué sous licence MIT. Voir [LICENSE](LICENSE).
