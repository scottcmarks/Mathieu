#!/bin/bash
# Serve the interactive 3D viewer and open it in your browser.
# (Browsers block STL fetches from file:// URLs, so we serve over localhost.)
# Ctrl-C to stop the server when you're done.
set -euo pipefail
cd "$(dirname "$0")"
PORT="${1:-8731}"
LAN=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
echo "M12 toy viewer:"
echo "  this Mac : http://localhost:$PORT/"
[ -n "$LAN" ] && echo "  on phone : http://$LAN:$PORT/   (same Wi-Fi)"
echo "(Ctrl-C to stop)"
( sleep 1; open "http://localhost:$PORT/" ) &
exec python3 -m http.server "$PORT"   # binds 0.0.0.0 -> reachable on the LAN
