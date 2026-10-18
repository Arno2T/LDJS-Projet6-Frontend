# Olympic Participation Tracker

Application React pour visualiser les donnees de participation aux Jeux Olympiques, construite avec React 19, TypeScript, Vite et Tailwind CSS.

## Tech Stack

- **Framework :** React 19 + TypeScript
- **Build :** Vite 6
- **Styling :** Tailwind CSS 3.4
- **Routing :** React Router v7 en mode Data Router
- **Tests :** Jest + React Testing Library

## Prerequis

- **Node.js** 22.x ou superieur
- **npm** 10.x ou superieur
- **Docker** avec Docker Compose v2 (pour lancer l'application en conteneur)

## Installation

```bash
git clone https://github.com/Arno2T/LDJS-Projet6-Frontend.git
cd LDJS-Projet6-Frontend
npm install
```

## Lancer l'application avec Docker

L'image est construite en deux etapes : build Vite avec Node, puis service des fichiers statiques par Nginx (utilisateur non root).

### Option 1 : construire l'image en local

```bash
docker compose up --build -d
```

L'application est accessible sur **http://localhost**.

```bash
docker compose logs -f   # suivre les logs
docker compose down      # arreter le conteneur
```

### Option 2 : utiliser l'image publiee sur GitHub Container Registry

La CI publie une image a chaque push sur `main`. Tags disponibles :

| Tag | Description |
|---|---|
| `latest` | Dernier build de `main` |
| `X.Y.Z` / `X.Y` | Version semantique produite par une release (ex : `1.0.0`) |
| `<branche>-<sha>` | Build d'un commit precis (ex : `main-569028a`) |

```bash
docker pull ghcr.io/arno2t/ldjs-projet6-frontend:latest
docker run -d --name olympic-front -p 80:80 ghcr.io/arno2t/ldjs-projet6-frontend:latest
```

L'application est accessible sur **http://localhost**. Pour l'arreter : `docker rm -f olympic-front`.

> Si le package est prive, authentifiez-vous d'abord avec un Personal Access Token (scope `read:packages`) :
> `echo <TOKEN> | docker login ghcr.io -u <utilisateur-github> --password-stdin`

> Le port `80` doit etre libre sur la machine. S'il est deja utilise, changez le port hote (ex : `-p 8081:80`, ou `"8081:80"` dans `docker-compose.yml`).

## Lancer l'application sans Docker

```bash
npm run dev
```

L'application est accessible sur **http://localhost:5173**.

## Versions et releases

Les versions sont gerees par [semantic-release](https://semantic-release.gitbook.io/) a partir des messages de commit, qui doivent respecter [Conventional Commits](https://www.conventionalcommits.org/fr/) :

| Type de commit | Effet sur la version |
|---|---|
| `fix: ...` | patch (`1.0.0` → `1.0.1`) |
| `feat: ...` | minor (`1.0.0` → `1.1.0`) |
| `feat!: ...` ou `BREAKING CHANGE:` dans le corps | major (`1.0.0` → `2.0.0`) |
| `chore:`, `ci:`, `docs:`, `test:`... | pas de nouvelle version |

Pour publier une version : onglet **Actions** > workflow **CI** > **Run workflow** sur la branche `main`. Le workflow lance les tests, cree la release GitHub (tag, notes, `CHANGELOG.md`, version dans `package.json`) puis publie l'image Docker taguee avec la version.

## Scripts disponibles

| Commande | Description |
|---|---|
| `npm run dev` | Serveur de developpement (port 5173) |
| `npm run build` | Verification TypeScript + build production (`dist/`) |
| `npm run preview` | Apercu du build de production |
| `npm test` | Lancer les tests |
| `npm run test:watch` | Tests en mode watch |
| `npm run test:coverage` | Tests avec rapport de couverture |

## Structure du projet

```
p6-dfsjs-frontend/
├── public/
│   └── mock/
│       └── olympic.json            # Donnees mock (5 pays, 3 participations chacun)
├── src/
│   ├── main.tsx                    # Point d'entree React 19
│   ├── App.tsx                     # Montage du RouterProvider
│   ├── router.tsx                  # Definition des routes et loaders
│   ├── index.css                   # Directives Tailwind CSS
│   ├── pages/
│   │   ├── Home.tsx                # Page d'accueil (liste des participations)
│   │   └── NotFound.tsx            # Page 404
│   ├── services/
│   │   └── olympicService.ts       # Service de donnees + loader de route
│   └── types/
│       └── olympic.ts              # Interfaces TypeScript (Olympic, Participation)
├── tests/
│   ├── polyfills.ts                # Polyfills pour React Router v7 dans jsdom
│   ├── setup.ts                    # Setup Jest (jest-dom)
│   └── components/
│       └── Home.test.tsx           # Tests du composant Home
├── index.html                      # Template HTML SPA
├── package.json
├── tsconfig.json                   # Configuration TypeScript stricte
├── vite.config.ts                  # Configuration Vite
├── jest.config.js                  # Configuration Jest
├── babel.config.json               # Presets Babel pour Jest (env, react, typescript)
├── tailwind.config.js              # Configuration Tailwind CSS
├── postcss.config.js               # Configuration PostCSS
└── CORRECTIONS.md                  # Journal des corrections appliquees
```

## Architecture

```
Pages (Composants UI)
    ↓ useLoaderData()
Router (Data Router + Loaders)
    ↓ loader()
Services (Fetch des donnees)
    ↓
Donnees (mock JSON)
```

Le projet utilise le **Data Router** de React Router v7. Les donnees sont chargees par un `loader` **avant** le rendu du composant, puis accessibles via `useLoaderData<T>()`.

### Routes

Les routes sont definies dans `src/router.tsx` :

| Route | Page | Loader |
|---|---|---|
| `/` | `Home` | `olympicLoader` (charge les donnees olympiques) |
| `*` | `NotFound` | - |

### Modele de donnees

```typescript
interface Olympic {
  id: number;
  country: string;
  participations: Participation[];
}

interface Participation {
  id: number;
  year: number;
  city: string;
  medalsCount: number;
  athleteCount: number;
}
```

### Donnees mock

5 pays avec 3 participations chacun (Londres 2012, Rio 2016, Tokyo 2020) :
France, United States, Germany, China, Great Britain.

## Tests

```bash
npm test
```

Les tests utilisent `createMemoryRouter` avec `hydrationData` pour injecter les donnees directement sans passer par le loader, ce qui evite les dependances aux Web APIs dans jsdom.

## License

MIT
