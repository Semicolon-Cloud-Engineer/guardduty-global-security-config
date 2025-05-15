#!/bin/bash

# Configuration
WATCHED_FILES=(.env application.properties pom.xml config.js config.json config.yaml settings.py webpack.config.js vite.config.js)
LOG_FILE="config_change.log"
HASH_FILE=".file_hashes"

# Initialize the log file if not exists
if [ ! -f "$LOG_FILE" ]; then
  touch "$LOG_FILE"
fi

# Initialize the hash file if not exists
if [ ! -f "$HASH_FILE" ]; then
  touch "$HASH_FILE"
fi

# Calculate SHA256 hash of a file
calculate_hash() {
  local file_path="$1"
  if [ -f "$file_path" ]; then
    sha256sum "$file_path" | awk '{print $1}'
  else
    echo ""
  fi
}

# Load previous hashes into an associative array
declare -A previous_hashes
while read -r line; do
  file_path=$(echo "$line" | cut -d' ' -f1)
  file_hash=$(echo "$line" | cut -d' ' -f2)
  previous_hashes["$file_path"]="$file_hash"
done < "$HASH_FILE"

# Monitor files and log changes
declare -A current_hashes
for file_path in "${WATCHED_FILES[@]}"; do
  file_hash=$(calculate_hash "$file_path")
  current_hashes["$file_path"]="$file_hash"

  if [[ -n "${previous_hashes[$file_path]}" ]]; then
    if [[ "${previous_hashes[$file_path]}" != "$file_hash" ]]; then
      if [[ -n "$file_hash" ]]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - MODIFIED: $file_path" >> "$LOG_FILE"
      else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - REMOVED: $file_path" >> "$LOG_FILE"
      fi
    fi
  elif [[ -n "$file_hash" ]]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ADDED: $file_path" >> "$LOG_FILE"
  fi

done

# Save current hashes to the hash file
> "$HASH_FILE"
for file_path in "${!current_hashes[@]}"; do
  echo "$file_path ${current_hashes[$file_path]}" >> "$HASH_FILE"
done

# Git pre-push hook setup
HOOK_PATH=".git/hooks/pre-push"
echo "#!/bin/bash
bash $(pwd)/config_change_detector.sh" > "$HOOK_PATH"
chmod +x "$HOOK_PATH"
echo "Git pre-push hook has been set up successfully."
