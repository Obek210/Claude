# Shadow Duel: Gothic Arena

2D fighting game made with **Godot 4** (GL Compatibility renderer).

## Features
- 12 playable characters (unlockable with coins)
- 3 arenas
- Best-of-3 rounds, energy system, dodge / attack / charge
- Main menu, character select, arena select, settings
- Progress saved locally (`user://save.cfg`)
- Android export preset (`com.shadowduel.gothicarena`)

## How to run
1. Install [Godot 4.x](https://godotengine.org/download) (project created with 4.7).
2. Clone this repository.
3. Open Godot -> **Import** -> select `project.godot`.
4. Press **F5** to play.

The first import takes a moment: Godot regenerates the `.godot/` cache automatically (it is not stored in git).

## Project structure
| File | Description |
|------|-------------|
| `main.gd` | All game logic (UI, fighting, AI, save system) |
| `node_2d.tscn` | Main scene |
| `Char*.png` | Character select portraits |
| `Char_anim_*.png` | Animation sprite sheets (10 columns x 9 rows) |
| `Stage_*.png` | Arena backgrounds |
| `*_bg.jpg` | Menu backgrounds |
| `export_presets.cfg.txt` | Android export preset (rename to `export_presets.cfg` to use) |

## Android build
Rename `export_presets.cfg.txt` to `export_presets.cfg`, then in Godot: **Project -> Export -> Android**. You need your own keystore (not included).
