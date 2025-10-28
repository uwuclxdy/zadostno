<?php
require_once __DIR__ . '/../includes/db_connect.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/course_access_check.php'; // Include our new guard

$course_id = $_GET['id'] ?? null;
if (!$course_id) {
    header('Location: ' . base_url('/dashboard.php'));
    exit();
}

// This function will protect the page and redirect if the user doesn't have access
check_course_access($pdo, $course_id);

// If the script continues, access is granted. Fetch course details.
$stmt = $pdo->prepare("SELECT * FROM courses WHERE id = ?");
$stmt->execute([$course_id]);
$course = $stmt->fetch();

// This should not happen if access check passed, but it's a good safeguard
if (!$course) {
    header('Location: ' . base_url('/dashboard.php'));
    exit();
}

$user_role = $_SESSION['role'];

require_once __DIR__ . '/../templates/header.php';
?>

<h1><?php echo htmlspecialchars($course['name']); ?></h1>
<p class="lead"><?php echo htmlspecialchars($course['description']); ?></p>
<hr>

<div class="row">
    <!-- Left Column: Materials -->
    <div class="col-md-6">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h3>Learning Materials</h3>
            <?php if ($user_role === 'teacher'): ?>
                <button class="btn btn-primary" disabled>Add Material</button> <!-- Disabled for now -->
            <?php endif; ?>
        </div>
        <div class="card">
            <div class="card-body">
                <p>Materials will be listed here.</p>
            </div>
        </div>
    </div>

    <!-- Right Column: Assignments -->
    <div class="col-md-6">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h3>Assignments</h3>
            <?php if ($user_role === 'teacher'): ?>
                <button class="btn btn-primary" disabled>Create Assignment</button> <!-- Disabled for now -->
            <?php endif; ?>
        </div>
        <div class="card">
            <div class="card-body">
                <p>Assignments will be listed here.</p>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/../templates/footer.php'; ?>