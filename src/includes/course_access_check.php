<?php
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

/**
 * Checks if the current logged-in user has permission to view a specific course.
 * Allowed users: Admins, assigned teachers, enrolled students.
 * Redirects to the dashboard with an error if access is denied.
 *
 * @param PDO $pdo The database connection object.
 * @param int $course_id The ID of the course to check.
 */
function check_course_access($pdo, $course_id) {
    if (!isset($_SESSION['user_id'])) {
        header('Location: ' . base_url('/login.php'));
        exit();
    }

    $user_id = $_SESSION['user_id'];
    $role = $_SESSION['role'];

    // Admins have access to everything
    if ($role === 'admin') {
        return; 
    }

    // Check if the user is an assigned teacher
    if ($role === 'teacher') {
        $stmt = $pdo->prepare("SELECT 1 FROM course_teachers WHERE course_id = ? AND teacher_id = ?");
        $stmt->execute([$course_id, $user_id]);
        if ($stmt->fetch()) {
            return; // Access granted
        }
    }

    // Check if the user is an enrolled student
    if ($role === 'student') {
        $stmt = $pdo->prepare("SELECT 1 FROM enrollments WHERE course_id = ? AND student_id = ?");
        $stmt->execute([$course_id, $user_id]);
        if ($stmt->fetch()) {
            return; // Access granted
        }
    }

    // If none of the above, deny access
    $_SESSION['error_message'] = "You do not have permission to access this course.";
    header('Location: ' . base_url('/dashboard.php'));
    exit();
}
// Add this new function at the end of the file
function is_course_teacher($pdo, $course_id, $user_id) {
    if (!isset($_SESSION['role']) || $_SESSION['role'] !== 'teacher') {
        return false;
    }
    $stmt = $pdo->prepare("SELECT 1 FROM course_teachers WHERE course_id = ? AND teacher_id = ?");
    $stmt->execute([$course_id, $user_id]);
    return $stmt->fetch() !== false;
}