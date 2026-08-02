#!/bin/bash
set -euo pipefail

# =========================================
# 🚀 KIANA-3.2 GCP DEPLOYER | FULL FEATURES
# ✅ NEW: VLESS+HTTP, VLESS+XHTTP, SSH+TLS
# ✅ USER/PASS: kiana3.2 | UUID: FIXED
# ✅ AUTO PRESETS + MANUAL SETUP RESTORED
# ✅ REGION SELECTOR + TAIWAN
# ✅ NO MORE N/A VALUES
# ✅ MAX SPEED XRAY + NGINX
# ✅ FIXED TIMEOUT ERROR
# =========================================

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# ==============================================
# 🔒 PERMANENT UUID & CREDS (WALA NAY USAB)
# ==============================================
UUID="a1b2c3d4-5678-40ef-98ab-cdef01234567"
USER="kiana3.2"
PASS="kiana3.2"

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
# LIST SERVICES (NO MORE N/A)
# ==============================================
list_deployed_services() {
  echo -e "\n======================================"
  echo -e "${CYAN}📋 ALL DEPLOYED SERVICES - FULL DETAILS${NC}"
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
      MIN_INST=$(echo "$DETAILS" | jq -r '.spec.template.spec.minInstances // "1"')
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
# ✅ FULL REGION SELECTOR RESTORED
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
# ✅ DEPLOY — DISPLAY 100% ORIGINAL!
# ==============================================
deploy_new_service() {
  select_region

  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  RAND=$(openssl rand -hex 3)
  CLOUD_RUN_SERVICE_NAME="xray-balanced-$RAND"
  BUILD_DIR=$(mktemp -d)
  trap 'rm -rf "$BUILD_DIR"' EXIT

  clear
  echo ""
  # ✅ GIBALIK EKSKAKTO SA IMONG GUSTO NGA LINYA!
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}🚀 KIANA-3.2 GCP DEPLOYER | NEW PROTOCOLS${NC}"
  echo -e "${GREEN}✅ VLESS+HTTP / VLESS+XHTTP / SSH+TLS${NC}"
  echo -e "${GREEN}✅ CREDS: kiana3.2 / UUID: $UUID${NC}"
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
  echo -e "${YELLOW}2) MANUAL SETUP  |  Custom values${NC}"
  while true; do
      read -p "Select Mode [1-2]: " RES_MODE
      case $RES_MODE in
          1)
              echo -e "\n${CYAN}--- AUTO PRESETS ---${NC}"
              echo "1) Basic:    1Gi RAM + 1 vCPU"
              echo "2) Balanced: 2Gi RAM + 2 vCPU ✅"
              echo "3) Max:      4Gi RAM + 4 vCPU"
              read -p "Choose preset [1-3]: " AUTO_CHOICE
              case $AUTO_CHOICE in
                  1) MEMORY="1Gi"; CPU="1"; CONCURRENCY="300" ;;
                  2) MEMORY="2Gi"; CPU="2"; CONCURRENCY="1000" ;;
                  3) MEMORY="4Gi"; CPU="4"; CONCURRENCY="1000" ;;
                  *) echo -e "${YELLOW}Using Balanced preset${NC}"; MEMORY="2Gi"; CPU="2"; CONCURRENCY="1000" ;;
              esac
              TIMEOUT="3600"
              MIN_INST="1"
              MAX_INST="1"
              echo -e "${GREEN}✅ Applied: $MEMORY | $CPU vCPU${NC}"
              break
              ;;
          2)
              echo -e "\n${YELLOW}--- MANUAL SETUP ---${NC}"
              while true; do
                  read -p "Memory [1=1Gi|2=2Gi|3=4Gi]: " MEM
                  case $MEM in
                      1) MEMORY="1Gi"; break ;;
                      2) MEMORY="2Gi"; break ;;
                      3) MEMORY="4Gi"; break ;;
                  esac
              done
              while true; do
                  read -p "vCPU [1|2|4]: " CPU_SEL
                  case $CPU_SEL in
                      1) CPU="1"; break ;;
                      2) CPU="2"; break ;;
                      3) CPU="4"; break ;;
                  esac
              done

              CONCURRENCY=$([ "$CPU" = "1" ] || [ "$MEMORY" = "1Gi" ] && echo "300" || echo "1000")
              TIMEOUT="3600"

              while true; do
                  read -p "Min Instances [0/1]: " MIN_INST
                  MIN_INST=${MIN_INST:-0}
                  [[ "$MIN_INST" =~ ^[0-1]$ ]] && break
              done
              while true; do
                  read -p "Max Instances [1-2]: " MAX_INST
                  MAX_INST=${MAX_INST:-1}
                  [[ "$MAX_INST" =~ ^[1-2]$ ]] && break
              done
              break
              ;;
          *) echo -e "${RED}Enter 1 or 2 only${NC}" ;;
      esac
  done

  cd "$BUILD_DIR" || exit 1

  # ✅ UPDATED XRAY CONFIG — FIXED UUID LANG GI-USAB
  cat > config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "policy": {
    "levels": {
      "0": {
        "handshake": 1,
        "connIdle": 86400,
        "bufferSize": 4194304
      }
    }
  },
  "inbounds": [
    {
      "tag": "trojan-ws",
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [{"password": "$PASS", "level": 0}] },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/tr-ConFig?ed=2560" },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpCongestion": "bbr",
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
      "settings": { "clients": [{"id": "$UUID", "level": 0}], "decryption": "none" },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vl-ConFig?ed=2560" },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpCongestion": "bbr",
          "tcpKeepAliveIdle": 300,
          "tcpKeepAliveInterval": 30
        }
      }
    },
    {
      "tag": "vless-http",
      "port": 10003,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [{"id": "$UUID", "level": 0}], "decryption": "none" },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "http",
        "httpSettings": { "path": "/vl-http", "host": ["\$host"] },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpCongestion": "bbr"
        }
      }
    },
    {
      "tag": "vless-xhttp",
      "port": 10004,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [{"id": "$UUID", "level": 0}], "decryption": "none" },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "http",
        "httpSettings": { "path": "/vl-xhttp", "host": ["\$host"], "method": "POST" },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpCongestion": "bbr"
        }
      }
    },
    {
      "tag": "ssh-tls",
      "port": 10005,
      "listen": "127.0.0.1",
      "protocol": "ssh",
      "settings": {
        "users": [{"user": "$USER", "password": "$PASS", "level": 0}],
        "encryption": "aes-256-gcm"
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": { "alpn": ["http/1.1"], "certificates": [{"certificate": "/etc/ssl/cert.pem", "key": "/etc/ssl/key.pem"}] },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpCongestion": "bbr"
        }
      }
    }
  ],
  "outbounds": [{"protocol": "freedom", "settings": { "domainStrategy": "UseIPv4v6" }}]
}
EOF

  # ✅ NGINX — WALAY GI-USAB GYUD
  cat > nginx.conf <<'EOF'
