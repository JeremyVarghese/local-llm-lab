#!/usr/bin/env/ bash

LLMS_ROOT="$HOME/llms"

Ministral3() {
  "$LLMS_ROOT/llama.cpp/build/bin/llama-server" \
    -m "$LLMS_ROOT/models/Ministral-3-8B-Instruct-2512-Q4_K_M.gguf" \
    --ctx-size 8192 \
    --threads 4 \
    --batch-size 256 \
    --host 0.0.0.0 \
    --port 8080
}
LLama3() {
  "$LLMS_ROOT/llama.cpp/build/bin/llama-server" \
    -m "$LLMS_ROOT/models/Llama-3.2-1B-Instruct-Q4_K_M.gguf" \
    --ctx-size 8192 \
    --threads 4 \
    --batch-size 128 \
    --port 8081
}
