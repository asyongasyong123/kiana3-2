#!/bin/bash
set -euo pipefail

# =========================================
# 🚀 KIANA-3.2 GCP DEPLOYER | FINAL PERFECTED
# ✅ NO MORE N/A VALUES
# ✅ SHOWS EXACT DEFAULTS IF NOT FOUND
# ✅ FIXED TIMEOUT + FULL DISPLAY
# ✅ MAX SPEED XRAY + NGINX
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
# LIST SERVICES WITH NO MORE N/A
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

      # Get full JSON details
      DETAILS=$(gcloud run services describe "$NAME" --region "$REGION" --project="$PROJECT_ID" --format=json 2>/dev/null)

      # Extract values OR use defaults if missing
      MEMORY=$(echo "$DETAILS" | jq -r '.spec.template.spec.containers[0].resources.limits.memory // "1Gi"')
      CPU=$(echo "$DETAILS" | jq -r '.spec.template.spec.containers[0].resources.limits.cpu // "1"')
      BILLING=$(echo "$DETAILS" | jq -r '.spec.template.spec.billingMode // "INSTANCE_BASED"' | sed 's/_/ /g;s/^./\U&/')
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
# REGION SELECTOR
# ==============================================
select_region() {
  echo -e "\n=== SELECT REGION ==="
  echo "1) us-central1 (US Iowa) | 5) asia-east1 (Taiwan 🇹🇼)"
  echo "2) us-east1 (US SC)      | 6) asia-southeast1 (SG 🇸🇬)"
  echo "3) us-east4 (US VA)      | 7) asia-northeast1 (JP 🇯🇵)"
  echo "4) us-west1 (US OR)      | 0) Custom"
  read -p "Enter number: " N
  case $N in
    1) REGION="us-central1" ;; 2) REGION="us-east1" ;; 3) REGION="us-east4" ;;
    4) REGION="us-west1" ;; 5) REGION="asia-east1" ;; 6) REGION="asia-southeast1" ;;
    7) REGION="asia-northeast1" ;; 0) read -p "Region code: " REGION ;;
    *) REGION="us-central1" ;;
  esac
  echo -e "${GREEN}✅ Region: $REGION${NC}"
}

# ==============================================
# DEPLOYMENT
# ==============================================
deploy_new_service() {
  select_region
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  RAND=$(openssl rand -hex 3)
  NAME="xray-balanced-$RAND"
  DIR=$(mktemp -d)
  trap 'rm -rf "$DIR"' EXIT

  clear
  echo -e "${CYAN}🚀 DEPLOYING: $NAME${NC}"
  echo -e "${GREEN}📍 Region: $REGION | Project: $PROJECT_ID${NC}"

  [ -z "$PROJECT_ID" ] && { echo -e "${RED}❌ Set project first!${NC}"; return; }

  gcloud services enable run.googleapis.com cloudbuild.googleapis.com --project="$PROJECT_ID" --quiet

  # Billing Mode
  echo -e "\n${CYAN}--- BILLING ---${NC}"
  echo "1) Request | 2) Instance (Recommended)"
  read -p "Select: " B
  [ "$B" = "2" ] && BILLING_FLAG="--no-cpu-throttling" || BILLING_FLAG="--cpu-throttling"

  # Resources
  echo -e "\n${CYAN}--- RESOURCES ---${NC}"
  echo "1) Basic: 1Gi+1vCPU | 2) Balanced: 2Gi+2vCPU | 3) Max: 4Gi+4vCPU"
  read -p "Select: " R
  case $R in
    1) MEM="1Gi"; CPU="1"; CONC="300" ;;
    2) MEM="2Gi"; CPU="2"; CONC="1000" ;;
    3) MEM="4Gi"; CPU="4"; CONC="1000" ;;
    *) MEM="2Gi"; CPU="2"; CONC="1000" ;;
  esac
  TIMEOUT="3600"
  MIN_INST="1"
  MAX_INST="1"

  cd "$DIR"

  # ✅ XRAY CONFIG
  cat > config.json <<'EOF'
{
  "log": { "loglevel": "warning" },
  "policy": { "levels": { "0": { "handshake": 1, "connIdle": 86400, "bufferSize": 4194304 } } },
  "inbounds": [
    { "tag":"trojan-ws","port":10001,"listen":"127.0.0.1","protocol":"trojan",
      "settings":{"clients":[{"password":"kiana-2","level":0}]},
      "sniffing":{"enabled":true,"destOverride":["http","tls","quic"],"routeOnly":true},
      "streamSettings":{"network":"ws","wsSettings":{"path":"/tr-ConFig?ed=2560"},
      "sockopt":{"tcpNoDelay":true,"tcpFastOpen":true,"tcpCongestion":"bbr","tcpKeepAliveIdle":300,"tcpKeepAliveInterval":30}}},
    { "tag":"vless-ws","port":10002,"listen":"127.0.0.1","protocol":"vless",
      "settings":{"clients":[{"id":"a1b2c3d4-5678-40ef-98ab-cdef01234567","level":0}],"decryption":"none"},
      "sniffing":{"enabled":true,"destOverride":["http","tls","quic"],"routeOnly":true},
      "streamSettings":{"network":"ws","wsSettings":{"path":"/vl-ConFig?ed=2560"},
      "sockopt":{"tcpNoDelay":true,"tcpFastOpen":true,"tcpCongestion":"bbr","tcpKeepAliveIdle":300,"tcpKeepAliveInterval":30}}}
  ],
  "outbounds":[{"protocol":"freedom","settings":{"domainStrategy":"UseIPv4v6"}}]
}
EOF

  # ✅ NGINX CONFIG
  cat > nginx.conf <<'EOF'
