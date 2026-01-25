 #!/usr/bin/env bash

GREEN="\033[1;32m"   # bright green
RESET="\033[0m"
SERVER_URL="http://localhost:8080/v1/completions"
CTX_LIMIT_CHARS=3000
TRIM_CHARS=2500
MAX_RESPONSE_TOKENS=2048

HISTORY=""

while true; do
  # Green prompt + green input
  printf "%b" "${GREEN}You: "
  read -r USER || break
  printf "%b\n" "${RESET}"
  # Append user input
  HISTORY+="User: $USER\nAssistant:"
 
  # Trim history if it grows too large (hard safety)
  if (( ${#HISTORY} > CTX_LIMIT_CHARS )); then
    # Keep only the last ~4000 chars
    HISTORY="$(echo -e "$HISTORY" | tail -c TRIM_CHARS)"
  fi
 
  # Send request
  RESPONSE=$(
    curl -N -s "$SERVER_URL" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg prompt "$HISTORY" \
        --argjson max_tokens "$MAX_RESPONSE_TOKENS" \
        '{
          prompt: $prompt,
          max_tokens: $max_tokens,
          temperature: 0.7,
          top_p: 0.9,
          stream: true,
          stop: ["User:", "\nUser:", "\\nUser:"] 
        }'
      )" | \
    sed -u '/^data: \[DONE\]/d; s/^data: //' | \
    jq -j --unbuffered -r '.choices[0].text // empty' | \
    tee /dev/tty
  )
  echo 
  echo "    ============================="
  printf "%s\n" "$RESPONSE" | glow
  echo
  HISTORY+=" $RESPONSE\n"
  # HISTORY+="$ASSISTANT\n"
done
