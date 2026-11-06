# Running YaminiJobApp on your computer

YaminiJobApp is a customized copy of [Dossier](https://github.com/AienTech/dossier). This setup keeps everything on your machine: the data in one SQLite file in `./data`, and the AI through [Ollama](https://ollama.com).

## Requirements

- **Node.js 24.7 or newer** (https://nodejs.org, the 24 LTS). Older versions won't work: the app uses Node's built-in argon2 password hashing, added in 24.7.
- **Ollama** (https://ollama.com), for the free local AI. Optional: you can pick a hosted AI (OpenAI, Anthropic, Mistral) in Settings → AI provider instead.
- macOS or Linux, or Windows with WSL or Git Bash, to run the setup script.

## First time

```bash
git clone https://github.com/ngaride/jobapp.git
cd jobapp
yarn setup        # or: scripts/setup-local.sh
```

The script asks for the password you'll sign in with, then writes `.env`, installs the dependencies, creates the database and downloads the AI model (`llama3.1:8b`, a few GB). To use another model, run `YAMINI_MODEL=qwen2.5:7b yarn setup` or change it later in Settings → AI provider.

If `yarn` isn't found yet, run `corepack enable` first (it comes with Node.js), or run `scripts/setup-local.sh` directly.

## Every day

```bash
yarn dev
```

Open http://localhost:3000 and sign in. Keep Ollama running in the background for the AI features.

## Good to know

- **Your data** is in `data/yaminijobapp.db`, with nightly backups next to it. Both `data/` and `.env` stay out of git.
- **Forgot your password?** Run `yarn hash-password`, put the new line in `.env` as `DOSSIER_PASSWORD=...`, and restart.
- **Settings** still use the upstream `DOSSIER_*` names in `.env`; `.env.example` explains every one.
- **Updates from upstream:** `git remote add upstream https://github.com/AienTech/dossier.git`, then `git fetch upstream` and merge `upstream/main`. After pulling changes, run `yarn setup` again to install and migrate.
