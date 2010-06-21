%%edb db interface
%%
-module(edb_db).
-vsn(0.1).
-author("Andy Chow <diudiu8848@163.com>").
-include("../include/edb.hrl").

%%api
-export([init/1, getRec/3, getRecExt/3, exec/3]).

init(DBParaList) ->
   
    DBTagList = init_db_servs(DBParaList, []),
    
    %%return db object atom
    {ok, DBTagList}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%API%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%init db server pool
init_db_servs([], DBObjList) ->
    DBObjList;
init_db_servs([H|T], DBObjList) ->
    {ok, TagName} = init_sig_db_serv(H),
    NewDBObjList = [TagName|DBObjList],
    init_db_servs(T, NewDBObjList).
    

%%init and connect signal db server
init_sig_db_serv(SigDBCfg) ->

    {TagName, DBServ, DBUser, DBPasswd, DBName, Pools} = SigDBCfg,
    DBPara = {DBServ, DBUser, DBPasswd, DBName},
    
    %%start new mysql service
    mysql:start_link(TagName, DBServ, DBUser, DBPasswd, DBName),
    
    %%create db service pool
    conn_pool(TagName, 1, Pools, DBPara),
    
    {ok, TagName}.
    

%%get record from assigned sql segment
getRec(DBObjList, DBTag, Sql) ->

    TmpList = get_sig_db_tag(DBObjList, DBTag),
    
    if
        is_list(TmpList), length(TmpList) > 0 ->
    
            %%get record from db server
            if
                is_list(DBTag), length(DBTag) > 0 ->
                    DBTagAtom = list_to_atom(DBTag);
                true ->
                    DBTagAtom = DBTag
            end,
        
            {_, Data} = mysql:fetch(DBTagAtom, Sql),
            {_, TabKeyInfo, DBRec, _, _} = Data,
            
            %%analize table key info
            {ok, KeyList} = analize_tab_keys(TabKeyInfo),

            %%analize record
            TRec = [binary_convert(H) || H <- DBRec],
            NRec = [list_to_tuple(X) || X <- TRec],
            DBNewRec = [list_to_tuple(KeyList)|NRec];
        true ->
            DBNewRec = []
    end,
    
    {ok, DBNewRec}.


%%get record ext
getRecExt(DBObj, Tab, Sql) ->
    {_, Data} = mysql:fetch(DBObj, Sql),
    {_, Key, Rec, _, _} = Data,    
    TRec = [binary_convert_ext(Tab, H) || H <- Rec],    
    NRec = [list_to_tuple(X) || X <- TRec],
    {ok, NRec}.


%%execute sql segment
exec(DBObjList, DBTag, Sql) ->

    TmpList = get_sig_db_tag(DBObjList, DBTag),
    
    if
        is_list(TmpList), length(TmpList) > 0 ->
    
            if
                is_list(DBTag), length(DBTag) > 0 ->
                    DBTagAtom = list_to_atom(DBTag);
                true ->
                    DBTagAtom = DBTag
            end,
    
            Result = mysql:fetch(DBTagAtom, Sql);
        true ->
            Result = "0"
    end,
    
    %%io:format("~na:~ts~n", [SqlTest]),
    %%io:format("~nb:~ts~n", [Sql]),
    %%io:format("~nResult:~p~n", [Result]),
    
    {ok, Result}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%private functions%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%get signal db service tag
get_sig_db_tag(RecList, TagName) ->
    AtomName = list_to_atom(TagName),
    SFun = fun(X) -> X =:= AtomName end,
    lists:filter(SFun, RecList).

%% create mysql connect pool
conn_pool(DBTag, Max, Max, Para) ->
    {Db_serv, Db_user, Db_pwd, Db_name} = Para,
    mysql:connect(DBTag, Db_serv, undefined, Db_user, Db_pwd, Db_name, true);
conn_pool(DBTag, Min, Max, Para) ->
    {Db_serv, Db_user, Db_pwd, Db_name} = Para,
    mysql:connect(DBTag, Db_serv, undefined, Db_user, Db_pwd, Db_name, true),
    conn_pool(DBTag, Min + 1, Max, Para).


%%analize table key info, reformat as tuple for return
analize_tab_keys(TabKeyInfo) ->
    TabKeyList = filter_tab_key(TabKeyInfo, []),
    {ok, TabKeyList}.


%%filter signal table key
filter_tab_key([], L) ->
    lists:reverse(L);
filter_tab_key([H|T], L) ->
    {_,TmpKey,_,_} = H,
    NewList = [edb_utils:binary_check(TmpKey)|L],
    filter_tab_key(T, NewList).
    
binary_convert_ext(Tab, L) ->
    TmpList = [Tab|L],
    NList = [edb_utils:binary_check(H) || H <- TmpList],
    NList.

%%binary convert
binary_convert(L) ->
    %%io:format("~n~p~n", [L]),
    NList = [edb_utils:binary_check(H) || H <- L],
    NList.
