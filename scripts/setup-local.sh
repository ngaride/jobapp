#!/usr/bin/env bash
# Sets up YaminiJobApp to run on this computer with Node.js, an SQLite file
# and a local AI model through Ollama. Safe to run again: it keeps an existing
# .env and only installs, generates and migrates.
#
#   scripts/setup-local.sh
#   yarn dev          # then open http://localhost:3000
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
MODEL="${YAMINI_MODEL:-llama3.1:8b}"

say() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\n\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# --- Node.js 24+ (the app uses Node's built-in argon2) ----------------------
command -v node >/dev/null || die "Node.js isn't installed. Install Node.js 24 or newer from https://nodejs.org."
# crypto.argon2 arrived in Node.js 24.7.0; test for it rather than the version.
node -e 'process.exit(typeof require("node:crypto").argon2 === "function" ? 0 : 1)' \
  || die "Node.js $(node -v) is too old: YaminiJobApp needs 24.7 or newer. Install the latest Node.js 24 LTS from https://nodejs.org (or: nvm install 24), open a new terminal, and run this again."

say "Enabling Yarn through Corepack"
corepack enable || { npm install -g corepack && corepack enable; }

say "Installing dependencies"
yarn install --immutable

# --- .env -------------------------------------------------------------------
mkdir -p "$ROOT/data"
if [ -f .env ]; then
  say ".env already exists; leaving it as it is"
else
  say "Choose the password you'll sign in with"
  HASH="$(yarn hash-password)"
  SECRET="$(node -e 'process.stdout.write(require("crypto").randomBytes(32).toString("base64"))')"
  cat > .env <<EOF
# Made by scripts/setup-local.sh. See .env.example for every option.

# Sign-in password hash (make a new one with: yarn hash-password)
DOSSIER_PASSWORD=$HASH
# Signs sessions and encrypts stored API keys. Changing it signs you out.
DOSSIER_SECRET=$SECRET

# Data lives in one SQLite file in ./data, with backups next to it.
DATABASE_URL="file:$ROOT/data/yaminijobapp.db"
DOSSIER_DATA_DIR=$ROOT/data

# Local AI through Ollama (https://ollama.com). Change it any time in
# Settings → AI provider; values saved there override these.
DOSSIER_AI_PROVIDER=local
DOSSIER_AI_URL=http://localhost:11434
DOSSIER_AI_MODEL=$MODEL

# Local only: never send the usage ping.
DOSSIER_TELEMETRY=off
EOF
  say "Wrote .env"
fi

say "Generating the database client and creating the database"
yarn generate
yarn prisma migrate deploy
# Adds the built-in resume themes (does nothing when they are already there).
yarn prisma db seed

# --- Ollama -----------------------------------------------------------------
if command -v ollama >/dev/null; then
  say "Pulling the AI model $MODEL with Ollama (a few GB, once)"
  ollama pull "$MODEL" || echo "Couldn't pull $MODEL now. Start Ollama and run: ollama pull $MODEL"
else
  say "Ollama isn't installed"
  echo "Install it from https://ollama.com, then run: ollama pull $MODEL"
  echo "(Or pick a hosted AI later in Settings → AI provider.)"
fi

say "Done. Start the app with:  yarn dev   and open http://localhost:3000"
