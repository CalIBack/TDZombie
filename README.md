# TDZombie

Shooter top-down estilo Hotline Miami (Godot 4.4, renderer Compatibility).
Zombies y tiradores; un toque o un balazo y estás muerto. Solo ves lo que entra en tu cono de visión.
Se gana solo saliendo por la Salida con la llave. Matar enemigos no gana: es opcional.

| Acción | Tecla |
|---|---|
| Moverse | WASD / flechas |
| Apuntar / disparar | Mouse / click izquierdo (mantener = ráfaga) |
| Recargar | R (también recarga sola si gatillás sin balas) |
| Pausa | ESC o P |
| Jugar de nuevo al terminar la partida | R |

## Estructura

```
escenas/
├── autoload/juego.tscn        autoload "Juego" (Musica: AudioStreamPlayer, process_mode Always)
├── jugador/jugador.tscn
├── enemigos/
│   ├── zombie.tscn            base (manOld_hold, tinte verde)
│   └── tirador.tscn           soldier1_gun, dispara ráfagas
├── mundo/
│   ├── puerta.tscn            bisagra en el origen, hoja de 64 px hacia +X
│   ├── meta.tscn
│   ├── llave.tscn             se recoge al pasar; la salida la pide
│   ├── vidrio.tscn            panel de 32 px que se rompe (rotalo 90° para paredes verticales)
│   └── lvl/lvl.tscn           nivel 1 (tu mapa)
└── ui/hud.tscn, menu.tscn, ranking.tscn (podio + lista)
scripts/                       todo el código (mismo árbol que escenas)
```

## Qué se configura en el editor (no por código)

- **Capas** (Proyecto > Configuración > Layer Names): 1 mundo, 2 jugador, 3 enemigos, 4 puertas, 5 vidrio.

  | Nodo | Layer | Mask |
  |---|---|---|
  | Jugador | jugador | mundo, puertas, vidrio |
  | Zombie / Tirador | enemigos | mundo, enemigos, puertas, vidrio |
  | ZonaMordida (zombie) | — | jugador |
  | Puerta/Hoja | puertas | — |
  | Puerta/Sensor | — | jugador, enemigos |
  | Meta | — | jugador |
  | Paredes (TileSet lvl1.tres, physics layer 0) | mundo | |
  | Vidrio (TileSet lvl1.tres, physics layer 1, tile 9:79) | vidrio | |

  Las balas y la visión usan exports con el selector de capas: `mascara_balas` en Jugador (mundo, enemigos, puertas)
  y `mascara_balas` en Tirador (mundo, jugador, puertas). Todos los enemigos tienen `mascara_vision`
  (mundo, jugador, puertas: el vidrio NO tapa la vista) y `mascara_sonido` (vidrio: el vidrio tapa el sonido).
  Las balas tampoco incluyen "vidrio", así que lo atraviesan.
- **Grupos**: `jugador`, `enemigos` y `manchas` están asignados en los nodos (pestaña Nodo > Grupos).
- **Señales**: todas conectadas desde la pestaña Nodo (botones del HUD y del menú, sliders, sensor de puerta,
  meta, campo de nombre, y en el nivel: Jugador → HUD/Nivel y Meta → Nivel). Los métodos se llaman `_on_<nodo>_<señal>`.
- **Navegación**: `Navegacion` (NavigationRegion2D) contiene Piso, Pared e Interactivos y ya está horneada.
  Si cambiás el mapa, seleccioná `Navegacion` y apretá **Bake NavigationPolygon** en la barra superior.
  Toma como obstáculo todo lo que esté en las capas "mundo" y "vidrio" (agent radius 18).
- **Cámara**: zoom 2× y límites (-640, -384, 640, 384) puestos en el Inspector.

## Cono de visión

