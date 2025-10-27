<?php
// --- Database Configuration ---
$host = 'localhost'; // Or your database host
$db = 'zadostno';    // The name of your database
$user = 'pma';       // Your database username
$pass = '';          // Your database password
// ------------------------------

$dsn = "pgsql:host=$host;dbname=$db";

$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION, // Throw exceptions on errors
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,       // Fetch associative arrays
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    // Create a new PDO instance
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    // If connection fails, stop the script and show an error
    throw new \PDOException($e->getMessage(), (int)$e->getCode());
}
?>