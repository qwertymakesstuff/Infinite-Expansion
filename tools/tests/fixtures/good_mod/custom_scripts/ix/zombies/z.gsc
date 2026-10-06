// stock scripts that every zombies map loads, including one from scripts\mp
run()
{
    spawner = scripts\mp\mp_agent::spawnnewagent;
    return scripts\cp\utility::isreallyalive( level );
}
