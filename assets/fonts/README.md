# Fuentes de CreaFácil

Fuentes incluidas como assets locales para que la app funcione sin conexión
(no se usa `google_fonts` con descarga en tiempo de ejecución).

| Familia | Uso | Archivos | Licencia |
|---|---|---|---|
| Poppins | Títulos, botones y etiquetas | `Poppins-Regular/Medium/SemiBold/Bold.ttf` | SIL OFL 1.1 (`OFL-Poppins.txt`) |
| Nunito | Texto de cuerpo | `Nunito-Regular/SemiBold/Bold.ttf` | SIL OFL 1.1 (`OFL-Nunito.txt`) |

Origen: <https://github.com/google/fonts> (carpetas `ofl/poppins` y `ofl/nunito`).

Google Fonts solo publica Nunito como fuente variable (`Nunito[wght].ttf`). Para que el peso
se aplique igual en Android y en web, se generaron instancias estáticas (400, 600 y 700) con
`fontTools`:

```sh
python -m fontTools.varLib.instancer "Nunito[wght].ttf" wght=600 --static --update-name-table -o Nunito-SemiBold.ttf
```

La licencia OFL permite esta modificación (Nunito no tiene «Reserved Font Name»).
