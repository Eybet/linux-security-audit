# Les contrôles de sécurité

Ce document décrit chaque contrôle que l'outil effectue : la commande utilisée, ce qu'une
sortie saine donne, ce qui constitue une faille, et la gravité attribuée.

Le score part de 100 et chaque échec retire des points selon sa gravité :

| Gravité | Points retirés |
|---|---|
| Critique | 20 |
| Moyen | 10 |
| Faible | 5 |

Un contrôle qui ne s'applique pas à la machine (service absent, par exemple dans un
conteneur) est marqué `N/A` et ne retire aucun point.

---

## 1. Droits de `/etc/passwd` et `/etc/shadow`

**Commande**
```bash
stat -c '%a %U:%G %n' /etc/passwd /etc/shadow
```

`/etc/passwd` liste les comptes ; `/etc/shadow` contient les empreintes des mots de passe.

| Fichier | Droits attendus | Faille si |
|---|---|---|
| `/etc/passwd` | `644`, `root:root` | modifiable par d'autres que root |
| `/etc/shadow` | `640` ou `600`, `root:shadow` | lisible par tout le monde (ex. `644`, `777`) |

Un `/etc/shadow` lisible par tous permet de récupérer les empreintes et de tenter de casser
les mots de passe hors ligne. **Gravité : critique.**

---

## 2. Comptes avec UID 0

**Commande**
```bash
awk -F: '$3==0 {print $1}' /etc/passwd
```

Sous Linux, c'est l'**UID 0** qui donne les pleins pouvoirs, pas le nom « root ». Tout compte
avec l'UID 0 est un super-utilisateur.

- Sain : seul `root` apparaît.
- Faille : un second nom apparaît (ex. `admin2`). C'est une porte dérobée classique, discrète
  dans une simple liste de comptes. **Gravité : critique.**

---

## 3. Configuration SSH

**Commande**
```bash
grep -Ei '^\s*PermitRootLogin|^\s*PasswordAuthentication' /etc/ssh/sshd_config
```

SSH est souvent le seul point d'entrée d'un serveur.

| Réglage | Valeur sûre | Faille |
|---|---|---|
| `PermitRootLogin` | `no` ou `prohibit-password` | `yes` : connexion directe en root autorisée |
| `PasswordAuthentication` | `no` (clés uniquement) | `yes` : exposé aux attaques par mot de passe |

`PermitRootLogin yes` est **critique** ; `PasswordAuthentication yes` est **moyen** (acceptable
dans un labo, à éviter en production).

> Note technique : la regex tolère les espaces et une casse variable, car un fichier peut
> contenir des lignes mal formées (par exemple après une édition automatique).

---

## 4. Pare-feu

**Commande**
```bash
ufw status        # ou : firewall-cmd --state / nft list ruleset / iptables -L
```

Un pare-feu limite les connexions entrantes aux seuls ports nécessaires.

- Sain : `ufw` actif avec une politique par défaut en refus.
- Faille : `Status: inactive`, aucune règle. **Gravité : moyen.**
- Si aucun outil de pare-feu n'est installé (cas d'un conteneur minimal) : `N/A`.

---

## 5. Ports ouverts

**Commande**
```bash
ss -tuln
```

Chaque port en écoute est une surface d'attaque potentielle.

- `0.0.0.0` / `:::` = service exposé à tout le réseau.
- `127.0.0.1` / `::1` = service local uniquement, risque plus faible.

Ce contrôle est surtout **informatif** : il liste les ports et signale ceux exposés au réseau.
Un service inattendu (ex. impression `:631` sur un serveur) mérite attention. **Gravité : faible.**

---

## 6. Fichiers modifiables par tous (world-writable)

**Commande**
```bash
find / -xdev -type f -perm -0002 -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null
```

Un fichier world-writable (droits se terminant par `2`, `6` ou `7`, ex. `666`) peut être
modifié par n'importe quel compte du système.

- `-xdev` limite la recherche au système de fichiers courant (évite `/proc`, les montages réseau).
- Sain : aucun fichier sensible world-writable.
- Faille : un fichier de données ou de configuration modifiable par tous (ex.
  `/srv/compta/budget.txt` en `666`). **Gravité : moyen.**

---

## Ce que l'outil ne vérifie pas (limites)

Un audit honnête nomme ses limites. Cette version ne couvre pas :

- les mises à jour de sécurité en attente ;
- la configuration fine de `sudoers` ;
- la robustesse réelle des mots de passe ;
- les règles SELinux / AppArmor ;
- les tâches `cron` suspectes ;
- l'intégrité des binaires système.

Ce sont des pistes d'amélioration pour une version future.
