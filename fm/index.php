<?php
error_reporting(NULL);
$TAB = 'USER';

// Main include
include($_SERVER['DOCUMENT_ROOT']."/inc/main.php");

// Header
//include($_SERVER['DOCUMENT_ROOT'].'/templates/1.html');
$wstring = <<<MSG
<html>
 <head>
  <meta charset="utf-8">
  <title>Hestia</title>
 </head>
 <body>
  <button onclick="document.location='/'">Exit to Control Panel »</button>
 </body>
</html>
MSG;
echo $wstring;
// Data
define('FM_EMBED', true);
define('FM_SELF_URL', $_SERVER['PHP_SELF']);
require 'tinyfilemanager.php';

// Back uri
$_SESSION['back'] = $_SERVER['REQUEST_URI'];
