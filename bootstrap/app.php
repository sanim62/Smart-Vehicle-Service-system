<?php

use Illuminate\Auth\Middleware\RedirectIfAuthenticated;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Support\Facades\Auth;

$storagePath = env('LARAVEL_STORAGE_PATH') ?: (isset($_ENV['LARAVEL_STORAGE_PATH']) ? $_ENV['LARAVEL_STORAGE_PATH'] : null);

$app = Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    );

if ($storagePath) {
    $app->useStoragePath($storagePath);
}

return $app
    ->withMiddleware(function (Middleware $middleware) {
        // Register the 'admin' middleware alias
        $middleware->alias([
            'admin' => \App\Http\Middleware\AdminMiddleware::class,
        ]);

        // Smart guest-route handling:
        // If an authenticated user visits /login or /register (e.g. to switch accounts),
        // they are automatically logged out and the login form is shown immediately.
        // They are NEVER required to manually logout first.
        // For any other guest route, they are redirected to their role-appropriate dashboard.
        RedirectIfAuthenticated::redirectUsing(function ($request) {
            $user = auth()->user();

            if (!$user) {
                return route('login');
            }

            // Auto-logout when user intentionally navigates to the login or register page.
            // This allows seamless account switching without a manual logout step.
            if ($request->is('login', 'register')) {
                Auth::guard('web')->logout();
                $request->session()->invalidate();
                $request->session()->regenerateToken();
                // Return null so the middleware falls through and shows the login form.
                return route('login');
            }

            // For any other guest-protected route, redirect to the correct role dashboard.
            if ($user->role === 'admin') {
                return route('admin.dashboard');
            }

            // workshop and owner use the general dashboard (shows role-specific content)
            return route('dashboard');
        });
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
