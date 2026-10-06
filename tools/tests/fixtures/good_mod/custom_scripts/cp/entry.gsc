init()
{
    custom_scripts\ix\core\shared::run();
    custom_scripts\ix\zombies\z::run();
    level thread custom_scripts\ix\core\shared::watch();
    pointer = custom_scripts\ix\core\shared::run;
    level [[ pointer ]]();
}
