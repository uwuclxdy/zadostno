<?php 
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../templates/header.php'; 
require_once __DIR__ . '/../includes/db_connect.php'; // We need the database connection

// Fetch role-specific data
$user_role = $_SESSION['role'];
$teacher_courses = [];

if ($user_role === 'teacher') {
    $teacher_id = $_SESSION['user_id'];
    $stmt = $pdo->prepare("
        SELECT c.id, c.name, c.description 
        FROM courses c
        JOIN course_teachers ct ON c.id = ct.course_id
        WHERE ct.teacher_id = ?
        ORDER BY c.name
    ");
    $stmt->execute([$teacher_id]);
    $teacher_courses = $stmt->fetchAll();
}

// You can add similar logic for students later
// if ($user_role === 'student') { ... }

$error_message = $_SESSION['error_message'] ?? null;
unset($_SESSION['error_message']);
?>

<?php if ($error_message): ?>
    <div class="alert alert-danger"><?php echo htmlspecialchars($error_message); ?></div>
<?php endif; ?>

<div class="card mb-4">
    <div class="card-header">
        <h2>Dashboard</h2>
    </div>
    <div class="card-body">
        <h5 class="card-title">Welcome, <?php echo htmlspecialchars($_SESSION['first_name']); ?>!</h5>
        <p class="card-text">You are logged in as a <strong><?php echo ucfirst(htmlspecialchars($user_role)); ?></strong>.</p>
    </div>
</div>

<!-- Role-Specific Content -->
<?php if ($user_role === 'teacher'): ?>
    <h3>My Courses</h3>
    <div class="row">
        <?php if (empty($teacher_courses)): ?>
            <div class="col">
                <p>You are not yet assigned to any courses.</p>
            </div>
        <?php else: ?>
            <?php foreach ($teacher_courses as $course): ?>
                <div class="col-md-4 mb-3">
                    <div class="card h-100">
                        <div class="card-body d-flex flex-column">
                            <h5 class="card-title"><?php echo htmlspecialchars($course['name']); ?></h5>
                            <p class="card-text flex-grow-1"><?php echo htmlspecialchars(substr($course['description'], 0, 100)) . '...'; ?></p>
                            <a href="<?php echo base_url('/course.php?id=' . $course['id']); ?>" class="btn btn-primary mt-auto">Go to Course</a>
                        </div>
                    </div>
                </div>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>
<?php endif; ?>

<?php if ($user_role === 'admin'): ?>
    <p>From here, you can manage users, courses, and system settings via the "Admin" dropdown in the navigation bar.</p>
<?php endif; ?>

<?php if ($user_role === 'student'): ?>
    <p>Your enrolled courses will be displayed here soon.</p>
<?php endif; ?>


<?php require_once __DIR__ . '/../templates/footer.php'; ?>```
**Explanation:**
-   We now connect to the database from the dashboard.
-   If the logged-in user is a 'teacher', we perform a `JOIN` query to find all courses linked to their `user_id` in the `course_teachers` table.
-   We then loop through these courses and display each one as a Bootstrap "card" with a title, a short description, and a link to its detail page.

---

### Step 2: Create the Course Detail Page

This is a new, central page. For now, it will just show the course title and create sections for "Materials" and "Assignments," which we will build in the next step. This page must be secure—only the assigned teacher, an enrolled student, or an admin should be able to see it.

#### File 2: `public/course.php` (New File)

```php
<?php
require_once __DIR__ . '/../src/pages/course.php';
?>