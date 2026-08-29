%%
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 2026. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
%%
-module(uuid).
-moduledoc(#{since => "OTP 30.0"}).
-moduledoc """
Universally Unique Identifiers

This module generates and processes UUIDs that comply with [RFC 9562].
A UUID uses a 16-byte binary as its native representation.
The canonical text representation uses lowercase hexadecimal digits and hyphens.
The module accepts the RFC `10` variant with versions 1 and 3 through 8.
It also accepts the Nil UUID and the Max UUID.

[RFC 9562]: https://www.rfc-editor.org/rfc/rfc9562.html
""".

-export([v4/0, v7/0, parse/1, format/1, is_uuid/1, version/1, nil/0, max/0]).
-export_type([uuid/0, version/0, uuid_kind/0]).

-nominal uuid() :: <<_:128>>.
-type version() :: 1 | 3 | 4 | 5 | 6 | 7 | 8.
-type uuid_kind() :: version() | nil | max.

-doc "Generates a random UUID version 4.".
-doc(#{since => <<"OTP 30.0">>}).
-spec v4() -> uuid().
v4() ->
    <<A:48, _:4, B:12, _:2, C:62>> = crypto:strong_rand_bytes(16),
    <<A:48, 4:4, B:12, 2:2, C:62>>.

-doc """
Generates a UUID version 7.

The UUID contains the current Unix timestamp in milliseconds.
UUIDs sort by this timestamp. Calls in the same millisecond have a random order.
Successive calls do not always return UUIDs in increasing order.
""".
-doc(#{since => <<"OTP 30.0">>}).
-spec v7() -> uuid().
v7() ->
    Timestamp = erlang:system_time(millisecond),
    <<_:6, RandA:12, RandB:62>> = crypto:strong_rand_bytes(10),
    <<Timestamp:48, 7:4, RandA:12, 2:2, RandB:62>>.

-doc """
Parses a UUID in its canonical text representation.

The hexadecimal digits can use uppercase, lowercase, or mixed case.
The function accepts Nil, Max, and RFC-variant versions 1 and 3 through 8.
""".
-doc(#{since => <<"OTP 30.0">>}).
-spec parse(binary()) -> {ok, uuid()} | {error, invalid_uuid}.
parse(<<A:8/binary, $-, B:4/binary, $-, C:4/binary, $-, D:4/binary, $-, E:12/binary>>) ->
    maybe
        {ok, UUID} ?= decode_hex(<<A/binary, B/binary, C/binary, D/binary, E/binary>>),
        true ?= is_uuid(UUID),
        {ok, UUID}
    else
        _ -> {error, invalid_uuid}
    end;
parse(Bin) when is_binary(Bin) ->
    {error, invalid_uuid}.

-doc "Converts a UUID to its canonical lowercase text representation.".
-doc(#{since => <<"OTP 30.0">>}).
-spec format(uuid()) -> binary().
format(UUID) ->
    case is_uuid(UUID) of
        true ->
            <<A:8/binary, B:4/binary, C:4/binary, D:4/binary, E:12/binary>> =
                binary:encode_hex(UUID, lowercase),
            <<A/binary, $-, B/binary, $-, C/binary, $-, D/binary, $-, E/binary>>;
        false ->
            error(badarg, [UUID])
    end.

-doc "Returns `true` if `Term` is a valid native UUID representation.".
-doc(#{since => <<"OTP 30.0">>}).
-spec is_uuid(term()) -> boolean().
is_uuid(<<0:128>>) ->
    true;
is_uuid(<<16#ffffffffffffffffffffffffffffffff:128>>) ->
    true;
is_uuid(<<_:48, Version:4, _:12, 2:2, _:62>>)
  when Version =:= 1; Version >= 3, Version =< 8 ->
    true;
is_uuid(_) ->
    false.

-doc "Returns the UUID version or special UUID kind. The function raises `badarg` for invalid input.".
-doc(#{since => <<"OTP 30.0">>}).
-spec version(uuid()) -> uuid_kind().
version(<<0:128>>) ->
    nil;
version(<<16#ffffffffffffffffffffffffffffffff:128>>) ->
    max;
version(<<_:48, Version:4, _:12, 2:2, _:62>>)
  when Version =:= 1; Version >= 3, Version =< 8 ->
    Version;
version(UUID) ->
    error(badarg, [UUID]).

-doc "Returns the Nil UUID.".
-doc(#{since => <<"OTP 30.0">>}).
-spec nil() -> uuid().
nil() ->
    <<0:128>>.

-doc "Returns the Max UUID.".
-doc(#{since => <<"OTP 30.0">>}).
-spec max() -> uuid().
max() ->
    <<16#ffffffffffffffffffffffffffffffff:128>>.

decode_hex(Hex) ->
    try
        {ok, binary:decode_hex(Hex)}
    catch
        error:badarg -> error
    end.
