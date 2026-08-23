#!/bin/sh

set -eu

EXPORT_DIR="${1:?Falta el directorio de exportacion web}"
BUILD_ID="${2:?Falta el identificador de la build}"
GAME_TITLE="${3:?Falta el titulo dinamico del juego}"
CHAIR_TITLE="${GAME_TITLE#Entre líneas: La }"
SHORT_NAME="$(printf '%s' "${CHAIR_TITLE}" | sed 's/^./\U&/')"
SERVICE_WORKER="${EXPORT_DIR}/index.service.worker.js"
ENGINE_SCRIPT="${EXPORT_DIR}/index.js"
MANIFEST="${EXPORT_DIR}/index.manifest.json"
HTML_SHELL="${EXPORT_DIR}/index.html"

if [ ! -s "${SERVICE_WORKER}" ] || [ ! -s "${ENGINE_SCRIPT}" ] || [ ! -s "${MANIFEST}" ] || [ ! -s "${HTML_SHELL}" ]; then
	echo "La exportacion web no contiene el HTML, service worker, index.js o el manifiesto" >&2
	exit 1
fi

# Identidad estable para la PWA de Entre líneas.
if ! grep -Fq '"id":"./entre-lineas"' "${MANIFEST}"; then
	sed -i "s#{\"background_color\"#{\"id\":\"./entre-lineas\",\"short_name\":\"${SHORT_NAME}\",\"description\":\"Novela visual ${GAME_TITLE}\",\"scope\":\"./\",\"background_color\"#" "${MANIFEST}"
fi
sed -i "s#\"name\":\"[^\"]*\"#\"name\":\"${GAME_TITLE}\"#" "${MANIFEST}"
sed -i "s#\"short_name\":\"[^\"]*\"#\"short_name\":\"${SHORT_NAME}\"#" "${MANIFEST}"
sed -i "s#\"description\":\"[^\"]*\"#\"description\":\"Novela visual ${GAME_TITLE}\"#" "${MANIFEST}"
sed -i "s#href=\"index.manifest.json[^\"]*\"#href=\"index.manifest.json?v=${BUILD_ID}\"#" "${HTML_SHELL}"

# Loader propio: oculta el splash genérico de Godot y conserva su progreso real.
if ! grep -Fq 'ENTRE_LINEAS_LOADING_UI' "${HTML_SHELL}"; then
	LOADER_STYLE='<!-- ENTRE_LINEAS_LOADING_UI --><style>#status{background:radial-gradient(circle at 50% 42%,#2c1b12 0%,#100a07 56%,#050302 100%)!important;gap:16px}#status-splash{display:none!important}#entre-lineas-loading-label{color:#f2c97e;font-family:Arial,sans-serif;font-size:clamp(14px,1.6vw,20px);font-weight:700;letter-spacing:.22em;line-height:1;text-align:center;text-transform:uppercase}#status-progress{position:relative!important;left:auto!important;right:auto!important;bottom:auto!important;width:min(460px,64vw)!important;height:8px;margin:0!important;border:0;border-radius:999px;overflow:hidden;appearance:none;-webkit-appearance:none;background:#24170f}#status-progress::-webkit-progress-bar{background:#24170f;border-radius:999px}#status-progress::-webkit-progress-value{background:#e4b968;border-radius:999px}#status-progress::-moz-progress-bar{background:#e4b968;border-radius:999px}</style>'
	sed -i "s|</head>|${LOADER_STYLE}</head>|" "${HTML_SHELL}"
	sed -i 's#<progress id="status-progress"></progress>#<div id="entre-lineas-loading-label">CARGANDO...</div><progress id="status-progress"></progress>#' "${HTML_SHELL}"
fi

# Cache aislada por build y actualización inmediata de la PWA instalada.
sed -i "s/^const CACHE_VERSION = .*/const CACHE_VERSION = '${BUILD_ID}';/" "${SERVICE_WORKER}"
sed -i "s/cache.addAll(CACHED_FILES)/cache.addAll(CACHED_FILES.map((file) => new Request(file, { cache: 'reload' })))/" "${SERVICE_WORKER}"
sed -i "s/let response = await event.preloadResponse;/let response = null;/" "${SERVICE_WORKER}"
sed -i "s/response = await self.fetch(event.request);/response = await self.fetch(new Request(event.request, { cache: 'reload' }));/" "${SERVICE_WORKER}"

if ! grep -q "ENTRE_LINEAS_AUTO_UPDATE" "${SERVICE_WORKER}"; then
	printf '%s\n' \
		'' \
		'// ENTRE_LINEAS_AUTO_UPDATE' \
		"self.addEventListener('install', (event) => {" \
		'  event.waitUntil(self.skipWaiting());' \
		'});' \
		'' \
		"self.addEventListener('activate', (event) => {" \
		'  event.waitUntil(self.clients.claim().then(() => self.clients.matchAll({' \
		"    type: 'window'," \
		'    includeUncontrolled: true,' \
		'})).then((clients) => Promise.all(clients.map((client) => client.navigate(client.url).catch(() => null)))));' \
		'});' >> "${SERVICE_WORKER}"
fi

REGISTER_CALL="navigator.serviceWorker.register(this.config.serviceWorker)"
REGISTER_NO_CACHE="navigator.serviceWorker.register(this.config.serviceWorker, { updateViaCache: 'none' })"
if grep -q "${REGISTER_CALL}" "${ENGINE_SCRIPT}"; then
	sed -i "s/${REGISTER_CALL}/${REGISTER_NO_CACHE}/" "${ENGINE_SCRIPT}"
fi

grep -Fq "const CACHE_VERSION = '${BUILD_ID}';" "${SERVICE_WORKER}"
grep -Fq "new Request(file, { cache: 'reload' })" "${SERVICE_WORKER}"
grep -Fq "new Request(event.request, { cache: 'reload' })" "${SERVICE_WORKER}"
grep -Fq "ENTRE_LINEAS_AUTO_UPDATE" "${SERVICE_WORKER}"
grep -Fq "updateViaCache: 'none'" "${ENGINE_SCRIPT}"
grep -Fq '"id":"./entre-lineas"' "${MANIFEST}"
grep -Fq "\"name\":\"${GAME_TITLE}\"" "${MANIFEST}"
grep -Fq "\"short_name\":\"${SHORT_NAME}\"" "${MANIFEST}"
grep -Fq '"scope":"./"' "${MANIFEST}"
grep -Fq "href=\"index.manifest.json?v=${BUILD_ID}\"" "${HTML_SHELL}"
grep -Fq 'ENTRE_LINEAS_LOADING_UI' "${HTML_SHELL}"
grep -Fq '>CARGANDO...</div>' "${HTML_SHELL}"
