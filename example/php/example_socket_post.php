<head>
<title>edb_socket_example</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body>
<?php
$cmd = $_GET["cmd"] ? $_GET["cmd"] : $_POST["cmd"];

if(empty($cmd) || $cmd != 'save')
{
?>
input data...<br>

<form action="example_socket_post.php" method="post">
<textarea name="info" cols="40" rows="6"></textarea>
<input type="hidden" name="cmd" value="save"><br>
<input type="submit" value="Submit">
</form>

<?php
}
else
{
	$info = $_POST["info"];

	save_data($info);
}


//save data to db server

function save_data($info)
{
	$address = '127.0.0.1';
	$service_port = 5554;

	if(empty($info) || $info == '')
	{
		echo 'no info';
		exit(1);
	}

	/* Create a TCP/IP socket. */
	$socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
	if ($socket < 0) {
		echo "socket_create() failed: reason: " . socket_strerror($socket) . "\n";
	} else {
		echo "OK.\n";
	}

	echo "Attempting to connect to '$address' on port '$service_port'...";
	$result = socket_connect($socket, $address, $service_port);
	if ($result < 0) {
		echo "socket_connect() failed.\nReason: ($result) " . socket_strerror($result) . "\n";
	} else {
		echo "OK.\n";
	}


	//中文必须编码！！！！！
	//$content = utf8_encode('中文');
	$content = "测试中文";

	$in = utf8_encode("<xml><cmd>exec</cmd><dbtag>tagone</dbtag><sql>insert into documents(group_id, group_id2, date_added, title, content) values(1, 2, now(), '$content', '$info')</sql></xml>");

	echo "Sending HTTP HEAD request...";
	socket_write($socket, $in, strlen($in));
	echo "OK.\n";

	/*
	echo "Reading response:\n\n";
	while ($out = socket_read($socket, 2048)) {
		echo $out;
	}
	*/

	$length = 1024 * 10;
	do
	{
		$flag=socket_recv($socket, $buf, $length,0);
		$sRespon .= $buf;
	}while($flag <= 0);

	//echo $sRespon;

	//analize xml string
	$xml =  (array)simplexml_load_string($sRespon);

	print_r($xml);

	echo "Closing socket...";
	socket_close($socket);
	echo "OK.\n\n";
}
?>