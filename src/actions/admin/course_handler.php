<?php
session_start();
require_once __DIR__ . '/../../includes/admin_check.php';
require_once __DIR__ . '/../../includes/db_connect.php';
require_once __DIR__ . '/../../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $course_id = $_GET['id'] ?? null;
    $is_edit_mode = $course_id !== null;

    $name = trim($_POST['name']);
    $description = trim($_POST['description']);
    $errors = [];

    if (empty($name)) {
        $errors[] = 'Course name is required.';
    }

    if (!empty($errors)) {
        $_SESSION['errors'] = $errors;
        $redirect_url = $is_edit_mode ? base_url('/admin/course_form.php?id=' . $course_id) : base_url('/admin/course_form.php');
        header('Location: ' . $redirect_url);
        exit();
    }

    try {
        if ($is_edit_mode) {
            // Update existing course
            $stmt = $pdo->prepare("UPDATE courses SET name = ?, description = ? WHERE id = ?");
            $stmt->execute([$name, $description, $course_id]);
            $_SESSION['success_message'] = 'Course updated successfully!';
        } else {
            // Insert new course
            $stmt = $pdo->prepare("INSERT INTO courses (name, description) VALUES (?, ?)");
            $stmt->execute([$name, $description]);
            $_SESSION['success_message'] = 'Course created successfully!';
        }
        header('Location: ' . base_url('/admin/courses.php'));
        exit();

    } catch (PDOException $e) {
        $_SESSION['errors'] = ['A database error occurred.'];
        $redirect_url = $is_edit_mode ? base_url('/admin/course_form.php?id=' . $course_id) : base_url('/admin/course_form.php');
        header('Location: ' . $redirect_url);
        exit();
    }
}