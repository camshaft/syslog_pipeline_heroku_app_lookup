-module (syslog_pipeline_heroku_app_lookup).

-export([start/0]).
-export([filter/1]).

start() ->
  ets:new(?MODULE, [
    public,
    named_table,
    {read_concurrency, true}
  ]).

filter({{Priority, Version, Timestamp, Hostname, <<"heroku">>, <<"router">>, MessageID, Message}, Fields}) ->
  ActualName = case lookup(Hostname) of
    Hostname ->
      HerokuName = fast_key:get(<<"host">>, Fields),
      case HerokuName of
        undefined ->
          Hostname;
        _ ->
          ets:insert(?MODULE, {Hostname, HerokuName}),
          HerokuName
      end;
    HerokuName ->
      HerokuName
  end,
  {ok, {{Priority, Version, Timestamp, ActualName, <<"heroku">>, <<"router">>, MessageID, Message}, Fields}};
filter({{Priority, Version, Timestamp, Hostname, AppName, ProcID, MessageID, Message}, Fields}) ->
  {ok, {{Priority, Version, Timestamp, lookup(Hostname), AppName, ProcID, MessageID, Message}, Fields}}.

lookup(Hostname) ->
  case ets:lookup(?MODULE, Hostname) of
    [] ->
      Hostname;
    [{_, AppName}|_] ->
      AppName
  end.
