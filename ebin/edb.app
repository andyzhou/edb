{application, edb,
 [
  {description, "EDB, database service"},
  {vsn, "0.1"},
  {modules, [edb, edb_sup, edb_serv]},
  {registered, [edb, edb_sup, edb_serv]},
  {applications, [kernel, stdlib]},
  {mod, {edb, []}}
 ]
 }.
