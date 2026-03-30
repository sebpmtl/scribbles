-module(scribbles_builder).
-behaviour(gen_server).

-export([start_link/0, rebuild/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

rebuild() ->
    gen_server:cast(?MODULE, build).

init([]) ->
    %% Optional: Trigger a build immediately on startup
    rebuild(),
    {ok, #{}}.

handle_cast(build, State) ->
    case code:load_file(scribbles_markdown) of
        {module, scribbles_markdown} ->
            ok;
        {error, Reason} ->
            io:format("Builder: failed reloading scribbles_markdown: ~p~n", [Reason])
    end,
    scribbles_markdown:run_build(),
    {noreply, State}.

handle_call(_Request, _From, State) -> {reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.