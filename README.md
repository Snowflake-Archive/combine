# Snowflake Combine
Remotely monitor crop farms on ComputerCraft & Plethora on a website!
## Setup Instructions
### Docker - Web Client & Websocket
**Requirements:** Docker w/ Compose >= 3.7, and two open ports.
1. Clone this repository.
2. Adjust the environment variables in docker-compose.yml
    - The web and turtle tokens must NOT be the safe.
3. Run `docker compose build`
4. Run `docker compose up`

### Turtle
**Requirements:** Turtle (advanced or normal), GPS, Block Scanner, Modem, Diamond Pickaxe, 2 Chests, and some fuel.
1. **Build the farm area.** 
    - The turtle's home position must have two chests, one above and one below.
    - The output chest must be below the turtle.
    - The fuel input chest must be above the turtle. 
1. **Prep the turtle.**
    - Clone the contents of the cc directory to the turtle. 
    - Give the turtle a modem, block scanner and pickaxe.
2. **Modify the configuration.**
    - The configuration file in the `/cc` directory is commented describing what each variable is for. 
4. Pretty much done.

## Notice
This software is currently in beta. Please except the occassional bug and glitch, and if you do find one, report it on the issues tab. If you find a fix, make a pull request and I'll be very happy. 