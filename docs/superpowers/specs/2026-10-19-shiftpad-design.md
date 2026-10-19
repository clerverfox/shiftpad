# ShiftPad : passer les vitesses virtuelles de MyWhoosh avec des Zwift Click V2

*Document de conception · 2026-10-19 · nom de travail du dossier : MyShift, nom produit : **ShiftPad** (choisi par le porteur)*

## 1. Intention

Le porteur du projet roule sur un home trainer D500 avec un Zwift Cog (pignon unique, pas de vraies vitesses) et possède une paire de **Zwift Click V2**. Il utilise **MyWhoosh** (gratuit) sur PC Windows pour ne pas payer l'abonnement Zwift. Pour changer de vitesse virtuelle dans MyWhoosh avec les Click, il a essayé **BikeControl** : la version d'essai (15 commandes/jour) s'est épuisée pendant la seule configuration, et il n'a jamais réussi à faire apparaître BikeControl dans MyWhoosh en connexion locale sur le même PC.

ShiftPad fait le même travail que BikeControl : il lit les boutons des Click V2 en Bluetooth et les transforme en commandes de vitesse (et autres actions) dans MyWhoosh. Ce qui doit le rendre meilleur :
1. **Ça marche sur un seul PC Windows du premier coup** : ShiftPad et MyWhoosh sur la même machine, sans installer Bonjour ni autre logiciel tiers.
2. **Aucune limite de commandes** pendant l'usage.
3. Une interface qui guide clairement (état des manettes, état de la liaison avec MyWhoosh, que faire si ça ne marche pas).

À terme, le porteur aimerait **gagner un peu d'argent** avec l'appli. Le code doit donc lui appartenir entièrement et pouvoir être vendu (voir §4).

## 2. Objectifs, non-objectifs, anti-objectifs

**Objectifs (v1)**
- Windows 10/11 en premier ; base de code unique pensée pour Android, macOS, iOS ensuite.
- Support complet de la paire Zwift Click V2 (gauche : 4 flèches + « − » ; droite : A, B, Y, Z + « + »).
- Deux modes, proposés et expliqués comme dans BikeControl :
  - **Manette droite seule** : fonctionne sans rien d'autre. Par défaut « + » = monter, « B » = descendre.
  - **Deux manettes** : la gauche est utilisable lorsqu'elle est débloquée (voir §5.2). L'appli guide l'utilisateur pour le déblocage, détecte quand il expire, prévient, et retombe proprement en mode droite seule.
