# Journal de bord

## 2026-10-18 — Dossiers par service, failles volontaires, audit manuel

**Fait**
- Nettoyage du bureau : `gnome-core` et `task-*-desktop` retirés. `gdm3` n'était déjà plus
  installé.
- Dossiers `/srv/compta` et `/srv/rh`, propriétaires `root:compta` et `root:rh`, puis `chmod 770`
  (seuls le propriétaire et le groupe ont accès).
- Deux snapshots VirtualBox : `propre` (serveur sain) puis `vulnerable` (avec failles).
- Failles volontaires introduites : compte `admin2` en UID 0, `/srv/compta/budget.txt` en 666,
  `PermitRootLogin yes`, pare-feu `ufw` inactif.
- Les 6 commandes d'audit lancées à la main sur l'état `vulnerable` : les 4 failles sont
  bien visibles.

**Appris / problèmes**
- Sous Linux, c'est l'**UID 0** qui fait le super-utilisateur, pas le nom « root ». D'où le
  danger d'`admin2`.
- `getent passwd` liste aussi des dizaines de **comptes système** (UID < 1000) : c'est normal,
  ils ont un shell `nologin` et servent aux services.
- Ma commande `sed` du 11/10 a laissé des caractères parasites (`ùù`) devant `PermitRootLogin`
  (problème d'encodage). Leçon : le script devra utiliser une regex tolérante.

**Prochaine fois**
- Écrire le script `audit.sh`, un contrôle à la fois, en commençant par `/etc/shadow`.

## 2026-10-17 — Utilisateurs de l'entreprise

**Fait**
- Création des groupes `compta` et `rh`.
- Création des utilisateurs `bob` (compta), `claire` (rh) et `stagiaire`.

**Appris / problèmes**
- Erreur de frappe : `sudo add user ...` donne `command not found`. La commande est
  `adduser`, en un seul mot.
- `adduser` demande des infos facultatives (nom complet, téléphone...) : Entrée pour passer.

**Prochaine fois**
- Dossiers `/srv/compta` et `/srv/rh`, snapshot, puis failles volontaires.

## 2026-10-11 — Création du serveur de test

**Fait**
- VM Debian 13 créée dans VirtualBox et installée en mode texte, sans mot de passe root.
- Redirection de port 2222 vers 22 et première connexion SSH depuis PowerShell.
- Début de suppression de l'interface graphique (GNOME installé par erreur).

**Appris / problèmes**
- Un serveur doit rester minimal : chaque paquet installé est une surface d'attaque en plus.
- La première connexion SSH demande de confirmer l'empreinte (fingerprint) de la machine,
  c'est normal.

**Prochaine fois**
- Terminer le nettoyage du bureau, puis créer les utilisateurs.
