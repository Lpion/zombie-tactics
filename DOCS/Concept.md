# 3D TopDownShooter (SP)

    Deadline: 13.05.2020 (evtl. 01.06.2020)


Goal of the game: 
- introduction (tutorial)
- The player needs to go from point A to B while, fighting basic enmies on the way. 
- first lvl = introduction
- second lvl = apply learned machanics while going to point B


Enviroment:
- basic meshes (brick walls, wooden barrel, floor)


Player: 
- can move on a 2 dimensional plane 
- shoot / punch enemies, while standing still or moveing
- can aim the weapon in the horizontal axis
- model is always faceing the cursor
- has health bar
- can die and respawn
- can pick up 
- Movement-States: idle, walk, run

Enemy: 
- only one enemy type
- has health bar
- hast basic movement 
- can die

Enemies
- Movement-States: walk, run
- can patrol 
- can attack (shooting)

Damage System:
- every player or enemy has 100p hitpoints
- one bullet makes 10p dmg
- one melee makes 5p dmg
- dmg reduces healthbar 
- when health = 0 on player => respawn

Weapons:
- 5 bullets in magazine ( shown in HUD )
- can reload ( on reload => restocks bullets, if magazine present)
- no bullets = no shooting

Pickups: 
- ammo (one mag = 5 bullets) = instant , adds bullets to counter in 

HUD:
- health = instant, adds points to health bar in HUD

UI:
- MENU
    - start menu
        - start button
        - lvl select buttonS
        - exit button
    - pause menu
        - restart button
        - exit button
        - rebirth button
- HUD: 
    - counter (ammo, health)
    - aiming cursor
    
