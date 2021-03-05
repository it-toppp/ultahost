<?php
error_reporting(NULL);
$TAB = 'USER';

// Main include
include($_SERVER['DOCUMENT_ROOT']."/inc/main.php");

// Data
define('FM_EMBED', true);
define('FM_SELF_URL', $_SERVER['PHP_SELF']);
require 'tinyfilemanager.php';

// Back uri
$_SESSION['back'] = $_SERVER['REQUEST_URI'];
