// [modes] multiplayer code must not reach the zombies module
init()
{
    custom_scripts\ix\zombies\z::run();
}
