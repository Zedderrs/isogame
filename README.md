# developed using godot 3.2.1
https://godotengine.org/download/windows
# isogame
isometric test game

testing to make an isometric graphics 2D game.

loosely roguelike/rpg for now. Trying to get it to be like diablo 2.

# Installation
    - Clone Github repository onto local computer (link: git@github.com:Zedderrs/isogame.git)
    - Launch Godot. In the Project Manager menu, import the project folder by navigating to the project folder and selecting the *project.godot* file. The project should become available in the Project Manager Menu. Select IsoGame and hit run.
    - In the editor, run the game by clicking the play button on the top-right.

# Game Design Concept
After having played Hades I've been inspired to flesh out some ideas for what this game should be about.

# Game
At it's core, this game is a dungeon crawler with roguelike aspects.

The first room you start in should always be the same with a randomized buff that get's you started.
I'm thinking it will be the right click skill (special skill) that will allow the player to begin making
choices based off what they get.

# Game art
The art for this game is provided by [PVGames](https://pvgames.itch.io/)
I've gotten a few packs so that I can have many many different characters/environments to choose from.
Visual aspects, from animations to background art, should all be already included here.

One thing that is missing is 'skill' or 'magic' art. To animate skills or attacks properly, PVGames does not provide this. I will either have to create this myself, or find other assets to work with.

# Customization

The code is set up to try to incorporate all the PVGames characters in it. I want to have a character selection screen, that allows you to choose:
- male/female
- race(eg. elf, human, half orc, drow seem to be the races offered in the assests)
- hair

Additionally as you go along the game, when you pick up an item it should equip over your character. The different
items will have status effects and will provide further customization into the character. The pieces include:
- main hand weapon
- off hand weapon
- top armor
- bottom armor
- accessory (maybe)

All these pieces should show on the character and their sprite sheets are included as separate animations to be drawn over the existing character.

# Hallway exploration

In general, the game flow will have the character exploring hallways with rooms. Each room has a door leading to it
which will present the player with a task/trial. The door will have an insignia on it that indicates the level of difficulty of the task/trial and the potential reward.

The player may always leave to the next level (or maybe the exit is hidden in one of the rooms), but may risk being
too weak to continue.

# Room design

# Skills

# Death and progression

The player will die, undoubtely before completing the game. There is an external progression that makes the
chracter better each time they play the game.

# Story

# Setting/Mood


