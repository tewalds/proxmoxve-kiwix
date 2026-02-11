#!/usr/bin/env bash

# Source the community helper library
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# --- Environment Setup ---
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export DISABLE_LOCALE="y"

# --- Container Variables ---
APP="Kiwix"
var_tags="${var_tags:-documentation;offline}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
PORT=8080

# --- Description (Shown in UI) ---
function description() {
  echo -e "${APP} hosts documentation offline, be that Wikipedia, Gutenberg, or more.
  Requires a pre-downloaded .zim archive from: https://library.kiwix.org
  For Wikipedia specifically, check out: https://github.com/pirate/wikipedia-mirror"
}

# Initialize library
header_info "$APP"
variables
color
catch_errors

# --- Data path ---
echo -e "\n--- ${APP} Configuration ---"
if [ -z "${ZIM_DIR:-}" ]; then
  read -p "Enter the path to your ZIM archives directory: " ZIM_DIR
fi
if [ ! -d "$ZIM_DIR" ]; then
  echo -e "${RD}[!] Error: Directory '$ZIM_DIR' not found.${CL}"
  exit 1
fi
if ! ls "${ZIM_DIR}"/*.zim >/dev/null 2>&1; then
  echo -e "${RD}[!] Error: No .zim files found in '$ZIM_DIR'.${CL}"
  exit 1
fi

# --- Build Sequence ---
start
build_container

# --- Bind Mount Configuration ---
msg_info "Configuring Bind Mount to ${ZIM_DIR}"
if pct set $CTID -features mountidmap=1 2>/dev/null; then
  msg_info "Enabled ID-mapped mounts (ownership preserved)"
  pct set $CTID -mp0 "$ZIM_DIR,mp=/data,ro=1"
  msg_ok "Bind Mount Configured (read-only, ownership preserved)"
else
  msg_info "ID-mapped mounts not available, using standard mount"
  msg_info "Note: Files will appear as nobody:nogroup inside container"
  msg_info "Ensure ZIM files are world-readable: chmod -R a+rX ${ZIM_DIR}"
  pct set $CTID -mp0 "$ZIM_DIR,mp=/data"
  msg_ok "Bind Mount Configured (read-write mount, read-only service)"
fi

# --- Provisioning ---
msg_info "Installing Kiwix-Tools & Setting up Service"
pct exec $CTID -- bash -c "
  export LC_ALL=C
  apt-get update && apt-get install -y kiwix-tools

  cat <<EOF > /etc/systemd/system/kiwix-serve.service
[Unit]
Description=Kiwix ZIM Server
After=network.target

[Service]
Type=simple
# shell/exec to get the * expansion to work.
ExecStart=/bin/sh -c 'exec /usr/bin/kiwix-serve --port $PORT /data/*.zim'
Restart=always
Nice=15

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable --now kiwix-serve
"
msg_ok "$APP is running"

pct set $CTID --onboot 1

IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
msg_ok "Completed Successfully!"

echo -e "\n${BGN}Kiwix is now running!${CL}"
echo -e "${TAB}${GATEWAY} URL: ${BL}http://${IP}:${PORT}${CL}"
echo -e "${TAB}${INFO} CTID: ${GN}${CTID}${CL}"
echo -e "${TAB}${INFO} Storage: Bind-mounted from ${ZIM_DIR}\n"
