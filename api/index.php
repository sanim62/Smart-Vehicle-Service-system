<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

// ─── Vercel: filesystem is read-only except /tmp ───────────────────────────
// Create writable directories in /tmp for Laravel's framework files
$storagePath = '/tmp/storage';
$directories = [
    $storagePath . '/framework/cache/data',
    $storagePath . '/framework/sessions',
    $storagePath . '/framework/views',
    $storagePath . '/logs',
    $storagePath . '/app/public',
];

foreach ($directories as $dir) {
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
}

// Copy the SQLite database to /tmp on first boot (since /tmp is writable)
$dbSource = __DIR__ . '/../database/database.sqlite';
$dbDest   = '/tmp/database.sqlite';
if (!file_exists($dbDest) && file_exists($dbSource)) {
    copy($dbSource, $dbDest);
}

// Tell Laravel to use /tmp/storage as the storage path
// LARAVEL_STORAGE_PATH is the official Laravel env variable for this
putenv('LARAVEL_STORAGE_PATH=' . $storagePath);
$_ENV['LARAVEL_STORAGE_PATH']    = $storagePath;
$_SERVER['LARAVEL_STORAGE_PATH'] = $storagePath;

// Point DB to the writable /tmp copy
putenv('DB_DATABASE=/tmp/database.sqlite');
$_ENV['DB_DATABASE']    = '/tmp/database.sqlite';
$_SERVER['DB_DATABASE'] = '/tmp/database.sqlite';

// ───────────────────────────────────────────────────────────────────────────


// Determine if the application is in maintenance mode...
if (file_exists($maintenance = __DIR__ . '/../storage/framework/maintenance.php')) {
    require $maintenance;
}

// Register the Composer autoloader...
require __DIR__ . '/../vendor/autoload.php';

// Bootstrap Laravel and handle the request...
/** @var Application $app */
$app = require_once __DIR__ . '/../bootstrap/app.php';

// Explicitly configure storage path on the application instance
$app->useStoragePath($storagePath);

// Ensure config uses the writable sqlite database in /tmp
config([
    'database.connections.sqlite.database' => '/tmp/database.sqlite',
    'view.compiled' => $storagePath . '/framework/views',
    'cache.stores.file.path' => $storagePath . '/framework/cache/data',
    'session.files' => $storagePath . '/framework/sessions',
    'session.driver' => env('SESSION_DRIVER', 'cookie'),
]);

try {
    $request = Request::capture();
    $response = $app->handleRequest($request);
    $response->send();
} catch (\Throwable $e) {
    http_response_code(500);
    header('Content-Type: text/html; charset=utf-8');
    echo '<h2>Laravel Application Error</h2>';
    echo '<p><strong>Message:</strong> ' . htmlspecialchars($e->getMessage()) . '</p>';
    echo '<p><strong>File:</strong> ' . htmlspecialchars($e->getFile()) . ':' . $e->getLine() . '</p>';
    echo '<pre style="background:#1e1e1e;color:#fff;padding:15px;border-radius:8px;overflow:auto;">' . htmlspecialchars($e->getTraceAsString()) . '</pre>';
}


