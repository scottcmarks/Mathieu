#!/bin/bash
# Serve the interactive 3D viewer and open it in your browser.
# (Browsers block STL fetches from file:// URLs, so we serve over localhost.)
# Ctrl-C to stop the server when you're done.
set -euo pipefail
cd "$(dirname "$0")"
PORT="${1:-8731}"
echo "Serving M12 toy viewer at http://localhost:$PORT/  (Ctrl-C to stop)"
( sleep 1; open "http://localhost:$PORT/" ) &
exec python3 -m http.server "$PORT"
