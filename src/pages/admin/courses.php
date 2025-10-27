<?php
require_once __DIR__ . '/../../includes/admin_check.php'; // Protect the page
require_once __DIR__ . '/../../includes/db_connect.php';
require_once __DIR__ . '/../../includes/functions.php';

// Fetch all courses from the database
$stmt = $pdo->query("SELECT * FROM courses ORDER BY name ASC");
$courses = $stmt->fetchAll();

$success_message = $_SESSION['success_message'] ?? null;
unset($_SESSION['success_message']);

require_once __DIR__ . '/../../templates/header.php';
?>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h1>Manage Courses</h1>
    <a href="<?php echo base_url('/admin/course_form.php'); ?>" class="btn btn-primary">Add New Course</a>
</div>

<?php if ($success_message): ?>
    <div class="alert alert-success"><?php echo htmlspecialchars($success_message); ?></div>
<?php endif; ?>

<div class="card">
    <div class="card-body">
        <table class="table table-striped">
            <thead>
                <tr>
                    <th>Course Name</th>
                    <th>Description</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($courses)): ?>
                    <tr>
                        <td colspan="3" class="text-center">No courses found.</td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($courses as $course): ?>
                        <tr>
                            <td><?php echo htmlspecialchars($course['name']); ?></td>
                            <td><?php echo htmlspecialchars(substr($course['description'], 0, 100)) . '...'; ?></td>
                            <td>
                                <a href="<?php echo base_url('/admin/manage_course_users.php?id=' . $course['id']); ?>" class="btn btn-sm btn-info">Manage Users</a>
                                <a href="<?php echo base_url('/admin/course_form.php?id=' . $course['id']); ?>" class="btn btn-sm btn-secondary">Edit</a>
                                <a href="<?php echo base_url('/actions/admin/delete_course.php?id=' . $course['id']); ?>" class="btn btn-sm btn-danger" onclick="return confirm('Are you sure you want to delete this course? This will remove all enrollments and related materials.')">Delete</a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php require_once __DIR__ . '/../../templates/footer.php'; ?>```
**Explanation:**
- The page is protected by `admin_check.php`.
- It fetches all courses from the `courses` table.
- It displays them in a table. Each row has three action buttons:
    - **Manage Users:** For assigning teachers/students (we will build this next).
    - **Edit:** Takes the admin to the form to modify the course.
    - **Delete:** A link that will trigger the deletion script (we will build this next). It includes a JavaScript confirmation pop-up.

---

### Step 3: Create the Add/Edit Course Form and Handler

We will use a single form for both creating and editing a course. The page will check if an `id` is in the URL. If yes, it's in "edit mode"; if no, it's in "add mode".

#### File 5: `public/admin/course_form.php` (New File)

```php
<?php
require_once __DIR__ . '/../../src/pages/admin/course_form.php';
?>