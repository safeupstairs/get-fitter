import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.WatchUi;

class HomeView extends WatchUi.View {
    var _note as String;

    function initialize() {
        View.initialize();
        _note = "";
    }

    function setNote(message as String) as Void {
        _note = message;
        WatchUi.requestUpdate();
    }

    function onShow() as Void {
        _note = "";
        WatchUi.requestUpdate();
    }

    function begin() as Void {
        if (PlanStore.isDoneToday()) {
            setNote("Already logged today");
            return;
        }
        var kind = PlanStore.todayKind();
        if (kind == PlanStore.KIND_REST) {
            var prompt = WatchUi.loadResource(Rez.Strings.LogRest) as String;
            WatchUi.pushView(new WatchUi.Confirmation(prompt), new LogRestDelegate(), WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        if (kind == PlanStore.KIND_CAL || (kind == PlanStore.KIND_COMBO && PlanStore.comboRunSaved())) {
            var circuit = new CircuitView();
            WatchUi.pushView(circuit, new CircuitDelegate(circuit), WatchUi.SLIDE_LEFT);
            return;
        }
        if (needsActivityList()) {
            setNote("Open the activity list to record");
            return;
        }
        var run = new RunView(kind == PlanStore.KIND_COMBO);
        WatchUi.pushView(run, new RunDelegate(run), WatchUi.SLIDE_LEFT);
    }

    function needsActivityList() as Boolean {
        if (!GetFitterApp.fromGlance) {
            return false;
        }
        var kind = PlanStore.todayKind();
        if (kind == PlanStore.KIND_RUN) {
            return true;
        }
        return kind == PlanStore.KIND_COMBO && !PlanStore.comboRunSaved();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        Ui.prepare(dc);
        var height = dc.getHeight();
        var narrow = dc.getWidth() < 300;
        var kind = PlanStore.todayKind();
        var titleFont = narrow ? Graphics.FONT_MEDIUM : Graphics.FONT_LARGE;

        Ui.centerText(dc, height * 16 / 100, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, PlanStore.appName());
        Ui.centerText(dc, height * 24 / 100, Graphics.FONT_XTINY, Graphics.COLOR_WHITE, PlanStore.dateLabel());
        Ui.centerText(dc, height * 32 / 100, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, dayLine());
        Ui.centerText(dc, height * 44 / 100, titleFont, PlanStore.accent(kind), PlanStore.title(kind));
        Ui.centerText(dc, height * 54 / 100, narrow ? Graphics.FONT_XTINY : Graphics.FONT_TINY, Graphics.COLOR_WHITE, PlanStore.detail(kind));
        Ui.centerText(dc, height * 64 / 100, narrow ? Graphics.FONT_XTINY : Graphics.FONT_TINY, statusColor(), statusLine());
        Ui.centerText(dc, height * 73 / 100, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, levelLine());
        var resting = restingLine();
        if (resting.length() > 0) {
            Ui.centerText(dc, height * 80 / 100, Graphics.FONT_XTINY, Graphics.COLOR_DK_GRAY, resting);
        }
        Ui.centerText(dc, height * 88 / 100, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, hintLine());
    }

    function dayLine() as String {
        var day = (PlanStore.todayIndex() % 4) + 1;
        return "Day " + day.toString() + " of 4";
    }

    function levelLine() as String {
        return "Level " + (PlanStore.cycles() + 1).toString() + " · " + PlanStore.sessions().toString() + " sessions";
    }

    function statusLine() as String {
        if (_note.length() > 0) {
            return _note;
        }
        if (PlanStore.isDoneToday()) {
            return "Logged today";
        }
        if (PlanStore.todayKind() == PlanStore.KIND_COMBO && PlanStore.comboRunSaved()) {
            return "Run saved · circuit next";
        }
        if (needsActivityList()) {
            return "Activity list to record";
        }
        if (PlanStore.todayKind() == PlanStore.KIND_REST) {
            return "Recovery day";
        }
        return "Ready";
    }

    function statusColor() as Graphics.ColorType {
        if (PlanStore.isDoneToday()) {
            return Graphics.COLOR_GREEN;
        }
        if (_note.length() > 0 || needsActivityList()) {
            return Graphics.COLOR_ORANGE;
        }
        return Graphics.COLOR_WHITE;
    }

    function hintLine() as String {
        if (PlanStore.isDoneToday() || needsActivityList()) {
            return "UP plan";
        }
        if (PlanStore.todayKind() == PlanStore.KIND_REST) {
            return "START log · UP plan";
        }
        if (PlanStore.todayKind() == PlanStore.KIND_COMBO && PlanStore.comboRunSaved()) {
            return "START circuit · UP plan";
        }
        return "START begin · UP plan";
    }

    function restingLine() as String {
        var resting = UserProfile.getProfile().restingHeartRate;
        if (resting == null) {
            return "";
        }
        return "Resting HR " + resting.format("%d");
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {
    var _home as HomeView;

    function initialize(home as HomeView) {
        BehaviorDelegate.initialize();
        _home = home;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER) {
            _home.begin();
            return true;
        } else if (key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
            PlanMenu.open();
            return true;
        }
        return false;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        _home.begin();
        return true;
    }

    function onMenu() as Boolean {
        PlanMenu.open();
        return true;
    }
}

class LogRestDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            PlanStore.markTodayDone();
        }
        return true;
    }
}
