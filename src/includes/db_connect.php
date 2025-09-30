<?php
// This script connects to the PostgreSQL database.
require_once __DIR__ . '/../../config.php';

try {
    $dsn = "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME;
    $pdo = new PDO($dsn, DB_USER, DB_PASS);

    // Set the PDO error mode to exception
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    // For development, show the error. In production, log it and show a generic message.
    die("ERROR: Could not connect. " . $e->getMessage());
}