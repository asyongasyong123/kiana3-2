#!/bin/bash
set -euo pipefail

# =========================================
# 🚀 GCP-XRAY DEPLOYER | AUTOMODE & MANUAL MODE DEPLOYMENT
# ✅ INTEGRATED DNS & ADBLOCK ROUTING
# ✅ NGINX PROXY CONNECT TIMEOUT ADDED
# ✅ CUSTOM TEXT DECOY (NO GITHUB IMAGE)
# ✅ FULL FLEXIBLE MANUAL MEMORY & VCPU SELECTION
# ✅ AUTO-SAVE CONFIGS TO FILE FOR EDITOR COPYING
# =========================================

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# ==============================================
# AUTO INSTALL JQ IF MISSING
# ==============================================
if ! command -v jq &> /dev/null; then
  echo -e "\n${YELLOW}⚠️ Installing required tool: jq...${NC}"
  sudo apt update -qq && sudo apt install -y -qq jq || {
    echo -e "${RED}❌ Failed to install jq!${NC}"
    exit 1
  }
  echo -e "${GREEN}✅ jq installed successfully!${NC}"
fi

# ==============================================
# LIST SERVICES
# ==============================================
list_deployed_services() {
  echo -e "\n======================================"
  echo -e "${CYAN}📋 ALL DEPLOYED GCP-XRAY SERVICES - FULL DETAILS${NC}"
  echo -e "======================================"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  echo "Project: $PROJECT_ID"
  echo ""

  declare -A REGION_NAMES=(
    ["us-central1"]="Iowa, United States 🇺🇸"
    ["us-east1"]="South Carolina, United States 🇺🇸"
    ["us-east4"]="N. Virginia, United States 🇺🇸"
    ["us-west1"]="Oregon, United States 🇺🇸"
    ["asia-east1"]="Taiwan 🇹🇼"
    ["asia-southeast1"]="Singapore 🇸🇬"
    ["asia-northeast1"]="Tokyo, Japan 🇯🇵"
    ["asia-northeast3"]="Seoul, South Korea 🇰🇷"
    ["europe-west1"]="Belgium 🇧🇪"
    ["europe-west4"]="Netherlands 🇳🇱"
    ["europe-west9"]="Paris, France 🇫🇷"
    ["asia-south1"]="Mumbai, India 🇮🇳"
  )

  SERVICES=$(gcloud run services list \
    --format="value(metadata.name, status.url, region, metadata.creationTimestamp.date(%Y-%m-%d))" \
    --project="$PROJECT_ID" 2>/dev/null)

  if [ -z "$SERVICES" ]; then
    echo -e "${RED}❌ No services found.${NC}"
  else
    local COUNT=1
    while IFS=$'\t' read -r NAME URL REGION CREATED; do
      [ -z "$NAME" ] && continue
      FULL_REGION="${REGION_NAMES[$REGION]:-$REGION}"

      DETAILS=$(gcloud run services describe "$NAME" --region "$REGION" --project="$PROJECT_ID" --format=json 2>/dev/null)

      MEMORY=$(echo "$DETAILS" | jq -r '.spec.template.spec.containers[0].resources.limits.memory // "1Gi"')
      CPU=$(echo "$DETAILS" | jq -r '.spec.template.spec.containers[0].resources.limits.cpu // "1"')
      BILLING=$(echo "$DETAILS" | jq -r '.spec.template.spec.billingMode // "Instance Based"' | sed 's/_/ /g;s/^./\U&/')
      MIN_INST=$(echo "$DETAILS" | jq -r '.spec.template.spec.minInstances // "0"')
      MAX_INST=$(echo "$DETAILS" | jq -r '.spec.template.spec.maxInstances // "1"')
      CONCURRENCY=$(echo "$DETAILS" | jq -r '.spec.template.spec.containerConcurrency // "300"')

      echo -e "${GREEN}=== SERVICE #$COUNT ===${NC}"
      echo "🔹 Name:         $NAME"
      echo "🔹 URL:          $URL"
      echo "🔹 Region:       $REGION → $FULL_REGION"
      echo "🔹 Created:      $CREATED"
      echo "🔹 Resources:    $MEMORY RAM | $CPU vCPU"
      echo "🔹 Billing:      $BILLING"
      echo "🔹 Instances:    Min $MIN_INST / Max $MAX_INST"
      echo "🔹 Connections:  Max $CONCURRENCY"
      echo ""
      ((COUNT++))
    done <<< "$SERVICES"
  fi
  
  echo -e "\n======================================"
  read -p "Press [Enter] to return..."
}

