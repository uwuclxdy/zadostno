<?php
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}
// Include our new helper function file
require_once __DIR__ . '/../includes/functions.php';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>zadostno</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Use the helper for our CSS file -->
    <link rel="stylesheet" href="<?php echo base_url('/css/style.css'); ?>">
</head>
<body>
    <header>
        <nav class="navbar navbar-expand-lg navbar-dark bg-dark-blue">
            <div class="container">
                <!-- Use the helper for the brand link -->
                <a class="navbar-brand" href="<?php echo base_url('/'); ?>">zadostno</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav ms-auto">
                        <?php if (isset($_SESSION['user_id'])): ?>
                            <!-- Use the helper for all logged-in links -->
                            <li class="nav-item">
                                <a class="nav-link" href="<?php echo base_url('/dashboard.php'); ?>">Dashboard</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" href="<?php echo base_url('/profile.php'); ?>">Profile</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" href="<?php echo base_url('/logout.php'); ?>">Logout</a>
                            </li>
                        <?php else: ?>
                             <!-- Use the helper for all public links -->
                            <li class="nav-item">
                                <a class="nav-link" href="<?php echo base_url('/login.php'); ?>">Login</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" href="<?php echo base_url('/register.php'); ?>">Register</a>
                            </li>
                        <?php endif; ?>
                    </ul>
                </div>
            </div>
        </nav>
    </header>
    <main class="py-4">
        <div class="container">