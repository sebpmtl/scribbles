-module(scribbles_watcher).
-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

%%%-------------------------------------------------------------------
%%% scribbles file watcher.
%%% This module is responsible for watching the 'posts' directory for changes.
%%% When a change is detected, it tells the builder to rebuild the site.

start_link(Path) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Path, []).

init(Path) ->
    %% Start polling every 1000ms
    timer:send_interval(1000, tick),
    %% We initialize last_mod to the current time so it doesn't
    %% double-build immediately on startup if you don't want it to.
    {ok, #{path => Path, last_mod => filelib:last_modified(Path)}}.

%% This handles the 'tick' from our timer
handle_info(tick, State = #{path := Path, last_mod := LastMod}) ->
    %% 1. Force everything to a list (String) to satisfy the type checker
    SearchPath = [filename:join(P, "*.*") || P <- Path ],

    %% 2. Now filelib:wildcard is 100% happy with a string()
    Files = lists:append([filelib:wildcard(S) || S <- SearchPath]),

    io:format("Files:  ~p~n",[Files]),

    CurrentMaxMod = case Files of
        [] -> 0;
        _ -> lists:max([filelib:last_modified(F) || F <- Files])
    end,

    case CurrentMaxMod > LastMod of
        true ->
            io:format("Watcher: Change detected in ~s~n", [Path]),
            timer:sleep(100),
            scribbles_builder:rebuild(),
            {noreply, State#{last_mod := CurrentMaxMod}};
        false ->
            {noreply, State}
    end;
handle_info(_Info, State) ->
    {noreply, State}.

%% --- ADD THESE TO STOP THE WARNINGS ---

handle_call(_Request, _From, State) ->
    %% This is for synchronous calls (which we aren't using yet)
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    %% This is for asynchronous casts (which we aren't using yet)
    {noreply, State}.
