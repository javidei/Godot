# Respaldo del fondo de la habitación de Javi

- Archivo original: `assets/backgrounds/fondo-habitacion-javi.png`
- Respaldo anterior a la pantalla verde: `backups/v0.5.7/fondo-habitacion-javi.png`
- Resolución: `1672 × 936`
- SHA-256 original: `4F8845BC8F8D1D00FAF279C5F2734934AFE0A0E9A41AAEF14486924F0B21066E`
- SHA-256 con pantalla verde: `51473C102777B81248B57278D1F551F1DB41CF620FD816C44E126C5F06752237`
- Color de la máscara: `#00FF00`
- Vértices en píxeles: `(262,352)`, `(456,352)`, `(456,477)`, `(262,480)`
- Límites verdes detectados: `x=262..455`, `y=352..479`
- Píxeles modificados: `24.541`
- Cambios detectados fuera de la máscara: `0`

Para restaurar manualmente el fondo original desde PowerShell:

```powershell
Copy-Item -LiteralPath "backups\v0.5.7\fondo-habitacion-javi.png" -Destination "assets\backgrounds\fondo-habitacion-javi.png" -Force
```
