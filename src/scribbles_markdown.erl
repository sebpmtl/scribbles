-module(scribbles_markdown).
-export([run_build/0]).

run_build() ->
    scribbles_assets:sync_assets(),
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
    {Meta, Body} = scribbles_parser:split_file(Raw),

    {{Y, M, D}, _} = calendar:local_time(),
    Today = iolist_to_binary(io_lib:format("~4..0w-~2..0w-~2..0w", [Y, M, D])),
    Slug = filename:basename(Path, ~".md"),

    #{
        title => scribbles_parser:get_val(~"title", Meta, ~"Untitled"),
        date  => scribbles_parser:get_val(~"date", Meta, Today),
        slug  => Slug,
        body  => Body,
        draft => (string:lowercase(scribbles_parser:get_val(~"draft", Meta, ~"false")) == ~"true")
    }.

render_post_page(#{slug := Slug, title := T, date := D, body := B}) ->
    io:format("  [Post] /posts/~s/~n", [Slug]),

    HtmlBody = scribbles_parser:rewrite_image_paths(md:to_html(B)),

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
