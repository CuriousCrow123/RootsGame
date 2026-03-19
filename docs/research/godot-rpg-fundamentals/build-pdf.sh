#!/bin/bash
# Build the Godot RPG Fundamentals PDF from markdown source
# Requirements: pandoc (3.x+), typst
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

pandoc "$ROOT_DIR/docs/research/godot-rpg-fundamentals.md" \
  --pdf-engine=typst \
  --template="$SCRIPT_DIR/template.typst" \
  --toc --toc-depth=2 \
  -f markdown-citations \
  --metadata title="Godot Fundamentals for a Larger Top-Down RPG" \
  --metadata subtitle="Comprehensive Research Report" \
  --metadata date="March 18, 2026" \
  -V fontsize=10.5pt \
  -V mainfont="Helvetica Neue" \
  -V codefont="Menlo" \
  -o "$SCRIPT_DIR/godot-rpg-fundamentals.pdf"

echo "✓ PDF generated: $SCRIPT_DIR/godot-rpg-fundamentals.pdf"
