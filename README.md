# Snowflake Combine

Remotely monitor crop farms on ComputerCraft & Plethora on a website!

## Setup Instructions

### Docker - Web Client & Websocket

**Requirements:** Docker w/ Compose >= 3.7, and two open ports.

1. Clone this repository.
2. Copy `docker-compose.example.yml` to `docker-compose.yml`.
    - **Caution:** Make sure you copy these files, otherwise you will experience merge conflicts.
3. Adjust the environment variables in docker-compose.yml
    - The web and turtle tokens must NOT be the safe.
4. Copy `config.example.json5` to `config.json5`. 
    - **Caution:** Make sure you copy these files, otherwise you will experience merge conflicts.
5. Adjust the configuration to your liking.
6. Create a folder with icons for mods.
    - They should be in this format [icons folder layout](https://i.znepb.me/LDIH.png)
7. Move this newley created folder to `client/public/icons`.
8. Run `docker compose build`.
9. Run `docker compose up -d`.

### Turtle

**Requirements:** Turtle (advanced or normal), GPS, Block Scanner, Modem, Diamond Pickaxe, 2 Chests, and some fuel.

1. **Build the farm area.**
    - The turtle's home position must have two chests, one above and one below.
    - The output chest must be below the turtle.
    - The fuel input chest must be above the turtle.
2. **Prep the turtle.**
    - Clone the contents of the cc directory to the turtle.
    - Give the turtle a modem, block scanner and pickaxe.
3. **Modify the configuration.**
    - The configuration file in the `/cc` directory is commented describing what each variable is for.

### Updating

**It is reccomended to update turtles before the frontend and websocket.**

#### Frontend Update

1. `git pull`
2. If there are any configuration changes required, make them.
3. Follow steps 8 and 9 of the Docker install guide.

#### Turtle Update

1. Go to a turtle's management page on Combine Web.
2. Click "Send Update"
3. Enter the updated main.lua file URL (GitHub raw URL) into the "Main file URL" box.
4. Do the same for the "Tortise file URL" box if Tortise has been updated as well.
5. Click "Send"
6. The turtle will update at the end of its current round. While updating, the turtle will breifly disappear from Combine Web. If it does not re-appear, you should go make sure it didn't break.