# ==============================================
# REGION SELECTOR
# ==============================================
select_region() {
  echo -e "\n=== GCP CLOUD RUN REGION SELECTION ==="
  echo "--- North America ---"
  echo "1) us-central1      (Iowa, US 🇺🇸)"
  echo "2) us-east1         (South Carolina, US 🇺🇸)"
  echo "3) us-east4         (N. Virginia, US 🇺🇸)"
  echo "4) us-west1         (Oregon, US 🇺🇸)"
  echo ""
  echo "--- Asia Pacific ---"
  echo "5) asia-east1       (Taiwan 🇹🇼 — RECOMMENDED!)"
  echo "6) asia-southeast1  (Singapore 🇸🇬)"
  echo "7) asia-northeast1   (Tokyo, Japan 🇯🇵)"
  echo "8) asia-northeast3   (Seoul, South Korea 🇰🇷)"
  echo "9) asia-south1      (Mumbai, India 🇮🇳)"
  echo ""
  echo "--- Europe ---"
  echo "10) europe-west1     (Belgium 🇧🇪)"
  echo "11) europe-west4    (Netherlands 🇳🇱)"
  echo "12) europe-west9    (Paris, France 🇫🇷)"
  echo ""
  echo "0) Enter custom region code"
  echo ""

  read -p "Enter region number: " REGION_NUM

  case $REGION_NUM in
    1) REGION="us-central1" ;;
    2) REGION="us-east1" ;;
    3) REGION="us-east4" ;;
    4) REGION="us-west1" ;;
    5) REGION="asia-east1" ;;
    6) REGION="asia-southeast1" ;;
    7) REGION="asia-northeast1" ;;
    8) REGION="asia-northeast3" ;;
    9) REGION="asia-south1" ;;
    10) REGION="europe-west1" ;;
    11) REGION="europe-west4" ;;
    12) REGION="europe-west9" ;;
    0) read -p "Type full region code: " REGION ;;
    *) echo -e "${YELLOW}⚠️ Invalid! Using us-central1${NC}"; REGION="us-central1" ;;
  esac

  echo -e "${GREEN}✅ Selected Region:${NC} $REGION"
}

