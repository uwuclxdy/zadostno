<?php
session_start();
require_once __DIR__ . '/../includes/db_connect.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/course_access_check.php'; // We'll use a new function from here

// --- Add this new function to your src/includes/course_access_check.php file ---
// This function checks if a user is specifically a teacher for a course.
/*
function is_course_teacher($pdo, $course_id, $user_id) {
    if (!isset($_SESSION['role']) || $_SESSION['role'] !== 'teacher') {
        return false;
    }
    $stmt = $pdo->prepare("SELECT 1 FROM course_teachers WHERE course_id = ? AND teacher_id = ?");
    $stmt->execute([$course_id, $user_id]);
    return $stmt->fetch() !== false;
}
*/
// -----------------------------------------------------------------------------

// We need the user to be logged in for any action
if (!isset($_SESSION['user_id'])) {
    header('Location: ' . base_url('/login.php'));
    exit();
}
$user_id = $_SESSION['user_id'];

// Determine course_id and action
$course_id = $_POST['course_id'] ?? $_GET['course_id'] ?? null;
$action = $_POST['action'] ?? $_GET['action'] ?? null;

if (!$course_id) {
    // Cannot proceed without a course context
    header('Location: ' . base_url('/dashboard.php'));
    exit();
}

// Ensure the user is the teacher for this course before allowing add/delete
if (!is_course_teacher($pdo, $course_id, $user_id)) {
    $_SESSION['error_message'] = 'You do not have permission to modify this course.';
    header('Location: ' . base_url('/course.php?id=' . $course_id));
    exit();
}

// Redirect path for success or failure
$redirect_url = base_url('/course.php?id=' . $course_id);

// --- Handle ADD action ---
if ($action === 'add' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = trim($_POST['title']);
    $type = $_POST['type'];

    if (empty($title)) {
        $_SESSION['error_message'] = 'Title is required.';
        header('Location: ' . $redirect_url);
        exit();
    }

    if ($type === 'file') {
        if (isset($_FILES['material_file']) && $_FILES['material_file']['error'] === UPLOAD_ERR_OK) {
            $file = $_FILES['material_file'];
            // File size validation (15MB)
            if ($file['size'] > 15 * 1024 * 1024) {
                $_SESSION['error_message'] = 'File is too large. Maximum size is 15MB.';
            } else {
                $upload_dir = __DIR__ . '/../../uploads/';
                // Create a unique filename to prevent overwrites
                $filename = uniqid() . '-' . basename($file['name']);
                $filepath = $upload_dir . $filename;
                
                if (move_uploaded_file($file['tmp_name'], $filepath)) {
                    $stmt = $pdo->prepare("INSERT INTO materials (course_id, title, type, content) VALUES (?, ?, 'file', ?)");
                    $stmt->execute([$course_id, $title, $filename]); // Store only the filename
                    $_SESSION['success_message'] = 'File uploaded successfully.';
                } else {
                    $_SESSION['error_message'] = 'Failed to move uploaded file.';
                }
            }
        } else {
            $_SESSION['error_message'] = 'File upload failed. Please try again.';
        }
    } elseif ($type === 'link') {
        $link = trim($_POST['material_link']);
        if (empty($link) || !filter_var($link, FILTER_VALIDATE_URL)) {
             $_SESSION['error_message'] = 'A valid URL is required for the link.';
        } else {
            $stmt = $pdo->prepare("INSERT INTO materials (course_id, title, type, content) VALUES (?, ?, 'link', ?)");
            $stmt->execute([$course_id, $title, $link]);
            $_SESSION['success_message'] = 'Link added successfully.';
        }
    }
}

// --- Handle DELETE action ---
if ($action === 'delete' && isset($_GET['id'])) {
    $material_id = $_GET['id'];
    
    $stmt = $pdo->prepare("SELECT * FROM materials WHERE id = ? AND course_id = ?");
    $stmt->execute([$material_id, $course_id]);
    $material = $stmt->fetch();
    
    if ($material) {
        // If it's a file, delete it from the server first
        if ($material['type'] === 'file') {
            $filepath = __DIR__ . '/../../uploads/' . $material['content'];
            if (file_exists($filepath)) {
                unlink($filepath); // Deletes the file
            }
        }
        // Now delete the record from the database
        $stmt = $pdo->prepare("DELETE FROM materials WHERE id = ?");
        $stmt->execute([$material_id]);
        $_SESSION['success_message'] = 'Material deleted successfully.';
    } else {
        $_SESSION['error_message'] = 'Material not found or you do not have permission to delete it.';
    }
}

header('Location: ' . $redirect_url);
exit();