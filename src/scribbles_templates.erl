-module(scribbles_templates).
-export([render_header/3, footer/0, masonry_grid/1]).

render_header(PageType, Title, DateHtml) ->
    %% Only show the Title and Date if we are on a post
    MetaBlock = case PageType of
        home -> <<>>; 
        post -> 
            << "<h2>", Title/binary, "</h2>", 
               "<span class='post-date'>", DateHtml/binary, "</span>" >>
    end,

    MainClass = case PageType of
        home -> <<>>;
        post -> <<" class='post'">>
    end,

    <<
      "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
      "<title>", Title/binary, "</title>"
      "<link rel='icon' type='image/png' sizes='256x256' href='/assets/static/img/fav-256-lg.webp'>"
      "<link rel='icon' type='image/png' sizes='128x128' href='/assets/static/img/fav-128-lg.webp'>"
      "<link rel='stylesheet' href='/assets/static/css/style.css'>"
      "<link rel='preconnect' href='https://fonts.googleapis.com'>"
      "<link rel='preconnect' href='https://fonts.gstatic.com' crossorigin>"
      "<link href='https://fonts.googleapis.com/css2?family=Silkscreen:wght@400;700&display=swap' rel='stylesheet'>"
      "</head><body>"
      "<header>"
        "<h1><a href='/'>SCRIBBLES</a></h1>"
        , MetaBlock/binary, 
        "<nav><ul>"
          "<li><a href='/'>home</a></li>"
          "<li><a href='/music.html'>music</a></li>"
          "<li><a href='/about.html'>about</a></li>"
          "<li><a href='/contact.html'>contact</a></li>"
        "</ul></nav>"
      "</header>"
      "<main", MainClass/binary, ">"
    >>.

footer() ->
    <<"</main><footer>&copy; 2026 Scribbles</footer></body></html>">>.

masonry_grid(Posts) ->
    %% Start the container
    Items = [render_card(P) || P <- Posts],
    << "<div class='masonry-container'>", (iolist_to_binary(Items))/binary, "</div>" >>.

render_card(#{title := T, date := D, slug := S, body := B}) ->
    %% 1. Strip ALL newlines and carriage returns globally
    %% This turns the whole post into one long single-line string.
    FlatBody = re:replace(B, <<"[\\r\\n]+">>, <<" ">>, [global, {return, binary}]),
    
    %% 2. Trim and force to binary
    TrimmedBody = case unicode:characters_to_binary(string:trim(FlatBody)) of
        Bin when is_binary(Bin) -> Bin;
        _ -> << "Encoding Error" >>
    end,
    
    %% 3. Slice the first 200 characters
    Teaser = case byte_size(TrimmedBody) > 200 of
        true -> <<(binary:part(TrimmedBody, 0, 200))/binary, "...">>;
        false -> TrimmedBody
    end,
    
    %% 4. Assemble the HTML
    %% Note: We use a <span> or just raw text inside the <a> to prevent block-level issues
    <<
      "<a href='/posts/", S/binary, "/' class='post-card'>",
        "<time>", D/binary, "</time>",
        "<h2>", T/binary, "</h2>",
        "<span class='teaser-text'>", Teaser/binary, "</span>",
      "</a>"
    >>.