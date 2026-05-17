<?php
chdir('c:\xampp\htdocs\EventHub\EventHub');
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$event = App\Models\Event::where('event_type', 'تقنية')->first();
if(!$event){
    $event = App\Models\Event::first();
    $event->event_type = 'تقنية';
    $event->save();
}
echo "Triggering notification for event: " . $event->title . "\n";
$controller = app()->make('App\Http\Controllers\EventController');
$method = new ReflectionMethod(get_class($controller), 'notifyInterestedUsers');
$method->setAccessible(true);
$method->invokeArgs($controller, [$event]);
echo "Done.\n";
