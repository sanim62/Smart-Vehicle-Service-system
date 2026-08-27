<?php

use App\Providers\AppServiceProvider;

$providers = [
    AppServiceProvider::class,
];

if (extension_loaded('oci8')) {
    $providers[] = Yajra\Oci8\Oci8ServiceProvider::class;
    $providers[] = Yajra\Oci8\Oci8ValidationServiceProvider::class;
}

return $providers;

