-module(scribbles_markdown).
-export([run_build/0, split_file/1, get_val/2]).

%%% Scribbles Markdown Engine.
%%% Responsible for parsing Frontmatter and stitching together 
%%% pure HTML binaries without heavy dependencies.

run_build() ->
    %% Ensure the output directory exists
    filelib:ensure_dir("compiled/dummy.txt"),
    
    %% Find the files
    Files = filelib:wildcard("posts/*.md"),
    io:format("Found ~p files to convert.~n", [length(Files)]),
    
    %% Processing loop
    %% Inside your loop in run_build/0
[begin
    try 
        convert_file(File),
        io:format("Documentation build complete.~n")
    catch 
        Class:Reason -> 
            io:format("Skipping ~s! Error (~p): ~p~n", [File, Class, Reason])
    end
 end || File <- Files].
    
    

%% --- Internals ---

convert_file(Path) ->
    {ok, Raw} = file:read_file(Path),
    
    %% 1. Slice the metadata and the body
    {Meta, Body} = split_file(Raw),
    
    %% 2. Extract the Title (Defaults to "Untitled")
    Title = get_val(<<"title">>, Meta),
    
    %% 3. Convert Markdown Body
    %% markdown:conv returns a list, we force it to binary
    HtmlBody = list_to_binary(markdown:conv(binary_to_list(Body))),
    
    %% 4. Construct the Final Binary Sandwich
    FinalHtml = << (scribbles_templates:header(Title))/binary, 
                   HtmlBody/binary, 
                   (scribbles_templates:footer())/binary >>,
    
    %% 5. Handle the output path (ELP-friendly binary logic)
    Base = case filename:basename(Path, <<".md">>) of
        B when is_binary(B) -> B;
        L when is_list(L) -> list_to_binary(L)
    end,
    OutName = <<Base/binary, ".html">>,
    
    file:write_file(filename:join(<<"compiled">>, OutName), FinalHtml).

%%  Separates YAML frontmatter from the markdown body.
split_file(Binary) ->
    case re:run(Binary, <<"^---(?:\r?\n)(.*?)(?:\r?\n)---(?:\r?\n)(.*)$">>, 
                [dotall, {capture, all_but_first, binary}]) of
        {match, [Meta, Body]} -> {Meta, Body};
        nomatch -> {<<>>, Binary}
    end.

%%  Extracts a specific key's value from the frontmatter binary.
get_val(Key, Meta) ->
    %% Note the ?: added to the second group
    Pattern = <<Key/binary, <<":\s*\"?(.*?)\"?(?:\r?\n|$)">>/binary>>,
    case re:run(Meta, Pattern, [{capture, all_but_first, binary}]) of
        {match, [Val]} -> Val;
        nomatch -> <<"Untitled">>
    end.

