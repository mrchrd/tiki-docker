<?php
$db_tiki        = getenv('TIKI_DB_DRIVER') ?: 'mysqli';
$host_tiki      = getenv('TIKI_DB_HOST') ?: 'localhost';
$user_tiki      = getenv('TIKI_DB_USER');
$pass_tiki      = getenv('TIKI_DB_PASS');
$dbs_tiki       = getenv('TIKI_DB_NAME');
$client_charset = 'utf8mb4';

$system_configuration_identifier = getenv('TIKI_SYSTEM_CONFIGURATION_IDENTIFIER');

if (is_readable('/var/www/tikiconfig/prefs.ini.php')) {
  $system_configuration_file = '/var/www/tikiconfig/prefs.ini.php';
} else {
  trigger_error('Ini file not found: /var/www/tikiconfig/prefs.ini.php', E_USER_WARNING);
}