worker_processes auto;
worker_rlimit_nofile 65535;
worker_priority -10;

events {
  worker_connections 16384;
  use epoll;
  multi_accept on;
  accept_mutex off;
}

http {
  include mime.types;
  default_type application/octet-stream;

  sendfile on;
  tcp_nodelay on;
  tcp_nopush on;
  keepalive_timeout 86400;
  keepalive_requests 100000;
  client_max_body_size 0;

  proxy_buffering off;
  proxy_request_buffering off;
  proxy_http_version 1.1;
  proxy_cache off;

  map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
  }

  server {
    listen 8080 reuseport;
    server_name _;

    location /health {
      return 200 "OK\n";
      add_header Content-Type text/plain;
    }

    location / {
      proxy_pass https://www.google.com;
      proxy_set_header Host www.google.com;
    }

    location /tr-ConFig {
      proxy_pass http://127.0.0.1:10001;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_read_timeout 86400;
      proxy_send_timeout 86400;
    }

    location /vl-ConFig {
      proxy_pass http://127.0.0.1:10002;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_read_timeout 86400;
      proxy_send_timeout 86400;
    }

    location /vl-http {
      proxy_pass http://127.0.0.1:10003;
      proxy_set_header Host $host;
      proxy_read_timeout 86400;
      proxy_send_timeout 86400;
    }

    location /vl-xhttp {
      proxy_pass http://127.0.0.1:10004;
      proxy_set_header Host $host;
      proxy_read_timeout 86400;
      proxy_send_timeout 86400;
    }

    location /ssh-tls {
      proxy_pass http://127.0.0.1:10005;
      proxy_set_header Host $host;
      proxy_read_timeout 86400;
      proxy_send_timeout 86400;
    }
  }
}
EOF

  cat > entrypoint.sh <<'EOF'
