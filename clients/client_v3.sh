 #!/usr/bin/env bash
# This version splits history into summary and recent convo 
# Not sure about this direction, may discard it
# Also Included a way for multi line input. Ctrl+D is for enter now 
GREEN="\033[1;32m"   # bright green
YELLOW="\033[1;33m"
RESET="\033[0m"
SERVER_URL="http://localhost:8080/v1/chat/completions" # Ministral-3-8B-Instruct-2512-Q4_K_M
SUMMARY_URL="http://localhost:8081/v1/chat/completions" # Llama-3.2-1B-Instruct-Q4_K_M
CTX_LIMIT_CHARS=3000
TRIM_CHARS=2500
MAX_SAFE_BYTES=12000
MAX_RESPONSE_TOKENS=2048

SUMMARY_FILE="memory_summary.md"
RECENT_FILE="recent_context.md"
MAX_RECENT_BYTES=4000
touch "$SUMMARY_FILE"
touch "$SUMMARY_FILE" "$RECENT_FILE"


# Ask for confirmation
read -r -p "Clear previous chat conversation [y/N]: " confirmation

# Check if input is y or Y
if [[ "$confirmation" =~ ^[Yy]$ ]]; then
    > "$SUMMARY_FILE"
    > "$RECENT_FILE"
    echo -e "${YELLOW}[System] History cleared.${RESET}"
else
    echo -e "${YELLOW}[System] Continuing with previous memory.${RESET}"
fi

if [ ! -s "$HIST_FILE" ]; then
  echo "System: You are a helpful, concise assistant." > "$RECENT_FILE"
fi

summarize_recent_into_history() {
    echo -e "${YELLOW}[System] [Compressing Memory...]${RESET}"

    OLD_SUMMARY=$(cat "$SUMMARY_FILE")
    RECENT_CONVO=$(cat "$RECENT_FILE")
    # 1. Capture the RAW output from the server so we can see errors
    RAW_RESPONSE=$(curl -s "$SUMMARY_URL" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
      --connect-timeout 5 \
      --max-time 300 \
      --arg prompt "Update the existing system summary using the new conversation below.
                     Preserve all important facts, decisions, goals, and preferences.
                     === Existing Summary ===
                     $OLD_SUMMARY
                     === New Conversation ===
                     $RECENT_CONVO" \
        '{
          messages: [{role: "user", content: $prompt}],
          temperature: 0.1,
          max_tokens: 1024
      }')")
    # 2. Try to extract the summary
    SUMMARY=$(echo "$RAW_RESPONSE" | jq -r '.choices[0].message.content')
    # 3. SAFETY GUARD: Check if it failed
    if [ "$SUMMARY" == "null" ] || [ -z "$SUMMARY" ]; then
        echo -e "\n${YELLOW}[ERROR] Summary failed! Server response:${RESET}"
        # Print the raw error so you know what is wrong
        echo "$RAW_RESPONSE" | jq . 
        return  # EXIT FUNCTION. Do NOT overwrite the file.
    fi
    # 4. Success! Overwrite history
    echo -e "System: [Context Summary]: $SUMMARY\n" > "$SUMMARY_FILE"
    > "$RECENT_FILE"
    echo -e "${YELLOW}[System] Summary complete! Resuming chat.${RESET}"
}

while true; do
  # Green prompt + green input
  printf "%b" "${GREEN}Enter message (Ctrl+D to send):"
  USER=$(cat)
  printf "%b\n" "${RESET}"
  # Append user input
  printf "User: %s\nAssistant:" "$USER" >> "$RECENT_FILE"
 
  # Send request
  # Stop if less than 10 bytes/sec for 120 seconds
  RESPONSE=$(
    curl -N -s "$SERVER_URL" \
      -H "Content-Type: application/json" \
      --connect-timeout 5 \
      --speed-limit 10 --speed-time 120 \
      -d "$(jq -n \
      --arg prompt "$(cat "$SUMMARY_FILE");echo;$(cat "$RECENT_FILE")" \
        --argjson max_tokens "$MAX_RESPONSE_TOKENS" \
        '{
          messages: [
            { role: "user", content: $prompt }
          ],
          max_tokens: $max_tokens,
          temperature: 0.7,
          top_p: 0.9,
          stream: true,
          stop: ["User:", "\nUser:", "\\nUser:","<|im_end|>"] 
        }'
      )" | \
    sed -u '/^data: \[DONE\]/d; s/^data: //' | \
    jq -j --unbuffered -r '.choices[0].delta.content // empty' | \
    tee /dev/tty
  )
  if [ -z "$RESPONSE" ]; then
    echo -e "${YELLOW}[System] Empty response, skipping history update.${RESET}"
    continue
  fi
  echo 
  echo "    ============================="
  printf "%s\n" "$RESPONSE" | glow
  echo
  printf " %s\n" "$RESPONSE" >> "$RECENT_FILE"
  #summarize_entire_history 
  RECENT_SIZE=$(wc -c < "$RECENT_FILE")
  if (( RECENT_SIZE > MAX_RECENT_BYTES )); then
      summarize_recent_into_summary
  fi
done
