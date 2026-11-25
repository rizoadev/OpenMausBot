#!/usr/bin/env bash
# Start OpenMausBot harness + web app for Live calls (Gemini Live provider).
# Gemini key is read from ~/.openmausbot/config.json (tts.geminiKey) - no env needed.
set -euo pipefail
cd "$(dirname "$0")"

cleanup() { kill "${SRV:-}" "${APP:-}" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

echo "→ harness  : http://127.0.0.1:8799"
pnpm dev:server > /tmp/omb-server.log 2>&1 & SRV=$!
sleep 8
echo "→ app       : http://127.0.0.1:5199"
pnpm dev > /tmp/omb-app.log 2>&1 & APP=$!

sleep 6
curl -sf -o /dev/null http://127.0.0.1:8799/api/config && echo "✔ harness up" || { echo "✘ harness failed"; tail -20 /tmp/omb-server.log; exit 1; }
curl -sf -o /dev/null http://127.0.0.1:5199/ && echo "✔ app up" || echo "✘ app failed"
curl -s http://127.0.0.1:8799/api/config | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const l=JSON.parse(s).live;console.log("✔ live provider:",l.provider,"| configured:",l.configured,"| voice:",l.geminiVoice);})'
echo
echo "Buka http://127.0.0.1:5199 → pilih bot → tombol Call (mode Live)."
echo "Ctrl-C untuk stop."
wait
