import Toybox.Lang;
import Toybox.WatchUi;

module PlanMenu {
    function open() as Void {
        var menu = new WatchUi.Menu2({:title => "This cycle"});
        var pos = PlanStore.todayIndex() % 4;
        var labels = ["Run", "Calisthenics", "Combo", "Rest"];
        for (var i = 0; i < 4; i++) {
            var detail = PlanStore.detail(i);
            if (i == pos) {
                if (PlanStore.isDoneToday()) {
                    detail = "Today · done";
                } else {
                    detail = "Today · " + detail;
                }
            }
            menu.addItem(new WatchUi.MenuItem(labels[i], detail, i, null));
        }
        menu.addItem(new WatchUi.MenuItem("Sessions", PlanStore.sessions().toString() + " logged", :sessions, null));
        menu.addItem(new WatchUi.MenuItem("Reset plan", "Back to day 1", :reset, null));
        WatchUi.pushView(menu, new PlanMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

class PlanMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :reset) {
            var prompt = WatchUi.loadResource(Rez.Strings.ResetPlan) as String;
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new WatchUi.Confirmation(prompt), new ResetPlanDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class ResetPlanDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            PlanStore.reset();
        }
        return true;
    }
}
