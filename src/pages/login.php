<?php require_once __DIR__ . '/../templates/header.php'; ?>

<div class="row justify-content-center">
    <div class="col-md-5">
        <div class="card">
            <div class="card-header">
                <h3 class="text-center">Login</h3>
            </div>
            <div class="card-body">
                <form action="/actions/login_handler.php" method="post">
                    <div class="mb-3">
                        <label for="email" class="form-label">Email address</label>
                        <input type="email" class="form-control" id="email" name="email" required>
                    </div>
                    <div class="mb-3">
                        <label for="password" class="form-label">Password</label>
                        <input type="password" class="form-control" id="password" name="password" required>
                    </div>
                    <div class="d-grid">
                         <button type="submit" class="btn btn-primary">Login</button>
                    </div>
                </form>
            </div>
             <div class="card-footer text-center">
                <p>Don't have an account? <a href="/register.php">Register here</a></p>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/../templates/footer.php'; ?>