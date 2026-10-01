import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;
import Toybox.UserProfile;
import Toybox.WatchUi;

class RunView extends WatchUi.View {
    var _thenCircuit as Boolean;
    var _session as ActivityRecording.Session or Null;
    var _timer as Timer.Timer or Null;
    var _started as Boolean;
    var _paused as Boolean;
    var _finished as Boolean;
    var _afterDialog as Number;
    var _targetMs as Number;
    var _elapsedMs as Number;
    var _activityHr as Number or Null;
    var _sensorHr as Number or Null;
    var _distance as Float;
    var _metric as Boolean;
    var _accuracy as Position.Quality;
    var _zones as Array<Number> or Null;
    var _buzzed as Boolean;
    var _error as String;
    var _title as String;

    function initialize(thenCircuit as Boolean) {
        View.initialize();
        _thenCircuit = thenCircuit;
        _session = null;
        _timer = new Timer.Timer();
        _started = false;
        _paused = false;
        _finished = false;
        _afterDialog = 0;
        _targetMs = PlanStore.runMinutes() * 60000;
        _elapsedMs = 0;
        _activityHr = null;
        _sensorHr = null;
        _distance = 0.0;
        _metric = true;
        _accuracy = Position.QUALITY_NOT_AVAILABLE;
        _zones = null;
        _buzzed = false;
        _error = "";
        _title = thenCircuit ? "COMBO RUN" : "RUN";
    }

