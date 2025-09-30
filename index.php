<?php
// Zadostno Application
header('Content-Type: text/html; charset=utf-8');

// Database connection function
function getDatabaseConnection() {
    $host = getenv('DB_HOST') ?: 'zadostno-postgres';
    $port = getenv('DB_PORT') ?: '5432';
    $dbname = getenv('DB_NAME') ?: 'zadostno_db';
    $user = getenv('DB_USER') ?: 'zadostno_user';
    $password = getenv('DB_PASSWORD');
    
    try {
        $pdo = new PDO("pgsql:host=$host;port=$port;dbname=$dbname", $user, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $pdo;
    } catch (PDOException $e) {
        return null;
    }
}

// Handle health check as JSON
if ($_SERVER['REQUEST_URI'] === '/health') {
    header('Content-Type: application/json');
    $db = getDatabaseConnection();
    $status = $db ? 'healthy' : 'database_error';
    echo json_encode([
        'status' => $status,
        'timestamp' => date('c'),
        'service' => 'zadostno',
        'php_version' => PHP_VERSION
    ]);
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zadostno</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }
        .info { background: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Zadostno is Running!</h1>
        
        <div class="status info">
            <strong>Service Status:</strong> ✅ Web server is running<br>
            <strong>PHP Version:</strong> <?= PHP_VERSION ?><br>
            <strong>Timestamp:</strong> <?= date('Y-m-d H:i:s T') ?>
        </div>

        <?php
        $db = getDatabaseConnection();
        if ($db) {
            echo '<div class="status success"><strong>Database:</strong> ✅ Connected to PostgreSQL</div>';
            
            // Test query
            try {
                $stmt = $db->query("SELECT version()");
                $version = $stmt->fetchColumn();
                echo '<div class="status info"><strong>PostgreSQL:</strong> ' . htmlspecialchars($version) . '</div>';
            } catch (Exception $e) {
                echo '<div class="status error"><strong>Database Query:</strong> ❌ ' . htmlspecialchars($e->getMessage()) . '</div>';
            }
        } else {
            echo '<div class="status error"><strong>Database:</strong> ❌ Connection failed</div>';
        }
        ?>

        <h2>Available Endpoints:</h2>
        <ul>
            <li><a href="/">/</a> - This page</li>
            <li><a href="/health">/health</a> - JSON health check</li>
            <li><a href="/test.php">/test.php</a> - PHP info page</li>
        </ul>

        <h2>Server Information:</h2>
        <ul>
            <li><strong>Server:</strong> <?= $_SERVER['SERVER_SOFTWARE'] ?></li>
            <li><strong>Port:</strong> <?= $_SERVER['SERVER_PORT'] ?></li>
            <li><strong>Document Root:</strong> <?= $_SERVER['DOCUMENT_ROOT'] ?></li>
            <li><strong>Request URI:</strong> <?= $_SERVER['REQUEST_URI'] ?></li>
        </ul>
    </div>
</body>
</html>
