# Déployer l’app client Flutter sous /client sur ton serveur

## 1. Comportement

- **Sur le web** : l’app utilise automatiquement le **même domaine** que la page.
  - Si l’app est servie depuis `https://ton-domaine.com/client/`, les appels API partent vers `https://ton-domaine.com/api`.
- **Sur mobile** : l’app continue d’utiliser l’URL configurée (ex. `http://restaurant.universaltechnologiesafrica.com/api`).

Aucune configuration manuelle par environnement : une seule build, ça s’adapte au domaine.

## 2. Build pour ton serveur

Dans le dossier `resto-app` :

```bash
cd resto-app
./build_web_client.sh
```

Ou à la main :

```bash
flutter build web --base-href /client/ --release
```

Les fichiers à déployer sont dans **`resto-app/build/web/`**.

## 3. Déploiement sur ton projet web

- Copie **tout le contenu** de `resto-app/build/web/` vers le dossier qui sert l’app client sur ton serveur.
- Exemple classique avec Laravel : copier dans **`public/client/`** (ou le répertoire que tu as prévu pour le client).

Structure typique :

```
ton-projet-web/
  public/
    client/          ← contenu de build/web/ (index.html, main.dart.js, etc.)
    ...
```

L’app sera alors accessible à : **`https://ton-domaine.com/client/`**  
Les appels API iront vers : **`https://ton-domaine.com/api`** (même domaine, pas de souci CORS si ton API est sur ce domaine).

## 4. Côté serveur (Laravel / API)

- L’API doit être exposée sous **`/api`** (ou configurer CORS si domaine différent).
- En production, servir le site en **HTTPS** pour éviter les erreurs de sécurité dans le navigateur.
