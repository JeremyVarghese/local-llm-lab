 #!/usr/bin/env bash

GREEN="\033[1;32m"   # bright green
YELLOW="\033[1;33m"
RESET="\033[0m"
SERVER_URL="http://localhost:8080/v1/chat/completions" # Ministral-3-8B-Instruct-2512-Q4_K_M
SUMMARY_URL="http://localhost:8081/v1/chat/completions" # Llama-3.2-1B-Instruct-Q4_K_M
CTX_LIMIT_CHARS=3000
TRIM_CHARS=2500
MAX_SAFE_BYTES=12000
MAX_RESPONSE_TOKENS=2048

HIST_FILE="chat_history.md"
touch "$HIST_FILE"

# Ask for confirmation
read -r -p "Clear previous chat conversation [y/N]: " confirmation

# Check if input is y or Y
if [[ "$confirmation" =~ ^[Yy]$ ]]; then
    > "$HIST_FILE"
    echo -e "${YELLOW}[System] History cleared.${RESET}"
else
    echo -e "${YELLOW}[System] Continuing with previous history.${RESET}"
fi

summarize_entire_history() {
    echo -e "${YELLOW}[System] [Compressing Memory...]${RESET}"

    FULL_CONVO=$(cat "$HIST_FILE")
    # 1. Capture the RAW output from the server so we can see errors
    RAW_RESPONSE=$(curl -s "$SUMMARY_URL" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg prompt "Summarize this conversation log concisely, keeping all key details:\n\n$FULL_CONVO" \
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
    echo -e "System: [Context Summary]: $SUMMARY\n" > "$HIST_FILE"
    echo -e "${YELLOW}[System] Summary complete! Resuming chat.${RESET}"
}

while true; do
  # Green prompt + green input
  printf "%b" "${GREEN}You: "
  read -r USER || break
  printf "%b\n" "${RESET}"
  # Append user input
  printf "User: %s\nAssistant:" "$USER" >> "$HIST_FILE"
 
  # Send request
  RESPONSE=$(
    curl -N -s "$SERVER_URL" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
      --arg prompt "$(cat "$HIST_FILE")" \
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
  echo 
  echo "    ============================="
  printf "%s\n" "$RESPONSE" | glow
  echo
  printf " %s\n" "$RESPONSE" >> "$HIST_FILE"
  # Check file size BEFORE asking user for input
  # BLOCKING CALL: The script waits here until finished
  summarize_entire_history 
done
