<?php
// Start the session if it's not already started
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check if the user_id is NOT set in the session
if (!isset($_SESSION['user_id'])) {
    // If not logged in, set an error message and redirect to login page
    $_SESSION['error_message'] = 'You must be logged in to view this page.';
    header('Location: /login.php');
    exit();
}
?>