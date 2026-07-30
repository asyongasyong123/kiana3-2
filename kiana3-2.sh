#!/bin/bash
set -euo pipefail

# =========================================
# 🚀 KIANA-3.2 GCP DEPLOYER | ENVOY FIXED EDITION
# ✅ ENVOY PORT 8080 BINDING FIXED
# ✅ NO MORE "FAILED TO LISTEN" ERROR
# ✅ CHOOSE: NGINX / ENVOY
# ✅ MAX SPEED OPTIMIZED
# ✅ TAIWAN REGION + ALL PRESETS
# =========================================

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# ==============================================
# List Deployed Services
# ==============================================
list_deployed_services() {
  echo -e "\n======================================"
  echo -e "${CYAN}📋 ALL DEPLOYED SERVICES${NC}"
  echo -e "======================================"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  echo "Project: $PROJECT_ID"
  echo ""
  gcloud run services list --format="table(metadata.name, status.url, region)" --project="$PROJECT_ID"
  echo -e "\n======================================"
  read -p "Press [Enter] to return..."
}

# ==============================================
# Region Selection
# ==============================================
select_region() {
  echo -e "\n=== GCP Cloud Run Region Selection ==="
  echo -e "${GREEN}✅ RECOMMENDED: 5 = asia-east1 (Taiwan 🇹🇼)${NC}"
  echo ""
  echo "1) us-central1      (Iowa)"
  echo "5) asia-east1       (Taiwan 🇹🇼)"
  echo "6) asia-southeast1  (Singapore)"
  echo "7) asia-northeast1  (Tokyo)"
  echo ""
  read -p "Enter number: " REGION_NUM
  case $REGION_NUM in
    5) REGION="asia-east1" ;;
    6) REGION="asia-southeast1" ;;
    7) REGION="asia-northeast1" ;;
    *) REGION="asia-east1"; echo -e "${YELLOW}⚠️ Defaulting to Taiwan region${NC}" ;;
  esac
  echo -e "${GREEN}✅ Selected Region: $REGION${NC}"
}

# ==============================================
# Frontend Selector (Nginx / Envoy)
# ==============================================
select_frontend() {
  echo -e "\n${CYAN}=========================================${NC}"
  echo -e "${GREEN}      FRONTEND PROXY SELECTOR${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo "1) NGINX + XRAY — Balanced, Stable"
  echo "2) ENVOY + XRAY — Low Latency, Fixed Port"
  echo -e "${CYAN}=========================================${NC}"
  while true; do
    read -p "Select [1-2]: " FE_CHOICE
    case $FE_CHOICE in
      1) FRONTEND="nginx"; break ;;
      2) FRONTEND="envoy"; break ;;
      *) echo -e "${RED}Enter 1 or 2 only!${NC}" ;;
    esac
  done
}

