#!/bin/bash

set -euo pipefail

# Start the canonical launch script so that both entrypoints stay in sync
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec "$SCRIPT_DIR/launch_server.sh"
