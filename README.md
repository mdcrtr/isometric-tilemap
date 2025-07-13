# isometric-tilemap
This project is to help me learn how to render and manipulate isometric tilemaps. Particularly, how to deal with tiles of differing heights. It uses the Love2D game framework.

In this approach I have a 32x32 grid of tiles and a 33x33 grid of heightmap vertices. Each tile has 4 surrounding heightmap vertices, which I use to determine the tile sprite to render. 

For mouse selection of vertices, I cast the mouse position to the grid and then perform linear search down the screen to find the closest heightmap vertex to the mouse position (in grid coordinate system). This allows for higher vertices in front of the initial grid position to be selected in preference.

# Controls

Escape - Quit

W, A, S, D - Pan map

Q, E - Zoom Out/In

R - Hot reload lua code

J, K, L - Select Lower/Raise/Level Terrain tool

T, Y - Select Tree/House tool

X - Select Remove tool

C - Add creature

Click and drag with the mouse to use the selected tool

# Screenshot (Programmer art warning)

<img width="1006" height="756" alt="isotiles3" src="https://github.com/user-attachments/assets/62887252-60e0-4fc8-ab46-18b0c69ec112" />
