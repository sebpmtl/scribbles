-module(scribbles_templates).
-export([header/1, footer/0]).

%%%-------------------------------------------------------------------
%%% scribbles templates.
%%% This module provides simple HTML templates for the documentation.
%%% The 'header' function takes a title and returns the HTML header with that title.
%%% The 'footer' function returns the HTML footer.
%%%-------------------------------------------------------------------


header(Title) ->
    << "<!DOCTYPE html>\n<html>\n<head>\n",
       "  <meta charset=\"UTF-8\">\n",
       "  <title>", Title/binary, "</title>\n",
       "</head>\n<body>\n" >>.

footer() ->
    << "\n</body>\n</html>" >>.