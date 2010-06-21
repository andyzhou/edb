{application, edb,
 [
  {description, "EDB, database service"},
  {vsn, "0.1"},
  {modules, [edb, edb_sup, edb_serv]},
  {registered, [edb, edb_sup, edb_serv]},
  {applications, [kernel, stdlib]},
  {mod, {edb, []}},
  {env, [
	 %%db_server, db_user, db_passwd, db_name, db_pools
   	 {db_setup, [
		      %%signal db set as tuple
		      %%{serviceTagName, dbServer,dbUser,dbPasswd,dbName,Pools}
		      {tagone, "127.0.0.1", "test", "test", "test", 8},
		      {tagtwo, "127.0.0.1", "test1", "test1", "test1", 8}
		    ]},
	 {sock_setup, [5554]}
	 ]}
 ]
 }.
