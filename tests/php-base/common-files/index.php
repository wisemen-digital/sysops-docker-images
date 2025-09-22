<?php

// Get the requested path
$path = trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');

switch ($path) {
  case 'phpinfo-config':
    phpinfo(INFO_CONFIGURATION);
    break;
  case 'phpinfo-vars':
    phpinfo(INFO_VARIABLES);
    break;
  default:
    header('Content-Type: text/plain');
    echo 'Hey from index.php';
}