# ==============================================
# DEPLOYMENT FUNCTION
# ==============================================
deploy_new_service() {
  select_region

  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  RAND=$(openssl rand -hex 3)
  CLOUD_RUN_SERVICE_NAME="gcp-xray-$RAND"
  BUILD_DIR=$(mktemp -d)
  trap 'rm -rf "$BUILD_DIR"' EXIT

  clear
  echo ""
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}🚀 GCP-XRAY DEPLOYER | AUTOMODE & MANUAL MODE DEPLOYMENT${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}✅ Project:${NC} $PROJECT_ID"
  echo -e "${GREEN}✅ Region:${NC} $REGION"
  echo -e "${GREEN}✅ Service Name:${NC} $CLOUD_RUN_SERVICE_NAME"
  echo ""

  if [ -z "$PROJECT_ID" ]; then
      echo -e "${RED}❌ No project set! Run: gcloud config set project YOUR_ID${NC}"
      read -p "Press [Enter] to return..."
      return
  fi

  gcloud services enable run.googleapis.com cloudbuild.googleapis.com --project="$PROJECT_ID" --quiet

  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}          BILLING MODE${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${YELLOW}Instance-Based = Stable, No Throttling${NC}"
  echo "1) Request-Based  |  2) Instance-Based"
  while true; do
      read -p "Select [1-2]: " BILLING_CHOICE
      case $BILLING_CHOICE in
          1) BILLING_MODE="request"; BILLING_FLAG="--cpu-throttling"; break ;;
          2) BILLING_MODE="instance"; BILLING_FLAG="--no-cpu-throttling"; break ;;
          *) echo -e "${RED}Enter 1 or 2 only${NC}" ;;
      esac
  done

  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}      RESOURCE CONFIG MODE${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}1) AUTO PRESETS  |  Recommended${NC}"
  echo -e "${YELLOW}2) MANUAL SETUP  |  Full Memory & vCPU Range${NC}"
  while true; do
      read -p "Select Mode [1-2]: " RES_MODE
      case $RES_MODE in
          1)
              echo -e "\n${CYAN}--- AUTO PRESETS ---${NC}"
              echo "1) Basic:    1Gi RAM + 1 vCPU"
              echo "2) Balanced: 2Gi RAM + 2 vCPU ✅"
              echo "3) Turbo:    4Gi RAM + 2 vCPU (High Concurrency)"
              read -p "Choose preset [1-3]: " AUTO_CHOICE
              case $AUTO_CHOICE in
                  1) MEMORY="1Gi"; CPU="1"; CONCURRENCY="1000" ;;
                  2) MEMORY="2Gi"; CPU="2"; CONCURRENCY="1000" ;;
                  3) MEMORY="4Gi"; CPU="2"; CONCURRENCY="1000" ;;
                  *) echo -e "${YELLOW}Using Balanced preset${NC}"; MEMORY="2Gi"; CPU="2"; CONCURRENCY="1000" ;;
              esac
              TIMEOUT="3600"
              MIN_INST="0"
              MAX_INST="1"
              echo -e "${GREEN}✅ Applied: $MEMORY | $CPU vCPU${NC}"
              break
              ;;
          2)
              echo -e "\n${YELLOW}--- MANUAL SETUP (UNLOCKED ALL SPECS) ---${NC}"
              echo "Select Memory:"
              echo "1) 256Mi   2) 512Mi   3) 1Gi   4) 2Gi"
              echo "5) 4Gi     6) 8Gi     7) 16Gi  8) Custom input"
              read -p "Select Memory [1-8]: " MEM
              case $MEM in
                  1) MEMORY="256Mi" ;;
                  2) MEMORY="512Mi" ;;
                  3) MEMORY="1Gi" ;;
                  4) MEMORY="2Gi" ;;
                  5) MEMORY="4Gi" ;;
                  6) MEMORY="8Gi" ;;
                  7) MEMORY="16Gi" ;;
                  8) read -p "Type custom memory (e.g. 512Mi, 4Gi, 32Gi): " MEMORY ;;
                  *) MEMORY="1Gi" ;;
              esac

              echo -e "\nSelect vCPU:"
              echo "1) 1 vCPU   2) 2 vCPU   3) 4 vCPU   4) 8 vCPU   5) Custom input"
              read -p "Select vCPU [1-5]: " CPU_SEL
              case $CPU_SEL in
                  1) CPU="1" ;;
                  2) CPU="2" ;;
                  3) CPU="4" ;;
                  4) CPU="8" ;;
                  5) read -p "Type custom vCPU (e.g. 0.5, 1, 2, 4, 8): " CPU ;;
                  *) CPU="1" ;;
              esac

              read -p "Max Connections/Concurrency [Default: 1000]: " CONCURRENCY
              CONCURRENCY=${CONCURRENCY:-1000}

              TIMEOUT="3600"

              read -p "Min Instances [Default: 0]: " MIN_INST
              MIN_INST=${MIN_INST:-0}

              read -p "Max Instances [Default: 1]: " MAX_INST
              MAX_INST=${MAX_INST:-1}

              echo -e "${GREEN}✅ Custom Selected: $MEMORY RAM | $CPU vCPU | Max Inst: $MAX_INST${NC}"
              break
              ;;
          *) echo -e "${RED}Enter 1 or 2 only${NC}" ;;
      esac
  done

  cd "$BUILD_DIR" || exit 1

  # ✅ OPTIMIZED XRAY CONFIG
  cat > config.json <<'EOF'
{
  "log": { "loglevel": "warning" },
  "dns": {
    "servers": ["8.8.8.8", "8.8.4.4"],
    "strategy": "UseIPv4"
  },
  "policy": {
    "levels": {
      "0": {
        "handshake": 2,
        "connIdle": 3600,
        "bufferSize": 1048576
      }
    }
  },
  "inbounds": [
    {
      "tag": "trojan-ws",
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [{"password": "gcp-xray", "level": 0}] },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan-ws"
        },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpKeepAliveIdle": 300,
          "tcpKeepAliveInterval": 30
        }
      }
    },
    {
      "tag": "vless-ws",
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [{"id": "a1b2c3d4-5678-40ef-98ab-cdef01234567", "level": 0}], "decryption": "none" },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless-ws"
        },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpKeepAliveIdle": 300,
          "tcpKeepAliveInterval": 30
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": { "domainStrategy": "UseIPv4" }
    },
    {
      "protocol": "blackhole",
      "tag": "blocked",
      "settings": {
        "response": { "type": "none" }
      }
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "domain": ["geosite:category-ads-all"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "inboundTag": ["trojan-ws", "vless-ws"],
        "outboundTag": "direct"
      }
    ]
  }
}
EOF

  # ✅ OPTIMIZED NGINX CONFIG (WITH CUSTOM TEXT DECOY)
  cat > nginx.conf <<'EOF'
