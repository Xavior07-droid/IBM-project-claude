# AWS Deployment Guide — Smart Recommend AI

This guide covers three deployment paths, from simplest to most hands-on.
Pick the one that matches your grading rubric / infrastructure comfort level.

---

## Option 1: AWS App Runner (simplest, recommended for coursework)

App Runner builds and runs containers directly from a Dockerfile with almost
no infrastructure management.

### Backend (API)
1. Push this repo to GitHub (or ECR if you prefer container-based deploys).
2. In the AWS Console, go to **App Runner → Create service**.
3. Source: **Source code repository** → connect GitHub → select this repo.
4. Deployment settings: point the build to `server/Dockerfile` (set "Source directory" to `server/` if prompted, or use the root `Dockerfile` which builds the backend only).
5. Port: `5000`.
6. Add environment variables (Configuration → Environment variables):
   ```
   NODE_ENV=production
   OPENAI_API_KEY=<your key, or leave blank for mock mode>
   OPENAI_MODEL=gpt-4o
   JWT_SECRET=<long random string>
   SESSION_SECRET=<long random string>
   CLIENT_URL=<your frontend URL, e.g. https://your-app.vercel.app>
   GOOGLE_CLIENT_ID=<optional>
   GOOGLE_CLIENT_SECRET=<optional>
   GOOGLE_CALLBACK_URL=https://<your-app-runner-url>/api/auth/google/callback
   ```
7. Deploy. App Runner gives you a public HTTPS URL automatically.

> **Note on SQLite + App Runner:** App Runner's filesystem is ephemeral —
> data doesn't persist across deploys/restarts. For a coursework demo this is
> fine. For anything longer-lived, either (a) mount an EFS volume via App
> Runner's VPC connector, or (b) switch `DATABASE_PATH` to a managed
> PostgreSQL instance (RDS) — the schema in `server/src/db/database.js` was
> written to be PostgreSQL-compatible with minimal changes (see below).

### Frontend
Simplest path: deploy the `client/` folder to **AWS Amplify Hosting** (or
Vercel/Netlify, which are equally valid for a Vite SPA) — point it at the
`client/` directory, build command `npm run build`, output directory `dist`.
Set `VITE_API_URL` (or rely on the Amplify rewrite rules) to point at your
App Runner backend URL.

Alternatively, run `client/Dockerfile` as a second App Runner service — it
serves the built SPA via nginx.

---

## Option 2: AWS Elastic Beanstalk

Elastic Beanstalk is a good fit if your course specifically asks for EB.

1. Install the EB CLI: `pip install awsebcli`
2. From the `server/` directory:
   ```bash
   cd server
   eb init -p docker smart-recommend-ai --region us-east-1
   eb create smart-recommend-env
   ```
3. Set environment variables:
   ```bash
   eb setenv NODE_ENV=production OPENAI_API_KEY=your_key JWT_SECRET=your_secret \
     SESSION_SECRET=your_secret CLIENT_URL=https://your-frontend-url.com
   ```
4. Deploy: `eb deploy`
5. Your API is now live at the EB-provided URL (`eb open` to view it).

For the frontend, either host it separately (Amplify/S3+CloudFront) or add
a second EB environment using `client/Dockerfile`.

---

## Option 3: AWS EC2 (full manual control)

1. Launch an EC2 instance (Ubuntu 22.04 LTS, t3.small or larger recommended).
2. SSH in and install Docker + Docker Compose:
   ```bash
   sudo apt update && sudo apt install -y docker.io docker-compose-plugin
   sudo usermod -aG docker $USER && newgrp docker
   ```
3. Clone your repo and configure environment variables:
   ```bash
   git clone <your-repo-url>
   cd smart-recommend-ai
   cp .env.example .env
   nano .env   # fill in OPENAI_API_KEY, JWT_SECRET, etc.
   ```
4. Build and run:
   ```bash
   docker compose up -d --build
   ```
5. Open inbound ports `3000` (frontend) and `5000` (backend) in your EC2
   security group, or better: put both behind an **Application Load Balancer**
   with an ACM SSL certificate and only expose port 443 publicly.
6. (Recommended) Attach an Elastic IP and point a Route 53 domain at it.
7. (Recommended) Mount an EBS volume for `/app/data` (the SQLite file) so
   data survives instance replacement, or migrate to RDS PostgreSQL for
   production durability.

---

## Migrating from SQLite to PostgreSQL (for production durability)

The schema in `server/src/db/database.js` avoids SQLite-only syntax
(dynamic typing shortcuts, `AUTOINCREMENT` reliance, etc.) specifically so
this migration is low-friction:

1. Provision an RDS PostgreSQL instance.
2. Swap `better-sqlite3` for `pg` in `server/package.json`.
3. Replace the `Database` connection in `database.js` with a `pg.Pool`,
   keeping the same table/column names — the `CREATE TABLE` statements
   translate almost directly (SQLite's `TEXT` → Postgres `TEXT`,
   `datetime('now')` → `NOW()`).
4. Update model files (`userModel.js`, `recommendationModel.js`,
   `bookmarkModel.js`) to use `pool.query()` with `$1, $2...` placeholders
   instead of `?`.
5. Set `DATABASE_URL` as the new connection env var.

---

## Environment Variables Reference

See `server/.env.example` for the full list with descriptions. The
essential ones for any deployment:

| Variable | Required | Notes |
|---|---|---|
| `OPENAI_API_KEY` | No | Leave blank to run in mock/demo mode |
| `JWT_SECRET` | Yes | Use a long random string in production |
| `SESSION_SECRET` | Yes | Use a long random string in production |
| `CLIENT_URL` | Yes | Must match your deployed frontend origin (CORS) |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | No | Omit to disable Google login |

---

## Post-Deployment Checklist

- [ ] Backend `/api/health` returns `{ "success": true, "status": "ok" }`
- [ ] `CLIENT_URL` on the backend matches the frontend's real deployed origin (CORS will fail otherwise)
- [ ] `OPENAI_API_KEY` set (or intentionally left blank for mock mode demo)
- [ ] `JWT_SECRET` / `SESSION_SECRET` are NOT the example defaults
- [ ] HTTPS is enforced (via ALB/CloudFront/App Runner's built-in TLS)
- [ ] If using Google login, `GOOGLE_CALLBACK_URL` matches what's registered in Google Cloud Console
