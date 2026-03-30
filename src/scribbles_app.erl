%%%-------------------------------------------------------------------
%%%  scribbles public API
%%%   This is the entry point for our application. It starts the supervision tree.
%%%-------------------------------------------------------------------

-module(scribbles_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    scribbles_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
