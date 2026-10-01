import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Ui {
    function buzz() as Void {
        try {
            if (Attention has :vibrate) {
                Attention.vibrate([
                    new Attention.VibeProfile(50, 180)
                ]);
            }
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
    }

    function prepare(dc as Graphics.Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
    }

    function centerText(dc as Graphics.Dc, y as Numeric, font as Graphics.FontType, color as Graphics.ColorType, message as String) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, font, message, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function clock(ms as Number) as String {
        var total = ms / 1000;
        if (total < 0) {
            total = 0;
        }
        var minutes = total / 60;
        var seconds = total % 60;
        return minutes.format("%02d") + ":" + seconds.format("%02d");
    }

    function ring(dc as Graphics.Dc, color as Graphics.ColorType, fraction as Float) as Void {
        var width = dc.getWidth();
        var cx = width / 2;
        var cy = dc.getHeight() / 2;
        var radius = width / 2 - 8;
        if (radius < 24) {
            return;
        }
        var pen = 8;
        if (width >= 360) {
            pen = 14;
        }
        dc.setPenWidth(pen);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, 90 - 359);
        var bounded = fraction;
        if (bounded < 0.0) {
            bounded = 0.0;
        }
        if (bounded > 1.0) {
            bounded = 1.0;
        }
        var sweep = (bounded * 359.0).toNumber();
        if (sweep >= 2) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, 90 - sweep);
        }
        dc.setPenWidth(1);
    }

    function pace(meters as Float, elapsedMs as Number, metric as Boolean) as String {
        var unit = metric ? "/km" : "/mi";
        if (meters < 30.0 || elapsedMs < 5000) {
            return "-- " + unit;
        }
        var unitMeters = metric ? 1000.0 : 1609.344;
        var paceSec = ((elapsedMs / 1000.0) * unitMeters / meters).toNumber();
        if (paceSec < 0 || paceSec > 30 * 60) {
            return "-- " + unit;
        }
        return (paceSec / 60).format("%d") + ":" + (paceSec % 60).format("%02d") + " " + unit;
    }

    function distance(meters as Float, metric as Boolean) as String {
        if (metric) {
            return (meters / 1000.0).format("%.2f") + " km";
        }
        return (meters / 1609.344).format("%.2f") + " mi";
    }
}