#!/bin/sh
mkdir -p /etc/ssl
openssl req -x509 -newkey rsa:4096 -days 365 -nodes -keyout /etc/ssl/key.pem -out /etc/ssl/cert.pem -subj "/CN=localhost" 2>/dev/null
/usr/local/bin/xray run -c /etc/xray.json &
sleep 2
exec /usr/local/openresty/bin/openresty -g 'daemon off;'
EOF
  chmod +x entrypoint.sh

  cat > Dockerfile <<'EOF'
FROM alpine:3.20 AS builder
RUN apk add --no-cache curl unzip ca-certificates openssl
RUN curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip && unzip -q xray.zip xray geosite.dat geoip.dat && chmod +x xray
FROM openresty/openresty:alpine-fat
RUN apk add --no-cache openssl
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
    --execution-environment gen2 --cpu-boost $BILLING_FLAG --quiet

  CLOUD_RUN_URL=$(gcloud run services describe $CLOUD_RUN_SERVICE_NAME --project="$PROJECT_ID" --region="$REGION" --format='value(status.url)')
  SHORT_LINK="$CLOUD_RUN_URL"
  FULL_LINK="$CLOUD_RUN_URL"

  clear
  echo -e "\n${CYAN}=========================================${NC}"
  echo -e "${GREEN}✅ DEPLOYMENT SUCCESS!${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}🔗 SHORT LINK:${NC} $SHORT_LINK"
  echo -e "${GREEN}🌐 FULL LINK:${NC} $FULL_LINK"
  echo -e "${GREEN}💚 HEALTH CHECK:${NC} $FULL_LINK/health"
  echo ""
  echo -e "${CYAN}📋 CLIENT CONFIGS:${NC}"
  DOMAIN_ONLY=$(echo "$FULL_LINK" | sed 's|https://||')
  echo -e "${GREEN}🔹 TROJAN WS/TLS${NC}"
  echo "   Address:   $DOMAIN_ONLY"
  echo "   Port:      443"
  echo "   Password:  $PASS"
  echo "   Path:      /tr-ConFig?ed=2560"
  echo "   SNI:       $DOMAIN_ONLY"
  echo -e "\n${GREEN}🔹 VLESS WS/TLS${NC}"
  echo "   Address:   $DOMAIN_ONLY"
  echo "   Port:      443"
  echo "   UUID:      $UUID"
  echo "   Path:      /vl-ConFig?ed=2560"
  echo "   Security:  TLS"
  echo "   SNI:       $DOMAIN_ONLY"
  echo -e "\n${GREEN}🔹 VLESS+HTTP${NC}"
  echo "   Address:   $DOMAIN_ONLY"
  echo "   Port:      443"
  echo "   UUID:      $UUID"
  echo "   Path:      /vl-http"
  echo "   Security:  TLS"
  echo -e "\n${GREEN}🔹 VLESS+XHTTP${NC}"
  echo "   Address:   $DOMAIN_ONLY"
  echo "   Port:      443"
  echo "   UUID:      $UUID"
  echo "   Path:      /vl-xhttp"
  echo "   Security:  TLS"
  echo -e "\n${GREEN}🔹 SSH+TLS${NC}"
  echo "   Address:   $DOMAIN_ONLY"
  echo "   Port:      443"
  echo "   Username:  $USER"
  echo "   Password:  $PASS"
  echo "   Path:      /ssh-tls"
  echo -e "${CYAN}=========================================${NC}"

  read -p "\nPress [Enter] to return to Main Menu..."
}

# ==============================================
# MAIN MENU
# ==============================================
while true; do
  clear
  echo "======================================"
  echo "   🚀 KIANA-3.2 GCP DEPLOYER MENU    "
  echo "======================================"
  echo "1) Deploy new Xray service"
  echo "2) List all services & FULL DETAILS"
  echo "3) Exit script"
  echo "======================================"
  read -p "Select option [1-3]: " MENU_CHOICE

  case $MENU_CHOICE in
    1) deploy_new_service ;;
    2) list_deployed_services ;;
    3) echo -e "\n👋 Goodbye!"; exit 0 ;;
    *) echo -e "${RED}❌ Enter 1/2/3 only${NC}"; sleep 2 ;;
  esac
done
