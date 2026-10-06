// [calls] a missing function, a missing script, a missing stock function, a missing stock script
init()
{
    custom_scripts\ix\core\shared::run();
    custom_scripts\ix\core\shared::not_defined();
    custom_scripts\ix\core\nowhere::run();
    custom_scripts\ix\core\compat::unknown_native();
    custom_scripts\ix\core\include_user::run();
    custom_scripts\ix\core\broken::run();
    custom_scripts\ix\core\develop_only::run();
    custom_scripts\ix\zombies\z::run();
    scripts\engine\utility::not_a_stock_function();
    scripts\engine\no_such_script::run();
    level thread scripts\engine\utility::waittill_any( "valid_stock_call" );
}
