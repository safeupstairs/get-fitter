import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GetFitterApp extends Application.AppBase {
    static var fromGlance as Boolean = false;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary or Null) as Void {
        fromGlance = false;
        if (state != null && state.hasKey(:launchedFromGlance) && state[:launchedFromGlance] == true) {
            fromGlance = true;
        }
        PlanStore.ensure();
    }

    function onStop(state as Dictionary or Null) as Void {
        SessionGuard.closeOpenSession();
    }

    function getInitialView() as [ WatchUi.Views ] or [ WatchUi.Views, WatchUi.InputDelegates ] {
        var home = new HomeView();
        return [home, new HomeDelegate(home)];
    }

    function getGlanceView() as [ WatchUi.GlanceView ] or [ WatchUi.GlanceView, WatchUi.GlanceViewDelegate ] or Null {
        return [new GetFitterGlanceView()];
    }

    function getGlanceTheme() as AppBase.GlanceTheme {
        var kind = PlanStore.todayKind();
        if (kind == PlanStore.KIND_RUN) {
            return AppBase.GLANCE_THEME_BLUE;
        } else if (kind == PlanStore.KIND_CAL) {
            return AppBase.GLANCE_THEME_GREEN;
        } else if (kind == PlanStore.KIND_COMBO) {
            return AppBase.GLANCE_THEME_GOLD;
        }
        return AppBase.GLANCE_THEME_PURPLE;
    }
}