    function onShow() as Void {
        if (_afterDialog == 1) {
            _afterDialog = 0;
            if (commitSave()) {
                return;
            }
        } else if (_afterDialog == 2) {
            _afterDialog = 0;
            commitDiscard();
            return;
        } else if (!_started) {
            _started = true;
            startRecording();
        }
        if (_timer != null && !_finished) {
            _timer.start(method(:onTick), 500, true);
        }
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
        }
    }

    function startRecording() as Void {
        var settings = System.getDeviceSettings();
        _metric = settings.distanceUnits == System.UNIT_METRIC;
        _zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_RUNNING);
        enableSensors();
        try {
            var created = ActivityRecording.createSession({
                :name => "Get Fitter",
                :sport => Activity.SPORT_RUNNING,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            _session = created;
            SessionGuard.close = method(:closeIfNeeded);
            if (!created.start()) {
                _error = "Recording did not start";
                _paused = true;
            }
        } catch (ex) {
            _error = "Recording unavailable";
            System.println(ex.getErrorMessage());
        }
    }

    function enableSensors() as Void {
        try {
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            Sensor.enableSensorEvents(method(:onSensor));
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
        try {
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        } catch (ex2) {
            System.println(ex2.getErrorMessage());
        }
    }

    function shutdownSensors() as Void {
        try {
            Sensor.enableSensorEvents(null);
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
        try {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        } catch (ex2) {
            System.println(ex2.getErrorMessage());
        }
    }

    function onSensor(info as Sensor.Info) as Void {
        if (info.heartRate != null) {
            _sensorHr = info.heartRate;
        }
    }

    function onPosition(info as Position.Info) as Void {
        _accuracy = info.accuracy;
        WatchUi.requestUpdate();
    }

    function onTick() as Void {
        snapshot();
        if (!_buzzed && _elapsedMs >= _targetMs) {
            _buzzed = true;
            Ui.buzz();
        }
        WatchUi.requestUpdate();
    }

    function snapshot() as Void {
        var info = Activity.getActivityInfo();
        if (info.timerTime != null) {
            _elapsedMs = info.timerTime;
        }
        if (info.currentHeartRate != null) {
            _activityHr = info.currentHeartRate;
        }
        if (info.elapsedDistance != null) {
            _distance = info.elapsedDistance;
        }
    }

    function togglePause() as Void {
        var session = _session;
        if (session == null) {
            WatchUi.requestUpdate();
            return;
        }
        if (session.isRecording()) {
            session.stop();
            _paused = true;
        } else {
            _paused = !session.start();
            if (_paused) {
                _error = "Could not resume";
            } else {
                _error = "";
            }
        }
        WatchUi.requestUpdate();
    }

    function openEndMenu() as Void {
        var session = _session;
        if (session != null && session.isRecording()) {
            session.stop();
            _paused = true;
        }
        var menu = new WatchUi.Menu2({:title => "End run"});
        var saveId = _thenCircuit ? Rez.Strings.SaveCombo : Rez.Strings.SaveRun;
        var saveLabel = WatchUi.loadResource(saveId) as String;
        var discardLabel = WatchUi.loadResource(Rez.Strings.DiscardRun) as String;
        menu.addItem(new WatchUi.MenuItem(saveLabel, null, :save, null));
        menu.addItem(new WatchUi.MenuItem(discardLabel, null, :discard, null));
        WatchUi.pushView(menu, new RunEndDelegate(self), WatchUi.SLIDE_UP);
    }

    function requestExit(which as Number) as Void {
        _afterDialog = which;
    }

    function commitSave() as Boolean {
        var session = _session;
        if (session == null) {
            _error = "Nothing to save";
            return false;
        }
        if (session.isRecording()) {
            session.stop();
        }
        var saved = session.save();
        if (!saved) {
            _error = "Could not save FIT";
            return false;
        }
        _session = null;
        SessionGuard.close = null;
        shutdownSensors();
        _finished = true;
        if (_thenCircuit) {
            PlanStore.markComboRunSaved();
            var circuit = new CircuitView();
            WatchUi.switchToView(circuit, new CircuitDelegate(circuit), WatchUi.SLIDE_LEFT);
        } else {
            PlanStore.markTodayDone();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function commitDiscard() as Void {
        closeIfNeeded();
        _finished = true;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function closeIfNeeded() as Void {
        var session = _session;
        _session = null;
        SessionGuard.close = null;
        shutdownSensors();
        if (session == null) {
            return;
        }
        if (session.isRecording()) {
            session.stop();
        }
        session.discard();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        Ui.prepare(dc);
        var height = dc.getHeight();
        var narrow = dc.getWidth() < 300;
        var fraction = 0.0;
        if (_targetMs > 0) {
            fraction = _elapsedMs.toFloat() / _targetMs.toFloat();
        }
        Ui.ring(dc, Graphics.COLOR_BLUE, fraction);

        Ui.centerText(dc, height * 28 / 100, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, _title);
        Ui.centerText(dc, height * 42 / 100, narrow ? Graphics.FONT_NUMBER_MILD : Graphics.FONT_NUMBER_MEDIUM, Graphics.COLOR_WHITE, Ui.clock(_elapsedMs));

        var targetLine = "of " + Ui.clock(_targetMs);
        if (_elapsedMs >= _targetMs) {
            targetLine = "Target met";
        }
        if (_paused) {
            targetLine = "Paused";
        }
        Ui.centerText(dc, height * 52 / 100, Graphics.FONT_TINY, _paused ? Graphics.COLOR_ORANGE : Graphics.COLOR_LT_GRAY, targetLine);
        Ui.centerText(dc, height * 62 / 100, narrow ? Graphics.FONT_TINY : Graphics.FONT_SMALL, Graphics.COLOR_WHITE, hrLine());
        Ui.centerText(dc, height * 71 / 100, Graphics.FONT_TINY, Graphics.COLOR_WHITE, Ui.distance(_distance, _metric) + "  " + Ui.pace(_distance, _elapsedMs, _metric));
        Ui.centerText(dc, height * 79 / 100, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, gpsLine());
        var footer = "START pause · BACK end";
        var footerColor = Graphics.COLOR_DK_GRAY;
        if (_error.length() > 0) {
            footer = _error;
            footerColor = Graphics.COLOR_ORANGE;
        }
        Ui.centerText(dc, height * 88 / 100, Graphics.FONT_XTINY, footerColor, footer);
    }

    function hrLine() as String {
        var hr = _activityHr;
        if (hr == null) {
            hr = _sensorHr;
        }
        if (hr == null) {
            return "HR --";
        }
        var zone = zoneName(hr);
        if (zone.length() == 0) {
            return "HR " + hr.format("%d");
        }
        return "HR " + hr.format("%d") + "  " + zone;
    }

    function zoneName(hr as Number) as String {
        var zones = _zones;
        if (zones == null) {
            return "HR";
        }
        var zone = 0;
        for (var i = 0; i < zones.size(); i++) {
            if (hr >= zones[i]) {
                zone = i + 1;
            }
        }
        if (zone > 5) {
            zone = 5;
        }
        if (zone == 0) {
            return "";
        }
        return "Z" + zone.toString();
    }

    function gpsLine() as String {
        if (_accuracy == Position.QUALITY_GOOD) {
            return "GPS good";
        } else if (_accuracy == Position.QUALITY_USABLE) {
            return "GPS ok";
        } else if (_accuracy == Position.QUALITY_POOR) {
            return "GPS weak";
        } else if (_accuracy == Position.QUALITY_LAST_KNOWN) {
            return "GPS last";
        }
        return "GPS ...";
    }
}

class RunDelegate extends WatchUi.BehaviorDelegate {
    var _run as RunView;

    function initialize(run as RunView) {
        BehaviorDelegate.initialize();
        _run = run;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        if (evt.getKey() == WatchUi.KEY_ENTER) {
            _run.togglePause();
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        _run.openEndMenu();
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        _run.togglePause();
        return true;
    }
}

class RunEndDelegate extends WatchUi.Menu2InputDelegate {
    var _run as RunView;

    function initialize(run as RunView) {
        Menu2InputDelegate.initialize();
        _run = run;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :save) {
            _run.requestExit(1);
        } else if (id == :discard) {
            _run.requestExit(2);
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
