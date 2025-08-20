#!/usr/bin/env bash
# Pull models listed in /app/models.txt, then create new local models with
# adjusted context windows (num_ctx) by creating a small Modelfile and
# running `ollama create`.

set -u
MODELS_FILE=/app/models.txt

if [ ! -f "$MODELS_FILE" ]; then
  echo "models file not found: $MODELS_FILE"
  exit 1
fi

sanitize_tag() {
  # replace slashes/spaces with - for tempfile/name safety
  echo "$1" | sed 's#[/ ]#-#g'
}

while IFS= read -r line || [ -n "$line" ]; do
  # strip CR, whitespace
  model=$(echo "$line" | tr -d '\r' | sed 's/^\s*//;s/\s*$//')
  # skip empty or commented lines
  [ -z "$model" ] && continue
  case "$model" in
    \#*) continue ;;
  esac

  echo "\nProcessing model: $model"

  # determine context mapping and suffix
  lower=$(echo "$model" | awk -F: '{print tolower($1)}')
  ctx=4096
  suffix=""
  if [[ "$lower" == mistral* ]]; then
    ctx=32768
    suffix="-32k"
  elif [[ "$lower" == deepseek* ]]; then
    ctx=131072
    suffix="-128k"
  elif [[ "$lower" == llama* ]]; then
    ctx=131072
    suffix="-128k"
  elif [[ "$lower" == gpt* ]]; then
    ctx=131072
    suffix="-128k"
  else
    ctx=4096
    suffix=""
  fi

  # split name:tag (if no tag, treat tag as latest)
  if [[ "$model" == *":"* ]]; then
    name=${model%%:*}
    tag=${model#*:}
  else
    name=$model
    tag=latest
  fi

  # if tag already contains our suffix, skip
  if [[ -n "$suffix" && "$tag" == *"$suffix" ]]; then
    echo " - Already has suffix $suffix, skipping reexport for $model"
    continue
  fi

  new_tag="${tag}${suffix}"
  # use hyphen-separated id to avoid colon/tag semantics and make names filesystem-friendly
  new_id="${name}-${new_tag}"

  echo " - target context: $ctx tokens -> new id: $new_id"

  # pull original model (if not present, this fetches it)
  echo " - pulling $model"
  if ! ollama pull "$model"; then
    echo "   failed to pull $model, skipping"
    continue
  fi

  # build a Modelfile to set num_ctx
  safe=$(sanitize_tag "${name}_${new_tag}")
  modelfile="/tmp/Modelfile-${safe}"
  cat > "$modelfile" <<EOF
FROM $model
# set context window
PARAMETER num_ctx $ctx
EOF

  echo " - creating $new_id from $model with num_ctx=$ctx"
  # if new_id already exists, remove it so we re-create with new Modelfile
  if ollama show "$new_id" >/dev/null 2>&1; then
    echo "   $new_id already exists — removing before recreate"
    if ! ollama rm "$new_id"; then
      echo "   failed to remove existing $new_id, skipping"
      rm -f "$modelfile"
      continue
    fi
  fi

  if ! ollama create "$new_id" -f "$modelfile"; then
    echo "   create failed for $new_id"
  else
    echo "   created $new_id"
  fi

  # cleanup
  rm -f "$modelfile"

done < "$MODELS_FILE"

echo "\nAll done."
