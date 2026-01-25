alias chatclient='~/llms/local-llm-lab/clients/base_client1.sh'

phi-server() {
  ~/llms/llama.cpp/build/bin/llama-server \
  -m ~/llms/models/Phi-3.1-mini-128k-instruct-Q4_K_M.gguf \
  --ctx-size 16384 \
  --threads 4 \
  --batch-size 128 \
  --host 0.0.0.0
  # WARNING: 0.0.0.0 exposes the server to your network
}

qwen14() {
  ~/llms/llama.cpp/build/bin/llama-cli \
    -m ~/llms/models/Qwen_Qwen3-14B-Q4_K_M.gguf \
    --ctx-size 4096 \
    --threads 4 \
    --batch-size 128 \
    --reasoning-budget 0 \
    "$@"
}
qwen14-server() {
  ~/llms/llama.cpp/build/bin/llama-server \
    -m ~/llms/models/Qwen_Qwen3-14B-Q4_K_M.gguf \
    --ctx-size 4096 \
    --threads 4 \
    --batch-size 128 \
    --reasoning-budget 0 \
    --reasoning-format none \
    --host 0.0.0.0 \ # WARNING: 0.0.0.0 exposes the server to your network
    "$@"
}

qwen30() {
  ~/llms/llama.cpp/build/bin/llama-cli \
    -m ~/llms/models/Qwen3-30B-A3B-Instruct-2507-Q3_K_S-2.70bpw.gguf \
    --ctx-size 1536 \
    --threads 4 \
    --batch-size 128 \
    --verbose-prompt \
    "$@"
}
qwen30-server() {
  ~/llms/llama.cpp/build/bin/llama-server \
    -m ~/llms/Qwen3-30B-A3B-Instruct-2507-Q3_K_S-2.70bpw.gguf \
    --ctx-size 4096 \
    --threads 4 \
    --batch-size 128 \
    --host 0.0.0.0 \ # WARNING: 0.0.0.0 exposes the server to your network
    --port 8080 \
    "$@"
}

llama3() {
   ~/llms/llama.cpp/build/bin/llama-cli \
   -m ~/llms/models/Meta-Llama-3.1-8B-Instruct-128k-Q4_0.gguf \
   --ctx-size 16384 \
   --threads 4 \
   --batch-size 128 \
   "$@" 
}
llama3-server() {
   ~/llms/llama.cpp/build/bin/llama-server \
   -m ~/llms/models/Meta-Llama-3.1-8B-Instruct-128k-Q4_0.gguf \
   --ctx-size 16384 \
   --threads 4 \
   --batch-size 128 \
   --host 0.0.0.0 \   # WARNING: 0.0.0.0 exposes the server to your network
   "$@" 
}

gptoss(){
  ~/llms/llama.cpp/build/bin/llama-cli \
  -m ~/llms/models/gpt-oss-20b-Q4_K_M.gguf \
  --ctx-size 2048 \
  --threads 4 \
  --batch-size 64 \
  "$@"
}
