#!/usr/bin/env bash
# Spustí lokální server přibalený v appce (tak, jak ho spouští Electron)
# a počká, až odpoví. Použití: smoke.sh "<cesta k .app>" <timeout v s>
set -uo pipefail
APP="$1"; WAIT="${2:-90}"
BIN="$APP/Contents/MacOS/Asistent Produkce"
DATA="$(mktemp -d)"
PORT=$((4000 + RANDOM % 2000))
ELECTRON_RUN_AS_NODE=1 LOCAL_MODE=1 PB_DATA_DIR="$DATA" PORT=$PORT HOSTNAME=127.0.0.1 NODE_ENV=production \
  "$BIN" "$APP/Contents/Resources/standalone/server.js" > "$DATA/server.log" 2>&1 &
PID=$!
ok=0
for i in $(seq 1 "$WAIT"); do
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/projects" || true)
  [ "$code" = "200" ] && { ok=1; break; }
  kill -0 $PID 2>/dev/null || break
  sleep 1
done
curl -s "http://127.0.0.1:$PORT/api/projects" | head -c 200; echo
kill $PID 2>/dev/null; wait $PID 2>/dev/null
if [ $ok = 1 ]; then echo "OK: server v $(basename "$APP") naběhl ($i s)"; exit 0; fi
echo "::error::Server v $APP nenaběhl"; cat "$DATA/server.log"; exit 1
