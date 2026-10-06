# WireGuard Mesh — app para umbrelOS

**Cliente WireGuard** que conecta tu Umbrel como *peer* de una **malla privada** existente: un túnel punto a punto hacia un hub/servidor WireGuard que ya tengas montado (un VPS, un router, otro server…).

⚠️ Esta app **no es un servidor VPN** para tus dispositivos. Si quieres montar un servidor WireGuard con interfaz web en tu Umbrel, usa la app oficial **"WireGuard" (wg-easy)** del App Store de Umbrel.

---

## ✨ Qué hace

- Levanta la interfaz `wg0` en el **host** del Umbrel (`network_mode: host`), como un peer más de tu malla.
- **Sin tocar archivos**: toda la configuración se hace con variables de entorno editables desde la UI de umbrelOS.
- **Genera la clave privada automáticamente** y la persiste en los datos de la app (nunca viaja por GitHub ni se muestra en la UI).
- **Página de estado** con el handshake, el tráfico y la **clave pública del peer** (para registrarla en el hub).
- Basada en la imagen oficial `linuxserver/wireguard`.

## 📋 Requisitos

1. Un **hub WireGuard** ya funcionando (servidor con una IP pública o dominio, puerto UDP abierto, y acceso para añadir peers).
2. Los datos de tu hub (cómo obtenerlos abajo).
3. umbrelOS (cualquier versión 1.x reciente).

## 🚀 Instalación

1. En la UI de Umbrel: **App Store** → los **tres puntos** (⋮) arriba a la derecha → **Community App Store**.
2. Añade este repositorio: `https://github.com/b0ga-blip/wg-umbrel-app`
3. Busca **WireGuard Mesh** e instálala.

## ⚙️ Configuración

Todo se configura con variables de entorno desde la UI:

**Ajustes → App settings → "WireGuard Mesh" → Advanced → Environment variables**

| Variable | Obligatoria | Descripción | Ejemplo |
|---|---|---|---|
| `WG_ADDRESS` | ✅ | IP de este peer dentro de la malla (con prefijo) | `10.13.13.2/32` |
| `WG_ENDPOINT` | ✅ | Host y puerto UDP del hub | `vpn.midominio.com:51820` |
| `WG_SERVER_PUBKEY` | ✅ | Clave pública del hub | `abc123...xyz=` |
| `WG_ALLOWED_IPS` | — | Subredes que se enrutan por el túnel (por defecto todo: `0.0.0.0/0, ::/0`; en una malla pon solo el rango de la malla, p. ej. `10.13.13.0/24`) | `10.13.13.0/24` |
| `WG_DNS` | — | Servidor DNS a usar dentro del túnel | `10.13.13.1` |
| `WG_KEEPALIVE` | — | Keepalive en segundos (recomendado detrás de NAT) | `25` |
| `WG_PRESHARED_KEY` | — | Clave precompartida, solo si el hub la exige | `...` |
| `WG_MTU` | — | MTU manual (por defecto la detecta WireGuard) | `1420` |
| `WG_PRIVATE_KEY` | — | **Avanzado**: clave privada fija. Vacía = se genera automáticamente y se guarda en `/config/privatekey` | `...` |

> 💡 `PUID=1000`, `PGID=1000` y `TZ=Europe/Madrid` también aparecen en la lista; déjalas como están salvo que sepas lo que haces.

Guarda los cambios y **reinicia la app** (App settings → ⋮ → Restart, o desde el dashboard). La app genera `wg0.conf` en cada arranque a partir de estas variables.

### Obtener los datos de tu hub

Ejecuta en el servidor WireGuard (el hub):

```bash
sudo wg show
```

Ahí verás:

- **Clave pública del hub** → valor para `WG_SERVER_PUBKEY` (campo *public key* de la interfaz, no de los peers).
- **Endpoint** → `IP_o_dominio:puerto` (el `ListenPort` del hub) → valor para `WG_ENDPOINT`.
- La IP que le hayas reservado a este peer en el rango de la malla → `WG_ADDRESS`.

