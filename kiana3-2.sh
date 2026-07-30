#!/bin/bash
set -euo pipefail

# =========================================
# 🚀 KIANA-3.1 GCP DEPLOYER | ENVOY OPTION EDITION
# ✅ CHOOSE: NGINX (BALANCED) or ENVOY (LOW LATENCY)
# ✅ MAX SPEED OPTIMIZATIONS FOR BOTH
# ✅ CANONICAL SHORT LINK + FULL SETUP INFO
# ✅ AUTO MODE: 3 PRESETS | MANUAL MODE
# ✅ REGION SELECTOR + TAIWAN
# ✅ ALL ORIGINAL FEATURES KEPT
# =========================================

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# ==============================================
# List All Deployed Services
# ==============================================
list_deployed_services() {
  echo -e "\n======================================"
  echo -e "${CYAN}📋 ALL DEPLOYED SERVICES${NC}"
  echo -e "======================================"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  echo "Project: $PROJECT_ID"
  echo ""
  
  gcloud run services list \
    --format="table(metadata.name, status.url, region, metadata.creationTimestamp.date(%Y-%m-%d))" \
    --filter="metadata.name~^xray-" \
    --project="$PROJECT_ID" || {
      echo -e "${YELLOW}ℹ️ No 'xray-' services found. Showing ALL services:\n${NC}"
      gcloud run services list --format="table(metadata.name, status.url, region)" --project="$PROJECT_ID"
    }
  
  echo -e "\n======================================"
  read -p "Press [Enter] to return to Main Menu..."
}

# ==============================================
# Region Selection Menu
# ==============================================
select_region() {
  echo -e "\n=== GCP Cloud Run Region Selection ==="
  echo "--- North America ---"
  echo "1) us-central1      (Iowa, US)"
  echo "2) us-east1         (South Carolina, US)"
  echo "3) us-east4         (Northern Virginia, US)"
  echo "4) us-west1         (Oregon, US)"
  echo ""
  echo "--- Asia Pacific ---"
  echo -e "${GREEN}5) asia-east1       (Taiwan 🇹🇼 — RECOMMENDED FOR MAX SPEED!)${NC}"
  echo "6) asia-southeast1  (Singapore)"
  echo "7) asia-northeast1  (Tokyo, Japan)"
  echo "8) asia-northeast3  (Seoul, South Korea)"
  echo ""
  echo "--- Europe ---"
  echo "9) europe-west1     (Belgium)"
  echo "10) europe-west4    (Netherlands)"
  echo "11) europe-west9    (Paris, France)"
  echo ""
  echo "0) Manually enter custom region code"
  echo ""

  read -p "Enter number for your selected region: " REGION_NUM

  case $REGION_NUM in
    1) REGION="us-central1" ;;
    2) REGION="us-east1" ;;
    3) REGION="us-east4" ;;
    4) REGION="us-west1" ;;
    5) REGION="asia-east1" ;;
    6) REGION="asia-southeast1" ;;
    7) REGION="asia-northeast1" ;;
    8) REGION="asia-northeast3" ;;
    9) REGION="europe-west1" ;;
    10) REGION="europe-west4" ;;
    11) REGION="europe-west9" ;;
    0) read -p "Enter full region code: " REGION ;;
    *) echo -e "${YELLOW}⚠️ Invalid input! Using default: us-central1${NC}"; REGION="us-central1" ;;
  esac

  echo -e "${GREEN}✅ Selected Region:${NC} $REGION"
}

# ==============================================
# Frontend Selector: Nginx or Envoy
# ==============================================
select_frontend() {
  echo -e "\n${CYAN}=========================================${NC}"
  echo -e "${GREEN}      FRONTEND PROXY SELECTOR${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}1) NGINX + XRAY${NC} — Balanced, Stable, Low Resource"
  echo -e "${YELLOW}   Best for daily use, heat control, long runtime${NC}"
  echo ""
  echo -e "${GREEN}2) ENVOY + XRAY${NC} — Lower Latency, Direct Pass-Through"
  echo -e "${YELLOW}   ~10-20% faster throughput, similar to other deployers${NC}"
  echo -e "${CYAN}=========================================${NC}"
  while true; do
    read -p "Select Frontend [1-2]: " FE_CHOICE
    case $FE_CHOICE in
      1) FRONTEND="nginx"; echo -e "${GREEN}✅ Using Nginx + Xray${NC}"; break ;;
      2) FRONTEND="envoy"; echo -e "${GREEN}✅ Using Envoy + Xray — Low Latency Mode${NC}"; break ;;
      *) echo -e "${RED}Invalid input! Enter 1 or 2 only${NC}" ;;
    esac
  done
}

