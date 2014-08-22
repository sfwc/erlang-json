-module(json).
-export([encode/1, decode/1]).

-import(lists, [concat/1, reverse/1]).
-import(string, [join/2]).

-export_type([jso/0]).

%%% Decoding:

-type input() :: string().
-type js_list() :: [jso()].
% TODO: Restrict maps to actually being valid JSOs, when Dialyzer becomes
%       capable of that.
-type js_map() :: #{}.
-type jso() :: js_list() | js_map() | number() | binary() | boolean().
-type result(A) :: {A, input()}.
-type state() :: any().

-spec parse_list(input(), state()) -> result(js_list()).
parse_list(Input, Acc) ->
  case parse(Input) of
    {Element, [$, | Rest]} -> parse_list(Rest, [Element | Acc]);
    {Element, [$] | Rest]} -> {reverse([Element | Acc]), Rest}
  end.

-spec parse_map(input(), state()) -> result(js_map()).
parse_map(Input, Acc) ->
  [$" | KeyString] = Input,
  {Key, ":" ++ Input1} = parse_string(KeyString, ""),
  case parse(Input1) of
    {Value, "," ++ Rest} -> parse_map(Rest, maps:put(Key, Value, Acc));
    {Value, "}" ++ Rest} -> {maps:put(Key, Value, Acc), Rest}
  end.

-spec parse_string(input(), state()) -> result(binary()).
parse_string([$" | Rest], Acc) -> {list_to_binary(reverse(Acc)), Rest};
parse_string([$\\, Char | Rest], Acc) -> parse_string(Rest, [Char | Acc]);
parse_string([Char | Rest], Acc) -> parse_string(Rest, [Char | Acc]).

-spec translate(state()) -> number() | boolean().
translate(Acc) ->
  case reverse(Acc) of
    "true" -> true;
    "false" -> false;
    Number ->
      case lists:member($., Number) of
        true -> list_to_float(Number);
        false -> list_to_integer(Number)
      end
  end.

-spec parse_token(input(), state()) -> result(number() | boolean()).
parse_token([], Acc) -> {translate(Acc), []};
parse_token(R=[Delim | _], Acc) when Delim == $,; Delim == $]; Delim == $} ->
  {translate(Acc), R};
parse_token([Char | Input], Acc) -> parse_token(Input, [Char | Acc]).

-spec parse(input()) -> result(jso()).
parse("[]" ++ Input) -> {[], Input};
parse("[" ++ Input) -> parse_list(Input, []);
parse("{}" ++ Input) -> {#{}, Input};
parse("{" ++ Input) -> parse_map(Input, #{});
parse("\"" ++ Input) -> parse_string(Input, "");
parse(Input) -> parse_token(Input, "").

-spec normalizeString(input()) -> input().
normalizeString([$" | R]) -> [$" | normalize(R)];
normalizeString([$\\, C | R]) -> [$\\, C | normalizeString(R)];
normalizeString([C | R]) -> [C | normalizeString(R)].

-spec normalize(input()) -> input().
normalize("") -> "";
normalize([$" | R]) -> [$" | normalizeString(R)];
normalize([W | R]) when W == $ ; W == $\t; W == $\n; W == $\r -> normalize(R);
normalize([C | R]) -> [C | normalize(R)].

-spec decode(nonempty_string()) -> jso().
decode(Input) ->
  {Value, ""} = parse(normalize(Input)),
  Value.


%%% Encoding:

to_key(S) when is_list(S) -> S;
to_key(A) when is_atom(A) -> atom_to_list(A);
to_key(B) when is_binary(B) -> binary_to_list(B);
to_key(I) when is_integer(I) -> integer_to_list(I);
to_key(F) when is_float(F) -> float_to_list(F).

encode(true) -> "true";
encode(false) -> "false";
encode(A) when is_atom(A) -> concat(["\"", A, "\""]);
encode(B) when is_binary(B) -> concat(["\"", binary_to_list(B), "\""]);
encode(I) when is_integer(I) -> integer_to_list(I);
encode(F) when is_float(F) -> float_to_list(F);
encode(L) when is_list(L) ->
  concat(["[", join([encode(E) || E <- L], ","), "]"]);
encode(M) when is_map(M) ->
  WithValidKeys =
    maps:fold(fun (K, V, NewM) ->
                NewK = to_key(K),
                false = maps:is_key(NewK, NewM),
                maps:put(NewK, V, NewM)
              end, #{}, M),
  concat(["{",
          join([concat(["\"", K, "\":", encode(V)])
               || {K, V} <- maps:to_list(WithValidKeys)],
               ","),
          "}"]).
