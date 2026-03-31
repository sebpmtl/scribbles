-module(scribbles_assets).
-export([process_images/2, image_program/0]).

%% Entry point: Scans SourceBase, puts optimized WebP into DestBase
process_images(SourceBase, DestBase) ->
    SourceBaseStr = normalize_path(SourceBase),
    DestBaseStr = normalize_path(DestBase),

    %% Create the directory if it doesn't exist
    filelib:ensure_dir(filename:join([DestBaseStr, "placeholder"])),

    ImageFiles = filelib:wildcard(SourceBaseStr ++ "/*.{jpg,jpeg,png}"),

    io:format("~n[ASSETS] Found ~p raw images to process.~n", [length(ImageFiles)]),
    case image_program() of
        {ok, Cmd} ->
            [process_individual_image(Cmd, I, DestBaseStr) || I <- ImageFiles];
        {error, no_imagemagick} ->
            io:format("  [ASSETS] ImageMagick not found, copying raw images instead.~n"),
            [copy_raw_image(I, DestBaseStr) || I <- ImageFiles]
    end.

process_individual_image(Cmd, SrcPath, DestBase) ->
    %% Get just the name (e.g., "my_schematic")
    BaseName0 = filename:rootname(filename:basename(SrcPath)),
    BaseName = normalize_path(BaseName0),

    ThumbDest = filename:join([DestBase, BaseName ++ "-thumb.webp"]),
    LargeDest = filename:join([DestBase, BaseName ++ "-lg.webp"]),

    %% 1. Check/Update Thumbnail
    case needs_update(SrcPath, ThumbDest) of
        true -> 
            io:format("  [MAGICK] ~s -> Thumb~n", [BaseName]),
            generate_thumb(Cmd, SrcPath, ThumbDest);
        false -> ok
    end,

    %% 2. Check/Update Large Image
    case needs_update(SrcPath, LargeDest) of
        true -> 
            io:format("  [MAGICK] ~s -> Large~n", [BaseName]),
            generate_large(Cmd, SrcPath, LargeDest);
        false -> ok
    end.

%% One function, called twice above
needs_update(Src, Dest) ->
    not filelib:is_file(Dest) orelse
    filelib:last_modified(Src) > filelib:last_modified(Dest).

copy_raw_image(SrcPath, DestBase) ->
    BaseName0 = filename:rootname(filename:basename(SrcPath)),
    BaseName = normalize_path(BaseName0),
    Ext = normalize_path(filename:extension(SrcPath)),
    DestPath = filename:join([DestBase, BaseName ++ Ext]),
    case file:copy(SrcPath, DestPath) of
        ok -> io:format("  [ASSETS] Copied raw image ~s -> ~s~n", [SrcPath, DestPath]);
        {error, R} -> io:format("  [ASSETS] Copy failed ~s: ~p~n", [SrcPath, R])
    end.

%% --- ImageMagick Shell Wrappers ---

%% --- ImageMagick Shell Wrappers ---

generate_thumb(Cmd, Src, Dest) ->
    %% Using 64x64^ and extent ensures a perfect square even if the source is a rectangle
    Command = Cmd ++ " \"" ++ Src ++ "\" -resize 64x64^ -gravity center -extent 64x64 -colors 16 \"" ++ Dest ++ "\"",
    os:cmd(Command).

generate_large(Cmd, Src, Dest) ->
    %% The \">\" ensures the shell doesn't interpret > as a file redirection
    Command = Cmd ++ " \"" ++ Src ++ "\" -resize \"1200x>\" -quality 82 \"" ++ Dest ++ "\"",
    os:cmd(Command).

image_program() ->
    case os:type() of
        {unix, _} ->
            %% Finds the absolute path to the binary
            RawCmd = os:cmd("command -v magick || command -v convert || echo 'none'"),
            case string:trim(RawCmd) of
                "none" -> {error, no_imagemagick};
                "" -> {error, no_imagemagick};
                Cmd -> {ok, Cmd}
            end;
        {win32, _} ->
            %% Basic Windows 'where' check
            case os:cmd("where magick") of
                "INFO: " ++ _ -> {error, no_imagemagick};
                Cmd -> {ok, string:trim(Cmd)}
            end;
        _ -> {error, no_imagemagick}
    end.

normalize_path(Path) when is_binary(Path) -> binary_to_list(Path);
normalize_path(Path) -> Path.