worker_processes auto;
worker_rlimit_nofile 10240;

events {
  worker_connections 4096;
  use epoll;
  multi_accept on;
}

http {
  include mime.types;
  default_type application/octet-stream;

  sendfile on;
  tcp_nodelay on;
  tcp_nopush on;
  keepalive_timeout 3600;
  keepalive_requests 100000;
  client_max_body_size 0;

  proxy_buffering off;
  proxy_request_buffering off;
  proxy_http_version 1.1;
  proxy_connect_timeout 10s;

  server {
    listen 8080;
    server_name _;

    location /health {
      return 200 "OK\n";
      add_header Content-Type text/plain;
    }

    location / {
      default_type text/html;
      return 200 "<!DOCTYPE html><html><head><title>Active</title></head><body style='font-family:sans-serif;text-align:center;padding:50px;'><h1>Cloud Server is Active</h1><p>Everything is operational.</p></body></html>";
    }

    location /trojan-ws {
      proxy_pass http://127.0.0.1:10001;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_read_timeout 3600s;
      proxy_send_timeout 3600s;
    }

    location /vless-ws {
      proxy_pass http://127.0.0.1:10002;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_read_timeout 3600s;
      proxy_send_timeout 3600s;
    }
  }
}
EOF

  cat > entrypoint.sh <<'EOF'
#!/bin/sh
/usr/local/bin/xray run -c /etc/xray.json &
sleep 2
exec /usr/local/openresty/bin/openresty -g 'daemon off;'
EOF
  chmod +x entrypoint.sh

  cat > Dockerfile <<'EOF'
