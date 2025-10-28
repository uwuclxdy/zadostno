<?php
// --- (Keep the top part of the file, including the access check, the same) ---
require_once __DIR__ . '/../includes/db_connect.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/course_access_check.php';

$course_id = $_GET['id'] ?? null;
if (!$course_id) { /* ... */ }

check_course_access($pdo, $course_id);

$stmt = $pdo->prepare("SELECT * FROM courses WHERE id = ?");
$stmt->execute([$course_id]);
$course = $stmt->fetch();
if (!$course) { /* ... */ }

$user_role = $_SESSION['role'];
$is_teacher = $user_role === 'teacher'; // A simple variable for convenience

// --- NEW: Fetch materials for this course ---
$stmt = $pdo->prepare("SELECT * FROM materials WHERE course_id = ? ORDER BY uploaded_at DESC");
$stmt->execute([$course_id]);
$materials = $stmt->fetchAll();
// ------------------------------------------

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
            <?php if ($is_teacher): ?>
                <!-- This button opens the modal defined at the bottom of the file -->
                <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addMaterialModal">
                    Add Material
                </button>
            <?php endif; ?>
        </div>
        <div class="card">
            <ul class="list-group list-group-flush">
                <?php if (empty($materials)): ?>
                    <li class="list-group-item">No materials have been added yet.</li>
                <?php else: ?>
                    <?php foreach ($materials as $material): ?>
                        <li class="list-group-item d-flex justify-content-between align-items-center">
                            <div>
                                <?php if ($material['type'] === 'link'): ?>
                                    <a href="<?php echo htmlspecialchars($material['content']); ?>" target="_blank">
                                        <?php echo htmlspecialchars($material['title']); ?> (Link)
                                    </a>
                                <?php else: ?>
                                    <a href="<?php echo base_url('/download.php?id=' . $material['id']); ?>">
                                        <?php echo htmlspecialchars($material['title']); ?> (File)
                                    </a>
                                <?php endif; ?>
                            </div>
                            <?php if ($is_teacher): ?>
                                <a href="<?php echo base_url('/actions/material_handler.php?action=delete&id=' . $material['id'] . '&course_id=' . $course_id); ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Are you sure you want to delete this material?');">
                                    Delete
                                </a>
                            <?php endif; ?>
                        </li>
                    <?php endforeach; ?>
                <?php endif; ?>
            </ul>
        </div>
    </div>

    <!-- Right Column: Assignments -->
    <div class="col-md-6">
        <!-- ... (Assignment section remains the same for now) ... -->
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h3>Assignments</h3>
            <?php if ($is_teacher): ?>
                <button class="btn btn-primary" disabled>Create Assignment</button>
            <?php endif; ?>
        </div>
        <div class="card">
            <div class="card-body">
                <p>Assignments will be listed here.</p>
            </div>
        </div>
    </div>
</div>


<!-- NEW: Add Material Modal -->
<?php if ($is_teacher): ?>
<div class="modal fade" id="addMaterialModal" tabindex="-1" aria-labelledby="addMaterialModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="addMaterialModalLabel">Add New Material</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <!-- The form will submit to our new handler -->
            <form action="<?php echo base_url('/actions/material_handler.php'); ?>" method="POST" enctype="multipart/form-data">
                <div class="modal-body">
                    <input type="hidden" name="course_id" value="<?php echo $course['id']; ?>">
                    <input type="hidden" name="action" value="add">
                    
                    <div class="mb-3">
                        <label for="title" class="form-label">Title</label>
                        <input type="text" class="form-control" id="title" name="title" required>
                    </div>

                    <div class="mb-3">
                        <label for="type" class="form-label">Material Type</label>
                        <select class="form-select" name="type" id="materialType" required>
                            <option value="file">File Upload</option>
                            <option value="link">External Link</option>
                        </select>
                    </div>

                    <!-- Field for File Upload -->
                    <div id="fileUploadGroup" class="mb-3">
                        <label for="material_file" class="form-label">File (Max 15MB)</label>
                        <input class="form-control" type="file" id="material_file" name="material_file">
                    </div>

                    <!-- Field for External Link -->
                    <div id="linkGroup" class="mb-3" style="display: none;">
                        <label for="material_link" class="form-label">URL</label>
                        <input type="url" class="form-control" id="material_link" name="material_link" placeholder="https://example.com">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="submit" class="btn btn-primary">Add Material</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Simple script to toggle form fields in the modal -->
<script>
document.getElementById('materialType').addEventListener('change', function () {
    if (this.value === 'file') {
        document.getElementById('fileUploadGroup').style.display = 'block';
        document.getElementById('linkGroup').style.display = 'none';
    } else {
        document.getElementById('fileUploadGroup').style.display = 'none';
        document.getElementById('linkGroup').style.display = 'block';
    }
});
</script>
<?php endif; ?>


<?php require_once __DIR__ . '/../templates/footer.php'; ?>