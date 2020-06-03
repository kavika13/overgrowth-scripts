var timer = {};

 (function() {
   var time = 0;
 
   function decrTimer() {
     time--;
     Text.setValue("timerText",String(time));
     if (time <= 0) {
       timer.stop();
     }
   }
 
   timer.start = function(limit) {
     time = limit;
     interval = setInterval(decrTimer,1000);
     Text.createText("timerText","TopCenter");
     Text.setValue("timerText",String(time));
   };

   timer.addTime = function(amount) {
     time += amount;
   };

   timer.stop = function() {
     clearInterval(interval);
     if (time > 0) Text.setValue("timerText","You win!");
     else Text.setValue("timerText","You lose.");
   };
 
 })();

