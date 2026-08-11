# Problemas conocidos

Este archivo se utiliza únicamente para errores, limitaciones o comportamientos que sabemos que debemos revisar. Las ideas de mejora que no sean problemas van en [`IDEAS.md`](IDEAS.md).

## Audio

- [ ] **Diferencias importantes de volumen entre algunas canciones.** Aunque existe un regulador individual por habitación y los volúmenes base son configurables desde JSON, los archivos de audio no tienen necesariamente el mismo nivel percibido. Hay que ajustar cada pista durante las pruebas y dejar valores base coherentes en los datos.

## Interfaz y resoluciones

- [ ] **Revisar escalado de interfaz en distintas resoluciones y relaciones de aspecto.** El juego tiene layouts responsive y se han corregido desbordamientos concretos, pero conviene validar de forma sistemática escritorio, ventanas pequeñas, móvil/vertical y distintas relaciones de aspecto.

## Pantalla completa

- [ ] **Revisar comportamiento de pantalla completa en los entornos soportados, especialmente Web.** No hay un fallo reproducible único documentado en este momento, pero la experiencia depende del navegador/plataforma y la preferencia guardada no se reaplica automáticamente al iniciar la versión Web. Conviene comprobar entrada, salida, redimensionado y uso táctil en varios navegadores.

## Criterio para añadir problemas

No añadir aquí mejoras hipotéticas ni errores no reproducidos. Cuando un problema se solucione, debe retirarse de esta lista y registrarse en [`CHANGELOG.md`](CHANGELOG.md) dentro de `Fixed`.
