import Toybox.Graphics;
import Toybox.WatchUi;

(:glance)
class GetFitterGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

        var kind = PlanStore.todayKind();
        var title = PlanStore.glanceTitle();
        var titleFont = Graphics.FONT_TINY;
        if (title.length() > 12) {
            titleFont = Graphics.FONT_XTINY;
        }

        if (height < 78) {
            dc.setColor(PlanStore.accent(kind), Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, height / 2, titleFont, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 28 / 100, Graphics.FONT_XTINY, PlanStore.appName(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(PlanStore.accent(kind), Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 52 / 100, titleFont, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 76 / 100, Graphics.FONT_XTINY, PlanStore.glanceDetail(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
