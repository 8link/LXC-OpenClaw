LXC-OpenClaw – Automated Proxmox Deployment Script

A fully automated Bash script for deploying and configuring an OpenClaw AI agent inside a Proxmox LXC container using the latest Debian template.

This script handles everything from container creation to full OpenClaw installation, configuration, and Telegram integration—making it ideal for rapid, reproducible deployments.

🚀 What this script does
Fetches the latest Debian 13 LXC template
Creates a new unprivileged LXC container in Proxmox
Automatically generates:
Secure root password
SSH access configuration
Injects environment variables directly into LXC config
Installs and configures:
OpenClaw
Node runtime
Required system packages
Sets up:
OpenRouter model integration
Brave Search API
Telegram bot + group support
Enables OpenClaw hooks and plugins
Sends a Telegram notification after deployment with container details
⚙️ Key Features
🔄 Fully automated end-to-end deployment
🧠 Preconfigured AI agent (OpenRouter model support)
📡 Telegram bot integration out-of-the-box
🔐 Secure credential handling (auto-generated password & SSH key)
📦 Lightweight LXC-based environment
🧩 Easily customizable via variables at the top of the script
📋 Requirements
Proxmox VE host
Available storage (local, data)
Network bridge configured (e.g., vmbr0)
Internet access inside container
▶️ Usage
chmod +x lxc-openclaw.sh
./lxc-openclaw.sh
🛠️ Configuration

Edit variables at the top of the script:

BOT_NAME – Name of your bot/container
MODEL – OpenRouter model (e.g., qwen, gpt, etc.)
TELEGRAM_BOT_TOKEN – Telegram bot token
MY_CHAT_ID – Your Telegram user ID
GROUP_ID – Telegram group ID
BRAVE_API_KEY – Web search API key
OPENROUTER_API_KEY – AI model API key
📦 Output

After execution, the script will provide:

Container ID
IP address
Stored root password (/root/openclaw-<ID>-password.txt)
Telegram confirmation message
⚠️ Security Notice

This script contains sensitive tokens (API keys, Telegram tokens).
Do NOT commit real credentials to public repositories.
Use environment variables or a .env file instead.

💡 Use Cases
Personal AI assistant hosting
Telegram AI bots
Self-hosted LLM automation
Rapid testing environments for OpenClaw