- Envoi des commandes à MyWhoosh par **OpenBikeControl** (protocole natif MyWhoosh ≥ 5.7), avec **repli clavier** automatique.
- Correspondance boutons → actions configurable (vitesses, direction, emotes, vue, masquer l'interface…), avec des valeurs par défaut sensées.
- Reconnexion automatique des manettes, sans intervention.

**Non-objectifs (v1)**
- Pas d'appli d'entraînement : pas de pilotage de la résistance du trainer (MyWhoosh le fait lui-même en FTMS).
- Pas de support de Zwift, Rouvy, etc. comme cibles (l'architecture doit permettre de les ajouter).
- Pas d'autres manettes que les Click V2 en v1 (Zwift Play, Ride, Click V1, manettes de jeu : plus tard ; l'abstraction « appareil » doit le permettre).
- Pas de paiement ni de licence en v1. Mais rien dans la conception ne doit empêcher un modèle payant ensuite.

**Anti-objectifs (échec même si « ça marche »)**
- Latence perceptible entre l'appui et le changement de vitesse, ou appuis perdus en plein effort.
- Déconnexions Bluetooth à répétition, ou manette gauche qui « meurt » en silence au bout d'une minute.
- Une appli qui ne se voit pas dans MyWhoosh sans explication (exactement l'échec vécu avec BikeControl).
- Une limite de commandes qui gêne l'utilisateur avant même qu'il ait roulé.

## 3. Contraintes

- **Juridique / licences** :
  - Le code actuel de BikeControl (github.com/OpenBikeControl/bikecontrol) est sous **licence non commerciale** ; ses parties Click V2 sont dans un module privé. **Ne pas copier son code.** On peut le lire pour comprendre le comportement ; on réimplémente à partir des faits de protocole (non protégeables).
  - Sources de protocole utilisables : projets **MIT** — thomaschampagne/zwiftboard (Go, Click V2 → MyWhoosh), prioneto/ClickShift (Swift), milabarreirae-prog/ZwiftClickV2-Bridge (C#) ; protocole OpenBikeControl (MIT) : github.com/OpenBikeControl/openbikecontrol-protocol. Citer les sources MIT dans un fichier de mentions si du code en est repris.
  - **Ne pas** utiliser de code GPL (anciennes versions de BikeControl, qdomyos-zwift) : ça forcerait l'appli à être GPL.
  - **Ne pas** débloquer la manette gauche en appelant les serveurs de Zwift avec le compte de l'utilisateur (méthode du projet ZwiftClickV2-Bridge) : zone grise juridique incompatible avec une appli vendue.
- **Nom** : ne pas utiliser « MyShift » (nom officiel du changement de vitesse de MyWhoosh), ni « Zwift »/« Whoosh » dans le nom produit.
- **Environnement de dev** : PC Windows 11, dossier vide, Flutter non installé (à installer). Le porteur ne code pas : Claude fait tout, le porteur teste sur son vélo.
- **Le PC de dev n'est pas le PC du vélo.** Le PC du vélo fait tourner MyWhoosh, est à portée Bluetooth des Click V2 et du D500 ; le porteur peut s'y rendre pour les sessions de test. Conséquences :
  - les tests sur matériel se font par **builds Windows copiés sur le PC du vélo** (exécutable portable ou installeur simple) ;
  - **dès la première version, l'appli embarque un mode diagnostic** : écran de trames BLE brutes, journal horodaté, bouton « exporter les journaux » (fichier à renvoyer à Claude) ;
  - le travail est découpé pour que chaque session de test sur le vélo valide plusieurs points à la fois (voir le spike §5.2 et les vérifications « à tester » de §5.1 et §5.3).
  - Option plus rapide si le porteur le souhaite : lancer Claude Code directement sur le PC du vélo pendant les phases d'exploration.
- **Bluetooth partagé** : MyWhoosh se connecte au D500 en Bluetooth sur le même PC. Le PC du vélo porte donc trois liaisons BLE (trainer + 2 manettes). **Un test de stabilité d'une heure fait partie de la première session sur le vélo** ; si des décrochages apparaissent, documenter une clé USB Bluetooth recommandée.
- **Langue de l'interface** : **anglais simple** uniquement en v1 (choix du porteur). Choix de Claude : textes centralisés dans des fichiers de traduction pour pouvoir ajouter le français plus tard sans retoucher les écrans.

## 4. Choix techniques décidés

*Choix de Claude, le porteur ayant délégué la technique.*
- **Flutter / Dart**, une seule base pour Windows, Android, macOS, iOS.
- **BLE : `universal_ble`** (BSD-3, support Windows WinRT). Pas `flutter_blue_plus` (licence payante pour usage commercial, pas de Windows natif).
- Code natif minimal par plateforme via plugins internes (Windows : C++ pour l'injection de touches et éventuellement l'enregistrement mDNS).

## 5. Comment ça marche

### 5.1 Lecture des Click V2 (faits de protocole, recoupés par plusieurs sources)
- Publicité BLE : manufacturer ID **0x094A** ; premier octet de données = type d'appareil : **0x0A = Click V2 droite, 0x0B = Click V2 gauche** (marqué « non confirmé » dans BikeControl → à vérifier sur le matériel réel).
- Service `00000001-19CA-4651-86E5-FA29DCDD09D1` (certains firmwares exposent aussi `0xFC82`).
  - `…0002` Async (notify) : boutons. `…0003` SyncRx (write) : commandes. `…0004` SyncTx (indicate) : réponses.
- Poignée de main en clair (sans chiffrement) : écrire `RideOn` (+ `02 03` pour la V2) sur SyncRx ; d'après zwiftboard, envoyer ensuite `00 08 00` puis `00 08 10` à ~100 ms d'intervalle. Une manette débloquée répond « RideOn » ; une manette verrouillée envoie un défi `FF 03 00 …`.
- Boutons : opcode **0x23**, protobuf dont le champ 1 est un uint32 **actif à 0** (bit à 0 = appuyé). Masques : LEFT 0x1, UP 0x2, RIGHT 0x4, DOWN 0x8, A 0x10, B 0x20, Y 0x40, Z 0x80, MINUS 0x100, PLUS 0x1000. Trame « tout relâché » : `08 FF FF FF FF 0F`. Filtrer les doublons. Autres opcodes : 0x15 inactif, 0x19 statut, 0x2A statut initial.
- Maintien : pas de ping dans le protocole ; zwiftboard renvoie `RideOn` toutes les 3 s comme sonde, et sous Windows une manette seule se déconnecte ~65 s après la dernière trame → zwiftboard la redémarre préventivement (octet `0x18`). Une manette n'accepte **qu'une connexion BLE** : Zwift / Zwift Companion doivent être fermés.
- Écrire `FF 04 00` maintient le déblocage d'une manette déjà débloquée.
- Firmware : BikeControl annonce un support jusqu'au firmware 1.2.0 ; les mises à jour Zwift peuvent casser la compatibilité. Afficher la version de firmware dans l'appli.

### 5.2 Le verrou de la manette gauche (principal risque)
- La droite fonctionne sans déblocage. La gauche cesse d'envoyer des événements après ~1 min si elle n'a pas été débloquée (déblocage valable ~24 h) par une appli Zwift.
- BikeControl débloque la gauche via du code privé ; hypothèse : il émule une manette Zwift vis-à-vis de l'appli Zwift (ou Companion) et relaie le défi/réponse vers la vraie manette.
- **Première étape du projet = un test exploratoire (spike)** pour établir, sur le matériel du porteur :
  1. si ouvrir Zwift Companion (gratuit, sans abonnement) puis le fermer suffit à débloquer la gauche pour ShiftPad pendant 24 h ;
  2. sinon, si un relais « ShiftPad se fait passer pour la manette auprès de l'appli Zwift » est faisable sans appel aux serveurs Zwift par ShiftPad lui-même.
- Le résultat du spike fixe le parcours de déblocage proposé dans l'appli. Si aucun parcours propre n'existe, la v1 sort avec : mode droite seule + utilisation de la gauche quand elle a été débloquée par ailleurs, avec explication claire.
- **Choix de Claude par défaut (le porteur n'a pas tranché)** : en v1, on **n'implémente pas** le relais « ShiftPad se fait passer pour une manette auprès de l'appli Zwift » (zone grise juridique, gros travail BLE périphérique sous Windows, compte Zwift requis). Le spike vérifie seulement la piste 1 (Companion). Le relais pourra être réévalué après la v1.

### 5.3 Envoi à MyWhoosh
- **Voie principale : OpenBikeControl en réseau local (mDNS + TCP)**. ShiftPad s'annonce `_openbikecontrol._tcp.local.` (enregistrements TXT : version, id, nom…), MyWhoosh s'y connecte en TCP ; messages bouton `[0x01][buttonId][state]` (Shift Up = 0x01, Shift Down = 0x02, pressé = 1, relâché = 0) ; 0x02 statut, 0x03 retour haptique, 0x04 infos appli. Côté MyWhoosh : écran Connexion → icône OpenBikeControl → Oui.
- **Contrainte clé** : fonctionner **sur le même PC Windows sans Bonjour**. Approche suggérée (au constructeur de choisir) : API DNS-SD native de Windows (`DnsServiceRegister`, dnsapi.dll) ou répondeur mDNS embarqué. Vérifier que MyWhoosh (même machine) découvre bien le service, y compris sur boucle locale/plusieurs interfaces réseau.
- **À tester tôt** : MyWhoosh accepte-t-il n'importe quel appareil OpenBikeControl, ou une liste blanche ? Si refus, le repli clavier devient la voie principale sous Windows.
- **Repli : touches clavier**. MyWhoosh utilise **I** et **K** pour les vitesses ; les sources se contredisent sur laquelle monte → **vérifier sur l'appli réelle**, et laisser modifiable. Injection Windows via `SendInput` avec scan codes (MyWhoosh est sous Unreal), cible la fenêtre `MyWhoosh.exe` / `MyWhooshHD.exe`, la ramène au premier plan si nécessaire. Autres touches : A/D ou flèches = direction, 1–7 = emotes, U ou H = masquer l'interface (à vérifier).
- Bascule automatique vers le clavier si la liaison OpenBikeControl n'est pas établie, avec indication visible de la voie utilisée.
- Plus tard (hors v1) : Android/macOS/iOS utilisent OpenBikeControl en priorité (iOS ne permet pas l'injection de touches).

### 5.4 Écrans (v1)
- **Accueil / état** : les deux manettes (connectée, débloquée ou non, batterie, firmware), la liaison MyWhoosh (OpenBikeControl connecté / clavier / rien) et un indicateur du dernier bouton pressé.
- **Assistant de premier lancement** : allumer les manettes → choix du mode (droite seule / deux manettes) → connecter à MyWhoosh (avec captures ou étapes) → test « appuie sur + ».
- **Correspondance des boutons** : par manette, bouton → action.
- **Dépannage** : messages explicites si MyWhoosh ne voit pas ShiftPad, si une manette est prise par une autre appli Zwift, si la gauche est verrouillée.

## 6. Critères de réussite
- Sur le PC du porteur, MyWhoosh et ShiftPad sur la même machine : une sortie d'une heure sans perte d'appui ni déconnexion non récupérée.
- Le changement de vitesse paraît instantané (objectif : moins de 100 ms entre l'appui et la commande envoyée).
- Un nouvel utilisateur arrive de l'installation au premier changement de vitesse en moins de 5 minutes, guidé par l'appli.

## 7. Laissé au constructeur
- Architecture interne, gestion d'état, structure des dossiers, tests.
- Design visuel précis des écrans.
- Choix d'implémentation mDNS sous Windows.
- Empaquetage Windows (MSIX ou installeur classique) pour les essais du porteur.
- Détails du repli clavier (focus, scan codes).
