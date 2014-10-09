-module(json_tests).

-import(json, [encode/1, decode/1]).

-include_lib("eunit/include/eunit.hrl").

% TODO: Refactor as a list of encoded/decoded pairs, testing both directions
%       for each pair.
% FIXME: Missing tests for most string escape sequences.

encode_test_() ->
  [?_assertEqual("1", encode(1))
  ,?_assertEqual("1.00000000000000000000e+00", encode(1.0))
  ,?_assertEqual("true", encode(true))
  ,?_assertEqual("false", encode(false))
  ,?_assertEqual("null", encode(null))
  ,?_assertEqual("\"foo\"", encode(foo))
  ,?_assertEqual("\"foo\"", encode(<<"foo">>))
  ,?_assertEqual("\"foo\\nbar\"", encode(<<"foo\nbar">>))
  ,?_assertEqual("\"put \\\"foo\\\" in quotes\"",
                 encode('put "foo" in quotes'))
  ,?_assertEqual("\"put \\\"foo\\\" in quotes\"",
                 encode(<<"put \"foo\" in quotes">>))
  ,?_assertEqual("[102,111,111]", encode("foo"))
  ,?_assertEqual("{}", encode(#{}))
  ,?_assertEqual("{\"a\":1}", encode(#{a => 1}))
  ,?_assertEqual("{\"b\":1}", encode(#{"b" => 1}))
  ,?_assertEqual("{\"c\":1}", encode(#{<<"c">> => 1}))
  ,?_assertEqual("{\"1\":\"d\"}", encode(#{1 => d}))
  ,?_assertError(_, encode(#{#{a => 1} => 2}))
  ,?_assertError(_, encode(#{a => 1, "a" => 2}))
  ].

decode_test_() ->
  [?_assertEqual(1, decode("1"))
  ,?_assertEqual(1, decode("   1   "))
  ,?_assertEqual(1.1, decode("1.1"))
  ,?_assertEqual(true, decode("true"))
  ,?_assertEqual(false, decode("false"))
  ,?_assertEqual(null, decode("null"))
  ,?_assertEqual(<<"foo">>, decode("\"foo\""))
  ,?_assertEqual(<<"foo\nbar">>, decode("\"foo\\nbar\""))
  ,?_assertEqual(<<"put \"foo\" in quotes">>,
                 decode("\"put \\\"foo\\\" in quotes\""))
  ,?_assertEqual([1, 2], decode("[1, 2]"))
  ,?_assertEqual(#{<<"a">> => 1, <<"b">> => 2}, decode("{\"a\": 1, \"b\": 2}"))
  ].



