# local-llm-lab

A small personal lab for experimenting with locally hosted LLMs.

This repo contains simple server and client scripts for running and interacting with LLMs on local machines (mostly built around `llama.cpp`). It’s designed to be lightweight, hackable, and friendly to low-resource setups like the Raspberry Pi. I'm using a Pi5 16GB for now.
I plan to add a small script for android as well.

Nothing fancy — just a place to test models, tweak prompts, and wire things together.

## Quick start

1. Make sure `llama.cpp` is built and your models are downloaded under `~/llms/models`.

2. Source the server/client definitions into your shell:
   ```bash
   source servers/servers_base.sh
   ```

## What’s inside
- `servers/` – scripts to start local LLM servers  
- `clients/` – client scripts to talk to those servers  

## Folder Structure

This repo lives inside a larger local LLM workspace. The layout looks like this:

```text
~
└── llms
    ├── llama.cpp        # llama.cpp source and binaries
    ├── models           # downloaded GGUF model files
    └── local-llm-lab    # this repository
        ├── servers      # scripts to launch LLM servers
        └── clients      # client scripts for interacting with servers
```

## Notes
This is an experiment-first repo. Things may change, break, or get rewritten as ideas evolve.

