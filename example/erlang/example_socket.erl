-module(example_socket).
-export([test/0]).

-include_lib("xmerl/include/xmerl.hrl").
-define(EDB_SERV, "192.168.9.128").
-define(EDB_PORT, 5555).

test() ->
    Msg = "<xml><cmd>get</cmd><sql>select * from documents order by id desc limit 1</sql></xml>",
    {ok, Socket} = gen_tcp:connect(?EDB_SERV, ?EDB_PORT, [binary, {packet, 0}]),
    gen_tcp:send(Socket, list_to_binary(Msg)),
    recv_msg(Socket),
    gen_tcp:close(Socket).
    

recv_msg(Socket) ->
  receive
    {tcp, Socket, Bin} ->
      Msg = binary_to_list(Bin),
      
      %%[Msg2] = io_lib:format("~ts", [Msg]),
      %%Msg2 = lists:flatten(io_lib:format("~ts", [Msg])).
      %%Msg2 = io_lib:format("~ts", [Msg]),
      io:format("Received msg: ~s~n", [Msg]),
      %%io:format("Received msg: ~s~n", [Msg2]),
      {ok, RecTuple} = parse_xml(Msg),
      %%RR = io_lib:format("~ts", [RecTuple]),
      io:format("~n~p~n", [RecTuple]),
      ok
  end.


%%analize xml into tuple
parse_xml(XmlString) ->
    NewStr = xmerl_ucs:from_utf8(XmlString),
    {Xml, _} = xmerl_scan:string(XmlString),
    RecTuple = xmerl_lib:simplify_element(Xml),
    {ok, RecTuple}.
