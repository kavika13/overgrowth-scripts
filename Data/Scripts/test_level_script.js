var woozy = {};
 
 (function() {
   var incrementer = 1;
   var fov = 90;
   var maxDelta = 45;
   var triggered = false;
   var interval = 0;
 
   function getWoozy() {
     fov += incrementer;
     if (fov >= 90 + maxDelta || fov <= 90 - maxDelta) 
         incrementer *= -1;
     Camera.setFOV(fov);
   }
 
   woozy.stop = function() {
     clearInterval(interval);
   };
 
   woozy.start = function() {
     if (triggered) return;
     triggered = true;
     interval = setInterval(getWoozy,20);
   };
 
 })();