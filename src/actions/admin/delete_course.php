<?php
session_start();
require_once __DIR__ . '/../../includes/admin_check.php';
require_once __DIR__ . '/../../includes/db_connect.php';
require_once __DIR__ . '/../../includes/functions.php';

$course_id = $_GET['id'] ?? null;

if (!$course_id) {
    header('Location: ' . base_url('/admin/courses.php'));
    exit();
}

try {
    // Because of "ON DELETE CASCADE" in our SQL setup, deleting a course
    // will automatically delete related enrollments, materials, assignments, etc.
    $stmt = $pdo->prepare("DELETE FROM courses WHERE id = ?");
    $stmt->execute([$course_id]);

    $_SESSION['success_message'] = 'Course and all related data have been deleted.';
} catch (PDOException $e) {
    $_SESSION['error_message'] = 'Failed to delete course due to a database error.';
}

header('Location: ' . base_url('/admin/courses.php'));
exit();