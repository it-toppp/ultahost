<?php
error_reporting(E_ALL);
@ini_set("display_errors","1");  
@ini_set("display_startup_errors","1");  
@ini_set('error_reporting', E_ALL);  
@ini_set("memory_limit", "-1");
@set_time_limit(0);
@ini_set('max_execution_time', 0);
$config_file_name = $_SERVER['DOCUMENT_ROOT'] . '/sys/config.php';

$file_content = 
'<?php
// MySQL Hostname
$sql_db_host = "'  . $_POST['sql_host'] . '";
// MySQL Database User
$sql_db_user = "'  . $_POST['sql_user'] . '";
// MySQL Database Password
$sql_db_pass = "'  . $_POST['sql_pass'] . '";
// MySQL Database Name
$sql_db_name = "'  . $_POST['sql_name'] . '";

// Site URL
$site_url = "' . $_POST['site_url'] . '"; // e.g (http://example.com)

// Purchase code
$purchase_code = "' . $_POST['purshase_code'] . '";
?>';
     

$config_file = file_put_contents($config_file_name, $file_content);
if (file_exists($_SERVER['DOCUMENT_ROOT'] . '/htaccess.txt')) {
  $htaccess = file_put_contents($_SERVER['DOCUMENT_ROOT'] . '/.htaccess', file_get_contents($_SERVER['DOCUMENT_ROOT'] . '/htaccess.txt'));
}

if ($config_file) {
	$con = mysqli_connect($_POST['sql_host'], $_POST['sql_user'], $_POST['sql_pass'], $_POST['sql_name']);
	if (mysqli_connect_errno()) {
		die("Failed to connect to MySQL: " . mysqli_connect_error());
	}
	
	$filename = $_SERVER['DOCUMENT_ROOT'] . '/database.sql';
	// Temporary variable, used to store current query
	$templine = '';
	// Read in entire file
	$lines = file($filename);
	// Loop through each line
	foreach ($lines as $line) {
	   // Skip it if it's a comment
	   if (substr($line, 0, 2) == '--' || $line == '')
	      continue;
	   // Add this line to the current segment
	   $templine .= $line;
	   $query = false;
	   // If it has a semicolon at the end, it's the end of the query
	   if (substr(trim($line), -1, 1) == ';') {
	      // Perform the query
	      $query = mysqli_query($con, $templine);
	      // Reset temp variable to empty
	      $templine = ''; 
	   }
	}
	
	if ($query) {
        $query_one  = mysqli_query($con, "UPDATE `pxp_config` SET `value` = '" . mysqli_real_escape_string($con, 'PixelPhoto'). "' WHERE `name` = 'site_url'");
        $query_one .= mysqli_query($con, "UPDATE `pxp_config` SET `value` = '" . mysqli_real_escape_string($con, 'PixelPhoto'). "' WHERE `name` = 'site_name'");
        $query_one .= mysqli_query($con, "UPDATE `pxp_config` SET `value` = '" . mysqli_real_escape_string($con, 'example@domain.com'). "' WHERE `name` = 'site_email'");
        $query_one .= mysqli_query($con, "UPDATE `pxp_config` SET `value` = '" . mysqli_real_escape_string($con, md5(microtime())). "' WHERE `name` = 'app_api_id'");
        $query_one .= mysqli_query($con, "UPDATE `pxp_config` SET `value` = '" . mysqli_real_escape_string($con, md5(time())). "' WHERE `name` = 'app_api_key'");
        $query_one .= mysqli_query($con, "INSERT INTO `pxp_users` (`user_id`, `username`, `email`, `ip_address`, `password`, `fname`, `lname`, `gender`, `email_code`, `language`, `avatar`, `cover`, `country_id`, `about`, `google`, `facebook`, `twitter`, `website`, `active`, `admin`, `verified`, `last_seen`, `registered`, `is_pro`, `posts`, `p_privacy`, `c_privacy`, `n_on_like`, `n_on_mention`, `n_on_comment`, `n_on_follow`, `src`) VALUES (1, '" . mysqli_real_escape_string($con, $_POST['admin_username']). "', '" . mysqli_real_escape_string($con, 'example@domain.com'). "', '::1', '" . mysqli_real_escape_string($con, sha1($_POST['admin_password'])) . "', '" . mysqli_real_escape_string($con, $_POST['admin_username']). "', '', 'male', '', 'english', 'media/img/d-avatar.jpg', 'media/img/d-cover.jpg', 0, '', '', '', '', '', 1, 1, 0, '" . time() . "', '00/0000', 0, 0, '1', '2', '1', '1', '1', '1', '');");
 }
}
