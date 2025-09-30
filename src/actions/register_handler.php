<?php
// This script handles the student registration process.

// Ensure the script is not accessed directly
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    die('Invalid request method.');
}

// Start session to use session variables
session_start();

// Include necessary files
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../includes/db_connect.php';

// --- 1. Get and Sanitize Form Data ---
$firstName = trim($_POST['first_name'] ?? '');
$lastName = trim($_POST['last_name'] ?? '');
$email = trim($_POST['email'] ?? '');
$phoneNumber = trim($_POST['phone_number'] ?? '');
$password = $_POST['password'] ?? '';
$confirmPassword = $_POST['confirm_password'] ?? '';

// --- 2. Validate Data ---
if (empty($firstName) || empty($lastName) || empty($email) || empty($password)) {
    $_SESSION['message'] = 'Please fill in all required fields.';
    $_SESSION['message_type'] = 'danger';
    header('Location: ' . BASE_URL . '/index.php?page=register');
    exit();
}

if ($password !== $confirmPassword) {
    $_SESSION['message'] = 'Passwords do not match.';
    $_SESSION['message_type'] = 'danger';
    header('Location: ' . BASE_URL . '/index.php?page=register');
    exit();
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $_SESSION['message'] = 'Invalid email format.';
    $_SESSION['message_type'] = 'danger';
    header('Location: ' . BASE_URL . '/index.php?page=register');
    exit();
}

// --- 3. Check if User Already Exists ---
try {
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        $_SESSION['message'] = 'An account with this email already exists.';
        $_SESSION['message_type'] = 'warning';
        header('Location: ' . BASE_URL . '/index.php?page=register');
        exit();
    }
} catch (PDOException $e) {
    // In production, log this error instead of showing it
    die("Database error: " . $e->getMessage());
}


// --- 4. Hash the Password (CRITICAL FOR SECURITY) ---
$passwordHash = password_hash($password, PASSWORD_DEFAULT);

// --- 5. Insert New User into Database ---
try {
    // The role is hardcoded to 'student' for self-registration
    $sql = "INSERT INTO users (first_name, last_name, email, phone_number, password_hash, role) VALUES (?, ?, ?, ?, ?, 'student')";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$firstName, $lastName, $email, $phoneNumber, $passwordHash]);

    // --- 6. Redirect on Success ---
    $_SESSION['message'] = 'Registration successful! You can now log in.';
    $_SESSION['message_type'] = 'success';
    header('Location: ' . BASE_URL . '/index.php?page=login');
    exit();

} catch (PDOException $e) {
    // Handle potential errors, e.g., database connection issues
    // In a real application, you would log this error.
    $_SESSION['message'] = 'An error occurred during registration. Please try again.';
    $_SESSION['message_type'] = 'danger';
    // For debugging: echo "Error: " . $e->getMessage();
    header('Location: ' . BASE_URL . '/index.php?page=register');
    exit();
}