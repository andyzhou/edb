<head>
<title>edb_socket_example</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body>

<?php
$address = '127.0.0.1';
$service_port = 5554;

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

$in = "<xml><cmd>get</cmd><sql>select * from users limit 10</sql></xml>";

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
$xml = simplexml_load_string($sRespon);
print_r($xml);


//get column info
$sRetInfo = $xml->info;
$iRet = $sRetInfo->ret;
$sColInfo = $sRetInfo->cols;
$aTmpArr = explode(",", $sColInfo);

print_r($sRetInfo);
printf("iRet:%d", $iRet);
print_r($aTmpArr);

echo '<table border=1>';

foreach($xml->reclist as $sv)
{
	foreach($sv->rec as $v)
	{
		$added_time = $v->date_added;
		$aTmpArrTwo = explode(",", $added_time);
		$sTime = $aTmpArrTwo[0] . "-" . $aTmpArrTwo[1] . "-" . $aTmpArrTwo[2] . " " . $aTmpArrTwo[3] . ":" . $aTmpArrTwo[4] .":" . $aTmpArrTwo[5];

		echo '<tr>';
		echo '<td>' . $v->id . '</td>';
		echo '<td>' . $v->title . '</td>';
		echo '<td>' . $sTime . '</td>';
		echo '<td>' . $v->content . '</td>';
		echo '</tr>';
	}
}

echo '</table>';

echo "Closing socket...";
socket_close($socket);
echo "OK.\n\n";
?>