<?php
require_once __DIR__ . '/../src/includes/db_connect.php';
require_once __DIR__ . '/../src/includes/functions.php';
require_once __DIR__ . '/../src/includes/course_access_check.php';

$material_id = $_GET['id'] ?? null;
if (!$material_id) {
    http_response_code(400);
    echo "Bad Request: No material ID provided.";
    exit();
}

// Fetch the material to find its course_id
$stmt = $pdo->prepare("SELECT * FROM materials WHERE id = ? AND type = 'file'");
$stmt->execute([$material_id]);
$material = $stmt->fetch();

if (!$material) {
    http_response_code(404);
    echo "Not Found: The requested file does not exist.";
    exit();
}

// Use our existing function to check if the user has access to this course
check_course_access($pdo, $material['course_id']);

// If the script continues, access is granted. Proceed to serve the file.
$file_path = __DIR__ . '/../uploads/' . $material['content'];

if (!file_exists($file_path)) {
    http_response_code(404);
    echo "Not Found: The file is missing from the server.";
    exit();
}

// Set headers to trigger a download
header('Content-Description: File Transfer');
header('Content-Type: application/octet-stream'); // A generic binary file type
header('Content-Disposition: attachment; filename="' . basename($material['title']) . '.' . pathinfo($file_path, PATHINFO_EXTENSION) . '"');
header('Expires: 0');
header('Cache-Control: must-revalidate');
header('Pragma: public');
header('Content-Length: ' . filesize($file_path));
flush(); // Flush the system output buffer
readfile($file_path); // Read the file and send it to the output buffer
exit();