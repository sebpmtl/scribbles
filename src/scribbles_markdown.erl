-module(scribbles_markdown).
-export([run_build/0, split_file/1, get_val/3]).

%%% Scribbles Engine V3: Alphabetical Files, Chronological Masonry.

run_build() ->

    %% 1. Sync static assets first
    sync_assets(),

    filelib:ensure_dir("compiled/posts/dummy.txt"),
    Files = filelib:wildcard("posts/*.md"),
    io:format("Found ~p files. Scanning...~n", [length(Files)]),

    %% 1. Scan and Parse (Alphabetical by filename)
    AllData = [parse_post(F) || F <- Files],

    %% 2. The Chronological Sort (Newest ISO dates first)
    Posts = lists:sort(
        fun(#{date := DateA}, #{date := DateB}) -> DateA > DateB end,
        [P || P <- AllData, maps:get(draft, P) == false]
    ),

    %% 3. Generate Individual Post Pages (slug/index.html)
    [render_post_page(P) || P <- Posts],

    %% 4. Generate the Infinite Masonry Index
    render_index_page(Posts),

    %% 5. Generate static pages
    render_contact_page(),

    io:format("Build complete: ~p posts published.~n", [length(Posts)]).

%% --- Internals ---

parse_post(Path) ->
    {ok, Raw} = file:read_file(Path),
    {Meta, Body} = split_file(Raw),

    %% Fallback: Today's ISO date
    {{Y, M, D}, _} = calendar:local_time(),
    Today = iolist_to_binary(io_lib:format("~4..0w-~2..0w-~2..0w", [Y, M, D])),

    %% Slug is strictly the filename (minus .md)
    Slug = filename:basename(Path, ~".md"),

    #{
        title => get_val(~"title", Meta, ~"Untitled"),
        date  => get_val(~"date", Meta, Today),
        slug  => Slug,
        body  => Body,
        draft => (string:trim(string:lowercase(get_val(~"draft", Meta, ~"false"))) == ~"true")
    }.

render_post_page(#{slug := Slug, title := T, date := D, body := B}) ->
    io:format("  [Post] /posts/~s/~n", [Slug]),

    HtmlBody0 = list_to_binary(markdown:conv_utf8(binary_to_list(B))),
    HtmlBody = rewrite_image_paths(HtmlBody0),

    %% Wrap in layout
    FinalHtml = << (scribbles_templates:render_header(post, T, D))/binary,
                   HtmlBody/binary,
                   (scribbles_templates:footer())/binary >>,

    %% Ensure directory: compiled/posts/slug/
    PostDir = filename:join([~"compiled", ~"posts", Slug]),
    filelib:ensure_dir(filename:join(PostDir, ~"index.html")),

    file:write_file(filename:join(PostDir, ~"index.html"), FinalHtml).

render_index_page(Posts) ->
    io:format("  [Index] Generating Masonry Home...~n"),

    GridHtml = scribbles_templates:masonry_grid(Posts),

    IndexHtml = << (scribbles_templates:render_header(home, ~"Scribbles", ~""))/binary,
                   GridHtml/binary,
                   (scribbles_templates:footer())/binary >>,

    file:write_file(~"compiled/index.html", IndexHtml).

render_contact_page() ->
    io:format("  [Contact] Generating contact.html~n"),
    Body = <<
      "<section>"
        "<h3>Contact</h2>"
        "<p>Find me online:</p>"
        "<ul>"
          "<li><a href='https://github.com/your-handle'>github</a></li>"
          "<li><a href='https://instagram.com/your-handle'>instagram</a></li>"
          "<li><a href='https://your-bandcamp-account.bandcamp.com'>bandcamp</a></li>"
          "<li><a href='/rss.xml'>rss</a></li>"
        "</ul>"
      "</section>"
    >>,
    ContactHtml = << (scribbles_templates:render_header(contact, ~"Contact", ~""))/binary,
                    Body/binary,
                    (scribbles_templates:footer())/binary >>,
    file:write_file(~"compiled/contact.html", ContactHtml).

rewrite_image_paths(Body) ->
    case scribbles_assets:image_program() of
        {ok, _} ->
            Pattern = ~"<img([^>]*?)src=(['\"])(?:\.\./)?priv/static/img/([^'\">]+?)(?:\.(?:jpg|jpeg|png))\\2([^>]*)>",
            Replacement = ~"<img\\1src=\\2/assets/static/img/\\3-lg.webp\\2\\4 srcset=\\2/assets/static/img/\\3-thumb.webp 64w, /assets/static/img/\\3-lg.webp 1200w\\2 sizes=\\\"(max-width: 600px) 100vw, 1200px\\\">",
            re:replace(Body, Pattern, Replacement, [global, {return, binary}]);
        {error, no_imagemagick} ->
            Pattern = ~"<img([^>]*?)src=(['\"])(?:\.\./)?priv/static/img/([^'\">]+?)(?:\.(?:jpg|jpeg|png))\\2([^>]*)>",
            Replacement = ~"<img\\1src=\\2/assets/static/img/\\3.jpg\\2\\4",
            re:replace(Body, Pattern, Replacement, [global, {return, binary}])
    end.

skip_raw_image(F) ->
    case re:run(F, "^priv/static/img/.*\\.(?:jpg|jpeg|png)$", [caseless]) of
        {match, _} -> true;
        nomatch -> false
    end.

split_file(Binary) ->
    %% The 'U' (ungreedy) option is key here.
    %% It ensures we stop at the first '---' after the header starts.
    case re:run(Binary, ~"^---(?:\r?\n)(.*?)(?:\r?\n)---(?:\r?\n)(.*)$",
                [dotall, ungreedy, {capture, all_but_first, binary}]) of
        {match, [Meta, Body]} -> {Meta, Body};
        nomatch -> {<<>>, Binary}
    end.

get_val(Key, Meta, Default) ->
    Pattern = <<Key/binary, ~":[ \\t]*\"?(.*?)\"?(?:\r?\n|$)"/binary>>,
    case re:run(Meta, Pattern, [{capture, all_but_first, binary}]) of
        {match, [Val]} -> Val;
        nomatch -> Default
    end.

sync_assets() ->
    io:format("  [Sync] Mapping priv/ to compiled/assets/...~n"),
    scribbles_assets:process_images("priv/static/img", "compiled/assets/static/img"),

    %% We want everything INSIDE priv/ to end up in compiled/assets/
    Files = filelib:wildcard("priv/**"),

    [begin
        %% Strip the "priv/" prefix from the path
        RelativePath = re:replace(F, "^priv/", "", [{return, list}]),

        %% New destination: compiled/assets/ + whatever was in priv
        Target = filename:join(["compiled", "assets", RelativePath]),

        case filelib:is_dir(F) of
            true ->
                filelib:ensure_dir(filename:join(Target, "dummy.txt"));
            false ->
                case skip_raw_image(F) of
                    true -> ok;
                    false ->
                        filelib:ensure_dir(Target),
                        case file:copy(F, Target) of
                            {ok, _} ->
                                io:format("  [OK] ~s -> ~s~n", [F, Target]);
                            {error, R} ->
                                io:format("  [!] Failed ~s: ~p~n", [F, R])
                        end
                end
        end
     end || F <- Files].
