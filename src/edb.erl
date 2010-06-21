%%edb application server
%%
-module(edb).
-vsn(0.1).
-author("Andy Chow <diudiu8848@163.com>").
-behaviour(application).

%%API
-export([start/0, stop/0]).
-export([get/1, get_ext/2, exec/1]).

%%CallBack
-export([start/2, stop/1]).


%%api
start() ->
    application:start(?MODULE).
    
stop() ->
    application:stop(?MODULE).

%%call back
start(_StartType, _StartArgs) ->
    %%get db setup from application config
    {ok, DbServCfg} = application:get_env(?MODULE, db_setup),
    {ok, SockServCfg} = application:get_env(?MODULE, sock_setup),
    AppServCfg = [DbServCfg,SockServCfg],
    
    case edb_sup:start_link(AppServCfg) of
        {ok, Pid} ->
            {ok, Pid};
        Error ->
            Error
    end.
    
stop(_State) ->
    ok.


%%get record
get(Sql) ->
    edb_serv:get(Sql).
    
%%get record ext, for erlang-web
get_ext(Tab, Sql) ->
    edb_serv:get_ext(Tab, Sql).

%%exec sql, like insert、update、delete
exec(Sql) ->
    edb_serv:exec(Sql).
