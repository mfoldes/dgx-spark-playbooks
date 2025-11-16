#!/bin/bash

# Teardown script for txt2kg project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_DIR="$SCRIPT_DIR/deploy/compose"
STACK_MODE="both"
REMOVE_IMAGES=true
REMOVE_VOLUMES=true

usage() {
  cat <<'EOF'
Usage: ./stop.sh [OPTIONS]

Options:
  --minimal        Tear down only the minimal stack (docker-compose.yml)
  --complete       Tear down only the complete stack (docker-compose.complete.yml)
  --both           Tear down both stacks (default)
  --keep-images    Do not remove images built by Docker Compose
  --keep-volumes   Do not remove volumes created by Docker Compose
  --help, -h       Show this help message

This script stops running services, removes containers, networks, volumes,
and (by default) local images that were created by docker-compose when using
start.sh or start.sh --complete.
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --minimal)
      STACK_MODE="minimal"
      shift
      ;;
    --complete)
      STACK_MODE="complete"
      shift
      ;;
    --both)
      STACK_MODE="both"
      shift
      ;;
    --keep-images)
      REMOVE_IMAGES=false
      shift
      ;;
    --keep-volumes)
      REMOVE_VOLUMES=false
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run './stop.sh --help' for usage information" >&2
      exit 1
      ;;
  esac
done

if ! command -v docker &> /dev/null; then
  echo "Error: docker is not installed or not in PATH" >&2
  exit 1
fi

if command -v nvidia-smi &> /dev/null && ! nvidia-smi &> /dev/null; then
  echo "Warning: NVIDIA GPU not accessible. Proceeding with teardown anyway."
fi

if docker compose version &> /dev/null; then
  DOCKER_COMPOSE_CMD=(docker compose)
elif command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE_CMD=(docker-compose)
else
  echo "Error: Neither 'docker compose' nor 'docker-compose' is available" >&2
  exit 1
fi

# Ensure HF_TOKEN is defined so docker compose can parse docker-compose.complete.yml safely.
export HF_TOKEN="${HF_TOKEN:-placeholder-hf-token}"

teardown_stack() {
  local stack_name=$1
  local compose_file=$2

  if [[ ! -f "$compose_file" ]]; then
    echo "Skipping $stack_name stack: compose file not found at $compose_file"
    return
  fi

  echo ""
  echo "Stopping $stack_name stack defined in $(basename "$compose_file")..."

  local cmd=("${DOCKER_COMPOSE_CMD[@]}" -f "$compose_file" down --remove-orphans)
  if [[ "$REMOVE_VOLUMES" == true ]]; then
    cmd+=(--volumes)
  fi
  if [[ "$REMOVE_IMAGES" == true ]]; then
    cmd+=(--rmi local)
  fi

  if "${cmd[@]}"; then
    echo "Successfully tore down $stack_name stack."
  else
    echo "Warning: Failed to fully tear down $stack_name stack (it may not have been running)."
  fi
}

case $STACK_MODE in
  minimal)
    teardown_stack "minimal" "$COMPOSE_DIR/docker-compose.yml"
    ;;
  complete)
    teardown_stack "complete" "$COMPOSE_DIR/docker-compose.complete.yml"
    ;;
  both)
    teardown_stack "minimal" "$COMPOSE_DIR/docker-compose.yml"
    teardown_stack "complete" "$COMPOSE_DIR/docker-compose.complete.yml"
    ;;
  *)
    echo "Internal error: unknown STACK_MODE '$STACK_MODE'" >&2
    exit 1
    ;;
esac

echo ""
echo "=========================================="
echo "txt2kg services have been stopped and cleaned up."
echo "=========================================="
echo ""
