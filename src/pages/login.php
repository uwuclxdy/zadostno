<?php
// Login page
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../templates/header.php';
?>
<h2>Login</h2>
<form method="post">
    <input type="text" name="username" placeholder="Username" required />
    <input type="password" name="password" placeholder="Password" required />
    <button type="submit">Login</button>
</form>
<?php
require_once __DIR__ . '/../templates/footer.php';
