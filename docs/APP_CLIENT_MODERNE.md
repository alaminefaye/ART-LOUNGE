# App Client Moderne (Commande à emporter) — Plan & Architecture

## Objectif
Créer une nouvelle application Flutter “client” (belle, moderne) dans la racine du projet, qui permet :
- Afficher le menu (catégories + produits)
- Ajouter au panier, passer une commande
- Payer avec Wave ou avec des points de fidélité (si activé et si le solde est suffisant)
- Commander “à emporter” (le client peut ne pas être sur place, puis venir récupérer)

Sans casser la logique actuelle “caisse” (app Flutter existante + flux sur place).

## Ce qui existe déjà dans ce repo (très important)
- Backend Laravel déjà en place avec API :
  - Menu public : `GET /api/categories`, `GET /api/produits`
  - Commandes : `POST /api/commandes` + gestion des statuts
  - Paiements : `POST /api/paiements` avec `wave`, `orange_money`, `points_fidelite`
  - Fidélité : `FidelitySetting`, `FidelityService`, `points_utilises` côté paiements
- Une app Flutter “caisse” existante : `resto_caisse_app/`
- Un build Flutter web déjà déployé dans `public/client/` mais sans les sources Flutter dans le repo
- Une charte couleur déjà définie côté Flutter caisse : primaire `#191F76`

Conclusion : on ne réinvente pas la caisse. On ajoute une “app client” qui consomme la même API Laravel.

## Comment ne pas casser la logique caisse (stratégie)
On sépare clairement les deux mondes :

### 1) App Caisse (inchangée)
- Continue de gérer les commandes “sur place”
- Continue d’encaisser côté staff
- Continue de générer factures, sessions de caisse, etc.

### 2) App Client (nouvelle)
- Crée des commandes “à emporter”
- Le staff voit ces commandes dans le back-office / caisse comme les autres
- Le client peut payer en avance (Wave / points) ou payer plus tard à la récupération (option)

Le point clé est de représenter “à emporter” côté base/API sans casser “sur place”.

## Modélisation recommandée : Commande Sur Place vs À Emporter

### Option A (minimaliste) : `table_id = NULL` ⇒ commande “à emporter”
Avantages :
- Peu de changements
- Pas besoin de gérer une “fausse table”

Contraintes :
- Il faut rendre `commandes.table_id` nullable
- Il faut sécuriser tous les endroits où le code suppose qu’une commande a une table (facture, libération de table, UI web)

### Option B (plus propre) : ajouter un champ `mode` (sur_place / emporter)
Avantages :
- Lecture claire côté admin
- Évite les “null” sémantiques

Contraintes :
- Une migration en plus + modifications d’affichage

Dans la première itération, l’Option A suffit pour aller vite et sans casser.

## Flux “à emporter” (commande distante)

### Étape 1 — Le client consulte le menu (sans se connecter)
- Les endpoints menu sont publics : affichage rapide

### Étape 2 — Le client se connecte / crée un compte
Pourquoi ?
- Pour rattacher la commande à un user “client”
- Pour la fidélité (points, historique)

### Étape 3 — Panier → “Commander”
La requête “créer commande à emporter” doit :
- Créer une commande avec `table_id = NULL`
- `user_id = client_user_id`
- `client_id = user.client_id` si existe
- `serveur_id = NULL`
- Produits attachés comme actuellement

### Étape 4 — Paiement (3 cas)

#### Cas A : Payer avec points fidélité
L’app :
- Demande le nombre de points à utiliser
- Appelle `POST /api/paiements` avec :
  - `commande_id`
  - `moyen_paiement = points_fidelite`
  - `points_utilises = X`
Le backend :
- Vérifie setting fidélité + solde points
- Débite les points
- Si la commande est totalement réglée : facture + statut `terminee`

#### Cas B : Payer avec Wave
Le backend actuel met le paiement en `en_attente` côté client.
Dans l’app :
- On lance Wave (ou on affiche les instructions)
- L’utilisateur saisit/colle l’ID de transaction
- On appelle `POST /api/paiements/{id}/confirmer` avec `transaction_id`
Ensuite :
- Le manager/caissier valide (endpoint `PATCH /api/paiements/{id}/valider`)
- La commande passe `terminee` et une facture est générée

#### Cas C : Payer à la récupération (plus tard)
On crée juste la commande “à emporter” sans paiement.
Quand le client vient, la caisse encaisse normalement.

## UX (très jolie / moderne)
Idées d’interface (sans changer la couleur existante) :
- Home : header avec logo + recherche + catégories en chips
- Liste produits : cards avec image, prix, bouton “+”
- Panier : bottom sheet moderne + total + “Commander”
- Checkout : sélection paiement (Wave / Points / Payer sur place)
- Mes commandes : statut + détails + bouton “Payer” si pas payé

Couleurs :
- Reprendre exactement la palette Flutter caisse (`#191F76` en primary)

## Roadmap “Boutique (achats) plus tard”
On prépare la structure en onglets :
- Menu
- Mes commandes
- Profil
- Boutique (désactivé/placeholder, à activer plus tard)

## Livrable technique prévu dans le repo
- Nouveau projet Flutter : `resto_client_app/` à la racine
- Ajustements backend minimaux pour supporter commandes “à emporter”

