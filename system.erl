-module(system).
-compile([export_all]).


etop() ->
    etop(5,10,memory).
%% Type :  runtime | reductions | memory | msg_q
etop(Time,Line,Type) ->
    spawn(fun() -> etop:start([{output, text}, {interval, Time}, {lines, Line}, {sort, Type}]) end).


sup(SupRef) ->
    supervisor:which_children(SupRef).

not_0_value(InfoName) ->
    PList = erlang:processes(),
    ZList = lists:keysort(3,filter_msg(PList,[],InfoName)),
    [erlang:length(PList),
     InfoName,
     erlang:length(ZList),
     ZList].

filter_msg([],List2,_InfoName) ->List2;
filter_msg([P|List],List2,InfoName) ->
    NewList=
        case erlang:process_info(P, InfoName) of
            {InfoName, 0} ->
                List2;
            Info ->
                [{P,
                  erlang:process_info(P, registered_name),
                  Info
                 }|List2] 	
        end,
    filter_msg(List,NewList,InfoName).

get_msg() ->
    PList = erlang:processes(),
    ZList =filter_msg2(PList,[],message_queue_len),
    [
     erlang:length(PList),
     get_msg_queue_and_messages,
     erlang:length(ZList),
     ZList].

filter_msg2([],List2,_InfoName) ->List2;
filter_msg2([P|List],List2,InfoName) ->
    NewList=
        case erlang:process_info(P, InfoName) of
            {InfoName, 0} ->
                List2;
            Info ->
                [{P,
                  erlang:process_info(P, registered_name),
                  Info,
                  erlang:process_info(P, messages),
                  erlang:process_info(P, current_function)
                 }|List2] 	
        end,
    filter_msg2(List,NewList,InfoName).



get_memory_pids(Memory) ->
    PList = erlang:processes(),
    lists:filter(
      fun(T) ->
              case erlang:process_info(T, memory) of
                  {_, VV} ->
                      if VV >  Memory -> true;
                         true -> false
                      end;
                  _ -> true 	
              end
      end, PList ).

gc(Memory) ->
    lists:foreach(
      fun(PID) ->
              erlang:garbage_collect(PID)
      end, get_memory_pids(Memory)).

than_value(InfoName, Value) ->
    PList = erlang:processes(),
    ZList =
        lists:filter(
          fun(T) ->
                  case erlang:process_info(T, InfoName) of
                      {InfoName, VV} ->
                          if VV >  Value -> true;
                             true -> false
                          end;
                      _ -> true
                  end
          end, PList ),
    ZZList =
        lists:map(
          fun(T) ->
                  {
               T,
               erlang:process_info(T, InfoName),
               erlang:process_info(T, registered_name)
              }
          end, ZList ),
    [erlang:length(PList),
     InfoName,
     Value,
     erlang:length(ZZList),
     ZZList].

get_msg_queue() ->
    io:fwrite("process count:~p~n~p
    value is not 0 count:~p~n
              Lists:~p~n",
    not_0_value(message_queue_len) ).

get_memory() ->
    io:fwrite("process count:~p~n~p
    value is large than ~p
              count:~p~n
              Lists:~p~n",
    than_value(memory, 1048576) ).

get_memory(Value) ->
    io:fwrite("process count:~p~n~p
    value is large than ~p
              count:~p~n
              Lists:~p~n",
    than_value(memory, Value) ).

get_heap() ->
    io:fwrite("process count:~p~n~p
    value is large than ~p
              count:~p~n
              Lists:~p~n",
    than_value(heap_size, 1048576) ).

get_heap(Value) ->
    io:fwrite("process count:~p~n~p
    value is large than ~p
              count:~p~nLists:~p~n",
    than_value(heap_size, Value) ).

get_processes() ->
    io:fwrite("process count:~p~n~p
    value is large than ~p
              count:~p~n
              Lists:~p~n",
    than_value(memory, 0) ).

not_0(InfoName) ->
    PList = erlang:ports(),
    ZList =filter_port(PList,[],InfoName),
    [erlang:length(PList),
     InfoName,
     erlang:length(ZList),
     lists:reverse(lists:keysort(3,ZList))].

filter_port([],List2,_InfoName) ->List2;
filter_port([P|List],List2,InfoName) ->
    NewList=
        case erlang:port_info(P, InfoName) of
            {InfoName, 0} ->
                List2;
            {_,Num} ->
                [{P,
                  erlang:port_info(P,name),
                  Num
                 }|List2];
            _ ->
                List2
        end,
    filter_port(List,NewList,InfoName).


input() ->
    not_0(input).

output() ->
    not_0(output).

io() ->
    erlang:statistics(io).

total_time() ->
    {Total_Wallclock_Time, _Wallclock_Time_Since_Last_Call} = erlang:statistics(wall_clock),
    {D, {H, M, S}} = calendar:seconds_to_daystime(Total_Wallclock_Time div 1000),
    lists:flatten(io_lib:format("~p days, ~p hours, ~p minutes and ~p seconds", [D, H, M, S])).

