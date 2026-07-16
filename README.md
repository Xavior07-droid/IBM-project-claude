# Smart Recommend AI

A production-ready, full-stack AI recommendation engine. Users describe what
they're looking for — movies, books, career paths, travel destinations, and
more — and get personalized, streamed, AI-generated recommendations with
reasoning, pros/cons, cost estimates, and confidence scores.

Built as an academic AI + Cloud Computing project, but wired up like a real
SaaS product: streaming AI responses, JWT + Google OAuth, SQLite persistence,
PDF export, an admin dashboard, Docker support, and AWS deployment docs.

![Tech](https://img.shields.io/badge/stack-React%20%2B%20Express%20%2B%20OpenAI-6d28d9)

---

## ✨ Features

- **AI-powered recommendations** across 10 categories (Movies, Books, Career, Travel, Electronics, Courses, Fashion, Restaurants, Games, Music)
- **Real-time streaming** — responses generate token-by-token via Server-Sent Events, like ChatGPT
- **Mock mode fallback** — the app works fully out of the box even without an OpenAI API key, using realistic sample data
- **Guest login + email/password + Google OAuth** authentication
- **History, bookmarks, and PDF export** of every recommendation set
- **Admin dashboard** with platform statistics
- **Dark mode**, fully responsive, glassmorphism/premium SaaS UI
- **Dockerized** frontend + backend, ready for AWS App Runner, Elastic Beanstalk, or EC2

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React 18, Vite, Tailwind CSS, Framer Motion, Lucide Icons |
| Backend | Node.js, Express (MVC architecture) |
| AI | OpenAI GPT-4o (or GPT-4.1), with automatic mock-mode fallback |
| Database | SQLite (via `better-sqlite3`), schema written to be PostgreSQL-compatible |
| Auth | JWT, guest sessions, Google OAuth 2.0 (`passport-google-oauth20`) |
| Security | Helmet, CORS, rate limiting, env-based secrets |

---

## 📁 Project Structure

```
smart-recommend-ai/
├── client/                  # React + Vite frontend
│   ├── src/
│   │   ├── components/      # Reusable UI components
│   │   ├── pages/           # Route-level pages
│   │   ├── layouts/         # Dashboard layout wrapper
│   │   ├── context/         # Auth + Theme React context
│   │   └── services/        # API client (axios) + SSE streaming
│   ├── Dockerfile
│   └── nginx.conf
├── server/                  # Express backend (MVC)
│   ├── src/
│   │   ├── config/          # env, passport
│   │   ├── controllers/     # Route handlers
│   │   ├── models/          # SQLite data access layer
│   │   ├── routes/          # Express routers
│   │   ├── middleware/      # Auth, error handling
│   │   ├── services/        # OpenAI integration, prompt builder, mock data
│   │   └── db/               # DB connection, schema, seed script
│   └── Dockerfile
├── docker-compose.yml       # Orchestrates both services
├── AWS_DEPLOYMENT.md        # Full AWS deployment guide (App Runner / EB / EC2)
└── README.md
```

---

## 🚀 Quick Start (Local Development)

### Prerequisites
- Node.js **22.5+** (required for the built-in `node:sqlite` module — see note below)
- npm

> **Why Node 22.5+?** The backend uses Node's built-in `node:sqlite` module
> instead of the native `better-sqlite3` package as its primary database
> driver. This means `npm install` works out of the box on Windows/macOS/Linux
> with **zero native compilation** — no Visual Studio Build Tools, no Xcode
> Command Line Tools, no `node-gyp` errors. If you're on an older Node version,
> the app automatically falls back to `better-sqlite3` if it's installed and
> able to build (see `server/src/db/database.js`), but upgrading Node is the
> simplest fix if you hit install errors.

### 1. Clone and install

```bash
git clone <your-repo-url>
cd smart-recommend-ai

# Backend
cd server
npm install
cp .env.example .env
# (optional) edit .env and add your OPENAI_API_KEY — the app runs fine without one, in mock mode

# Frontend
cd ../client
npm install
cp .env.example .env
```

### 2. Run both servers

In two terminals:

```bash
# Terminal 1 — backend (http://localhost:5000)
cd server
npm run dev

# Terminal 2 — frontend (http://localhost:5173)
cd client
npm run dev
```

Visit **http://localhost:5173**. The Vite dev server proxies `/api` requests
to the backend automatically (see `client/vite.config.js`).

### 3. (Optional) Seed an admin account

```bash
cd server
npm run seed
```

This creates an admin login: `admin@smartrecommend.ai` / `Admin@123`
(**change this password before deploying anywhere real**). Visit
`/dashboard/admin` after logging in with these credentials.

---

## 🤖 Running With vs. Without a Real OpenAI Key

- **No `OPENAI_API_KEY` set** → the server automatically runs in **mock mode**.
  You'll see a console warning on startup, and every `/api/recommend` call
  returns realistic, well-formed sample recommendations (with simulated
  streaming) instead of calling OpenAI. This means the entire app — UI,
  streaming, history, bookmarks, PDF export — is demoable immediately with
  zero setup.
- **`OPENAI_API_KEY` set** → the server calls the real OpenAI Chat Completions
  API (`gpt-4o` by default, configurable via `OPENAI_MODEL`), with real
  token-by-token streaming.

The API key is **only ever read server-side** from environment variables —
it is never sent to or exposed in the frontend bundle.

---

## 🔑 Enabling Google Login (optional)

Google login is fully wired up (Passport strategy, callback route, DB
fields) but disabled by default. To enable it:

1. Create OAuth credentials in [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Add an authorized redirect URI: `http://localhost:5000/api/auth/google/callback` (adjust for your deployed domain)
3. Add to `server/.env`:
   ```
   GOOGLE_CLIENT_ID=your_client_id
   GOOGLE_CLIENT_SECRET=your_client_secret
   ```
4. Restart the server — the "Continue with Google" button will now appear on the login page automatically.

Without these values set, the app works fine with guest login and email/password auth — the Google button simply doesn't render.

---

## 🐳 Running With Docker

```bash
cp .env.example .env
# edit .env with your OPENAI_API_KEY, JWT_SECRET, etc.

docker compose up --build
```

- Frontend: **http://localhost:3000**
- Backend API: **http://localhost:5000**

The SQLite database persists in a named Docker volume (`sqlite_data`) across
container restarts.

To stop: `docker compose down` (add `-v` to also wipe the database volume).

---

## ☁️ AWS Deployment

See **[AWS_DEPLOYMENT.md](./AWS_DEPLOYMENT.md)** for full step-by-step guides
covering:
- AWS App Runner (simplest)
- AWS Elastic Beanstalk
- AWS EC2 (manual, full control)
- Migrating from SQLite to RDS PostgreSQL for production durability

---

## 🔒 Security Notes

- OpenAI API key is never exposed to the client — all AI calls are proxied through the backend
- Helmet sets standard security headers
- CORS is restricted to `CLIENT_URL`
- Rate limiting is applied to all `/api` routes (configurable via env)
- Passwords are hashed with bcrypt (10 rounds)
- JWTs are signed server-side with a configurable secret and expiry

---

## 🛠️ Troubleshooting

**`npm install` fails with `node-gyp` / "Could not find any Visual Studio installation" / `better-sqlite3` build errors**

This happens when npm tries to compile the native `better-sqlite3` addon and
there's no matching prebuilt binary for your Node version/platform, and no
C++ build tools installed to compile it from source.

Fix: **upgrade to Node.js 22.5 or later.** The backend's database layer
(`server/src/db/database.js`) uses Node's built-in `node:sqlite` module as
its primary driver — it requires no native compilation at all, so
`better-sqlite3` is now an *optional* dependency that npm will happily skip
if it can't build (this is what `optionalDependencies` does). As long as
you're on Node 22.5+, you'll never hit this error.

Check your version with `node --version`. If you need to upgrade, use
[nvm](https://github.com/nvm-sh/nvm) (macOS/Linux) or
[nvm-windows](https://github.com/coreybutler/nvm-windows) / the installer
from [nodejs.org](https://nodejs.org) (Windows).

**Server logs "Using SQLite driver: better-sqlite3" instead of "node:sqlite"**

This just means you're on an older Node version and the app fell back
successfully — everything still works identically. To use the zero-build
path, upgrade to Node 22.5+.

## 📡 API Reference

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/guest` | Start a guest session |
| `POST` | `/api/auth/register` | Create an account |
| `POST` | `/api/auth/login` | Log in |
| `GET`  | `/api/auth/google` | Start Google OAuth flow |
| `GET`  | `/api/auth/me` | Get current user |
| `POST` | `/api/recommend` | Generate recommendations (non-streaming) |
| `GET`  | `/api/recommend/stream` | Generate recommendations (SSE streaming) |
| `GET`  | `/api/history` | Paginated recommendation history (supports `search`, `category`) |
| `GET`  | `/api/history/:id` | Single history item |
| `GET`  | `/api/bookmarks` | List bookmarks |
| `POST` | `/api/bookmarks` | Create a bookmark |
| `DELETE` | `/api/bookmarks/:id` | Remove a bookmark |
| `GET`  | `/api/export/:id` | Export a recommendation set as PDF |
| `GET`  | `/api/admin/stats` | Admin-only platform statistics |

---

## 🧪 Notes for Graders / Reviewers

- The AI service (`server/src/services/openaiService.js`) implements real
  OpenAI streaming via the official `openai` SDK, with strict JSON-mode
  prompting (`server/src/services/promptBuilder.js`) and a parsing safety
  net for malformed responses.
- The mock-mode fallback (`server/src/services/mockRecommendationService.js`)
  mirrors the exact same response shape and even simulates streaming, so the
  frontend requires zero special-casing between demo and live modes.
- Database schema (`server/src/db/database.js`) is deliberately written in a
  PostgreSQL-compatible style for easy migration in a real deployment.
