#!/bin/zsh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SECFONTS="$SCRIPT_DIR/secfonts"
MERGE_PY="$SCRIPT_DIR/merge_fonts.py"

DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true

echo "=== Android Studio Font Fix (macOS) ==="

# ----------------------------------------
# Locate layoutlib cache directories
# ----------------------------------------
get_cache_dirs() {
  local base="$HOME/Library/Caches"
  find "$base" -type d -path "*/AndroidStudio*/layoutlib/fonts" 2>/dev/null
}

# ----------------------------------------
# Fallback to app bundle (rarely needed)
# ----------------------------------------
get_app_bundle_dir() {
  local candidates=(
    "/Applications/Android Studio.app/Contents"
    "$HOME/Applications/Android Studio.app/Contents"
  )

  for c in "${candidates[@]}"; do
    if [[ -d "$c/plugins/design-tools/resources/layoutlib/data/fonts" ]]; then
      echo "$c/plugins/design-tools/resources/layoutlib/data/fonts"
    fi
  done
}

# ----------------------------------------
# Copy fonts
# ----------------------------------------
copy_fonts() {
  local src="$1"
  local dest="$2"

  if $DRY_RUN; then
    echo "[DRY RUN] Copy fonts → $dest"
  else
    rsync -av --ignore-existing "$src/" "$dest/"
  fi
}

# ----------------------------------------
# Merge XML safely
# ----------------------------------------
merge_xml() {
  local target="$1"
  local patch="$2"

  if [[ ! -f "$target" ]]; then
    echo "⚠ Missing $target"
    return
  fi

  if $DRY_RUN; then
    echo "[DRY RUN] Merge XML → $target"
  else
    python3 "$MERGE_PY" "$target" "$patch"
  fi
}

# ----------------------------------------
# Apply fix to one directory
# ----------------------------------------
process_dir() {
  local fonts_dir="$1"
  local backup_dir="$fonts_dir"_backup

  echo ""
  echo "→ Processing: $fonts_dir"

  if [[ ! -d "$fonts_dir" ]]; then
    echo "❌ Not found"
    return
  fi

  # Backup
  if [[ ! -d "$backup_dir" ]]; then
    echo "Creating backup..."
    $DRY_RUN || cp -R "$fonts_dir" "$backup_dir"
  else
    echo "Backup exists"
  fi

  # Copy fonts
  copy_fonts "$SECFONTS" "$fonts_dir"

  # Merge XML
  merge_xml "$fonts_dir/fonts.xml" "$SECFONTS/fonts.xml"
  merge_xml "$fonts_dir/font_fallback.xml" "$SECFONTS/fonts.xml"

  echo "✔ Done"
}

# ----------------------------------------
# Restore
# ----------------------------------------
restore() {
  local dirs=$(get_cache_dirs)

  for d in $dirs; do
    local backup="${d}_backup"

    echo ""
    echo "→ Restoring: $d"

    if [[ -d "$backup" ]]; then
      if $DRY_RUN; then
        echo "[DRY RUN] Restore $d"
      else
        rm -rf "$d"
        mv "$backup" "$d"
      fi
      echo "✔ Restored"
    else
      echo "⚠ No backup found"
    fi
  done
}

# ----------------------------------------
# MAIN MENU
# ----------------------------------------
while true; do
  echo ""
  echo "1. Apply Font Fix"
  echo "2. Restore Fonts"
  echo "3. Exit"
  read "CHOICE?Select: "

  case $CHOICE in
    1)
      dirs=$(get_cache_dirs)

      if [[ -z "$dirs" ]]; then
        echo "⚠ No cache found."
        echo "👉 Open Layout Preview in Android Studio once, then retry."

        fallback=$(get_app_bundle_dir)
        if [[ -n "$fallback" ]]; then
          echo "Using fallback: $fallback"
          process_dir "$fallback"
        fi
      else
        for d in $dirs; do
          process_dir "$d"
        done
      fi
      ;;
    2)
      restore
      ;;
    3)
      exit 0
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done