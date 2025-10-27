<?php
// We must start the session on every page that uses session variables
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Include our database connection
require_once __DIR__ . '/../includes/db_connect.php';

// Check if the form was submitted using POST
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = trim($_POST['email']);
    $password = $_POST['password'];

    // Basic validation
    if (empty($email) || empty($password)) {
        // If fields are empty, set an error message in the session
        $_SESSION['error_message'] = 'Both email and password are required.';
        // Redirect back to the login page
        header('Location: /login.php');
        exit();
    }

    try {
        // Prepare a SQL statement to find the user by email
        $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        // Check if a user was found AND if the submitted password matches the hashed password in the database
        if ($user && password_verify($password, $user['password_hash'])) {
            // Password is correct!
            
            // Regenerate the session ID for security
            session_regenerate_id();
            
            // Store user data in the session
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['first_name'] = $user['first_name'];
            $_SESSION['role'] = $user['role'];
            
            // Redirect to the dashboard
            header("Location: /dashboard.php");
            exit();

        } else {
            // User not found or password was incorrect
            $_SESSION['error_message'] = 'The email or password you entered was not valid.';
            header('Location: /login.php');
            exit();
        }
    } catch (PDOException $e) {
        // Handle database errors
        $_SESSION['error_message'] = 'A database error occurred. Please try again later.';
        header('Location: /login.php');
        exit();
    }
} else {
    // If someone tries to access this file directly without submitting the form
    header('Location: /login.php');
    exit();
}