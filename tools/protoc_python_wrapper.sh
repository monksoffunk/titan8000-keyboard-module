#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_PYTHON="${ROOT_DIR}/.venv/bin/python3"
NANOPB_PROTOC="${ROOT_DIR}/modules/lib/nanopb/generator/protoc"

if [ ! -x "${VENV_PYTHON}" ]; then
  echo "error: ${VENV_PYTHON} is not executable. Run 'make setup' first." >&2
  exit 1
fi

if [ ! -f "${NANOPB_PROTOC}" ]; then
  echo "error: ${NANOPB_PROTOC} was not found. Run 'make setup' first." >&2
  exit 1
fi

exec "${VENV_PYTHON}" "${NANOPB_PROTOC}" "$@"
