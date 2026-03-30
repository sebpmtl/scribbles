-module(scribbles_markdown).
-export([run_build/0, split_file/1, get_val/3]).

%%% Scribbles Markdown Engine.
%%% Responsible for parsing Frontmatter and stitching together 
%%% pure HTML binaries without heavy dependencies.

run_build() ->
    io:format("DEBUG: Version 2 - do_convert should be disabled~n"),
    filelib:ensure_dir("compiled/dummy.txt"),
    Files = filelib:wildcard("posts/*.md"),
    io:format("Found ~p files to convert.~n", [length(Files)]),
    
    [try convert_file(F) 
     catch C:R -> io:format("Error ~s: ~p:~p~n", [F, C, R]) 
     end || F <- Files],

    io:format("Build complete.~n"). %% Move to the very end of the function to ensure it runs regardless of errors in individual files. 
    
    

%% --- Internals ---

convert_file(Path) ->
    {ok, Raw} = file:read_file(Path),
    case split_file(Raw) of
        {<<>>, _Body} ->
            %% This happens if the YAML header is missing or incomplete
            io:format("  [Skip] No metadata found in ~s~n", [Path]),
            ignore;
        {Meta, Body} ->
            %% Check draft status ONLY if Meta exists
            DraftRaw = get_val(<<"draft">>, Meta, <<"false">>),
            Draft = list_to_binary(string:to_lower(binary_to_list(re:replace(DraftRaw,
                                <<"(?:^[ \t\r\n]+|[ \t\r\n]+$)">>,
                                <<"">>,
                                [global, {return, binary}])))),

            case Draft of
                <<"true">> ->
                    io:format("  [Draft] Skipping ~s~n", [Path]),
                    delete_output(Path),
                    skip;
                _ ->
                    %% Only proceed to build if Meta is valid AND draft is not true
                    do_convert(Path, Meta, Body)
            end
    end.

do_convert(Path, Meta, Body) ->
    io:format("  Processing ~s...~n", [Path]),
    Title = get_val(<<"title">>, Meta, <<"Untitled">>),
    Date = get_val(<<"date">>, Meta, <<"Unknown">>),
    
    HtmlBody = list_to_binary(markdown:conv(binary_to_list(Body))),
    
    FinalHtml = << (scribbles_templates:header(Title, Date))/binary, 
                   HtmlBody/binary, 
                   (scribbles_templates:footer())/binary >>,

    Base = case filename:basename(Path, <<".md">>) of
        B when is_binary(B) -> B;
        L -> list_to_binary(L)
    end,
    
    file:write_file(filename:join(<<"compiled">>, <<Base/binary, ".html">>), FinalHtml).

%%  Remove target HTML output when a post is marked draft.
delete_output(Path) ->
    OutName = output_name(Path),
    OutPath = filename:join(<<"compiled">>, OutName),
    case file:delete(OutPath) of
        ok -> ok;
        {error, enoent} -> ok;
        {error, Reason} -> io:format("  [Draft] Failed deleting ~s: ~p~n", [OutPath, Reason])
    end.

output_name(Path) ->
    Base = case filename:basename(Path, <<".md">>) of
        B when is_binary(B) -> B;
        L -> list_to_binary(L)
    end,
    <<Base/binary, ".html">>.

%%  Separates YAML frontmatter from the markdown body.
split_file(Binary) ->
    case re:run(Binary, <<"---(?:\r?\n)(.*?)(?:\r?\n)---(?:\r?\n)(.*)$">>, 
                [dotall, {capture, all_but_first, binary}]) of
        {match, [Meta, Body]} -> {Meta, Body};
        nomatch -> {<<>>, Binary}
    end.

%%  Extracts a specific key's value from the frontmatter binary.
get_val(Key, Meta, Default) ->
    Pattern = <<Key/binary, <<":[ \\t]*\"?(.*?)\"?(?:\r?\n|$)">>/binary>>,
    case re:run(Meta, Pattern, [{capture, all_but_first, binary}]) of
        {match, [Val]} -> Val;
        nomatch -> Default
    end.

