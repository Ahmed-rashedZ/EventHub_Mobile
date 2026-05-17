<?php
chdir('c:\xampp\htdocs\EventHub\EventHub');
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$user = App\Models\User::find(24);
$req = Illuminate\Http\Request::create('/api/profile', 'PUT', ['name'=>$user->name, 'email'=>$user->email, 'interests'=>['تقنية']]);
$req->setUserResolver(function() use ($user) { return $user; });
$res = app()->make('App\Http\Controllers\AuthController')->updateProfile($req);
echo $res->getStatusCode() . "\n";
echo $res->getContent();
