-module(scribbles_parser).
-export([split_file/1,get_val/3,rewrite_image_paths/1]).



split_file(Binary) ->
    case re:run(Binary, ~"^---(?:\r?\n)(.*?)(?:\r?\n)---(?:\r?\n)(.*)$",
                [dotall, ungreedy, {capture, all_but_first, binary}]) of
        {match, [Meta, Body]} -> {Meta, Body};
        nomatch -> {<<>>, Binary}
    end.

get_val(Key, Meta, Default) ->
    Pattern = [Key, ~":[ \t]*\"?(.*?)\"?(?:\r?\n|$)"],
    case re:run(Meta, Pattern, [{capture, all_but_first, binary}]) of
        {match, [Val]} -> Val;
        nomatch -> Default
    end.

rewrite_image_paths(Body) ->
    %% Simplified regex and logic
    Pattern = ~"<img([^>]*?)src=(['\"])(?:\.\./)?priv/static/img/([^'\">]+?)(?:\.(?:jpg|jpeg|png))\\2([^>]*)>",
    case scribbles_assets:image_program() of
        {ok, _} ->
            Repl = ~"<img\\1src=\\2/assets/static/img/\\3-lg.webp\\2\\4 srcset=\\2/assets/static/img/\\3-thumb.webp 64w, /assets/static/img/\\3-lg.webp 1200w\\2 sizes=\"(max-width: 600px) 100vw, 1200px\">",
            re:replace(Body, Pattern, Repl, [global, {return, binary}]);
        _ ->
            Repl = ~"<img\\1src=\\2/assets/static/img/\\3.jpg\\2\\4",
            re:replace(Body, Pattern, Repl, [global, {return, binary}])
    end.
