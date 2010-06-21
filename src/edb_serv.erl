%%edb gen server
%%
-module(edb_serv).
-vsn(0.1).
-author("Andy Chow <diudiu8848@163.com>").
-behaviour(gen_server).

%%API
-export([start/1, stop/0]).
-export([get/2, exec/2]).
-export([get_ext/2]).

%%CallBack
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).


%%api
start(Args) ->
    %%get db config
    {_Local, DBCfg} = Args,
    
    %%start gen server
    case gen_server:start({local, ?MODULE}, ?MODULE, DBCfg, []) of
        {ok, Pid} ->
            {ok, Pid};
        {error, {already_started, Pid}} ->
            {ok, Pid};
        Other ->
            Other
    end.

stop() ->
    gen_server:call(?MODULE, stop).


get(DBTag, SQL) ->
    gen_server:call(?MODULE, {get, DBTag, SQL}).
    
exec(DBTag, SQL) ->
    gen_server:call(?MODULE, {exec, DBTag, SQL}).

%%-spec getExt(atom, list) -> {ok, Rec}.
get_ext(Tab, SQL) ->
    gen_server:call(?MODULE, {get_ext, Tab, SQL}).
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%private functions%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%call backs
init(Args) ->
    %%{ok, DbServCfg} = application:get_env(?MODULE, db_setup),  
    {ok, DBObjList} = edb_db:init(Args),
    
    %%return mutl db pool object list
    {ok, DBObjList}.

handle_call({get, DBTag, Sql}, _From, State) ->
    Reply = edb_db:getRec(State, DBTag, Sql),
    {reply, Reply, State};
handle_call({exec, DBTag, Sql}, _From, State) ->
    Reply = edb_db:exec(State, DBTag, Sql),
    {reply, Reply, State};
handle_call({get_ext, Tab, Sql}, _From, State) ->
    Reply = edb_db:getRecExt(State, Tab, Sql),
    {reply, Reply, State};
handle_call(stop, _From, State) ->
    {stop, normal, State}.
    

handle_cast(_Msg, State) ->
    {noreply, State}.    
    
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
