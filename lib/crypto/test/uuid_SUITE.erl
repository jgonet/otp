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
-module(uuid_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-export([suite/0, all/0]).
-export([generation/1, text/1, validation/1, invalid/1]).

suite() ->
    [{ct_hooks, [ts_install_cth]}].

all() ->
    [generation, text, validation, invalid].

generation(_Config) ->
    V4s = [uuid:v4() || _ <- lists:seq(1, 100)],
    ?assertEqual(100, sets:size(sets:from_list(V4s))),
    ?assert(lists:all(fun(UUID) -> uuid:version(UUID) =:= 4 end, V4s)),

    V7 = uuid:v7(),
    <<_:48, 7:4, _:12, 2:2, _:62>> = V7.

text(_Config) ->
    Text = <<"919108f7-52d1-4320-9bac-f847db4148a8">>,
    {ok, UUID} = uuid:parse(Text),
    ?assertEqual(4, uuid:version(UUID)),
    ?assertEqual(Text, uuid:format(UUID)),
    ?assertEqual({ok, UUID}, uuid:parse(<<"919108F7-52D1-4320-9bAC-f847DB4148A8">>)),

    V7Text = <<"017f22e2-79b0-7cc3-98c4-dc0c0c07398f">>,
    {ok, V7} = uuid:parse(V7Text),
    ?assertEqual(7, uuid:version(V7)),
    ?assertEqual(V7Text, uuid:format(V7)).

validation(_Config) ->
    ?assertEqual(nil, uuid:version(uuid:nil())),
    ?assertEqual(max, uuid:version(uuid:max())),
    ?assertEqual(<<"00000000-0000-0000-0000-000000000000">>, uuid:format(uuid:nil())),
    ?assertEqual(<<"ffffffff-ffff-ffff-ffff-ffffffffffff">>, uuid:format(uuid:max())),
    lists:foreach(
      fun(Version) ->
              UUID = <<0:48, Version:4, 0:12, 2:2, 0:62>>,
              ?assert(uuid:is_uuid(UUID)),
              ?assertEqual(Version, uuid:version(UUID)),
              ?assertEqual({ok, UUID}, uuid:parse(uuid:format(UUID)))
      end,
      [1, 3, 4, 5, 6, 7, 8]).

invalid(_Config) ->
    Invalid = [
        not_a_binary,
        <<0:120>>,
        <<0:48, 2:4, 0:12, 2:2, 0:62>>,
        <<0:48, 4:4, 0:12, 0:2, 0:62>>,
        <<0:48, 4:4, 0:12, 3:2, 0:62>>
    ],
    ?assert(lists:all(fun(UUID) -> not uuid:is_uuid(UUID) end, Invalid)),
    lists:foreach(fun(UUID) -> ?assertError(badarg, uuid:version(UUID)) end, Invalid),

    InvalidText = [
        <<"919108f752d143209bacf847db4148a8">>,
        <<"919108f7-52d1-2320-9bac-f847db4148a8">>,
        <<"919108f7-52d1-4320-1bac-f847db4148a8">>,
        <<"919108f7-52d1-4320-dbac-f847db4148a8">>,
        <<"919108f7-52d1-4320-9bac-f847db4148ag">>
    ],
    ?assert(lists:all(fun(Text) -> uuid:parse(Text) =:= {error, invalid_uuid} end,
                      InvalidText)),
    ?assertError(function_clause, uuid:parse(not_a_binary)),
    ?assertError(function_clause, uuid:parse("919108f7-52d1-4320-9bac-f847db4148a8")),
    ?assertError(badarg, uuid:format(<<0:120>>)).
