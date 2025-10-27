<?php
// Start the session if it's not already started
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check if the user is logged in and if they are an admin
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') {
    // If not an admin, set an error message and redirect to the dashboard
    $_SESSION['error_message'] = 'You do not have permission to access this page.';
    
    // We need to construct the base URL for the redirect
    // A simple redirect will work if the base_url function isn't available here.
    // Let's create a temporary redirect path.
    $redirect_path = '/zadostno_redovalnica/zadostno/public/dashboard.php';
    header('Location: ' . $redirect_path);
    exit();
}
?>