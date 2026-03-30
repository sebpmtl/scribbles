-module(scribbles_templates).
-export([header/2, footer/0]).

%%%-------------------------------------------------------------------
%%% scribbles templates.
%%% This module provides simple HTML templates for the documentation.
%%% The 'header' function takes a title and date and returns the HTML header with that title and date.
%%% The 'footer' function returns the HTML footer.
%%%-------------------------------------------------------------------


header(Title, Date) ->
    << "<!DOCTYPE html>\n<html>\n<head>\n",
       "  <title>", Title/binary, "</title>\n",
       "  <link rel=\"stylesheet\" href=\"static/css/style.css\">\n",
       "</head>\n<body>\n",
       "  <p class=\"date\">Published on: ", Date/binary, "</p>\n",
       "  <h1>", Title/binary, "</h1>\n" >>.

footer() ->
    << "\n</body>\n</html>" >>.