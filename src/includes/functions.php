<?php
/**
 * Generates a correct, full URL to a path inside your project's public folder.
 */
function base_url($path = '') {
    // IMPORTANT: Make sure this path matches your project's folder structure inside htdocs.
    // It should be the path from 'localhost' to your 'public' folder.
    $base_path = '/zadostno_redovalnica/zadostno/public'; 

    // Remove leading slash from the provided $path to prevent double slashes
    if (!empty($path) && $path[0] === '/') {
        $path = substr($path, 1);
    }
    
    return rtrim($base_path, '/') . '/' . $path;
}
?>