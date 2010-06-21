%%edb socket server
%%
-module(edb_socket_serv).
-author("Andy Chow <diudiu8848@gmail.com>").
-vsn(0.1).
-behaviour(gen_server).
-include("../include/edb.hrl").

-define(TCP_OPTIONS, [binary, {packet, 0}, {active, true}, {reuseaddr, true}]).
-define(EDB_SOCK_PORT, 5555).

%%API
-export([start/1, stop/0]).

%%CallBack
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).


%%%%%%%%%%%%%%%%%%%%

%%start socket server
start(Args) ->
    %%get sock cfg 
    {_Local, SockServCfg} = Args,
    
    %%start gen server
    case gen_server:start({local, ?MODULE}, ?MODULE, SockServCfg, []) of
        {ok, Pid} ->
            {ok, Pid};
        {error, {already_started, Pid}} ->
            {ok, Pid};
        Other ->
            Other
    end.


init(Args) ->
    %%{ok, DbServCfg} = application:get_env(?MODULE, db_setup),
    State = "ok",    
    [SockPort|T] = Args,
    
    if 
        is_integer(SockPort), SockPort > 0 ->
            SockServPort = SockPort;
        true->
            SockServPort = ?EDB_SOCK_PORT
    end,
    
    %%init socket listen
    Pid = spawn(fun() -> manage_clients([]) end),
    register(client_manager, Pid),
    
    %%listen port
    {ok, Listener} = gen_tcp:listen(SockServPort, ?TCP_OPTIONS),
   
    %%spawn new process
    SFun = fun() -> process_connect(Listener) end,
    spawn(SFun),
    
    {ok, State}.
    
stop() ->
    gen_server:call(?MODULE, stop).

%%process signal client connect
process_connect(Listener) ->
    %%accept signal connect
    case gen_tcp:accept(Listener) of
    
        {ok, Socket} ->
            spawn(fun() -> process_connect(Listener) end),
    
            %%send socket handle to manager
            client_manager ! {connect, Socket},
    
            %%wait connected client command
            wait_client(Socket);
        
        {error,closed} ->
            void
    end.
    

%%wait and process connected client command
wait_client(Socket) ->
    receive
        {tcp, Socket, Data} ->
            process_client_command(Socket, Data),
            wait_client(Socket);
        {tcp_closed, Socket} ->
            client_manager ! {disconnect, Socket};
        {error,closed} ->
            client_manager ! {disconnect, Socket};            
        _Any ->
            wait_client(Socket)
    end.


%%client command process
process_client_command(Socket, Data) ->

    %%analize client cmd, xml format
    {Cmd, DbTag, Sql} = analize_clnt_cmd(Data),
    AtomCmd = list_to_atom(Cmd),
    
    
    case AtomCmd of
        get ->
            {ok, Reply} = edb_serv:get(DbTag, Sql),
            NewReply = edb_socket_xml:format_db_rec(Reply);
        exec ->
            {ok, Reply} = edb_serv:exec(DbTag, Sql),            
            NewReply = edb_socket_xml:format_exec_ret(Reply);
        _->
            NewReply = edb_socket_xml:format_invalid_cmd()
    end,
   
    %%send data to client
    %%NewReplyExt = utf8:from_binary(list_to_binary(NewReply)),
    gen_tcp:send(Socket, NewReply ++ "\n\r").
    

%%analize client xml command
%%<xml><cmd>xxx</cmd><sql><![CDATA[xxxx]]></sql></xml>
analize_clnt_cmd(Data) ->
    %%io:format("~nData:~p~n", [Data]),
    %%command string convert, and remove unuseful characters
    NewData = edb_utils:binary_check(Data),
    Str = string:strip(NewData, both, $\n),
    NewStr = string:strip(Str, both, $\r),
    
    if
        is_list(NewStr), length(NewStr) > 10 ->  
            {Xml, _Rest} = xmerl_scan:string(NewStr),
            [ #xmlText{value=Cmd} ]  = xmerl_xpath:string("//cmd/text()", Xml),
            [ #xmlText{value=DBTag} ]  = xmerl_xpath:string("//dbtag/text()", Xml),        
            [ #xmlText{value=Sql} ] = xmerl_xpath:string("//sql/text()", Xml),
        
            %%for chinese utf8 code
            [DescBinSql] = io_lib:format("~ts", [Sql]),
        
            {Cmd, DBTag, DescBinSql};
        true ->
            {"Invalid", ""}
    end.
    

%%client manager
manage_clients(Sockets) ->
    receive
        {connect, Socket} ->
            %%increate socket list
            NewSockets = [Socket|Sockets],
            Total_clients = length(Sockets) + 1;
        {disconnect, Socket} ->
            %%decreate socket list
            NewSockets = lists:delete(Socket, Sockets),            
            Total_clients = length(Sockets) - 1;
        _Any ->
            NewSockets = Sockets,
            Total_clients = length(Sockets)
    end,
    io:format("~ntotal clients:~p~n", [Total_clients]),
    manage_clients(NewSockets).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%private functions%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%call backs
handle_call(stop, _From, State) ->
    {stop, normal, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.
    
handle_cast(_Msg, State) ->
    {noreply, State}.
    
    
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

