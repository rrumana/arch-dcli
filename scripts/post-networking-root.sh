#!/usr/bin/env bash
set -euo pipefail

if command -v systemctl &>/dev/null; then
  if systemctl list-unit-files | grep -q '^NetworkManager\.service'; then
    systemctl enable --now NetworkManager >/dev/null 2>&1 || true
  fi
  if systemctl list-unit-files | grep -q '^bluetooth\.service'; then
    systemctl enable --now bluetooth >/dev/null 2>&1 || true
  fi
fi