- `Oscuridad` (CanvasModulate) en el nivel oscurece todo.
- `Jugador/ConoVision` (PointLight2D) ilumina un círculo, con un GradientTexture2D radial y sombras.
  `Jugador/MascaraCono` (LightOccluder2D con forma de "C") tapa esa luz en todas las direcciones menos el
  frente, y así queda el cono. La C está en la capa de luz 2: la linterna la tiene en `shadow_item_cull_mask`
  y el Aura no, así que el Aura sigue iluminando alrededor tuyo. Para cambiar el ángulo del cono, editá los
  puntos del polígono de `MascaraCono` en el editor.
  `Jugador/Aura` (PointLight2D con un degradado radial) te deja ver un poco alrededor.
- Las paredes tienen oclusores en el TileSet (occlusion layer 0) y cada `Puerta/Hoja` un `LightOccluder2D`:
  proyectan sombra, así que no ves lo que hay detrás. El vidrio no tiene oclusor: se ve a través.
- Paredes, vidrios, hojas de puerta, láseres, fogonazos y la salida usan un `CanvasItemMaterial` con
  Light Mode = Unshaded: se ven siempre, aunque estén en la oscuridad.

## Láseres

`Jugador/Laser` (verde) y `Tirador/Laser` (rojo) son `Line2D`. Cada frame se lanza un rayo con la misma
máscara que las balas y la línea termina donde pegaría el tiro. La dispersión está en 0: la bala va por el láser.
El del tirador aparece solo cuando te ve (estado Atacando), `tiempo_reaccion` antes del primer disparo.

## Zombies

Arrancan en el estado `Dormido`, quietos y mirando hacia donde los rotaste en el nivel. Se despiertan si te
ven (cono de 120°, 380 px), si les pegan o si escuchan un disparo (tuyo o de un tirador) a menos de 550 px
sin un vidrio en el medio. Una vez despiertos, te persiguen hasta el final.

## Texturas

| Nodo | Export / propiedad | PNG |
|---|---|---|
| Jugador | textura_arma (y Sprite2D) | hitman1_gun |
| Jugador | textura_recarga | hitman1_reload |
| Jugador | textura_sin_arma (al morir) | hitman1_stand |
| Zombie | Visual/Sprite2D | manOld_hold |
| Tirador | Visual/Sprite2D | soldier1_gun |
| Puerta | Hoja/Sprite2D | AtlasTexture del tile de puerta de tilesheet_complete |

Los Sprite2D tienen `centered = false` y `offset = (-17, -22)`: así el centro del cuerpo queda en el origen
aunque las tres texturas del jugador tengan anchos distintos (49, 39 y 33 px). Las balas, el fogonazo
(estallido amarillo) y las manchas de sangre se dibujan por código.

## Nivel 1

- Las 4 puertas interiores pintadas como tiles se reemplazaron por instancias de `puerta.tscn` (las dobles son
  dos hojas: la derecha rotada 180°). La del borde izquierdo quedó como tile y encima está la `Meta`.
- Enemigos: 6 tiradores y 7 zombies (1 tanque, 2 rápidos), ordenados en `Enemigos/Tiradores` y `Enemigos/Zombies`.
  Se cuentan (para el HUD) todos los que cuelguen de `Enemigos`, en cualquier subcarpeta.
  La rotación con la que está puesto un tirador es hacia donde mira en guardia.
- Los vidrios de la sala de arriba a la derecha (tile 9,79 en `Interactivos`) no tienen colisión en el TileSet;
  si querés que frenen, agregales un polígono de física en `lvl1.tres`.

## Variantes: Tanque y Rápido

Cualquier enemigo (zombie o tirador) tiene en el Inspector el grupo **Variante**:

| Casilla | Qué cambia | Valor |
|---|---|---|
| `tanque` | solo la vida | `vida_tanque` (4) |
| `rapido` | solo la velocidad | `velocidad_rapido` (175) |

Se pueden marcar las dos. Se aplican al empezar el nivel, y además el enemigo se tiñe
(tanque más oscuro, rápido más rojo) para reconocerlo.

## Vidrios

