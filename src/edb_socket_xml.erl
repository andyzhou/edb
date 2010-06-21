%%edb socket xml functions
%%
-module(edb_socket_xml).
-vsn(0.1).
-author("Andy Chow <diudiu8848@163.com>").
-export([format_db_rec/1, format_exec_ret/1, format_invalid_cmd/0]).

-define(EDB_XML_HEAD, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><xml>").
-define(EDB_XML_BOTTOM, "</xml>").

%%reformat db record into xml format
format_db_rec(DataList) ->
    if
        is_list(DataList), length(DataList) > 1 ->
            Len = length(DataList),
            Reply = analize_db_rec(DataList, {}, 0, []) ++ "</reclist>";
        true ->
            Reply = "<info><ret>0</ret></info>"
    end,
    
    ?EDB_XML_HEAD ++ Reply ++ ?EDB_XML_BOTTOM.
    

%%analize and reformat db exec return
format_exec_ret(ReturnInfo) ->
    {ExecResult, ExecRetInfo} = ReturnInfo,
    {_,_,_,AffectedRows,Msg} = ExecRetInfo,
    MsgStr = edb_utils:binary_check(Msg),
    
    case ExecResult of
        updated ->
            RetStr = "1";
        error ->
            RetStr = "0";
        _->
            RetStr = "0"
    end,
    
    AffectedRowsStr = "<rows>" ++ integer_to_list(AffectedRows) ++ "</rows>",
    DBMsgStr = "<msg>" ++ MsgStr ++ "</msg>",
    
    Reply = "<ret>" ++ RetStr ++ "</ret>" ++ AffectedRowsStr ++ DBMsgStr,
    ?EDB_XML_HEAD ++ Reply ++ ?EDB_XML_BOTTOM.


%%format invalid command
format_invalid_cmd() ->
    ?EDB_XML_HEAD ++ "<ret>0</ret>" ++ ?EDB_XML_BOTTOM.

%%%%%%%%%%%%%%%%%%%%%%%%
%%private functions
%%%%%%%%%%%%%%%%%%%%%%%%


%%analize data record
analize_db_rec([], ColumnTuple, X, XmlStr) ->
    XmlStr;
analize_db_rec([H|T], ColumnTuple, X, XmlStr) ->
    %%io:format("~nX:~p~n", [X]),
    if
        X =:= 0 ->
            %%column        
            %%analize column info
            Len = size(H),
            TmpList = tuple_to_list(H),
            ColumnTupleInfo = list_to_tuple(lists:reverse(TmpList)),
            ColStrList = analize_column_info(1, Len, ColumnTupleInfo, []),
            TmpStr = "<info><ret>1</ret><cols>" ++ ColStrList ++ "</cols></info><reclist>";            
        X > 0 ->
            %%signal record
            %%TmpStr = "<column>" ++ H ++ "</column>";
            SigRecLen = size(H),
            SigRec = analize_sig_record(1, SigRecLen, ColumnTuple, H, []),
            
            %%io:format("~nSigRec:~p~n", [SigRec]),
            TmpStr = "<rec>" ++ SigRec ++ "</rec>",
            ColumnTupleInfo = ColumnTuple;
        true ->
            TmpStr = "<info><ret>0</ret></info>",
            ColumnTupleInfo = ColumnTuple
    end,    
    NewXmlStr = XmlStr ++ TmpStr,
    NewX = X + 1,
    analize_db_rec(T, ColumnTupleInfo, NewX, NewXmlStr).


%%analize signal record
analize_sig_record(Max, Max, ColumnTuple, DataTuple, SigRecListStr) ->
    SigCol = element(Max - Max + 1, ColumnTuple),    
    SigColData = element(Max, DataTuple),
    %%io:format("~nSigCol1:~p~n", [SigCol]),
    if
        is_integer(SigColData) ->
            SigColDataStr = integer_to_list(SigColData);
        is_atom(SigColData) ->
            SigColDataStr = atom_to_list(SigColData);
        is_tuple(SigColData) ->
            SigColDataStr = "";
        true ->
            SigColDataStr = SigColData
    end,
    
    SigColStr = "<" ++ SigCol ++ "><![CDATA[" ++ SigColDataStr ++ "]]></" ++ SigCol ++ ">",
    NewSigRecListStr = SigRecListStr ++ SigColStr,
    NewSigRecListStr;
analize_sig_record(Min, Max, ColumnTuple, DataTuple, SigRecListStr) ->

    SigCol = element(Max - Min + 1, ColumnTuple),    
    SigColData = element(Min, DataTuple),
    %%io:format("~nSigCol2:~p~n", [SigCol]),
    if
        is_integer(SigColData) ->
            SigColDataStr = integer_to_list(SigColData);
        is_atom(SigColData) ->
            SigColDataStr = atom_to_list(SigColData);
        is_tuple(SigColData) ->
            TmpList = tuple_to_list(SigColData),    
            SigColDataStr = analize_list_elment(TmpList, []);
        true ->
            SigColDataStr = SigColData
    end,
    
    SigColStr = "<" ++ SigCol ++ ">" ++ SigColDataStr ++ "</" ++ SigCol ++ ">",
    NewSigRecListStr = SigRecListStr ++ SigColStr,
    analize_sig_record(Min + 1, Max, ColumnTuple, DataTuple, NewSigRecListStr).
    


%%analize tuple and convert elements
analize_tuple_element(DataTuple) ->
    if 
        is_tuple(DataTuple), size(DataTuple) > 0 ->
            Reply = analize_list_elment(tuple_to_list(DataTuple), []);
        true ->
            Reply = ""
    end,
    Reply.


%%analize list and convert elements
analize_list_elment([], StrList) ->
    StrList;
analize_list_elment([H|T], StrList) ->
    if
        is_atom(H) ->
            TmpStr = "",
            NewList = T;
        is_integer(H) ->
            TmpStr = integer_to_list(H),
            NewList = T;
        is_tuple(H) ->
            L = tuple_to_list(H),
            NewList = L ++ T,
            TmpStr = "";
        true ->
            TmpStr = H,
            NewList = T
    end,
    
    if
        is_list(TmpStr), length(TmpStr) > 0 ->
            if 
                is_list(StrList), length(StrList) > 0 ->        
                    NewStrList = StrList ++ "," ++ TmpStr;
                true ->
                    NewStrList = TmpStr
            end;
        true ->
            NewStrList = StrList
    end,
    analize_list_elment(NewList, NewStrList).
    

%%analize column info
analize_column_info(Max, Max, ColumnInfo, StrList) ->
    SigCol = element(Max, ColumnInfo),
    NewStrList = SigCol ++ "," ++ StrList,
    NewStrList;
analize_column_info(Min, Max, ColumnInfo, StrList) ->
    SigCol = element(Min, ColumnInfo),
    NewStrList = SigCol ++ "," ++ StrList,
    analize_column_info(Min + 1, Max, ColumnInfo, NewStrList).

    

