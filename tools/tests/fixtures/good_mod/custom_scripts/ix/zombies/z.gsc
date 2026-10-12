// stock scripts that every zombies map loads, including one from scripts\mp
run()
{
    spawner = scripts\mp\mp_agent::spawnnewagent;
    // stock fields with tokens (level.wave_num) and fields of the mod's own
    count = level.wave_num + level.ix.order.size;
    return scripts\cp\utility::isreallyalive( level );
}
