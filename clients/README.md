# base_client1.sh

A simple terminal-based client for talking to a local LLM server.

This script connects to a locally running `llama-server` (OpenAI-compatible `/v1/completions` endpoint) and gives you a basic REPL-style chat loop in the terminal. It keeps a rolling conversation history, streams responses as they’re generated, and renders the final output nicely.

## What it does
- Sends prompts to a local LLM server over HTTP
- Streams tokens as they arrive
- Maintains a rolling conversation context
- Automatically trims history to stay within a safe context size
- Pretty-prints the final response using `glow`

## Requirements
- A running `llama-server` (or compatible server)
- `curl`
- `jq`
- `glow` (optional, but recommended for nicer output)

## Usage
```bash
chmod +x base_client1.sh
./base_client1.sh
