%%%-------------------------------------------------------------------
%%% scribbles top level supervisor.
%%% This is the root of our supervision tree. It starts the watcher and builder.
%%% 
%%%-------------------------------------------------------------------

-module(scribbles_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1,
        period => 5
    },

    %% Define your two workers
    ChildSpecs = [
        #{id => scribbles_builder,
          start => {scribbles_builder, start_link, []},
          restart => permanent},

        #{id => scribbles_watcher,
          start => {scribbles_watcher, start_link, ["./posts"]}, %% Pass your source dir
          restart => permanent}
    ],

    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