Ya no son tiles: cada panel es una instancia de `vidrio.tscn` (StaticBody2D en la capa "vidrio") dentro del
nodo `Vidrios` del nivel. La capa `Interactivos` se borró; los tiles de la puerta de salida pasaron a `Pared`.

- Sano: frena a todos y tapa el sonido, pero deja ver (no tiene oclusor ni está en `mascara_vision`).
- Se rompe con cualquier bala (tuya o de un tirador): la bala lo atraviesa y sigue de largo.
- Se rompe si un enemigo lo choca caminando. La navegación ya no lo cuenta como obstáculo,
  así que los zombies van derecho hacia el vidrio y lo atraviesan.
- Roto: desaparece el `Panel`, se apaga la colisión y aparecen los `Restos` (5 Polygon2D celestes).

## Llave

`llave.tscn` es un Area2D que detecta al jugador. Al recogerla emite `recogida` (conectada al Nivel en la
escena), el HUD pasa a "LLAVE ✓" y recién ahí la Meta te deja ganar. Si no querés que la salida pida
llave en un nivel, desmarcá `salida_requiere_llave` en el nodo raíz del nivel.

## Agregar un nivel

1. Duplicá `lvl.tscn`, cambiá `nombre` en el nodo raíz y re-horneá la navegación.
2. Sumá su ruta en `scripts/autoload/juego.gd` → `NIVELES`. El número de nivel sale del orden de esa lista.

## Partida, puntos y ranking

- Al apretar **Jugar** el menú pide tu nombre (hasta 12 letras; recuerda el último). La partida arranca en el nivel 1.
- Una partida sigue hasta que ganás el último nivel o morís. Al pasar de nivel se conservan los puntos y el tiempo.
- Puntos por enemigo (exports del grupo **Puntos** de cada escena):

  | Enemigo | Puntos |
  |---|---|
  | Tirador | 200 |
  | Zombie tonto | 100 |
  | Zombie inteligente | 200 |
  | Zombie rápido o tanque | 300 |
  | Zombie rápido y tanque | 500 |

  Las variantes pisan a "inteligente": un zombie rápido inteligente da 300.
- Al terminar se guarda `{nombre, puntos, tiempo}` en `user://ajustes.cfg`. Orden: más puntos; si empatan,
  menos tiempo; si empatan, por nombre. Quedan los 10 mejores: los 3 primeros en el podio (oro, plata, bronce)
  y del 4 al 10 en lista. Tu última partida aparece marcada.
- Salir al menú desde la pausa abandona la partida y no la guarda.

## Zombie inteligente

Casilla `inteligente` en cada zombie. Marcada: usa la navegación y rodea paredes. Sin marcar: va en línea
recta hacia vos y se queda chocando contra lo que haya en el medio. En el nivel 1, `Zombie2` y `Zombie4`
son inteligentes.

## Sonido

| Archivo | Dónde | Notas |
|---|---|---|
| `assets/audio/musica/background.mp3` | `musica` del Menú y del Nivel | Loop activado en Importar; no se corta al cambiar de escena |
| `assets/audio/sfx/disparo.ogg` | Jugador y Tirador → Sonidos/Disparo | `max_polyphony` 4 / 3 para que las ráfagas no se corten |
| `assets/audio/sfx/recarga.ogg` | Jugador → Sonidos/Recarga | |
| `assets/audio/sfx/zombie.ogg` | Zombie → Sonidos/Grunido | Loop activado en Importar; se oye hasta 700 px |

Los .m4a originales se convirtieron a .ogg (Godot no importa .m4a). El zombie empieza a sonar al
despertarse, cada uno con un pitch al azar entre 0.8 y 1.2 (`variacion_pitch`) y desde un punto al azar
del audio, y se calla al morir. Quedan sin audio: SinBalas y Muerte del jugador, Impacto/Muerte/GolpePuerta
de los enemigos, Sonido de puertas, vidrios y llave, y Victoria/Derrota del HUD.