worker_processes auto; worker_rlimit_nofile 65535; worker_priority -10;
events { worker_connections 16384; use epoll; multi_accept on; accept_mutex off; }
http {
  include mime.types; default_type application/octet-stream;
  sendfile on; tcp_nodelay on; tcp_nopush on; keepalive_timeout 86400; keepalive_requests 100000; client_max_body_size 0;
  proxy_buffering off; proxy_request_buffering off; proxy_http_version 1.1; proxy_cache off;
  map $http_upgrade $connection_upgrade { default upgrade; '' close; }
  server {
    listen 8080 reuseport; server_name _;
    location /health { return 200 "OK\n"; add_header Content-Type text/plain; }
    location / { proxy_pass https://www.google.com; proxy_set_header Host www.google.com; }
    location /tr-ConFig { proxy_pass http://127.0.0.1:10001; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_read_timeout 86400; }
    location /vl-ConFig { proxy_pass http://127.0.0.1:10002; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_read_timeout 86400; }
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
RUN apk add --no-cache curl unzip ca-certificates && curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip && unzip -q xray.zip xray geosite.dat geoip.dat && chmod +x xray
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
  gcloud builds submit --project="$PROJECT_ID" --tag gcr.io/$PROJECT_ID/$NAME . --quiet

  echo -e "${CYAN}🚀 Deploying...${NC}"
  gcloud run deploy "$NAME" \
    --image gcr.io/$PROJECT_ID/$NAME --project="$PROJECT_ID" --platform managed --region "$REGION" --allow-unauthenticated \
    --port 8080 --memory "$MEM" --cpu "$CPU" --concurrency "$CONC" --timeout "$TIMEOUT" \
    --min-instances "$MIN_INST" --max-instances "$MAX_INST" --execution-environment gen2 --cpu-boost $BILLING_FLAG --quiet

  URL=$(gcloud run services describe "$NAME" --region "$REGION" --format='value(status.url)')
  DOM=$(echo "$URL" | sed 's|https://||')

  clear
  echo -e "\n${GREEN}✅ SUCCESS!${NC}"
  echo -e "🔗 LINK: $URL"
  echo -e "💚 HEALTH: $URL/health"
  echo -e "\n${CYAN}--- CONFIGS ---${NC}"
  echo -e "${GREEN}TROJAN:${NC} $DOM | 443 | kiana-2 | /tr-ConFig?ed=2560"
  echo -e "${GREEN}VLESS:${NC} $DOM | 443 | a1b2c3d4-5678-40ef-98ab-cdef01234567 | /vl-ConFig?ed=2560"
  read -p "\nPress [Enter]..."
}

# ==============================================
# MAIN MENU
# ==============================================
while true; do
  clear
  echo "===== KIANA-3.2 DEPLOYER ====="
  echo "1) Deploy New Service"
  echo "2) List All Services"
  echo "3) Exit"
  read -p "Select: " OPT
  case $OPT in
    1) deploy_new_service ;;
    2) list_deployed_services ;;
    3) echo -e "\n👋 Bye!"; exit 0 ;;
  esac
done