### Registrar este peer en el hub

La página de estado de la app (`https://<tu-umbrel>.local:51822/`, o desde el dashboard al abrir la app) muestra la **clave pública de este peer**. En el hub, añádela (ejemplo con `wg`):

```bash
sudo wg set wg0 peer <CLAVE_PUBLICA_DE_ESTE_PEER> allowed-ips 10.13.13.2/32
# y para que sobreviva a reinicios, añádela también al [Peer] de tu wg0.conf del hub
```

Una vez registrada, el handshake aparece en la página de estado.

## 🔧 Configuración manual (avanzado)

Si prefieres traer tu propio `wg0.conf` (por ejemplo, uno exportado por otra herramienta):

1. Deja `WG_ENDPOINT` y `WG_SERVER_PUBKEY` **vacías** en las variables de entorno.
2. Coloca tu `wg0.conf` en el directorio de datos de la app: `.../app-data/wg-mesh/data/wg_confs/wg0.conf` (accesible con el explorador de archivos de umbrelOS o por SSH).
3. Reinicia la app. Tu archivo se respeta tal cual, sin sobrescribir.

> Si no hay ninguna configuración, la app crea una **plantilla** con estas instrucciones en `wg_confs/wg0.conf` en el primer arranque.

## 🔒 Seguridad

- **La clave privada nunca se publica ni se sube a GitHub**: se genera localmente y vive solo en los datos de la app (`/config/privatekey` y `wg0.conf`).
- Este repositorio no contiene ni debe contener claves, IPs ni configuraciones reales (`.gitignore` excluye `*.conf`, `*.key`, `*.pem`, `*private*`, `.env`).
- La página de estado solo muestra la salida de `wg show` y la clave pública — nunca claves privadas.
- Cambia `WG_PRIVATE_KEY` (o borra `/config/privatekey`) solo si sabes que debes regenerar el par de claves, y recuerda actualizar el peer en el hub.

## 🛠️ Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| La página de estado dice "wg0 no está activa" | Faltan datos de configuración | Revisa `WG_ENDPOINT`, `WG_SERVER_PUBKEY` y `WG_ADDRESS`; mira los logs de la app |
| `wg show` sale vacío en el hub (sin handshake) | El peer no está registrado en el hub, o `AllowedIPs` del hub no coincide | Registra la clave pública del peer en el hub |
| El peer está registrado pero no hay tráfico | `AllowedIPs` de esta app no cubre la subred destino | Pon el rango de la malla en `WG_ALLOWED_IPS` |
| El handshake se cae a los minutos | NAT/firewall sin keepalive | Sube `WG_KEEPALIVE` a 25 (por defecto ya lo está) |
| No hay UDP hacia el hub | Puerto del hub bloqueado | Verifica en el hub: `sudo ufw status` / reglas del proveedor |

Los logs de la app se ven en **Ajustes → App settings → "WireGuard Mesh" → View logs** (aparece `[render-wg0]` con el modo aplicado en cada arranque).

## 🧩 Desarrollo

Estructura del paquete (estándar de paquetes de Umbrel):

```
wg-mesh/
├── umbrel-app.yml          # Manifest (id, versión, descripción)
├── docker-compose.yml      # Servicios app (túnel) + status (página de estado)
├── hooks/pre-start         # Migra una config legacy existente (solo primer arranque)
├── scripts/render-wg0.sh   # Genera wg0.conf desde las variables de entorno
└── icon.svg
```

El contenedor usa la imagen oficial `lscr.io/linuxserver/wireguard` (pinneada por digest). El script `render-wg0.sh` corre antes de `/init` y decide el modo (variables de entorno → manual → plantilla).

## 📄 Licencia

MIT — úsala, modifícala y compártela libremente.