FROM alpine:3.20 AS builder
RUN apk add --no-cache curl unzip ca-certificates
RUN curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip && unzip -q xray.zip xray geosite.dat geoip.dat && chmod +x xray
FROM openresty/openresty:alpine-fat
COPY --from=builder /xray /usr/local/bin/xray
COPY --from=builder /geosite.dat /usr/local/share/xray/
COPY --from=builder /geoip.dat /usr/local/share/xray/
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/xray /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF

  echo -e "${CYAN}🔨 Building image...${NC}"
  gcloud builds submit --project="$PROJECT_ID" --tag gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME . --quiet

  echo -e "${CYAN}🚀 Deploying to Cloud Run...${NC}"
  gcloud run deploy $CLOUD_RUN_SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME \
    --project="$PROJECT_ID" --platform managed --region "$REGION" --allow-unauthenticated \
    --port 8080 --memory $MEMORY --cpu $CPU --concurrency $CONCURRENCY \
    --timeout $TIMEOUT --min-instances $MIN_INST --max-instances $MAX_INST \
    --session-affinity \
    --execution-environment gen2 $BILLING_FLAG --cpu-boost --quiet

  CLOUD_RUN_URL=$(gcloud run services describe "$CLOUD_RUN_SERVICE_NAME" --project="$PROJECT_ID" --region="$REGION" --format='value(status.url)')
  DOMAIN=$(echo "$CLOUD_RUN_URL" | sed 's|https://||')
  CANONICAL_LINK="https://$DOMAIN"

  # 🔗 GENERATE RAW IMPORTABLE LINKS
  TROJAN_LINK="trojan://gcp-xray@firebase-settings.crashlytics.com:443?type=ws&host=${DOMAIN}&headerType=none&path=%2Ftrojan-ws&security=tls&sni=firebase-settings.crashlytics.com#${CLOUD_RUN_SERVICE_NAME}"
  VLESS_LINK="vless://a1b2c3d4-5678-40ef-98ab-cdef01234567@firebaseremoteconfigrealtime.googleapis.com:443?encryption=none&type=ws&host=${DOMAIN}&headerType=none&path=%2Fvless-ws&security=tls&sni=firebaseremoteconfigrealtime.googleapis.com#${CLOUD_RUN_SERVICE_NAME}"

  # 📁 AUTOMATIC SAVE TO FILE PARA SA EDITOR COPYING
  cat <<EOF > "$HOME/configs.txt"
=== TROJAN LINK ===
$TROJAN_LINK

=== VLESS LINK ===
$VLESS_LINK
EOF

  clear
  echo -e "\n${CYAN}=========================================${NC}"
  echo -e "${GREEN}✅ GCP-XRAY DEPLOYMENT SUCCESS!${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}🔗 SHORT LINK:${NC} $CANONICAL_LINK"
  echo -e "${GREEN}🌐 FULL LINK:${NC} $CÑDOMAIN"
  echo -e "${GREEN}💚 HEALTH CHECK:${NC} $CANONICAL_LINK/health"
  echo -e "${YELLOW}📁 SAVED TO FILE:${NC} configs.txt (Open Cloud Shell Editor to copy easily)"
  echo ""
  echo -e "${CYAN}📋 GENERATED CONFIG LINKS FOR NETMOD:${NC}"
  echo -e "${GREEN}🔹 TROJAN LINK:${NC}"
  echo "$TROJAN_LINK"
  echo ""
  echo -e "${GREEN}🔹 VLESS LINK:${NC}"
  echo "$VLESS_LINK"
  echo -e "${CYAN}=========================================${NC}"

  read -p $'\nPress [Enter] to return to Main Menu...'
}

# ==============================================
# MAIN MENU
# ==============================================
while true; do
  clear
  echo "======================================"
  echo "    GCP-XRAY DEPLOYER MENU    "
  echo "======================================"
  echo "1) Deploy New GCP-XRAY Service"
  echo "2) List All Services & FULL DETAILS"
  echo "3) Exit Script"
  echo "======================================"
  read -p "Select Option [1-3]: " MENU_CHOICE

  case $MENU_CHOICE in
    1) deploy_new_service ;;
    2) list_deployed_services ;;
    3) echo -e "\n👋 Goodbye!"; exit 0 ;;
    *) echo -e "${RED}❌ Enter 1/2/3 only${NC}"; sleep 2 ;;
  esac
done