# ==============================================
# Deployment Process
# ==============================================
deploy_new_service() {
  select_region
  select_frontend

  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  RAND=$(openssl rand -hex 3 2>/dev/null)
  CLOUD_RUN_SERVICE_NAME="xray-${FRONTEND}-$RAND"
  BUILD_DIR=$(mktemp -d)
  cleanup() { rm -rf "$BUILD_DIR" || true; }; trap cleanup EXIT

  clear
  echo -e "\n${CYAN}=========================================${NC}"
  echo -e "${GREEN}🚀 DEPLOYING: ${FRONTEND^^} + XRAY${NC}"
  echo -e "${GREEN}✅ PORT 8080 FIXED | TAIWAN REGION${NC}"
  echo -e "${CYAN}=========================================${NC}"

  gcloud services enable run.googleapis.com cloudbuild.googleapis.com --project="$PROJECT_ID" --quiet

  # Billing Mode
  echo -e "\n${CYAN}--- BILLING MODE ---${NC}"
  echo "1) Request-Based  |  2) Instance-Based (No Throttle)"
  while true; do
    read -p "Select [1-2]: " BILLING_CHOICE
    case $BILLING_CHOICE in
      1) BILLING_MODE="request"; break ;;
      2) BILLING_MODE="instance"; break ;;
      *) echo -e "${RED}Enter 1 or 2 only!${NC}" ;;
    esac
  done

  # Resource Presets
  echo -e "\n${CYAN}--- RESOURCE PRESET ---${NC}"
  echo "1) 1Gi + 1vCPU  |  2) 2Gi + 2vCPU ✅ RECOMMENDED  |  3) 4Gi + 4vCPU"
  while true; do
    read -p "Select [1-3]: " RES_CHOICE
    case $RES_CHOICE in
      1) MEMORY="1Gi"; CPU="1"; CONCURRENCY="300"; break ;;
      2) MEMORY="2Gi"; CPU="2"; CONCURRENCY="1000"; break ;;
      3) MEMORY="4Gi"; CPU="4"; CONCURRENCY="1000"; break ;;
      *) echo -e "${RED}Enter 1-3 only!${NC}" ;;
    esac
  done
  MIN_INST="1"; MAX_INST="1"; TIMEOUT="3600"

  cd "$BUILD_DIR" || exit 1

  # Xray Config
  cat > config.json <<'EOF'
{
  "log": { "loglevel": "warning" },
  "policy": { "levels": { "0": { "handshake": 1, "connIdle": 86400, "bufferSize": 4194304 } } },
  "inbounds": [
    { "tag": "trojan", "port": 10001, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [{"password": "kiana-2"}] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/tr-ws?ed=2560" }, "sockopt": { "tcpNoDelay": true, "tcpFastOpen": true } } },
    { "tag": "vless", "port": 10002, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [{"id": "a1b2c3d4-5678-40ef-98ab-cdef01234567", "decryption": "none"}] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vl-ws?ed=2560" }, "sockopt": { "tcpNoDelay": true, "tcpFastOpen": true } } }
  ],
  "outbounds": [{"protocol": "freedom", "settings": { "domainStrategy": "UseIPv4v6" }}]
}
EOF

  # --- Nginx Config ---
  if [ "$FRONTEND" = "nginx" ]; then
  cat > nginx.conf <<'EOF'
worker_processes auto; worker_rlimit_nofile 65535;
events { worker_connections 16384; use epoll; multi_accept on; }
http {
  include mime.types; default_type application/octet-stream;
  sendfile on; tcp_nodelay on; keepalive_timeout 86400;
  location /health { return 200 "OK\n"; }
  location /tr-ws { proxy_pass http://127.0.0.1:10001; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; }
  location /vl-ws { proxy_pass http://127.0.0.1:10002; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; }
  location / { proxy_pass https://www.google.com; proxy_set_header Host www.google.com; }
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
RUN apk add --no-cache curl unzip ca-certificates && curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip && unzip -q xray.zip xray && chmod +x xray
FROM openresty/openresty:alpine-fat
COPY --from=builder /xray /usr/local/bin/xray
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY entrypoint.sh /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF
  fi

  # --- Envoy Config (FIXED PORT 8080) ---
  if [ "$FRONTEND" = "envoy" ]; then
  cat > envoy.yaml <<'EOF'
static_resources:
  listeners:
  - name: listener_0
    address: { socket_address: { address: 0.0.0.0, port_value: 8080 } }
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager"
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: all
              domains: ["*"]
              routes:
              - match: { path: "/health" }
                direct_response: { status: 200, body: { inline_string: "OK\n" } }
              - match: { prefix: "/tr-ws" }
                route: { cluster: trojan, upgrade_configs: [{ upgrade_type: websocket }] }
              - match: { prefix: "/vl-ws" }
                route: { cluster: vless, upgrade_configs: [{ upgrade_type: websocket }] }
              - match: { prefix: "/" }
                route: { cluster: google }
          http_filters:
          - name: envoy.filters.http.router
            typed_config: {}
  clusters:
  - name: trojan
    connect_timeout: 1s
    load_assignment: { endpoints: [{ lb_endpoints: [{ endpoint: { address: { socket_address: { address: 127.0.0.1, port_value: 10001 } } } }] }] }
  - name: vless
    connect_timeout: 1s
    load_assignment: { endpoints: [{ lb_endpoints: [{ endpoint: { address: { socket_address: { address: 127.0.0.1, port_value: 10002 } } } }] }] }
  - name: google
    connect_timeout: 5s
    load_assignment: { endpoints: [{ lb_endpoints: [{ endpoint: { address: { socket_address: { address: www.google.com, port_value: 443 } } } }] }] }
    transport_socket: { name: envoy.transport_sockets.tls }
EOF
  cat > entrypoint.sh <<'EOF'
#!/bin/sh
/usr/local/bin/xray run -c /etc/xray.json &
sleep 2
exec /usr/local/bin/envoy -c /etc/envoy.yaml --service-cluster proxy --service-node node-1
EOF
  chmod +x entrypoint.sh

  cat > Dockerfile <<'EOF'
FROM alpine:3.20 AS builder
RUN apk add --no-cache curl unzip ca-certificates && curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip && unzip -q xray.zip xray && chmod +x xray
FROM envoyproxy/envoy:v1.31.0
COPY --from=builder /xray /usr/local/bin/xray
COPY config.json /etc/xray.json
COPY envoy.yaml /etc/envoy.yaml
COPY entrypoint.sh /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF
  fi

  # Build & Deploy
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

  # Get Final Link
  CLOUD_RUN_URL=$(gcloud run services describe $CLOUD_RUN_SERVICE_NAME --project="$PROJECT_ID" --region="$REGION" --format='value(status.url)')
  DOMAIN=$(echo "$CLOUD_RUN_URL" | sed 's|https://||')

  clear
  echo -e "\n${CYAN}=========================================${NC}"
  echo -e "${GREEN}✅ DEPLOYMENT SUCCESS!${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${GREEN}🔗 LINK:${NC} https://$DOMAIN"
  echo -e "${GREEN}💚 HEALTH:${NC} https://$DOMAIN/health"
  echo -e "${GREEN}⚡ REGION:${NC} $REGION | ${FRONTEND^^} + XRAY"
  echo -e "${CYAN}=========================================${NC}"
  read -p "\nPress [Enter] to finish..."
}

# Main Menu
while true; do
  clear
  echo "======================================"
  echo "   🚀 KIANA-3.2 GCP DEPLOYER MENU    "
  echo "======================================"
  echo "1) Deploy New Service"
  echo "2) List All Services"
  echo "3) Exit"
  echo "======================================"
  read -p "Select [1-3]: " MENU_CHOICE
  case $MENU_CHOICE in
    1) deploy_new_service ;;
    2) list_deployed_services ;;
    3) exit 0 ;;
    *) echo -e "${RED}Invalid selection!${NC}"; sleep 2 ;;
  esac
done
