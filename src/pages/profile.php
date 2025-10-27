<?php
// 1. SETUP: We need all our core files
require_once __DIR__ . '/../includes/auth_check.php'; // Protects the page
require_once __DIR__ . '/../includes/db_connect.php';
require_once __DIR__ . '/../includes/functions.php'; // Our new URL helper

$user_id = $_SESSION['user_id'];
$errors = $_SESSION['errors'] ?? [];
$success_message = $_SESSION['success_message'] ?? null;

unset($_SESSION['errors']);
unset($_SESSION['success_message']);

// 2. HANDLE FORM SUBMISSIONS
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Check which form was submitted
    $action = $_POST['action'] ?? '';

    // --- A. Handle Profile Information Update ---
    if ($action === 'update_profile') {
        $first_name = trim($_POST['first_name']);
        $last_name = trim($_POST['last_name']);
        $email = trim($_POST['email']);
        $phone_number = trim($_POST['phone_number']);

        if (empty($first_name) || empty($last_name) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = "First name, last name, and a valid email are required.";
        } else {
            // Check if email is being changed and if it's already taken
            $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
            $stmt->execute([$email, $user_id]);
            if ($stmt->fetch()) {
                $errors[] = "This email address is already in use by another account.";
            }
        }

        if (empty($errors)) {
            $sql = "UPDATE users SET first_name = ?, last_name = ?, email = ?, phone_number = ? WHERE id = ?";
            $pdo->prepare($sql)->execute([$first_name, $last_name, $email, $phone_number, $user_id]);
            $_SESSION['first_name'] = $first_name; // Update session
            $_SESSION['success_message'] = "Profile updated successfully!";
            header('Location: ' . base_url('/profile.php'));
            exit();
        }
    }

    // --- B. Handle Password Change ---
    if ($action === 'change_password') {
        $current_password = $_POST['current_password'];
        $new_password = $_POST['new_password'];
        $confirm_password = $_POST['confirm_password'];

        $stmt = $pdo->prepare("SELECT password_hash FROM users WHERE id = ?");
        $stmt->execute([$user_id]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($current_password, $user['password_hash'])) {
            $errors[] = "Current password is incorrect.";
        }
        if (strlen($new_password) < 8) {
            $errors[] = "New password must be at least 8 characters long.";
        }
        if ($new_password !== $confirm_password) {
            $errors[] = "New passwords do not match.";
        }

        if (empty($errors)) {
            $new_password_hash = password_hash($new_password, PASSWORD_DEFAULT);
            $sql = "UPDATE users SET password_hash = ? WHERE id = ?";
            $pdo->prepare($sql)->execute([$new_password_hash, $user_id]);
            $_SESSION['success_message'] = "Password changed successfully!";
            header('Location: ' . base_url('/profile.php'));
            exit();
        }
    }
    // If there were errors, store them in the session and redirect
    if (!empty($errors)) {
        $_SESSION['errors'] = $errors;
        header('Location: ' . base_url('/profile.php'));
        exit();
    }
}

// 3. FETCH CURRENT USER DATA to display in the forms
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$user_id]);
$current_user = $stmt->fetch();

// 4. DISPLAY THE PAGE
require_once __DIR__ . '/../templates/header.php';
?>

<h1>My Profile</h1>
<hr>

<?php if ($success_message): ?>
    <div class="alert alert-success"><?php echo htmlspecialchars($success_message); ?></div>
<?php endif; ?>
<?php if (!empty($errors)): ?>
    <div class="alert alert-danger">
        <ul class="mb-0">
            <?php foreach ($errors as $error): ?>
                <li><?php echo htmlspecialchars($error); ?></li>
            <?php endforeach; ?>
        </ul>
    </div>
<?php endif; ?>

<div class="row">
    <!-- Profile Details Column -->
    <div class="col-md-6">
        <div class="card">
            <div class="card-header"><h4>Update Profile Information</h4></div>
            <div class="card-body">
                <form action="<?php echo base_url('/profile.php'); ?>" method="POST">
                    <input type="hidden" name="action" value="update_profile">
                    <div class="mb-3">
                        <label for="first_name" class="form-label">First Name</label>
                        <input type="text" class="form-control" id="first_name" name="first_name" value="<?php echo htmlspecialchars($current_user['first_name']); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label for="last_name" class="form-label">Last Name</label>
                        <input type="text" class="form-control" id="last_name" name="last_name" value="<?php echo htmlspecialchars($current_user['last_name']); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label for="email" class="form-label">Email Address</label>
                        <input type="email" class="form-control" id="email" name="email" value="<?php echo htmlspecialchars($current_user['email']); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label for="phone_number" class="form-label">Phone Number (Optional)</label>
                        <input type="tel" class="form-control" id="phone_number" name="phone_number" value="<?php echo htmlspecialchars($current_user['phone_number'] ?? ''); ?>">
                    </div>
                    <button type="submit" class="btn btn-primary">Update Profile</button>
                </form>
            </div>
        </div>
    </div>
    <!-- Change Password Column -->
    <div class="col-md-6">
         <div class="card">
            <div class="card-header"><h4>Change Password</h4></div>
            <div class="card-body">
                <form action="<?php echo base_url('/profile.php'); ?>" method="POST">
                     <input type="hidden" name="action" value="change_password">
                    <div class="mb-3">
                        <label for="current_password" class="form-label">Current Password</label>
                        <input type="password" class="form-control" id="current_password" name="current_password" required>
                    </div>
                     <div class="mb-3">
                        <label for="new_password" class="form-label">New Password</label>
                        <input type="password" class="form-control" id="new_password" name="new_password" required>
                    </div>
                     <div class="mb-3">
                        <label for="confirm_password" class="form-label">Confirm New Password</label>
                        <input type="password" class="form-control" id="confirm_password" name="confirm_password" required>
                    </div>
                    <button type="submit" class="btn btn-primary">Change Password</button>
                </form>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/../templates/footer.php'; ?>