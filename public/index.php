<?php
// Include core files
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../src/includes/db_connect.php';
require_once __DIR__ . '/../src/includes/functions.php';

// --- Basic Router ---
// Determine which page to load from the `page` query parameter.
$page = $_GET['page'] ?? 'login'; // Default to login page

// --- Handle Actions (Form Submissions) ---
$action = $_GET['action'] ?? null;
if ($action) {
    // Look for the corresponding action handler in the src/actions/ directory
    $actionPath = __DIR__ . '/../src/actions/' . $action . '_handler.php';

    if (file_exists($actionPath)) {
        require $actionPath;
        // The handler script will typically end with an exit() or header() call,
        // so the script might stop here.
    }
}


// --- Load Page Content ---
$pagePath = __DIR__ . '/../src/pages/' . $page . '.php';

if (file_exists($pagePath)) {
    require $pagePath;
} else {
    // Page not found, show a 404 error
    http_response_code(404);
    echo "<h1>404 Page Not Found</h1>";
}