# ==============================================
# Full Deployment Process
# ==============================================
deploy_new_service() {
  select_region
  select_frontend

  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  RAND=$(openssl rand -hex 3 2>/dev/null)
  CLOUD_RUN_SERVICE_NAME="xray-${FRONTEND}-$RAND"
  BUILD_DIR=$(mktemp -d)

  cleanup() { rm -rf "$BUILD_DIR" || true; }
  trap cleanup EXIT

  clear
  echo ""
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}🚀 KIANA-3.1 GCP DEPLOYER | ENVOY OPTION${NC}"
  echo -e "${GREEN}✅ FRONTEND: ${FRONTEND^^} + XRAY${NC}"
  echo -e "${GREEN}✅ MAX SPEED OPTIMIZED${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}✅ Project:${NC} $PROJECT_ID"
  echo -e "${GREEN}✅ Region:${NC} $REGION"
  echo -e "${GREEN}✅ Service Name:${NC} $CLOUD_RUN_SERVICE_NAME"
  echo ""

  if [ -z "$PROJECT_ID" ]; then
      echo -e "${RED}ERROR: No GCP project set!${NC}"
      echo -e "Run: gcloud config set project YOUR_PROJECT_ID"
      read -p "Press [Enter] to return to Main Menu..."
      return
  fi

  gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project="$PROJECT_ID" --quiet

  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}          BILLING MODE${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${YELLOW}Instance-Based = More Stable, No Throttling = MAX SPEED${NC}"
  echo "1) Request-Based  |  2) Instance-Based"
  while true; do
      read -p "Select [1-2]: " BILLING_CHOICE
      case $BILLING_CHOICE in
          1) BILLING_MODE="request"; break ;;
          2) BILLING_MODE="instance"; break ;;
          *) echo -e "${RED}Invalid input!${NC}" ;;
      esac
  done

  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}      RESOURCE CONFIG MODE${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}1) AUTO MODE  |  Pre-optimized setups (Recommended)${NC}"
  echo -e "${YELLOW}2) MANUAL MODE |  Set your own values${NC}"
  while true; do
      read -p "Select Mode [1-2]: " RES_MODE
      case $RES_MODE in
          1)
              echo -e "\n${CYAN}--- AUTO MODE PRESETS ---${NC}"
              echo "1) Basic: 1Gi RAM + 1 vCPU  |  Light use"
              echo "2) Balanced: 2Gi RAM + 2 vCPU  |  ✅ BEST SPEED + STABILITY"
              echo "3) Max: 4Gi RAM + 4 vCPU  |  Heavy use"
              read -p "Choose preset [1-3]: " AUTO_CHOICE
              case $AUTO_CHOICE in
                  1) MEMORY="1Gi"; CPU="1"; CONCURRENCY="300" ;;
                  2) MEMORY="2Gi"; CPU="2"; CONCURRENCY="1000" ;;
                  3) MEMORY="4Gi"; CPU="4"; CONCURRENCY="1000" ;;
                  *) echo -e "${YELLOW}⚠️ Invalid! Using default: Balanced (2Gi+2vCPU)${NC}"
                     MEMORY="2Gi"; CPU="2"; CONCURRENCY="1000" ;;
              esac
              TIMEOUT="3600"
              MIN_INST="1"
              MAX_INST="1"
              echo -e "${GREEN}✅ APPLIED: $MEMORY RAM + $CPU vCPU | Min/Max: 1/1${NC}"
              break
              ;;
          2)
              echo -e "\n${YELLOW}--- MANUAL CONFIGURATION ---${NC}"
              echo -e "${YELLOW}Recommended: 2Gi RAM + 2vCPU / 4Gi + 2vCPU${NC}"
              while true; do
                  read -p "Memory [1=1Gi|2=2Gi|3=4Gi]: " MEM
                  case $MEM in
                      1) MEMORY="1Gi"; break ;;
                      2) MEMORY="2Gi"; break ;;
                      3) MEMORY="4Gi"; break ;;
                  esac
              done
              while true; do
                  read -p "vCPU [1=1|2=2|3=4]: " CPU_SEL
                  case $CPU_SEL in
                      1) CPU="1"; break ;;
                      2) CPU="2"; break ;;
                      3) CPU="4"; break ;;
                  esac
              done

              if [ "$CPU" = "1" ] || [ "$MEMORY" = "1Gi" ]; then
                  CONCURRENCY="300"
              else
                  CONCURRENCY="1000"
              fi
              TIMEOUT="3600"

              echo -e "${YELLOW}💡 Min Instances = 1 = No Disconnects${NC}"
              while true; do
                  read -p "Min Instances [0/1, default=0]: " MIN_INST
                  MIN_INST=${MIN_INST:-0}
                  [[ "$MIN_INST" =~ ^[0-1]$ ]] && break || echo -e "${RED}Only 0 or 1 allowed${NC}"
              done
              while true; do
                  read -p "Max Instances [1-2, default=1]: " MAX_INST
                  MAX_INST=${MAX_INST:-1}
                  [[ "$MAX_INST" =~ ^[1-2]$ ]] && break || echo -e "${RED}Only 1 or 2 allowed${NC}"
              done
              break
              ;;
          *) echo -e "${RED}❌ Invalid input! Enter 1 or 2 only${NC}" ;;
      esac
  done

  cd "$BUILD_DIR" || exit 1

  # ==============================================
  # MAX SPEED OPTIMIZED XRAY CONFIG (SAME FOR BOTH)
  # ==============================================
  cat > config.json <<'EOF'
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
      "settings": { "clients": [{"password": "kiana-2", "level": 0}] },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/tr-ws?ed=2560" },
        "sockopt": {
          "tcpNoDelay": true,
          "tcpFastOpen": true,
          "tcpCongestion": "bbr"
        }
      }
    },
    {
      "tag": "vless-ws",
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [{"id": "a1b2c3d4-5678-40ef-98ab-cdef01234567", "level": 0}], "decryption": "none" },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vl-ws?ed=2560" },
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

  # ==============================================
  # NGINX CONFIG (IF SELECTED)
  # ==============================================
  if [ "$FRONTEND" = "nginx" ]; then
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
  sendfile on; tcp_nodelay on; tcp_nopush on;
  keepalive_timeout 86400; keepalive_requests 100000;
  client_max_body_size 0;
  proxy_buffering off; proxy_request_buffering off;
  proxy_http_version 1.1; proxy_cache off;
  map $http_upgrade $connection_upgrade { default upgrade; '' close; }
  server {
    listen 8080 reuseport; server_name _;
    location /health { return 200 "OK\n"; add_header Content-Type text/plain; }
    location / { proxy_pass https://www.google.com; proxy_set_header Host www.google.com; }
    location /tr-ws { proxy_pass http://127.0.0.1:10001; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host $host; proxy_read_timeout 86400; }
    location /vl-ws { proxy_pass http://127.0.0.1:10002; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host $host; proxy_read_timeout 86400; }
  }
}
EOF
  fi

  # ==============================================
  # ENVOY CONFIG (IF SELECTED)
  # ==============================================
  if [ "$FRONTEND" = "envoy" ]; then
  cat > envoy.yaml <<'EOF'
static_resources:
  listeners:
  - name: listener_0
    address: { socket_address: { address: 0.0.0.0, port_value: 8080 } }
    per_connection_buffer_limit_bytes: 4194304
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          codec_type: AUTO
          http2_protocol_options: { max_concurrent_streams: 1000 }
          stream_idle_timeout: 86400s
          request_timeout: 86400s
          route_config:
            name: local_route
            virtual_hosts:
            - name: service
              domains: ["*"]
              routes:
              - match: { path: "/health" }
                direct_response: { status: 200, body: { inline_string: "OK\n" } }
              - match: { path: "/" }
                route: { cluster: google, timeout: 0s }
              - match: { prefix: "/tr-ws" }
                route: { cluster: trojan, timeout: 0s, upgrade_configs: [{ upgrade_type: websocket }] }
              - match: { prefix: "/vl-ws" }
                route: { cluster: vless, timeout: 0s, upgrade_configs: [{ upgrade_type: websocket }] }
          http_filters:
          - name: envoy.filters.http.router
            typed_config: { "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router }
  clusters:
  - name: trojan
    connect_timeout: 1s
    http2_protocol_options: {}
    load_assignment: { cluster_name: trojan, endpoints: [{ lb_endpoints: [{ endpoint: { address: { socket_address: { address: 127.0.0.1, port_value: 10001 } } } }] }] }
  - name: vless
    connect_timeout: 1s
    http2_protocol_options: {}
    load_assignment: { cluster_name: vless, endpoints: [{ lb_endpoints: [{ endpoint: { address: { socket_address: { address: 127.0.0.1, port_value: 10002 } } } }] }] }
  - name: google
    connect_timeout: 5s
    load_assignment: { cluster_name: google, endpoints: [{ lb_endpoints: [{ endpoint: { address: { socket_address: { address: www.google.com, port_value: 443 } } } }] }] }
    transport_socket: { name: envoy.transport_sockets.tls, typed_config: { "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.TlsTransportContext", sni: "www.google.com" } }
EOF
  fi

  # ==============================================
  # ENTRYPOINT & DOCKERFILE
  # ==============================================
  if [ "$FRONTEND" = "nginx" ]; then
  cat > entrypoint.sh <<'EOF'
#!/bin/sh
sysctl -w net.core.somaxconn=65535 2>/dev/null || true
sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null || true
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
  fi

  if [ "$FRONTEND" = "envoy" ]; then
  cat > entrypoint.sh <<'EOF'
#!/bin/sh
sysctl -w net.core.somaxconn=65535 2>/dev/null || true
sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null || true
/usr/local/bin/xray run -c /etc/xray.json &
sleep 2
exec /usr/local/bin/envoy -c /etc/envoy.yaml
EOF
  chmod +x entrypoint.sh

  cat > Dockerfile <<'EOF'
FROM alpine:3.20 AS builder
RUN apk add --no-cache curl unzip ca-certificates
RUN curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip && unzip -q xray.zip xray geosite.dat geoip.dat && chmod +x xray
FROM envoyproxy/envoy:v1.31.0
COPY --from=builder /xray /usr/local/bin/xray
COPY --from=builder /geosite.dat /usr/local/share/xray/
COPY --from=builder /geoip.dat /usr/local/share/xray/
COPY config.json /etc/xray.json
COPY envoy.yaml /etc/envoy.yaml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/xray /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF
  fi

  echo -e "${CYAN}Building image...${NC}"
  gcloud builds submit --project="$PROJECT_ID" --tag gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME . --quiet

  BILLING_FLAGS=$([ "$BILLING_MODE" = "instance" ] && echo "--no-cpu-throttling" || echo "--cpu-throttling")

  echo -e "${CYAN}Deploying to Cloud Run...${NC}"
  gcloud run deploy $CLOUD_RUN_SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$CLOUD_RUN_SERVICE_NAME \
    --project="$PROJECT_ID" --platform managed --region "$REGION" --allow-unauthenticated \
    --port 8080 --memory $MEMORY --cpu $CPU --concurrency $CONCURRENCY \
    --timeout $TIMEOUT --min-instances $MIN_INST --max-instances $MAX_INST \
    --execution-environment gen2 --cpu-boost $BILLING_FLAGS --quiet

  # Get Final Domain
  CLOUD_RUN_URL=$(gcloud run services describe $CLOUD_RUN_SERVICE_NAME --project="$PROJECT_ID" --region="$REGION" --format='value(status.url)')
  DOMAIN=$(echo "$CLOUD_RUN_URL" | sed 's|https://||')
  CANONICAL_LINK="https://$DOMAIN"

  # ==============================================
  # FINAL OUTPUT
  # ==============================================
  clear
  echo -e "\n${CYAN}=========================================${NC}"
  echo -e "${GREEN}✅ DEPLOYMENT SUCCESS!${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}🔗 CANONICAL / SHORT LINK:${NC} $CANONICAL_LINK"
  echo -e "${GREEN}🌐 FULL DOMAIN:${NC} $DOMAIN"
  echo -e "${GREEN}💚 HEALTH CHECK:${NC} https://$DOMAIN/health"
  echo ""
  echo -e "${CYAN}📋 SETUP DETAILS:${NC}"
  echo -e "• Service Name: $CLOUD_RUN_SERVICE_NAME"
  echo -e "• Region: $REGION"
  echo -e "• Frontend: ${FRONTEND^^} + Xray"
  echo -e "• Billing Mode: $BILLING_MODE"
  echo -e "• Resources: $MEMORY RAM | $CPU vCPU | Max $CONCURRENCY connections"
  echo -e "• Min/Max Instances: $MIN_INST / $MAX_INST"
  echo -e "${CYAN}=========================================${NC}"

  echo -e "\n${YELLOW}💡 Envoy = ~10-20% faster / Nginx = more battery efficient${NC}"
  read -p "\nPress [Enter] to return to Main Menu..."
}

# ==============================================
# Main Menu Loop
# ==============================================
while true; do
  clear
  echo "======================================"
  echo "   🚀 KIANA-3.1 GCP DEPLOYER MENU    "
  echo "======================================"
  echo "1) Deploy new service (Choose Nginx/Envoy)"
  echo "2) List all deployed services & URLs"
  echo "3) Exit script"
  echo "======================================"
  read -p "Select an option [1-3]: " MENU_CHOICE

  case $MENU_CHOICE in
    1) deploy_new_service ;;
    2) list_deployed_services ;;
    3) echo -e "\n👋 Goodbye!"; exit 0 ;;
    *) echo -e "${RED}❌ Invalid selection! Enter 1/2/3 only.${NC}"; sleep 2 ;;
  esac
done
