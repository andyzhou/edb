%%edb utils
%%
-module(edb_utils).
-vsn(0.1).
-author("Andy Chow <diudiu8848@163.com>").
-compile(export_all).

%%convert binary to list
binary_check(X) when is_binary(X) ->
    binary_to_list(X);
binary_check(X) ->
    X.
