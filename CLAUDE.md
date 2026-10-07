# Niversar.io

## Description
App iOS personnelle de rappels d'anniversaires, pour un seul utilisateur et un seul appareil (iPhone 13 mini, iOS 26.5).
Pas d'App Store, pas de serveur, pas de compte, pas de synchronisation. Tout est local.

## Environnement : contraintes non négociables
- Mac professionnel **sans droits administrateur** : jamais de `sudo`, jamais de Homebrew, jamais d'installation système.
- Xcode 26.3 installé dans `~/Applications/Xcode.app`, sélectionné via `DEVELOPER_DIR` (déjà exporté dans `~/.zshrc`).
- Le débogueur ne peut pas s'attacher (pas de droits `_developer`) : on lance l'app sans débogueur. Ne jamais réactiver « Debug executable ».
- Signature : Personal Team gratuite (compte Apple perso). **Ne jamais modifier** l'équipe, le bundle identifier, les réglages de signature ni les entitlements.
- L'iPhone doit être branché directement sur le MacBook (pas via le dock).
- Aucune dépendance tierce. Uniquement les frameworks Apple.

## Stack
- Swift 6 (mode de langage 6, concurrence stricte complète), avertissements traités comme des erreurs.
- SwiftUI, cible iOS 26.0, iPhone uniquement, portrait, mode sombre uniquement.
- Observation (`@Observable`) pour l'état. Pas de TCA, pas de MVVM cérémoniel.
- Stockage : un fichier JSON versionné (Codable) dans Application Support.
- Photos : PhotosPicker, image réduite et copiée dans l'app, référencée par nom de fichier (jamais par chemin absolu).
- Notifications : UserNotifications, rappels non répétés pour les 64 prochaines occurrences, recalculés à chaque ouverture et à chaque modification.
- Tests : Swift Testing (`import Testing`, `@Test`, `#expect`). Pas de XCTest pour la logique.
- Style : `swift format` (fourni avec la toolchain), configuration dans `.swift-format`.

## Structure
```
Niversario.xcodeproj
Niversario/                 app SwiftUI (dossier synchronisé : un fichier ajouté ici est pris en compte sans toucher au .pbxproj)
Packages/BirthdayKit/       logique métier pure, sans UI, testable sur macOS avec `swift test`
scripts/                    check.sh (format + lint + tests), run-device.sh (build + install + lancement sur l'iPhone)
```
Toute logique de calcul (dates, âges, tri, sélection des rappels) vit dans `BirthdayKit`. L'app ne fait que l'afficher.

## Commandes
- `scripts/check.sh` : formatage, lint strict, tests du package. Doit passer avant chaque commit.
- `scripts/run-device.sh` : compile, installe et lance l'app sur l'iPhone.

## Conventions de code
- **Aucun commentaire dans le code.** Le code doit se lire seul : noms explicites, petites fonctions.
- Modifications minimales : ne toucher que ce que la tâche demande. Pas de reformatage ou de refactoring opportuniste.
- Typage strict : pas de force unwrap (`!`), pas de `try!`, pas de `as!`, pas d'`Any`. Contrôle d'accès explicite dans le package (`public` uniquement pour l'API utilisée par l'app).
- Types valeur (`struct`, `enum`) par défaut. Types `Sendable` dans le package.
- Dates : `Calendar` grégorien explicite ; date du jour et calendrier injectés pour rendre la logique testable. Jamais de calcul en secondes (86 400).
- Tests sur toute la logique métier, cas limites compris (29 février, changement d'année, jour J, année inconnue).
- Interface en français.

## Règles de travail
- Une seule chose à la fois. Faire un commit Git après chaque étape qui fonctionne, avec `scripts/check.sh` vert.
- Ne pas modifier le `.pbxproj` au-delà des réglages de build explicitement demandés. Ne jamais y ajouter de package : c'est fait à la main dans Xcode.
- Si une demande est une mauvaise idée ou entre en conflit avec ce fichier, le dire franchement avant d'agir.
- Si une action demande des droits administrateur, s'arrêter et le signaler.

## Décisions produit
- Saisie manuelle uniquement (pas d'accès aux Contacts).
- Un seul rappel par personne : le jour J à 9h00.
- Année de naissance facultative : pas d'âge affiché si elle est inconnue.
- Né un 29 février : fêté le 28 février les années non bissextiles.
- Suppression toujours confirmée.
- Modèle Birthday : id, prénom, jour, mois, année (optionnelle), couleur, emoji, surnom, photo, instagram, note (tous optionnels sauf id, prénom, jour, mois, couleur).
- Phrases de notification (tirées au hasard) :
  - « 🎉🥳 C'est l'anniversaire de [Prénom] [Emoji] aujourd'hui ! »
  - « 🎉🥳 [Prénom] [Emoji] souffle ses bougies aujourd'hui, pense à lui écrire ! »
  - « 🎉🥳 Aujourd'hui c'est le jour de [Prénom] [Emoji], tu sais ce qu'il te reste à faire ! »
  - « 🎉🥳 [Prénom] [Emoji] a un an de plus aujourd'hui ! »
  - « 🎉🥳 Happy birthday [Prénom] [Emoji], don't forget to wish them well ! »
  - « 🎉🥳 [Prénom] [Emoji] devient plus vieux aujourd'hui... pense à le lui rappeler ! »
  - « 🎉🥳 Alerte gâteau : [Prénom] [Emoji] fête son anniversaire aujourd'hui ! »
  - « 🎉🥳 Breaking news : [Prénom] [Emoji] a survécu à une année de plus. Envoie-lui un message ! »
  - « 🎉🥳 Mission du jour : souhaiter un joyeux anniversaire à [Prénom] [Emoji]. Ce message s'autodétruira à minuit. »
  - « 🎉🥳 Hoje é o dia de [Prénom] [Emoji] ! Parabéns, et pense à lui écrire ! »

## Direction visuelle
Hybride : composants natifs iOS 26 (Liquid Glass sur barres et boutons flottants, feuilles natives, transition zoom carte → fiche, haptiques, Dynamic Type) avec l'identité de l'app.
- Fond `#0F0F14`, surfaces `#1A1A24`, surfaces élevées `#22222F`, séparateurs `#2A2A38`.
- Texte principal `#F0F0F5`, secondaire `#6B6B80`, tertiaire `#3D3D50`.
- Accent menthe `#4ECFA0` (AccentColor de l'app).
- Palette pastel, une couleur par mois et choisissable par personne :
  `#FFB3B3` `#FFD4A3` `#FFF0A3` `#B3F0B3` `#A3D4FF` `#C4B3FF` `#FFB3E6` `#B3FFF0` `#FFB3C6` `#D4FFB3` `#B3C6FF` `#FFE0B3`
- Police système uniquement, en styles dynamiques (pas de tailles en points fixes).
- Écran principal : 2 prochains anniversaires en cartes, puis calendrier mensuel à défilement horizontal (nom du mois dans sa couleur pastel, numéros de jours uniquement, jour actuel en cercle accent atténué).
- Fiche personne façon Hinge : photo pleine largeur (ou initiale sur fond surface), bandeau sombre en bas avec barre pastel, prénom, badge âge et date, surnom, badge « Dans X jours » ; puis note, Instagram, Modifier, Supprimer.
- Ton des textes : chaleureux et léger (« C'est qui la prochaine star du gâteau ? 🎂 »).
