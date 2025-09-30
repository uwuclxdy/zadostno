<?php
// Register page
require_once __DIR__ . '/../templates/header.php';
?>
<h2>Register</h2>
<form method="post">
    <input type="text" name="username" placeholder="Username" required />
    <input type="email" name="email" placeholder="Email" required />
    <input type="password" name="password" placeholder="Password" required />
    <button type="submit">Register</button>
</form>
<?php
require_once __DIR__ . '/../templates/footer.php';
