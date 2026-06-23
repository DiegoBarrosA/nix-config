# Available Tools

## Bundled Plugins

### summarize
Summarizes web pages, PDFs, and YouTube videos.
- Input: URL or file path
- Output: Concise summary of content

### peekaboo (rubi only)
Takes screenshots of the current screen.
- Available only on desktop (rubi)
- Useful for visual context

### sag (rubi only)
Text-to-speech synthesis.
- Converts text responses to audio
- Available only on desktop (rubi)

## Local Infrastructure

### llama.cpp (cobalto)
Local LLM inference server running on cobalto:11435
- Model: Llama 3.2 3B Instruct (Q8_0)
- Context: 8192 tokens
- GPU accelerated via Vulkan (AMD RX 460/580)

### Syncthing
File synchronization across devices.
- Notes and documents sync between machines

### Tailscale
VPN connecting all machines.
- rubi, cobalto, and mobile devices

## External Integrations

The following MCP servers may be available depending on environment:
- Jira Cloud (project management)
- Confluence Cloud (documentation)
- Obsidian (note-taking via REST API)
- mcp-nixos (NixOS package/option search)
- jobspy (job search — LinkedIn, Indeed, Google Jobs)
- github (company research, code search)
- playwright (web scraping, browser automation)
