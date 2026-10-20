# ShiftPad : modèle payant

*Document de conception · 2026-10-20 · fait suite à la v1 validée (sortie d'une heure le 2026-10-20, voir `docs/testing/findings.md`)*

## 1. Intention

Le porteur veut gagner un peu d'argent avec ShiftPad, sans refaire l'erreur de BikeControl : un essai qui s'épuise pendant la configuration, avant même d'avoir roulé.

Choix faits par le porteur :
- **achat unique**, pas d'abonnement ;
- **essai complet de 14 jours**, sans limite de commandes ;
- **deux canaux de vente** : le Microsoft Store et un site à lui ;
- **pas encore de statut** pour encaisser : il faudra en créer un avant la première vente.

## 2. Objectifs, non-objectifs, anti-objectifs

**Objectifs**
- Pendant 14 jours après la première ouverture, tout fonctionne, sans aucune limite.
- Ensuite, un achat unique débloque ShiftPad pour toujours sur cette version majeure (v1.x).
- Acheter prend moins de 2 minutes et ne demande ni compte ShiftPad ni mot de passe.
- Une fois acheté, ShiftPad marche **hors ligne** (un PC de vélo n'est pas toujours connecté).

**Non-objectifs**
- Pas d'abonnement, pas de publicité, pas de collecte de données d'usage.
- Pas de protection anti-copie lourde. On accepte qu'une personne déterminée puisse contourner l'essai : ce n'est pas rentable de la combattre, et une protection lourde gênerait les acheteurs honnêtes.

**Anti-objectifs (échec même si « ça marche »)**
- Une séance coupée en plein effort parce que l'essai ou une vérification de licence a expiré.
- Un acheteur bloqué parce qu'Internet ou le serveur de licence ne répond pas.
- Un compte à rebours ou des messages insistants pendant la séance.

## 3. Règles produit

1. **L'essai démarre à la première ouverture** de ShiftPad, pas à l'installation. Il dure 14 jours calendaires.
2. **Pendant l'essai**, l'accueil affiche discrètement « Essai : X jours restants » et un bouton « Acheter ». Rien d'autre.
3. **Jamais de coupure pendant une séance.** Si l'essai expire pendant que ShiftPad est ouvert, tout continue jusqu'à la fermeture.
4. **Après l'essai**, à l'ouverture, un écran simple propose d'acheter ShiftPad (prix affiché) ou d'entrer une clé. Les manettes restent connectées et l'écran de diagnostic reste accessible, mais aucune commande n'est envoyée à MyWhoosh.
5. **Hors ligne** : une licence déjà validée reste valable sans Internet. Pour une licence achetée sur le site, ShiftPad la revérifie tous les 7 jours s'il a Internet, et tolère 60 jours sans contact. Ensuite, il demande une connexion, sans couper une séance en cours.
6. **Prix** : à décider (proposition : 12 € TTC). Même prix sur les deux canaux.

## 4. Les deux canaux

### 4.1 Microsoft Store (version « Store »)
- Le paquet est publié en **MSIX**. Microsoft le signe, l'installe et le met à jour : pas d'alerte « éditeur inconnu ».
- L'essai et l'achat sont gérés par le Store. On règle « essai gratuit de 14 jours » dans le Partner Center.
- ShiftPad lit l'état de la licence avec l'API Windows `StoreContext.GetAppLicenseAsync()` (est-ce un essai, et jusqu'à quand). Le Store garde cette licence hors ligne.
- Le bouton « Acheter » ouvre l'achat dans le Store (`RequestPurchaseAsync`).
- Microsoft encaisse et reverse au porteur, avec une commission (environ 12 % pour une application, taux à vérifier au moment de l'inscription).

### 4.2 Site du porteur (version « directe »)
- Le site est une page de présentation simple avec un bouton « Acheter ».
- **Paiement par un « vendeur officiel » (merchant of record)** comme Lemon Squeezy ou Paddle. C'est ce service qui vend légalement, encaisse, et gère la **TVA européenne** et les factures. Le porteur reçoit des versements. Frais : environ 5 % + 0,50 € par vente (à vérifier).
- Après l'achat, le client reçoit une **clé de licence** par e-mail et la colle dans ShiftPad.
- ShiftPad **active** la clé une fois en ligne (API de licence du service), puis garde chez lui une preuve d'activation. Une clé = 3 PC (le PC du vélo, plus deux de rechange).
- L'essai de 14 jours est compté localement : date de première ouverture, gardée à deux endroits pour éviter qu'une simple réinstallation le remette à zéro (le gain contre la triche reste modeste, on l'assume).
- La version directe a besoin d'une **signature de code** pour éviter l'alerte Windows SmartScreen. Option la moins chère : Azure Trusted Signing (abonnement mensuel modeste, à vérifier). Sans signature, l'alerte « Windows a protégé votre PC » fera fuir des acheteurs.

### 4.3 Une seule base de code
- Le choix du canal se fait à la compilation (`--dart-define=CHANNEL=store` ou `direct`).
- Le reste de l'appli ne parle qu'à une interface `LicenseService`. Elle répond à quatre questions : est-on en essai ? combien de jours restent-ils ? l'appli est-elle débloquée ? comment acheter ou activer ?
- Deux implémentations : `StoreLicenseService` (API Windows Store, via un petit plugin natif en C++) et `KeyLicenseService` (clé + API du vendeur officiel).
- Le « verrou » est à un seul endroit : le `ShiftPadController` n'envoie rien quand l'appli n'est pas débloquée **et** que l'essai était déjà fini à l'ouverture (règle 3).

## 5. Préalables hors code (à faire par le porteur, avant la première vente)

1. **Statut** : créer une micro-entreprise (gratuit, en ligne sur le guichet unique de l'INPI). Activité de vente de logiciels, BNC ou BIC selon le conseil reçu. *À confirmer avec un comptable ou l'URSSAF, ce document n'est pas un conseil juridique.*
2. **Nom** : vérifier que « ShiftPad » n'est pas déjà une marque déposée dans le domaine (bases INPI et EUIPO), et réserver le nom de domaine.
3. **Comptes** : compte développeur Microsoft Partner Center (individuel), compte chez le vendeur officiel (Lemon Squeezy ou Paddle), tous les deux liés au statut.
4. **Textes obligatoires** : politique de confidentialité (exigée par le Store : ShiftPad ne collecte rien sauf la clé de licence pour l'activation), conditions de vente, mentions de compatibilité (« compatible avec les Zwift Click V2 », sans logo Zwift ni MyWhoosh).

## 6. Ce qui reste à décider

- Le prix exact (proposition : 12 €).
- Lemon Squeezy ou Paddle (à comparer au moment de l'inscription : frais, versements en euros, API de licence).
- Ce que débloque l'achat pour la v2 : rien d'automatique (proposition), ou une remise pour les acheteurs de la v1.

## 7. Critères de réussite

- Un nouvel utilisateur roule 14 jours sans voir de limite.
- Un acheteur sur le Store passe de « essai fini » à « débloqué » en moins de 2 minutes, sans clé.
- Un acheteur sur le site colle sa clé et c'est débloqué en moins de 2 minutes.
- Une fois débloqué, ShiftPad démarre et fonctionne sans Internet.
- Aucune séance n'est jamais coupée par l'essai ou la licence (test automatique).
