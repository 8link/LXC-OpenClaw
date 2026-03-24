#!/bin/bash

# ── Load config ────────────────────────────────────────────────────────────────
CONFIG_FILE="$(dirname "$0")/config.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config file not found at $CONFIG_FILE" >&2
    exit 1
fi

source "$CONFIG_FILE"

# ── Validate required variables ───────────────────────────────────────────────
# Optional: OPENCLAW_VERSION (empty = install latest), GROUP_ID (empty = skip in openclaw config)
required_vars=(
    debian_ver
    KEY
    BOT_NAME
    OPENCLAW_GATEWAY_TOKEN
    BRAVE_API_KEY
    TELEGRAM_BOT_TOKEN
    OPENROUTER_API_KEY
    MY_CHAT_ID
    MODEL
    JSON_PATH
)

missing=()
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing+=("$var")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: the following required variables are empty or missing:" >&2
    for var in "${missing[@]}"; do
        echo "  - $var" >&2
    done
    echo "Check your config file: $CONFIG_FILE" >&2
    exit 1
fi

# ── Resolve optional variables ────────────────────────────────────────────────
if [[ -z "$OPENCLAW_VERSION" ]]; then
    echo "OPENCLAW_VERSION not set — latest will be installed."
fi

if [[ -z "$GROUP_ID" ]]; then
    echo "GROUP_ID not set — skipping in openclaw config."
fi

# ── Your script logic below ───────────────────────────────────────────────────
echo "All required variables loaded successfully."


pveam update
TEMPLATE=$(pveam available --section system | grep $debian_ver | awk '{print $NF}' | sort -V | tail -1)

echo "Latest $debian_ver template: $TEMPLATE"

if [ -z "$TEMPLATE" ]; then
    echo "No $debian_ver template found."
    exit 1
fi

if pveam list local | grep -q "$TEMPLATE"; then
    echo "Debian LXC template is already available locally."
else
    echo "Debian LXC template not found locally. Checking if available for download..."
    if pveam available --section system | grep -q "$TEMPLATE"; then
        echo "Template available for download. Downloading..."
        pveam download local "$TEMPLATE"
    else
        echo "Template not available for download."
        exit 1
    fi
fi


ID=$(pvesh get /cluster/nextid)
echo "Next available container ID: $ID"

# Generate and store initial root password
PW=$(openssl rand -base64 12)
printf '%s\n' "$PW" > /root/openclaw-$ID-password.txt
chmod 600 /root/openclaw-$ID-password.txt

# Write SSH key to temporary file
KEYFILE="/tmp/openclaw-$ID-key.pub"
printf '%s\n' "$KEY" > "$KEYFILE"
chmod 600 "$KEYFILE"

pct create $ID local:vztmpl/$TEMPLATE \
  --hostname openclaw-$BOT_NAME \
  --password "$PW" \
  --ssh-public-keys "$KEYFILE" \
  --cores 2 --memory 2048 --swap 512 \
  --rootfs data:32 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp,gw=192.168.10.1 \
  --features keyctl=1,nesting=1 \
  --unprivileged 1 \
  --onboot 1 \
  --nameserver 192.168.10.2 \
  --tags "openclaw;$BOT_NAME" 

cat <<EOF >> /etc/pve/lxc/$ID.conf
lxc.environment.runtime = BRAVE_API_KEY=$BRAVE_API_KEY
lxc.environment.runtime = TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
lxc.environment.runtime = OPENROUTER_API_KEY=$OPENROUTER_API_KEY
lxc.environment.runtime = OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
lxc.environment.runtime = BOT_NAME=$BOT_NAME
lxc.environment.runtime = MY_CHAT_ID=$MY_CHAT_ID
lxc.environment.runtime = ID=$ID
lxc.environment.runtime = MODEL=$MODEL
lxc.environment.runtime = JSON_PATH=$JSON_PATH
lxc.environment.runtime = OPENCLAW_VERSION=$OPENCLAW_VERSION
lxc.environment.runtime = GROUP_ID=$GROUP_ID
EOF

pct start $ID
sleep 2  # Wait for container to boot

# Add IP to /etc/issue
pct exec $ID -- bash -c 'cat >> /etc/issue << EOF

-------------------------------
Container IP: $(hostname -I)
Hostname: $(hostname)
-------------------------------
EOF'


pct exec $ID -- bash -lc '
  ERRORS=""
  apt update &&
  apt install -y curl mc htop jq &&

  echo "Fixing systemd for OpenClaw..."
  loginctl enable-linger root 

  curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
  
  openclaw onboard --non-interactive --accept-risk --daemon-runtime node --gateway-auth token --gateway-token $OPENCLAW_GATEWAY_TOKEN --install-daemon --json --mode local --node-manager npm  --openrouter-api-key $OPENROUTER_API_KEY --gateway-bind lan
  
  openclaw hooks enable session-memory
  openclaw hooks enable boot-md
  openclaw hooks enable bootstrap-extra-files

  echo "Adding OpenClaw configuration..."
 [ -n "$MODEL" ] && jq ".agents.defaults.model.primary = \"$MODEL\" | .agents.defaults.models = {\"$MODEL\": {}} | .agents.list = [{\"id\": \"main\", \"model\": \"$MODEL\"}]" $JSON_PATH > tmp.json && mv tmp.json $JSON_PATH
 [ -n "$MY_CHAT_ID" ] && jq ".channels.telegram.allowFrom = [\"$MY_CHAT_ID\"] | .channels.telegram.groupAllowFrom = [\"$MY_CHAT_ID\"]" $JSON_PATH > tmp.json && mv tmp.json $JSON_PATH
 [ -n "$BRAVE_API_KEY" ] && jq ".tools.web = {search: {enabled: true, provider: \"brave\", apiKey: \"$BRAVE_API_KEY\"}}" $JSON_PATH > tmp.json && mv tmp.json $JSON_PATH
 npm i -g clawhub
 [ -n "$GROUP_ID" ] && jq ".channels.telegram.groups[\"$GROUP_ID\"] = {\"requireMention\": false}" $JSON_PATH > tmp.json && mv tmp.json $JSON_PATH
  echo "OpenClaw configuration updated."

  openclaw plugins enable telegram
  openclaw channels add --channel telegram --token "$TELEGRAM_BOT_TOKEN"
  openclaw gateway restart 

  if [ -z "$ERRORS" ]; then
      STATUS="✅ No errors reported"
  else
      STATUS="⚠️ Installation finished with errors:
  $ERRORS"
  fi

  MSG="Instalation of OpenClaw on $BOT_NAME is complete!
  $STATUS
  🤖Used model: $MODEL
  📦Container ID: $ID
  🌐IP: $(hostname -I)"

  openclaw message send -t "$MY_CHAT_ID" -m "$MSG"
  '

