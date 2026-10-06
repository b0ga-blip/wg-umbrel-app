#!/usr/bin/env bash
# render-wg0.sh — Genera /config/wg_confs/wg0.conf a partir de las variables
# de entorno de la app, editables en umbrelOS:
#   Ajustes → App settings → "WireGuard Mesh" → Advanced → Environment variables
#
# Modos (por orden de prioridad):
#   1. ENV (recomendado, comunidad): WG_ENDPOINT y WG_SERVER_PUBKEY definidas
#      → renderiza wg0.conf en cada arranque a partir de las variables.
#   2. MANUAL: sin variables de entorno → respeta un wg0.conf existente
#      (colocado a mano o migrado por el hook pre-start desde el path legacy).
#   3. TEMPLATE: sin variables y sin wg0.conf → escribe una plantilla con
#      instrucciones.
set -euo pipefail

CONF_DIR="/config/wg_confs"
CONF="${CONF_DIR}/wg0.conf"
KEYFILE="/config/privatekey"

log() { echo "[render-wg0] $*"; }

mkdir -p "${CONF_DIR}"

# ---------------------------------------------------------------- Modo 1: ENV
if [[ -n "${WG_ENDPOINT:-}" && -n "${WG_SERVER_PUBKEY:-}" ]]; then
  if [[ -z "${WG_ADDRESS:-}" ]]; then
    log "ERROR: WG_ADDRESS vacía. Pon la IP de este peer dentro de la malla (p. ej. 10.100.0.2/32) en Ajustes → App settings → Advanced → Environment variables."
    exit 1
  fi

  PRIVATE_KEY="${WG_PRIVATE_KEY:-}"
  if [[ -z "${PRIVATE_KEY}" ]]; then
    if [[ -f "${KEYFILE}" ]]; then
      PRIVATE_KEY=$(tr -d '\n' < "${KEYFILE}")
    else
      PRIVATE_KEY=$(wg genkey)
      umask 077
      printf '%s\n' "${PRIVATE_KEY}" > "${KEYFILE}"
      chmod 600 "${KEYFILE}"
      log "Clave privada generada y persistida en ${KEYFILE} (no se publica nunca)"
    fi
  fi

  {
    echo "[Interface]"
    echo "PrivateKey = ${PRIVATE_KEY}"
    echo "Address = ${WG_ADDRESS}"
    if [[ -n "${WG_DNS:-}" ]]; then
      echo "DNS = ${WG_DNS}"
    fi
    if [[ -n "${WG_MTU:-}" ]]; then
      echo "MTU = ${WG_MTU}"
    fi
    echo ""
    echo "[Peer]"
    echo "PublicKey = ${WG_SERVER_PUBKEY}"
    echo "Endpoint = ${WG_ENDPOINT}"
    echo "AllowedIPs = ${WG_ALLOWED_IPS:-0.0.0.0/0, ::/0}"
    echo "PersistentKeepalive = ${WG_KEEPALIVE:-25}"
    if [[ -n "${WG_PRESHARED_KEY:-}" ]]; then
      echo "PresharedKey = ${WG_PRESHARED_KEY}"
    fi
  } > "${CONF}"
  chmod 600 "${CONF}"
  fix_ownership() {
    if [[ "$(id -u)" = "0" && -n "${PUID:-}" && -n "${PGID:-}" ]]; then
      chown "${PUID}:${PGID}" "${CONF}" "${CONF_DIR}" "${KEYFILE}" 2>/dev/null || true
    fi
  }
  fix_ownership
  log "wg0.conf generado desde variables de entorno (${WG_ENDPOINT})"
  exit 0
fi

# --------------------------------------------------------------- Modo 2: MANUAL
if [[ -f "${CONF}" ]]; then
  log "wg0.conf existente: se respeta (config manual o migrada)"
  exit 0
fi

# ------------------------------------------------------------- Modo 3: TEMPLATE
cat > "${CONF}" <<'TEMPLATE'
# =============================================================================
# WireGuard Mesh — configuración pendiente
# =============================================================================
# Esta plantilla se genera en el primer arranque cuando no hay configuración.
# Dos formas de configurar el túnel:
#
# 1) RECOMENDADA — Variables de entorno (sin tocar archivos):
#    Ajustes → App settings → "WireGuard Mesh" → Advanced → Environment variables
#    Define al menos:
#      WG_ADDRESS        IP de este peer dentro de la malla (p. ej. 10.100.0.2/32)
#      WG_ENDPOINT       Host:puerto del hub (p. ej. vpn.ejemplo.com:51820)
#      WG_SERVER_PUBKEY  Clave pública del hub (salida de `wg show` en el servidor)
#    Opcionales: WG_DNS, WG_ALLOWED_IPS, WG_PRESHARED_KEY, WG_KEEPALIVE,
#    WG_MTU, WG_PRIVATE_KEY (por defecto se genera y persiste en /config/privatekey)
#    Tras cambiar las variables, reinicia la app.
#
# 2) MANUAL — Sustituye este archivo por tu wg0.conf y reinicia la app
#    (deja WG_ENDPOINT y WG_SERVER_PUBKEY vacías).
#    La clave privada NUNCA debe publicarse ni compartirse.
# =============================================================================
TEMPLATE
log "Plantilla escrita en ${CONF}: faltan WG_ENDPOINT y WG_SERVER_PUBKEY"
