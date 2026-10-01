import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Calendar plan stored on the watch. Cycle is run, calisthenics, combo, rest.
(:glance)
module PlanStore {
    const KIND_RUN = 0;
    const KIND_CAL = 1;
    const KIND_COMBO = 2;
    const KIND_REST = 3;

    function ensure() as Void {
        if (Storage.getValue("anchor") != null) {
            return;
        }
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        Storage.setValue("anchor", ymdToDay(info.year as Number, info.month as Number, info.day as Number));
        Storage.setValue("doneThrough", -1);
        Storage.setValue("runMin", 15);
        Storage.setValue("rounds", 2);
        Storage.setValue("cycles", 0);
        Storage.setValue("sessions", 0);
        Storage.setValue("comboRun", -1);
    }

    function reset() as Void {
        Storage.deleteValue("anchor");
        Storage.deleteValue("doneThrough");
        Storage.deleteValue("runMin");
        Storage.deleteValue("rounds");
        Storage.deleteValue("cycles");
        Storage.deleteValue("sessions");
        Storage.deleteValue("comboRun");
        ensure();
    }

    function todayIndex() as Number {
        ensure();
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var today = ymdToDay(info.year as Number, info.month as Number, info.day as Number);
        var anchor = num("anchor", today);
        var delta = today - anchor;
        if (delta < 0) {
            Storage.setValue("anchor", today);
            Storage.setValue("doneThrough", -1);
            Storage.setValue("comboRun", -1);
            return 0;
        }
        return delta;
    }

    function kindForIndex(index as Number) as Number {
        var cycle = index % 4;
        if (cycle < 0) {
            cycle = 0;
        }
        return cycle;
    }

    function todayKind() as Number {
        return kindForIndex(todayIndex());
    }

    function isDoneToday() as Boolean {
        return num("doneThrough", -1) >= todayIndex();
    }

    function comboRunSaved() as Boolean {
        return num("comboRun", -1) == todayIndex();
    }

    function markComboRunSaved() as Void {
        Storage.setValue("comboRun", todayIndex());
    }

    function markTodayDone() as Void {
        var index = todayIndex();
        if (num("doneThrough", -1) >= index) {
            return;
        }
        Storage.setValue("doneThrough", index);
        var logged = num("sessions", 0) + 1;
        Storage.setValue("sessions", logged);
        Storage.setValue("comboRun", -1);
        if (logged % 4 == 0) {
            var minutes = num("runMin", 15) + 2;
            if (minutes > 40) {
                minutes = 40;
            }
            Storage.setValue("runMin", minutes);
            var level = num("cycles", 0) + 1;
            Storage.setValue("cycles", level);
            if (level % 2 == 0) {
                var nextRounds = num("rounds", 2) + 1;
                if (nextRounds > 4) {
                    nextRounds = 4;
                }
                Storage.setValue("rounds", nextRounds);
            }
        }
    }

    function runMinutes() as Number {
        var value = num("runMin", 15);
        if (value < 10) {
            return 10;
        }
        if (value > 40) {
            return 40;
        }
        return value;
    }

    function roundCount() as Number {
        var value = num("rounds", 2);
        if (value < 1) {
            return 1;
        }
        if (value > 4) {
            return 4;
        }
        return value;
    }

    function cycles() as Number {
        var value = num("cycles", 0);
        if (value < 0) {
            return 0;
        }
        return value;
    }

    function sessions() as Number {
        var value = num("sessions", 0);
        if (value < 0) {
            return 0;
        }
        return value;
    }

    function restSeconds() as Number {
        var rest = 20 - (cycles() / 2) * 2;
        if (rest < 12) {
            rest = 12;
        }
        return rest;
    }

    function moves() as Array<Dictionary> {
        return [
            {:name => "Squat", :cue => "Sit back, drive up", :work => 40},
            {:name => "Push-up", :cue => "Straight body line", :work => 30},
            {:name => "Reverse lunge", :cue => "Alternate legs", :work => 40},
            {:name => "Plank", :cue => "Brace your core", :work => 30},
            {:name => "Glute bridge", :cue => "Squeeze at the top", :work => 40},
            {:name => "Climbers", :cue => "Keep hips low", :work => 30}
        ] as Array<Dictionary>;
    }

    function title(kind as Number) as String {
        if (kind == KIND_CAL) {
            return "Calisthenics";
        } else if (kind == KIND_COMBO) {
            return "Combo";
        } else if (kind == KIND_REST) {
            return "Rest";
        }
        return "Run";
    }

    function detail(kind as Number) as String {
        var minutes = runMinutes().toString();
        var rounds = roundCount().toString();
        var moveCount = moves().size().toString();
        if (kind == KIND_RUN) {
            return "Easy run · " + minutes + " min";
        } else if (kind == KIND_CAL) {
            return moveCount + " moves · " + rounds + " rounds";
        } else if (kind == KIND_COMBO) {
            return minutes + " min run, then circuit";
        }
        return "Walk easy and stretch";
    }

    function glanceTitle() as String {
        ensure();
        if (isDoneToday()) {
            return "Done today";
        }
        var kind = todayKind();
        if (kind == KIND_RUN) {
            return "Run " + runMinutes().toString() + " min";
        } else if (kind == KIND_CAL) {
            return "Calisthenics";
        } else if (kind == KIND_COMBO) {
            if (comboRunSaved()) {
                return "Circuit next";
            }
            return "Combo day";
        }
        return "Rest day";
    }

    function glanceDetail() as String {
        if (isDoneToday()) {
            return title(todayKind());
        }
        var kind = todayKind();
        if (kind == KIND_RUN) {
            return "Easy aerobic";
        } else if (kind == KIND_CAL) {
            return roundCount().toString() + " rounds";
        } else if (kind == KIND_COMBO) {
            if (comboRunSaved()) {
                return roundCount().toString() + " rounds";
            }
            return "Run then circuit";
        }
        return "Recover";
    }

    function accent(kind as Number) as Graphics.ColorType {
        if (kind == KIND_RUN) {
            return Graphics.COLOR_BLUE;
        } else if (kind == KIND_CAL) {
            return Graphics.COLOR_GREEN;
        } else if (kind == KIND_COMBO) {
            return Graphics.COLOR_ORANGE;
        }
        return Graphics.COLOR_LT_GRAY;
    }

    function appName() as String {
        return WatchUi.loadResource(Rez.Strings.AppName) as String;
    }

    function dateLabel() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var month = info.month as Number;
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var label = "";
        if (month >= 1 && month <= 12) {
            label = (months[month - 1] as String) + " " + (info.day as Number).toString();
        }
        var weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var dow = info.day_of_week as Number;
        if (dow >= 1 && dow <= 7) {
            label = (weekdays[dow - 1] as String) + " " + label;
        }
        return label;
    }

    function num(key as String, fallback as Number) as Number {
        var value = Storage.getValue(key);
        if (value instanceof Number) {
            return value as Number;
        }
        return fallback;
    }

    // Howard Hinnant civil-from-days, days since 1970-01-01.
    function ymdToDay(y as Number, m as Number, d as Number) as Number {
        var yy = y;
        var mp = m + 9;
        if (m <= 2) {
            yy = y - 1;
        }
        if (m > 2) {
            mp = m - 3;
        }
        var era = yy / 400;
        if (yy < 0) {
            era = (yy - 399) / 400;
        }
        var yoe = yy - era * 400;
        var doy = (153 * mp + 2) / 5 + d - 1;
        var doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
        return era * 146097 + doe - 719468;
    }
}
