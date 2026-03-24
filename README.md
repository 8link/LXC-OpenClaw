# 🐾 LXC-OpenClaw

> Automated Proxmox LXC deployment script for [OpenClaw](https://github.com/openclaw) AI agents — from zero to running bot in a single command.

---

## Overview

**LXC-OpenClaw** is a fully automated Bash script that deploys and configures an OpenClaw AI agent inside a Proxmox LXC container using the latest Debian template.

It handles everything from container creation to full OpenClaw installation, configuration, and Telegram integration — making it ideal for rapid, reproducible deployments.

---

## 🚀 What It Does

- Fetches the latest **Debian 13 LXC template** automatically
- Creates a new **unprivileged LXC container** in Proxmox
- Auto-generates a **secure root password** and **SSH access config**
- Injects environment variables directly into the LXC config
- Installs and configures:
  - OpenClaw + Node runtime + required system packages
  - OpenRouter model integration
  - Brave Search API
  - Telegram bot + group support
- Enables OpenClaw **hooks and plugins**
- Sends a **Telegram notification** after deployment with container details

---

## ⚙️ Key Features

| Feature | Details |
|---|---|
| 🔄 Fully automated | End-to-end deployment, no manual steps |
| 🧠 AI preconfigured | OpenRouter model support out of the box |
| 📡 Telegram ready | Bot + group integration included |
| 🔐 Secure by default | Auto-generated passwords & SSH keys |
| 📦 Lightweight | LXC-based, minimal footprint |
| 🧩 Customizable | All options exposed as variables at the top of the script |

---

## 📋 Requirements

- Proxmox VE host
- Available storage (`local`, `data`, or custom pool)
- Network bridge configured (e.g., `vmbr0`)
- Internet access from inside the container

---

## ▶️ Usage

```bash
chmod +x lxc-openclaw.sh
./lxc-openclaw.sh
```

---

## 🛠️ Configuration

Edit the variables block at the top of the script before running:

```bash
BOT_NAME=""               # Name of your bot / container
MODEL=""                  # OpenRouter model (e.g. qwen, gpt-4o, etc.)
TELEGRAM_BOT_TOKEN=""     # Your Telegram bot token
MY_CHAT_ID=""             # Your Telegram user ID
GROUP_ID=""               # Telegram group ID
BRAVE_API_KEY=""          # Brave Search API key
OPENROUTER_API_KEY=""     # OpenRouter API key
```

---

## 📦 Output

After a successful run, the script provides:

- ✅ Container ID & IP address
- ✅ Root password saved to `/root/openclaw-<ID>-password.txt`
- ✅ Telegram confirmation message with deployment details

---

## ⚠️ Security Notice

> This script handles sensitive credentials (API keys, Telegram tokens).
>
> **Do NOT commit real credentials to public repositories.**  
> Use environment variables or a `.env` file and add it to `.gitignore`.

---

## 💡 Use Cases

- 🤖 Personal AI assistant hosting
- 💬 Telegram AI bots
- 🏠 Self-hosted LLM automation
- 🧪 Rapid testing environments for OpenClaw

---

## 📄 License

MIT — feel free to fork, modify, and deploy.
