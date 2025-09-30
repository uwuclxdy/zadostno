<?php
// General utility functions
function redirect($url) {
    header('Location: ' . $url);
    exit();
}
