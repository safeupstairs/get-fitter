import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class CircuitView extends WatchUi.View {
    var _timer as Timer.Timer or Null;
    var _moves as Array<Dictionary>;
    var _rounds as Number;
    var _round as Number;
    var _move as Number;
    var _phase as Symbol;
    var _phaseMs as Number;
    var _origin as Number;
    var _pausedAccum as Number;
    var _paused as Boolean;
    var _pausedForCover as Boolean;
    var _armed as Boolean;
    var _done as Boolean;
    var _finished as Boolean;
    var _afterDialog as Number;
    var _restLabel as String;
    var _hr as Number or Null;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
        _moves = PlanStore.moves();
        _rounds = PlanStore.roundCount();
        _round = 0;
        _move = 0;
        _phase = :work;
        _phaseMs = 30000;
        _origin = 0;
        _pausedAccum = 0;
        _paused = false;
        _pausedForCover = false;
        _armed = false;
        _done = false;
        _finished = false;
        _afterDialog = 0;
        _restLabel = "Rest";
        _hr = null;
    }

    function onShow() as Void {
        if (_afterDialog == 1) {
            _afterDialog = 0;
            _finished = true;
            disableHr();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }
        if (!_armed) {
            _armed = true;
            arm();
        } else if (_pausedForCover && !_done) {
            _pausedForCover = false;
            _origin = System.getTimer();
            _paused = false;
        }
        enableHr();
        if (!_done && _timer != null) {
            _timer.start(method(:onTick), 200, true);
        }
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
        }
        disableHr();
        if (_done || _finished || _paused) {
            return;
        }
        _pausedAccum = _pausedAccum + (System.getTimer() - _origin);
        _paused = true;
        _pausedForCover = true;
    }

    function arm() as Void {
        _round = 0;
        _move = 0;
        _phase = :work;
        _phaseMs = workMs(0);
        _origin = System.getTimer();
        _pausedAccum = 0;
        _paused = false;
        Ui.buzz();
    }

    function workMs(index as Number) as Number {
        var move = _moves[index] as Dictionary;
        return (move.get(:work) as Number) * 1000;
    }

    function enableHr() as Void {
        try {
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            Sensor.enableSensorEvents(method(:onSensor));
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
    }

    function disableHr() as Void {
        try {
            Sensor.enableSensorEvents(null);
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
    }

    function onSensor(info as Sensor.Info) as Void {
        if (info.heartRate != null) {
            _hr = info.heartRate;
        }
    }

    function onTick() as Void {
        if (!_done && !_paused && elapsed() >= _phaseMs) {
            advance();
        }
        WatchUi.requestUpdate();
    }

    function elapsed() as Number {
        if (_paused) {
            return _pausedAccum;
        }
        return _pausedAccum + (System.getTimer() - _origin);
    }

    function togglePause() as Void {
        if (_done) {
            _finished = true;
            disableHr();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }
        if (_paused) {
            _origin = System.getTimer();
            _paused = false;
            _pausedForCover = false;
        } else {
            _pausedAccum = elapsed();
            _paused = true;
        }
        WatchUi.requestUpdate();
    }

    function skip() as Void {
        if (_done) {
            return;
        }
        advance();
    }

    function advance() as Void {
        var lastMove = _move >= _moves.size() - 1;
        var lastRound = _round >= _rounds - 1;
        if (_phase == :work) {
            if (lastMove && lastRound) {
                complete();
                return;
            }
            _phase = :rest;
            if (lastMove) {
                _restLabel = "Next round";
                _phaseMs = (PlanStore.restSeconds() + 15) * 1000;
            } else {
                _restLabel = "Rest";
                _phaseMs = PlanStore.restSeconds() * 1000;
            }
        } else if (lastMove) {
            _round = _round + 1;
            _move = 0;
            _phase = :work;
            _phaseMs = workMs(0);
        } else {
            _move = _move + 1;
            _phase = :work;
            _phaseMs = workMs(_move);
        }
        _origin = System.getTimer();
        _pausedAccum = 0;
        _paused = false;
        Ui.buzz();
        WatchUi.requestUpdate();
    }

    function complete() as Void {
        if (_done) {
            return;
        }
        _done = true;
        PlanStore.markTodayDone();
        if (_timer != null) {
            _timer.stop();
        }
        Ui.buzz();
        WatchUi.requestUpdate();
    }

    function requestAbandon() as Void {
        _afterDialog = 1;
    }

    function confirmEnd() as Void {
        if (_done) {
            togglePause();
            return;
        }
        var prompt = WatchUi.loadResource(Rez.Strings.EndCircuit) as String;
        WatchUi.pushView(new WatchUi.Confirmation(prompt), new EndCircuitDelegate(self), WatchUi.SLIDE_IMMEDIATE);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        Ui.prepare(dc);
        var height = dc.getHeight();
        var narrow = dc.getWidth() < 300;
        if (_done) {
            Ui.ring(dc, Graphics.COLOR_GREEN, 1.0);
            Ui.centerText(dc, height * 40 / 100, narrow ? Graphics.FONT_MEDIUM : Graphics.FONT_LARGE, Graphics.COLOR_GREEN, "Done");
            Ui.centerText(dc, height * 52 / 100, Graphics.FONT_TINY, Graphics.COLOR_WHITE, "Today is logged");
            Ui.centerText(dc, height * 84 / 100, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, "START close");
            return;
        }

        var remain = _phaseMs - elapsed();
        if (remain < 0) {
            remain = 0;
        }
        var fraction = 0.0;
        if (_phaseMs > 0) {
            fraction = remain.toFloat() / _phaseMs.toFloat();
        }
        var working = _phase == :work;
        Ui.ring(dc, working ? Graphics.COLOR_GREEN : Graphics.COLOR_BLUE, fraction);

        var move = _moves[_move] as Dictionary;
        var headline = _restLabel;
        var cue = "Shake out, then next";
        if (working) {
            headline = move.get(:name) as String;
            cue = move.get(:cue) as String;
        }
        Ui.centerText(dc, height * 30 / 100, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, progressLabel());
        Ui.centerText(dc, height * 40 / 100, narrow ? Graphics.FONT_SMALL : Graphics.FONT_MEDIUM, working ? Graphics.COLOR_GREEN : Graphics.COLOR_BLUE, headline);
        Ui.centerText(dc, height * 52 / 100, narrow ? Graphics.FONT_NUMBER_MILD : Graphics.FONT_NUMBER_MEDIUM, Graphics.COLOR_WHITE, Ui.clock(remain));
        Ui.centerText(dc, height * 63 / 100, Graphics.FONT_XTINY, Graphics.COLOR_WHITE, cue);
        Ui.centerText(dc, height * 72 / 100, Graphics.FONT_XTINY, _paused ? Graphics.COLOR_ORANGE : Graphics.COLOR_LT_GRAY, _paused ? "Paused" : hrText());
        Ui.centerText(dc, height * 86 / 100, Graphics.FONT_XTINY, Graphics.COLOR_DK_GRAY, "START pause · DOWN skip");
    }

    function progressLabel() as String {
        return "Round " + (_round + 1).toString() + "/" + _rounds.toString() + "  ·  " + (_move + 1).toString() + "/" + _moves.size().toString();
    }

    function hrText() as String {
        if (_hr == null) {
            return "HR --";
        }
        return "HR " + (_hr as Number).format("%d");
    }
}

class CircuitDelegate extends WatchUi.BehaviorDelegate {
    var _circuit as CircuitView;

    function initialize(circuit as CircuitView) {
        BehaviorDelegate.initialize();
        _circuit = circuit;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER) {
            _circuit.togglePause();
            return true;
        } else if (key == WatchUi.KEY_DOWN || key == WatchUi.KEY_UP) {
            _circuit.skip();
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        _circuit.confirmEnd();
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        _circuit.togglePause();
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        _circuit.skip();
        return true;
    }
}

class EndCircuitDelegate extends WatchUi.ConfirmationDelegate {
    var _circuit as CircuitView;

    function initialize(circuit as CircuitView) {
        ConfirmationDelegate.initialize();
        _circuit = circuit;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _circuit.requestAbandon();
        }
        return true;
    }
}
