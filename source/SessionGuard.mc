import Toybox.Lang;

// Lets the app discard an open FIT session on exit without pulling
// ActivityRecording into the glance build.
(:glance)
module SessionGuard {
    var close as Method or Null = null;

    function closeOpenSession() as Void {
        var fn = close;
        if (fn != null) {
            fn.invoke();
        }
    }
}
