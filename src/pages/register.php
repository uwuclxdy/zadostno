<?php 
require_once __DIR__ . '/../templates/header.php'; 

// --- Get any error messages or old form data from the session ---
$errors = $_SESSION['errors'] ?? [];
$old_input = $_SESSION['old_input'] ?? [];

// Clear them from the session so they don't persist
unset($_SESSION['errors']);
unset($_SESSION['old_input']);
// ----------------------------------------------------------------

?>

<div class="row justify-content-center">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <h3 class="text-center">Student Registration</h3>
            </div>
            <div class="card-body">
                <?php if (!empty($errors)): ?>
                    <div class="alert alert-danger">
                        <ul class="mb-0">
                            <?php foreach ($errors as $error): ?>
                                <li><?php echo htmlspecialchars($error); ?></li>
                            <?php endforeach; ?>
                        </ul>
                    </div>
                <?php endif; ?>

                <form action="/actions/register_handler.php" method="POST">
                    <div class="mb-3">
                        <label for="first_name" class="form-label">First Name</label>
                        <input type="text" class="form-control" id="first_name" name="first_name" value="<?php echo htmlspecialchars($old_input['first_name'] ?? ''); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label for="last_name" class="form-label">Last Name</label>
                        <input type="text" class="form-control" id="last_name" name="last_name" value="<?php echo htmlspecialchars($old_input['last_name'] ?? ''); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label for="email" class="form-label">Email Address</label>
                        <input type="email" class="form-control" id="email" name="email" value="<?php echo htmlspecialchars($old_input['email'] ?? ''); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label for="password" class="form-label">Password (min. 8 characters)</label>
                        <input type="password" class="form-control" id="password" name="password" required>
                    </div>
                    <div class="mb-3">
                        <label for="password_confirm" class="form-label">Confirm Password</label>
                        <input type="password" class="form-control" id="password_confirm" name="password_confirm" required>
                    </div>
                    <div class="d-grid">
                        <button type="submit" class="btn btn-primary">Register</button>
                    </div>
                </form>
            </div>
            <div class="card-footer text-center">
                <p>Already have an account? <a href="/login.php">Login here</a></p>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/../templates/footer.php'; ?>```
**Explanation:**
-   At the top, we check the `$_SESSION` for any `'errors'` or `'old_input'`. This is how the handler will send information back if validation fails.
-   We then `unset()` them so they only appear once.
-   The form displays the errors in a red box.
-   Each input field's `value` attribute is set to the "old input" if it exists. This prevents users from having to re-type everything after a small error.

---

### Step 2: Create the Registration Handler

This is the most important part. This script will validate the user's input, check for duplicate emails, hash the password, and create the new user in the database.

#### File 3: `src/actions/register_handler.php`

```php
<?php
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../includes/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // 1. Collect and sanitize input
    $first_name = trim($_POST['first_name']);
    $last_name = trim($_POST['last_name']);
    $email = trim($_POST['email']);
    $password = $_POST['password'];
    $password_confirm = $_POST['password_confirm'];

    $errors = [];

    // 2. Validate input
    if (empty($first_name)) {
        $errors[] = 'First name is required.';
    }
    if (empty($last_name)) {
        $errors[] = 'Last name is required.';
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $errors[] = 'A valid email is required.';
    }
    if (strlen($password) < 8) {
        $errors[] = 'Password must be at least 8 characters long.';
    }
    if ($password !== $password_confirm) {
        $errors[] = 'Passwords do not match.';
    }

    // 3. Check if email already exists in the database
    if (empty($errors)) {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->execute([$email]);
        if ($stmt->fetch()) {
            $errors[] = 'An account with this email already exists.';
        }
    }

    // 4. If there are errors, redirect back to the registration page
    if (!empty($errors)) {
        // Store errors and old input in session to display them back on the form
        $_SESSION['errors'] = $errors;
        $_SESSION['old_input'] = [
            'first_name' => $first_name,
            'last_name' => $last_name,
            'email' => $email,
        ];
        header('Location: /register.php');
        exit();
    }

    // 5. If validation passes, hash password and insert into database
    $password_hash = password_hash($password, PASSWORD_DEFAULT);
    $role = 'student'; // Self-registration is always for students

    try {
        $stmt = $pdo->prepare("INSERT INTO users (first_name, last_name, email, password_hash, role) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$first_name, $last_name, $email, $password_hash, $role]);
        
        // 6. Redirect to login page with a success message
        $_SESSION['success_message'] = 'Registration successful! Please log in.';
        header('Location: /login.php');
        exit();
    } catch (PDOException $e) {
        // Handle unexpected database errors
        $_SESSION['errors'] = ['A database error occurred. Please try again.'];
        header('Location: /register.php');
        exit();
    }

} else {
    // Redirect if accessed directly
    header('Location: /register.php');
    exit();
}