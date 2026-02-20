#!/bin/bash
set -euo pipefail

git config --global --unset core.hooksPath || true

echo "Global git hooks path removed."
echo "Repositories will use their local hooks."
