# Understory

A Contra-style 2D run-and-gun platformer built with **Godot 4.7**.

## Features

- Run, jump, crouch and free-aim with mouse or right stick
- Three weapons: normal gun, machine gun and spread gun (pickups)
- 5 hand-made levels across jungle, forest and lava tilesets
- Enemy variety: walkers, flyers and aiming gunners
- Boss fights at the end of levels 3, 4 and 5
- Keys, doors, breakable walls, moving platforms, spikes and lava hazards
- HUD with hearts, timer, death counter, weapon indicator and toasts
- Synth sound effects and looping music
- Keyboard and gamepad support

## Controls

| Action | Keyboard / Mouse | Gamepad |
| --- | --- | --- |
| Move | A / D or arrow keys | Left stick / D-pad |
| Jump | Space, W or Up | A / Cross |
| Crouch | S or Down | B / Circle |
| Aim | Mouse | Right stick |
| Shoot | Left mouse button | Right trigger / X |
| Start / confirm | Enter or Space | A / Cross |

## Requirements

- [Godot 4.7](https://godotengine.org/) (standard build, no C# required)

## Running

Open the project in Godot and press **F5**, or run from a terminal:

```sh
godot --path .
```

The main scene is `StartMenu.tscn`, which leads into `World.tscn` and then the level set.

## Project structure

```
Assets/        Sprites, tilesets and audio
Levels/        Level scenes (1-5)
Objects/       Reusable scenes (player, enemies, bosses, bullets, pickups, hazards)
Scripts/       GDScript gameplay code (player, enemies, effects, audio)
tools/         Helper and verification scripts used during development
World.tscn     Hub scene that starts the level flow
StartMenu.tscn Main menu (project entry point)
Win.tscn       End-of-game screen
```

## Todo

- [ ] Ambientação
- [ ] Criar sprites para o jogo
- [ ] Criar história
- [ ] Criar fases
- [ ] Adicionar mecânicas
  - [ ] Corda
  - [ ] Dash
