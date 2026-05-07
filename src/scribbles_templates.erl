-module(scribbles_templates).
-export([render_header/3, footer/0, masonry_grid/1]).

render_header(PageType, Title, DateHtml) ->
    %% MetaBlock is now just a sub-list (IO List)
    MetaBlock = case PageType of
        home -> [];
        post ->
            [~"<h2>", Title, ~"</h2>",
             ~"<time>", DateHtml, ~"</time>"];
        archive -> []
    end,

    BodyAttr = case PageType of
        home -> ~" data-page='home'";
        post -> ~" data-page='post'";
        archive -> ~" data-page='archive'"
    end,

    %% The whole return value is one large IO List
    [
      ~"<!DOCTYPE html><html><head><meta charset='UTF-8'>",
      ~"<title>", Title, ~"</title>",
      ~"<link rel='stylesheet' href='/assets/static/css/style.css'>",
      ~"</head><body>",
      ~"<header>",
        ~"<h1><a href='/'>SCRIBBLES</a></h1>",
        ~"<nav><ul>",
          ~"<li><a href='/'>home</a></li>",
          ~"<li><a href='/archive.html'>archive</a></li>",
          ~"<li><a href='/about.html'>about</a></li>",
        ~"</ul></nav>",
       MetaBlock,
      ~"</header>",
      ~"<main", BodyAttr, ~">"
    ].

footer() ->
    ~"</main><footer>&copy; 2026 Scribbles</footer></body></html>".

masonry_grid(Posts) ->
    %% Items is a list of lists. We wrap it in the div tags.
    Items = [render_card(P) || P <- Posts],
    [~"<div class='masonry'>", Items, ~"</div>"].

render_card(#{title := T, date := D, slug := S, body := B}) ->
    TeaserHtml = case byte_size(B) > 200 of
        true -> md:to_html(binary:part(B, 0, 200));
        false -> md:to_html(B)
    end,

    [
      ~"<article>",
        ~"<a href='/posts/", S, ~"/'>",
          ~"<time>", D, ~"</time>",
          ~"<h2>", T, ~"</h2>",
          TeaserHtml,
        ~"</a>",
      ~"</article>"
    ].
