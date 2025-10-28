<?php
header('Content-Type: text/html; charset=utf-8');

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
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 800px; margin: 0 auto; }
        .status { padding: 15px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border-left: 4px solid #28a745; }
        .error { background: #f8d7da; color: #721c24; border-left: 4px solid #dc3545; }
        .info { background: #d1ecf1; color: #0c5460; border-left: 4px solid #17a2b8; }
        h1 { color: #333; }
        h2 { color: #555; margin-top: 30px; }
        ul { line-height: 1.8; }
        a { color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Zadostno is Running!</h1>
        
        <div class="status info">
            <strong>Service Status:</strong> ✅ Web server is operational<br>
            <strong>PHP Version:</strong> <?= PHP_VERSION ?><br>
            <strong>Timestamp:</strong> <?= date('Y-m-d H:i:s T') ?>
        </div>

        <?php
        $db = getDatabaseConnection();
        if ($db) {
            echo '<div class="status success"><strong>Database:</strong> ✅ Connected to PostgreSQL</div>';
            
            try {
                $stmt = $db->query("SELECT version()");
                $version = $stmt->fetchColumn();
                echo '<div class="status info"><strong>PostgreSQL Version:</strong> ' . htmlspecialchars($version) . '</div>';
            } catch (Exception $e) {
                echo '<div class="status error"><strong>Database Query:</strong> ❌ ' . htmlspecialchars($e->getMessage()) . '</div>';
            }
        } else {
            echo '<div class="status error"><strong>Database:</strong> ❌ Connection failed - check your credentials</div>';
        }
        ?>

        <h2>📍 Available Endpoints:</h2>
        <ul>
            <li><a href="/">/</a> - This status page</li>
            <li><a href="/health">/health</a> - JSON health check endpoint</li>
        </ul>

        <h2>🔧 Server Information:</h2>
        <ul>
            <li><strong>Server Software:</strong> <?= $_SERVER['SERVER_SOFTWARE'] ?></li>
            <li><strong>Port:</strong> <?= $_SERVER['SERVER_PORT'] ?></li>
            <li><strong>Document Root:</strong> <?= $_SERVER['DOCUMENT_ROOT'] ?></li>
            <li><strong>Request Method:</strong> <?= $_SERVER['REQUEST_METHOD'] ?></li>
        </ul>

        <h2>💡 Next Steps:</h2>
        <ul>
            <li>Replace this index.php with your application code</li>
            <li>Modify database/init.sql to create your database schema</li>
            <li>Use the management scripts (zs, zl, zr, zu) for easy maintenance</li>
        </ul>
    </div>
</body>
</html>
