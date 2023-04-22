module main;

immutable exeVersion = "0.1 20230422";

import std.stdio;
import std.file;
import std.process;
import core.exception;
import std.json;
import std.conv;
import core.time;
import std.datetime;
import std.logger;
import std.array;

version(Windows) {
string configFile = "config.json";
string audioPlayer = "mpg123.exe -T";
string editor = "notepad";
}
else {
string configFile = "config.json";
string audioPlayer = "mpg123 -T";
string editor = "nano";
}

void main(string[] args)
{
    
    if(args.length < 2){
        showHelp();
        return;
    }

    switch (args[1])
    {
    case "-h", "--help":
        showHelp();
        break;
    case "-v", "--version":
        showVersion();
        break;
    case "-s", "--sound":
        if(args.length < 3){
        paraEnough();
        return;
        }
        addSound(args[2]);
        break;
    case "-sl", "--soundslist":
        showSoundsList();
        break;
    case "-t", "--todo":
        addTODO(args);
        break;
    case "start":
        start();
        break;
    case "--set-audioplayer":
        if(args.length < 3){
        paraEnough();
        return;
        }
        setAudioPlayer(args[2]);
        break;
    case "edit":
        edit();
        break;
    case "set-editor":
        if(args.length < 3){
        paraEnough();
        return;
        }
        seteditor(args[2]);
        break;
    case "init":
    init();
        break;
    default:
        break;
    }
}

void init() {
    std.file.write(configFile, `{
    "sounds": [
    ],
    "todo": [
    ]
}`);
}

void seteditor(string opt)
{
    JSONValue config = parseJSON(readText(configFile));
    config["editor"] = JSONValue(opt);
    std.file.write(configFile, config.toPrettyString);
}

void edit()
{
    JSONValue config = parseJSON(readText(configFile));
    try
    {
        editor = config["editor"].str;
    }
    catch (JSONException)
    {
    }
    auto pid = spawnProcess(editor.split(" ") ~ configFile);
    if (wait(pid) != 0)
    {
        //TODO
    }
}

void setAudioPlayer(string opt)
{
    JSONValue config = parseJSON(readText(configFile));
    config["audioplayer"] = JSONValue(opt);
    std.file.write(configFile, config.toPrettyString);
}

string audioPlayerLog(string opt)
{
    Lang lang = getLang();
    if (lang == Lang.zh_cn)
        return audioPlayerLogText_ZH_CN ~ opt;
    return audioPlayerLogText_EN_US ~ opt;
}

void start()
{
    JSONValue config = parseJSON(readText(configFile));
    try
    {
        audioPlayer = config["audioplayer"].str;
    }
    catch (JSONException)
    {
    }
    string[][] todos;
    foreach (key; config["todo"].array)
    {
        string[] cache;
        foreach (subkey; key.array)
        {
            cache ~= subkey.str;
        }
        todos ~= cache;
    }

    SysTime timenow;
    while (true)
    {
        timenow = Clock.currTime();
        foreach (todo; todos)
        {
            try
            {
                if (todo[1].to!int == timenow.second
                        && todo[2].to!int == timenow.minute
                        && todo[3].to!int == timenow.hour)
                {
                    playMusic(todo[0]);
                }
            }
            catch (ArrayIndexError)
            {
                if (todo[1].to!int == timenow.second && todo[2].to!int == timenow.minute)
                {
                    playMusic(todo[0]);
                }
            }
        }
    }
}

void playMusic(string music)
{
    log(LogLevel.info, audioPlayerLog(music));
    auto ls = executeShell(audioPlayer ~ " " ~ music);
    if (ls.status != 0)
    {
    } // TODO
    else
        writeln(ls.output);
}

void addTODO(string[] args)
{
    JSONValue config = parseJSON(readText(configFile));
    string sound = null;
    try
    {
        args = args[2 .. $];
        int i = 1;
        foreach (key; config["sounds"].array)
        {
            if (args[0] == i.to!string)
            {
                sound = key.str;
            }
            i++;
        }
        args = args[1 .. $];
    }
    catch (ArrayIndexError)
    {
        paraEnough();
    }
    if (sound == null)
    {
        return;
    } // TODO
    config["todo"].array ~= JSONValue([sound] ~ args);
    std.file.write(configFile, config.toPrettyString);
}

void addSound(string opt)
{
    JSONValue config = parseJSON(readText(configFile));
    config["sounds"].array ~= JSONValue(opt);
    std.file.write(configFile, config.toPrettyString);
}

void showSoundsList()
{
    JSONValue config = parseJSON(readText(configFile));
    int i = 1;
    foreach (key; config["sounds"].array)
    {
        writeln(i.to!string ~ " " ~ "| " ~ key.str); // a Tab
        i++;
    }
}

enum Lang
{
    en_us,
    zh_cn
}

Lang getLang()
{
    Lang lang = Lang.en_us;
    if (environment.get("LANG") == "zh_CN.UTF-8")
        lang = Lang.zh_cn;
    return lang;
}

void paraEnough()
{
    Lang lang = getLang();
    if (lang == Lang.en_us)
        writeln(paraEnoughText_EN_US);
    if (lang == Lang.zh_cn)
        writeln(paraEnoughText_ZH_CN);
}

void showVersion()
{
    Lang lang = getLang();
    if (lang == Lang.en_us)
        writeln(versionText_EN_US);
    if (lang == Lang.zh_cn)
        writeln(versionText_ZH_CN);
}

void showHelp()
{
    Lang lang = getLang();
    if (lang == Lang.en_us)
        writeln(helpText_EN_US);
    if (lang == Lang.zh_cn)
        writeln(helpText_ZH_CN);
}

immutable helpText_EN_US = `Play Sound Per Date

Usage:
pspd <Options> [Args]
pspd init                           Init config file.

Options:
    -h, --help                      Show this helping message.
    -v, --version                   Show version.
    -s, --sound <sound>             Add sound.
    -sl, --soundslist               Output sounds list.
    -t, --todo <token> <s> <m> [h]  Create a todo (token, second, minute, and hour).
    start                           Start a PSPD process.
    --set-audioplayer <player>      Set your audio-player like the default what it is "mpg123 -T".
    edit                            Edit config file.
    set-editor                      Set editor about editting config file.
    init                            Init config file.
`;

immutable helpText_ZH_CN = `Play Sound Per Date

用法:
pspd <选项> [参数]
pspd init                            初始化配置文件

选项:
    -h, --help                       显示这个帮助信息.
    -v, --version                    显示版本.
    -s, --sound <sound>              添加声音.
    -sl, --soundslist                输出声音列表.
    -t, --todo <token> <s> <m> [h]   创建一个待办任务 (Token, 秒, 分, 和可选的小时).
    start                            开启一个 PSPD 进程.
    --set-audioplayer <player>       设置你的音频播放器, 例如默认的 "mpg123 -T".
    edit                             编辑配置文件.
    set-editor                       设置编辑配置文件的编辑器.
    init                             初始化配置文件
`;

immutable versionText_EN_US = "Play Sound Per Date (PSPD) " ~ exeVersion ~ "\nCopyright (C) 2023 Plasma";

immutable versionText_ZH_CN = "Play Sound Per Date (PSPD) " ~ exeVersion ~ "\nCopyright © 2023 Plasma";

immutable paraEnoughText_EN_US = "No enough parameters, input \"-h\" to get more information.";

immutable paraEnoughText_ZH_CN = "参数不够, 输入 \"-h\" 以获取更多信息.";

immutable audioPlayerLogText_EN_US = "Playing: ";
immutable audioPlayerLogText_ZH_CN = "正在播放: ";
