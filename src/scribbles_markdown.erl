-module(scribbles_markdown).
-export([run_build/0]).

run_build() ->
   
   %% This ensures the 'compiled' folder exists so we can put 'index.html' in it.
    %% If the folder is already there, it does nothing.
    filelib:ensure_dir("compiled/dummy.txt"),
   
    %% 1. Find the files (using the recursion skills you're practicing)
    Files = filelib:wildcard("posts/*.md"),

    io:format("Found ~p files to convert.~n", [length(Files)]), %% Add this!
    
    %% Terse processing loop
    [convert_file(F) || F <- Files],
    
    io:format("Documentation build complete.~n").



    convert_file(File) ->
    {ok, Bin} = file:read_file(File),
    Html = markdown:conv(binary_to_list(Bin)),

    %% 1. Force the input to a binary and CRASH if it's an error/tuple.
    %% This 'binds' Base as a pure binary(), satisfying the checker.
    Base = case filename:basename(File, ~".md") of
        B when is_binary(B) -> B;
        L when is_list(L) -> list_to_binary(L)
    end,

    %% 2. Now use binary interpolation. 
    %% EqWAlizer is 100% fine with this because 'Base' is strictly binary() here.
    OutName = <<Base/binary, ".html">>,

    ok = file:write_file(filename:join(~"compiled", OutName), Html).

