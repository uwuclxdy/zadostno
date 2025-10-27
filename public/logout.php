<?php
// Start the session to access it
session_start();

// Unset all of the session variables
$_SESSION = [];

// Destroy the session from the server
session_destroy();

// Redirect to the login page with a success message
header("location: /login.php?loggedout=true");
exit;
?>