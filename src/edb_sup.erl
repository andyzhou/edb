%%edb supervisor server
%%

-module(edb_sup).
-vsn(0.1).
-author("Andy Chow <diudiu8848@163.com>").
-behaviour(supervisor).

%%API
-export([start_link/1, init/1]).

start_link(Args) ->
    supervisor:start_link(?MODULE, Args).
    
init(Args) ->
    [DBServCfg, SockServCfg|T] = Args,    
    
    ChildGenServ = {edb_serv, {edb_serv, start, [{local, DBServCfg}]}, permanent, 2000, worker, [edb_serv]},
    ChildSockServ = {edb_socket_serv, {edb_socket_serv, start, [{local, SockServCfg}]}, permanent, 2000, worker, [edb_socket_serv]},
    
    {ok, {{one_for_one, 3, 10}, [ChildGenServ, ChildSockServ]}}.
