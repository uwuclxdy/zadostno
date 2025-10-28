<?php
require_once __DIR__ . '/../../includes/admin_check.php';
require_once __DIR__ . '/../../includes/db_connect.php';
require_once __DIR__ . '/../../includes/functions.php';

$course_id = $_GET['id'] ?? null;
if (!$course_id) {
    header('Location: ' . base_url('/admin/courses.php'));
    exit();
}

// --- 1. Fetch Core Course Details ---
$stmt = $pdo->prepare("SELECT * FROM courses WHERE id = ?");
$stmt->execute([$course_id]);
$course = $stmt->fetch();
if (!$course) {
    $_SESSION['error_message'] = 'Course not found.';
    header('Location: ' . base_url('/admin/courses.php'));
    exit();
}

// --- 2. Fetch Assigned Teachers for this Course ---
$stmt = $pdo->prepare("
    SELECT u.id, u.first_name, u.last_name FROM users u
    JOIN course_teachers ct ON u.id = ct.teacher_id
    WHERE ct.course_id = ? ORDER BY u.last_name
");
$stmt->execute([$course_id]);
$assigned_teachers = $stmt->fetchAll();

// --- 3. Fetch Enrolled Students for this Course ---
$stmt = $pdo->prepare("
    SELECT u.id, u.first_name, u.last_name FROM users u
    JOIN enrollments e ON u.id = e.student_id
    WHERE e.course_id = ? ORDER BY u.last_name
");
$stmt->execute([$course_id]);
$enrolled_students = $stmt->fetchAll();

// --- 4. Fetch ALL available teachers and students to add them ---
$all_teachers = $pdo->query("SELECT id, first_name, last_name FROM users WHERE role = 'teacher' ORDER BY last_name")->fetchAll();
$all_students = $pdo->query("SELECT id, first_name, last_name FROM users WHERE role = 'student' ORDER BY last_name")->fetchAll();


$success_message = $_SESSION['success_message'] ?? null;
$error_message = $_SESSION['error_message'] ?? null;
unset($_SESSION['success_message'], $_SESSION['error_message']);

require_once __DIR__ . '/../../templates/header.php';
?>

<nav aria-label="breadcrumb">
  <ol class="breadcrumb">
    <li class="breadcrumb-item"><a href="<?php echo base_url('/admin/courses.php'); ?>">Manage Courses</a></li>
    <li class="breadcrumb-item active" aria-current="page">Manage Users for <?php echo htmlspecialchars($course['name']); ?></li>
  </ol>
</nav>

<h1>Manage Users for: <?php echo htmlspecialchars($course['name']); ?></h1>
<hr>

<?php if ($success_message): ?>
    <div class="alert alert-success"><?php echo htmlspecialchars($success_message); ?></div>
<?php endif; ?>
<?php if ($error_message): ?>
    <div class="alert alert-danger"><?php echo htmlspecialchars($error_message); ?></div>
<?php endif; ?>


<div class="row">
    <!-- TEACHER MANAGEMENT -->
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <h4>Assigned Teachers</h4>
            </div>
            <div class="card-body">
                <!-- Form to add a new teacher -->
                <form class="mb-3" action="<?php echo base_url('/actions/admin/manage_course_users_handler.php'); ?>" method="POST">
                    <input type="hidden" name="course_id" value="<?php echo $course_id; ?>">
                    <input type="hidden" name="action" value="add_teacher">
                    <div class="input-group">
                        <select name="user_id" class="form-select" required>
                            <option value="">-- Select a Teacher --</option>
                            <?php foreach ($all_teachers as $teacher): ?>
                                <option value="<?php echo $teacher['id']; ?>"><?php echo htmlspecialchars($teacher['first_name'] . ' ' . $teacher['last_name']); ?></option>
                            <?php endforeach; ?>
                        </select>
                        <button type="submit" class="btn btn-primary">Add Teacher</button>
                    </div>
                </form>

                <!-- List of currently assigned teachers -->
                <ul class="list-group">
                    <?php if (empty($assigned_teachers)): ?>
                        <li class="list-group-item">No teachers assigned.</li>
                    <?php else: ?>
                        <?php foreach ($assigned_teachers as $teacher): ?>
                            <li class="list-group-item d-flex justify-content-between align-items-center">
                                <?php echo htmlspecialchars($teacher['first_name'] . ' ' . $teacher['last_name']); ?>
                                <a href="<?php echo base_url('/actions/admin/manage_course_users_handler.php?action=remove_teacher&user_id=' . $teacher['id'] . '&course_id=' . $course_id); ?>" class="btn btn-sm btn-danger">Remove</a>
                            </li>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </ul>
            </div>
        </div>
    </div>

    <!-- STUDENT MANAGEMENT -->
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <h4>Enrolled Students</h4>
            </div>
            <div class="card-body">
                <!-- Form to add a new student -->
                 <form class="mb-3" action="<?php echo base_url('/actions/admin/manage_course_users_handler.php'); ?>" method="POST">
                    <input type="hidden" name="course_id" value="<?php echo $course_id; ?>">
                    <input type="hidden" name="action" value="add_student">
                    <div class="input-group">
                        <select name="user_id" class="form-select" required>
                            <option value="">-- Select a Student --</option>
                            <?php foreach ($all_students as $student): ?>
                                <option value="<?php echo $student['id']; ?>"><?php echo htmlspecialchars($student['first_name'] . ' ' . $student['last_name']); ?></option>
                            <?php endforeach; ?>
                        </select>
                        <button type="submit" class="btn btn-primary">Add Student</button>
                    </div>
                </form>
                
                <!-- List of currently enrolled students -->
                <ul class="list-group">
                    <?php if (empty($enrolled_students)): ?>
                        <li class="list-group-item">No students enrolled.</li>
                    <?php else: ?>
                        <?php foreach ($enrolled_students as $student): ?>
                            <li class="list-group-item d-flex justify-content-between align-items-center">
                                <?php echo htmlspecialchars($student['first_name'] . ' ' . $student['last_name']); ?>
                                <a href="<?php echo base_url('/actions/admin/manage_course_users_handler.php?action=remove_student&user_id=' . $student['id'] . '&course_id=' . $course_id); ?>" class="btn btn-sm btn-danger">Remove</a>
                            </li>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </ul>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/../../templates/footer.php'; ?>```

---

### Step 2: The Handler for All User Management Actions

This single handler file is responsible for adding/removing both teachers and students. It uses an `action` parameter to decide what to do.

#### File 3: `src/actions/admin/manage_course_users_handler.php` (New File)

```php
<?php
session_start();
require_once __DIR__ . '/../../includes/admin_check.php';
require_once __DIR__ . '/../../includes/db_connect.php';
require_once __DIR__ . '/../../includes/functions.php';

// Determine the action from either POST (for adding) or GET (for removing)
$action = $_POST['action'] ?? $_GET['action'] ?? null;
$course_id = $_POST['course_id'] ?? $_GET['course_id'] ?? null;
$user_id = $_POST['user_id'] ?? $_GET['user_id'] ?? null;

// Validate that we have all necessary data
if (!$action || !$course_id || !$user_id) {
    $_SESSION['error_message'] = 'Invalid request.';
    header('Location: ' . base_url('/admin/courses.php'));
    exit();
}

// The redirect path will be the same for all outcomes
$redirect_url = base_url('/admin/manage_course_users.php?id=' . $course_id);

try {
    switch ($action) {
        case 'add_teacher':
            // IGNORE a duplicate assignment to prevent errors
            $stmt = $pdo->prepare("INSERT INTO course_teachers (course_id, teacher_id) VALUES (?, ?) ON CONFLICT (course_id, teacher_id) DO NOTHING");
            $stmt->execute([$course_id, $user_id]);
            $_SESSION['success_message'] = 'Teacher assigned successfully.';
            break;

        case 'remove_teacher':
            $stmt = $pdo->prepare("DELETE FROM course_teachers WHERE course_id = ? AND teacher_id = ?");
            $stmt->execute([$course_id, $user_id]);
            $_SESSION['success_message'] = 'Teacher removed from course.';
            break;

        case 'add_student':
             // IGNORE a duplicate enrollment to prevent errors
            $stmt = $pdo->prepare("INSERT INTO enrollments (course_id, student_id) VALUES (?, ?) ON CONFLICT (course_id, student_id) DO NOTHING");
            $stmt->execute([$course_id, $user_id]);
            $_SESSION['success_message'] = 'Student enrolled successfully.';
            break;

        case 'remove_student':
            $stmt = $pdo->prepare("DELETE FROM enrollments WHERE course_id = ? AND student_id = ?");
            $stmt->execute([$course_id, $user_id]);
            $_SESSION['success_message'] = 'Student unenrolled from course.';
            break;

        default:
            $_SESSION['error_message'] = 'Unknown action.';
            break;
    }
} catch (PDOException $e) {
    // Catch any database errors, like trying to add a user that doesn't exist
    $_SESSION['error_message'] = 'A database error occurred: ' . $e->getMessage();
}

header('Location: ' . $redirect_url);
exit();