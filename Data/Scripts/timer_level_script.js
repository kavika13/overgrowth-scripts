var timer = {};

 (function() {
   var time = 0;
   var time2 = 0;
   var time3 = 0;
   var interval;
   var interval2;
   var interval3;
   /*Graphics.setPostEffects(false);*/
 
   function decrTimer() {
     Text.setValue("timerText",String(time));
     time--;
     if (time < 0) {
       time = 0;
       timer.stop();
     }
   }
   
   function decrTimer2() {
     time2--;
     Camera.setFOV(time2+90);
     if (time2 <= 0) {
       time2 = 0;
       Camera.setFOV(90);
       Text.setValue("raceText","...");
       clearInterval(interval2);
     }
   }

   function decrTimer3() {
     time3--;
     if (time3 <= 0) {
       time3 = 0;
       Text.setValue("raceText","...");
       clearInterval(interval3);
     }
   }
 
   timer.start = function(limit) {
     time = limit/2;
     interval = setInterval(decrTimer,1000);
     Text.createText("timerText","TopCenter");
     Text.createText("raceText","BottomCenter");
     Text.setValue("timerText",String(time));
     Text.setValue("raceText","Race started!");
     time3 = 3;
     interval3 = setInterval(decrTimer3,1000);
     /*Graphics.setPostEffects(true);*/
   };

   timer.addTime = function(amount) {
     time += amount/2;
     Text.setValue("raceText","Checkpoint!");
     time2 = 20;
     interval2 = setInterval(decrTimer2,50);
   };

   timer.stop = function() {
     Graphics.setPostEffects(false);
     clearInterval(interval);
     if (time > 0) Text.setValue("raceText","You win!");
     else Text.setValue("raceText","You lose.");
   };
 
 })();

