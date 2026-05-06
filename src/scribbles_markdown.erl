-module(scribbles_markdown).
-export([run_build/0, split_file/1, get_val/3]).

run_build() ->
    sync_assets(),
    filelib:ensure_dir(~"compiled/posts/dummy.txt"),

    Files = filelib:wildcard("posts/*.md"),
    io:format("Found ~p files. Scanning...~n", [length(Files)]),

    %% Parse and filter drafts in one pass
    AllData = [parse_post(F) || F <- Files],
    Posts = lists:sort(
        fun(#{date := DateA}, #{date := DateB}) -> DateA > DateB end,
        [P || P <- AllData, maps:get(draft, P) == false]
    ),

    [render_post_page(P) || P <- Posts],
    render_index_page(Posts),
    render_contact_page(),

    io:format("Build complete: ~p posts published.~n", [length(Posts)]).

%% --- Internals ---

parse_post(Path) ->
    {ok, Raw} = file:read_file(Path),
    {Meta, Body} = split_file(Raw),

    {{Y, M, D}, _} = calendar:local_time(),
    Today = iolist_to_binary(io_lib:format("~4..0w-~2..0w-~2..0w", [Y, M, D])),
    Slug = filename:basename(Path, ~".md"),

    #{
        title => get_val(~"title", Meta, ~"Untitled"),
        date  => get_val(~"date", Meta, Today),
        slug  => Slug,
        body  => Body,
        draft => (string:lowercase(get_val(~"draft", Meta, ~"false")) == ~"true")
    }.

render_post_page(#{slug := Slug, title := T, date := D, body := B}) ->
    io:format("  [Post] /posts/~s/~n", [Slug]),

    HtmlBody = rewrite_image_paths(md:to_html(B)),

    %% Use IO List instead of binary concatenation
    FinalHtml = [
        scribbles_templates:render_header(post, T, D),
        HtmlBody,
        scribbles_templates:footer()
    ],

    PostDir = filename:join([~"compiled", ~"posts", Slug]),
    TargetFile = filename:join(PostDir, ~"index.html"),
    filelib:ensure_dir(TargetFile),
    file:write_file(TargetFile, FinalHtml).

render_index_page(Posts) ->
    io:format("  [Index] Generating Masonry Home...~n"),

    IndexHtml = [
        scribbles_templates:render_header(home, ~"Scribbles", ~""),
        scribbles_templates:masonry_grid(Posts),
        scribbles_templates:footer()
    ],
    file:write_file(~"compiled/index.html", IndexHtml).

render_contact_page() ->
    io:format("  [Contact] Generating contact.html~n"),

    Body = [
        ~"<section><h3>Contact</h3>",
        ~"<p>Find me online:</p><ul>",
        ~"<li><a href='https://github.com/your-handle'>github</a></li>",
        ~"<li><a href='/rss.xml'>rss</a></li></ul></section>"
    ],

    ContactHtml = [
        scribbles_templates:render_header(contact, ~"Contact", ~""),
        Body,
        scribbles_templates:footer()
    ],
    file:write_file(~"compiled/contact.html", ContactHtml).

%% --- Helpers ---

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

sync_assets() ->
    io:format("  [Sync] Mapping priv/ to compiled/assets/...~n"),
    scribbles_assets:process_images("priv/static/img", "compiled/assets/static/img"),

    Files = filelib:wildcard("priv/**"),
    [copy_asset(F) || F <- Files].

copy_asset(Src) ->
    RelPath = re:replace(Src, "^priv/", "", [{return, list}]),
    Target = filename:join(["compiled", "assets", RelPath]),

    case filelib:is_dir(Src) of
        true -> filelib:ensure_dir(filename:join(Target, "dummy.txt"));
        false ->
            case is_raw_image(Src) of
                true -> ok;
                false ->
                    filelib:ensure_dir(Target),
                    file:copy(Src, Target)
            end
    end.

is_raw_image(F) ->
    re:run(F, "\\.(?:jpg|jpeg|png)$", [caseless]) /= nomatch.
