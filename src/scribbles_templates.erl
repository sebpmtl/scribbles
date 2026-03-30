-module(scribbles_templates).
-export([header/2, footer/0, masonry_grid/1]).

header(Title, Date) ->
    DateHtml = case Date of
        <<"">> -> << >>; %% Hide date on home
        _ -> <<"<time class='iso-date'>", Date/binary, "</time>">>
    end,
    <<
      "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
      "<title>", Title/binary, "</title>"
      "<link rel='stylesheet' href='/assets/static/css/style.css'>"
      "</head><body>"
      "<header><h1>", Title/binary, "</h1>", DateHtml/binary, "</header>"
      "<main>"
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