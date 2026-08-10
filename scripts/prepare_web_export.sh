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

# Define una identidad exclusiva y estable para Entre lineas. Sin `id`, Chrome
# puede asociar la exportacion generica de Godot a otra PWA del mismo sitio y
# afirmar que ya esta instalada aunque el juego no tenga acceso visible.
if ! grep -Fq '"id":"./entre-lineas"' "${MANIFEST}"; then
	sed -i "s#{\"background_color\"#{\"id\":\"./entre-lineas\",\"short_name\":\"${SHORT_NAME}\",\"description\":\"Novela visual ${GAME_TITLE}\",\"scope\":\"./\",\"background_color\"#" "${MANIFEST}"
fi
sed -i "s#\"name\":\"[^\"]*\"#\"name\":\"${GAME_TITLE}\"#" "${MANIFEST}"
sed -i "s#\"short_name\":\"[^\"]*\"#\"short_name\":\"${SHORT_NAME}\"#" "${MANIFEST}"
sed -i "s#\"description\":\"[^\"]*\"#\"description\":\"Novela visual ${GAME_TITLE}\"#" "${MANIFEST}"

# Chrome mantiene su propia cache del manifiesto. La referencia versionada
# obliga a leer la identidad nueva y evita que siga mostrando la PWA fantasma.
sed -i "s#href=\"index.manifest.json[^\"]*\"#href=\"index.manifest.json?v=${BUILD_ID}\"#" "${HTML_SHELL}"

# Cada build usa una cache distinta aunque Godot reutilice su plantilla.
sed -i "s/^const CACHE_VERSION = .*/const CACHE_VERSION = '${BUILD_ID}';/" "${SERVICE_WORKER}"

# Evita que la cache HTTP de GitHub Pages (10 minutos) alimente la cache nueva
# con index.html, index.pck o index.wasm pertenecientes a la build anterior.
sed -i "s/cache.addAll(CACHED_FILES)/cache.addAll(CACHED_FILES.map((file) => new Request(file, { cache: 'reload' })))/" "${SERVICE_WORKER}"
sed -i "s/let response = await event.preloadResponse;/let response = null;/" "${SERVICE_WORKER}"
sed -i "s/response = await self.fetch(event.request);/response = await self.fetch(new Request(event.request, { cache: 'reload' }));/" "${SERVICE_WORKER}"

# Evita que una app instalada siga ejecutando la build anterior. El worker
# nuevo toma el control, elimina la cache antigua y recarga los clientes una vez.
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

# Obliga al navegador a consultar el worker publicado en cada arranque.
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
