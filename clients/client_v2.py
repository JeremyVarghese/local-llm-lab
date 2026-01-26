#!/usr/bin/env python3
"""
Readable Python port of client_v2.sh
Python 3.11 compatible
"""

from __future__ import annotations

import json
import sys
import shutil
from pathlib import Path
from typing import Iterator
import subprocess

try:
    import requests
except ImportError:
    print("Please install requests: pip install requests")
    sys.exit(1)


# ======================
# Configuration
# ======================

GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
RESET = "\033[0m"

SERVER_URL = "http://localhost:8080/v1/chat/completions"
SUMMARY_URL = "http://localhost:8081/v1/chat/completions"

MAX_RESPONSE_TOKENS = 2048

HIST_FILE = Path("chat_history.md")


# ======================
# Utilities
# ======================

def print_system(msg: str) -> None:
    print(f"{YELLOW}[System] {msg}{RESET}")


def stream_chat_completion(payload: dict) -> Iterator[str]:
    """
    Stream tokens from the LLM server.
    Yields text chunks as they arrive.
    """
    with requests.post(
        SERVER_URL,
        headers={"Content-Type": "application/json"},
        json=payload,
        stream=True,
        timeout=None,
    ) as response:
        response.raise_for_status()

        for raw_line in response.iter_lines(decode_unicode=False):
            if not raw_line:
                continue
            try:
                line = raw_line.decode("utf-8")
            except UnicodeDecodeError:
                line = raw_line.decode("utf-8", errors="replace")

            if line.startswith("data: "):
                data = line.removeprefix("data: ").strip()

                if data == "[DONE]":
                    break

                try:
                    parsed = json.loads(data)
                    delta = parsed["choices"][0]["delta"]
                    content = delta.get("content")
                    if content:
                        yield content
                except (KeyError, json.JSONDecodeError):
                    continue


# ======================
# History Management
# ======================

def summarize_entire_history() -> None:
    """
    Compress the entire conversation history using the summary model.
    Overwrites chat_history.md on success.
    """
    print_system("[Compressing Memory...]")

    full_convo = HIST_FILE.read_text(encoding="utf-8")

    payload = {
        "messages": [
            {
                "role": "user",
                "content": (
                    "Summarize this conversation log concisely, "
                    "keeping all key details:\n\n"
                    f"{full_convo}"
                ),
            }
        ],
        "temperature": 0.1,
        "max_tokens": 1024,
    }

    response = requests.post(
        SUMMARY_URL,
        headers={"Content-Type": "application/json"},
        json=payload,
        timeout=120,
    )

    try:
        data = response.json()
        summary = data["choices"][0]["message"]["content"]
    except (ValueError, KeyError):
        print_system("ERROR: Summary failed! Raw server response:")
        print(response.text)
        return

    if not summary:
        print_system("ERROR: Summary empty. History not overwritten.")
        return

    HIST_FILE.write_text(
        f"System: [Context Summary]: {summary}\n\n",
        encoding="utf-8",
    )

    print_system("Summary complete! Resuming chat.")


# ======================
# Main Loop
# ======================

def main() -> None:
    HIST_FILE.touch(exist_ok=True)

    confirmation = input("Clear previous chat conversation [y/N]: ").strip()

    if confirmation.lower() == "y":
        HIST_FILE.write_text("", encoding="utf-8")
        print_system("History cleared.")
    else:
        print_system("Continuing with previous history.")

    while True:
        try:
            user_input = input(f"{GREEN}You: {RESET}")
        except EOFError:
            print()
            break

        # Append user message to history
        with HIST_FILE.open("a", encoding="utf-8") as f:
            f.write(f"User: {user_input}\nAssistant:")

        payload = {
            "messages": [
                {
                    "role": "user",
                    "content": HIST_FILE.read_text(encoding="utf-8"),
                }
            ],
            "max_tokens": MAX_RESPONSE_TOKENS,
            "temperature": 0.7,
            "top_p": 0.9,
            "stream": True,
            "stop": [
                "User:",
                "\nUser:",
                "\\nUser:",
                "<|im_end|>",
            ],
        }

        print()
        response_text_parts: list[str] = []

        try:
            for chunk in stream_chat_completion(payload):
                print(chunk, end="", flush=True)
                response_text_parts.append(chunk)
        except requests.RequestException as e:
            print_system(f"Network error: {e}")
            continue

        response_text = "".join(response_text_parts)

        print("\n    =============================")

        # Optional: pipe through glow if available
        if shutil.which("glow"):
            subprocess.run(
                ["glow"],
                input=response_text,
                text=True,
            )
        else:
            print(response_text)

        print()

        with HIST_FILE.open("a", encoding="utf-8") as f:
            f.write(f" {response_text}\n")

        # Always summarize after each exchange (same as bash)
        summarize_entire_history()


if __name__ == "__main__":
    main()

