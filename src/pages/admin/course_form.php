<?php
require_once __DIR__ . '/../../includes/admin_check.php';
require_once __DIR__ . '/../../includes/db_connect.php';
require_once __DIR__ . '/../../includes/functions.php';

// --- Determine Mode: Edit or Add ---
$course_id = $_GET['id'] ?? null;
$is_edit_mode = $course_id !== null;
$course = null;
$page_title = 'Add New Course';
$form_action = base_url('/actions/admin/course_handler.php');

if ($is_edit_mode) {
    $stmt = $pdo->prepare("SELECT * FROM courses WHERE id = ?");
    $stmt->execute([$course_id]);
    $course = $stmt->fetch();
    if (!$course) {
        // Course not found, redirect
        $_SESSION['error_message'] = 'Course not found.';
        header('Location: ' . base_url('/admin/courses.php'));
        exit();
    }
    $page_title = 'Edit Course';
    // Add the id to the form action for the handler
    $form_action .= '?id=' . $course_id;
}

$errors = $_SESSION['errors'] ?? [];
unset($_SESSION['errors']);

require_once __DIR__ . '/../../templates/header.php';
?>

<h1><?php echo $page_title; ?></h1>
<hr>

<?php if (!empty($errors)): ?>
    <div class="alert alert-danger">
        <ul class="mb-0">
            <?php foreach ($errors as $error): ?>
                <li><?php echo htmlspecialchars($error); ?></li>
            <?php endforeach; ?>
        </ul>
    </div>
<?php endif; ?>

<div class="card">
    <div class="card-body">
        <form action="<?php echo $form_action; ?>" method="POST">
            <div class="mb-3">
                <label for="name" class="form-label">Course Name</label>
                <input type="text" class="form-control" id="name" name="name" value="<?php echo htmlspecialchars($course['name'] ?? ''); ?>" required>
            </div>
            <div class="mb-3">
                <label for="description" class="form-label">Description</label>
                <textarea class="form-control" id="description" name="description" rows="5"><?php echo htmlspecialchars($course['description'] ?? ''); ?></textarea>
            </div>
            
            <a href="<?php echo base_url('/admin/courses.php'); ?>" class="btn btn-secondary">Cancel</a>
            <button type="submit" class="btn btn-primary"><?php echo $is_edit_mode ? 'Update Course' : 'Create Course'; ?></button>
        </form>
    </div>
</div>

<?php require_once __DIR__ . '/../../templates/footer.php'; ?>