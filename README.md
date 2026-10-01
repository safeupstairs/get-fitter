# Get Fitter

On-watch training app for Garmin **Forerunner 165** and **fēnix 7**. The plan, timers, and progression stay on the watch. There is no account, backend, subscription, or network API.

## Daily plan

The plan starts the day you first open the app and repeats every four local midnights:

| Day | Session |
| --- | --- |
| 1 | Easy run |
| 2 | Calisthenics circuit |
| 3 | Combo: easy run, then the same circuit |
| 4 | Rest (log it when you have recovered) |

Every four logged days, the easy run grows by 2 minutes (cap 40). Every eight logged days, the circuit gains a round (cap 4). Rest between moves starts at 20 seconds and shortens slightly as the level rises, down to 12 seconds.

Progress is stored with `Application.Storage` (`anchor`, `doneThrough`, `runMin`, `rounds`, `cycles`, `sessions`, `comboRun`).

## What you can do

- **Glance** shows today's title (for example `Run 15 min`, `Calisthenics`, `Combo day`, `Rest day`, or `Done today`).
- **Circuit** shows one move at a time, with a work timer and a rest timer. START pauses. DOWN or UP skips. BACK can end the circuit without logging the day.
- **Run** starts an `ActivityRecording` session (`SPORT_RUNNING`). The screen shows the timer, live heart rate and zone, distance, average pace, and GPS quality. START pauses. BACK opens Save / Discard.
- **Combo** saves the run first, then opens the circuit. The day is logged when the circuit finishes. If you leave after the run is saved, the home screen offers **circuit next** for the rest of that day.
- Rest days are logged from the home screen and count toward progression.

Runs are saved as FIT files on the watch (the Fit permission). After the watch syncs, they show up in the Garmin account already on the device, the same way a native activity does. The circuit itself is guided on the watch and is not a second FIT file.

Launch a run from the **activity / app list**. A watch app opened from the glance list is not allowed to record an activity; the home screen says so instead of starting a doomed session. Calisthenics and rest still work from a glance launch.

## Controls

| Screen | Input |
| --- | --- |
| Home | START or tap begins today. UP or DOWN opens the cycle menu. |
| Cycle menu | Reset plan returns storage to day 1, level 1. |
| Run | START pause/resume. BACK: save or discard. |
| Circuit | START pause/resume. DOWN or UP skips. Swipe skips on touch devices. BACK ends without logging. |

## Permissions

| Permission | Why |
| --- | --- |
| Fit | `ActivityRecording` writes the run FIT file. |
| Positioning | GPS track and the GPS quality line during the run. |
| Sensor | Live heart rate on the run and during the circuit. |
| UserProfile | Resting heart rate on the home screen, and run heart-rate zones. |

## Project layout

```
manifest.xml          watch-app, fr165 + fenix7, API 4.0.0
monkey.jungle
source/               Monkey C
resources/strings/    app name and prompts
resources/drawables/  launcher icon
```

## Open in VS Code on a Mac

1. Install [Visual Studio Code](https://code.visualstudio.com/).
2. Install Garmin's **Monkey C** extension (`garmin.monkey-c`). This repo recommends it in `.vscode/extensions.json`.
3. Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) for macOS and sign in with a free Garmin developer account.
4. In SDK Manager, install the current Connect IQ SDK. Download the device definitions for **Forerunner 165** (`fr165`) and **fēnix 7** (`fenix7`).
5. In VS Code, choose **File → Open Folder** and select this repository (the folder that contains `monkey.jungle` and `manifest.xml`).
6. Command Palette (`Cmd+Shift+P`) → **Monkey C: Verify Installation**.
7. If the SDK is not picked up, set `monkeyC.sdkPath` to the folder SDK Manager installed. That is usually:

   `~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-<version>`

8. The first build asks for a developer key. Let the extension generate one, or set `monkeyC.developerKeyPath`. The key is a signing secret and stays on your Mac (typically `~/Library/Application Support/Garmin/ConnectIQ/developer_key`). Do not commit it.
9. Command Palette → **Monkey C: Run App**. Choose `fr165` or `fenix7`. The simulator starts with Get Fitter.
10. Command Palette → **Monkey C: Export Project** builds a `.iq` for the two products in the manifest.

Equivalent terminal build, after the SDK `bin` directory is on your `PATH`:

```bash
monkeyc \
  -f monkey.jungle \
  -o bin/get-fitter.prg \
  -y "$HOME/Library/Application Support/Garmin/ConnectIQ/developer_key" \
  -d fr165
monkeydo bin/get-fitter.prg fr165
```

Use `-d fenix7` for the fēnix 7. Add `-e` and an `.iq` output path to export a package instead of a single device program.

## Try it in the simulator

- Home shows the day in the cycle, the prescription, level, session count, and resting HR from the sim profile.
- START on a run day records until you save or discard. Saving a run-only day returns home with **Logged today**.
- On a combo day, save the run and the circuit opens. Finish the circuit (or skip moves) to log the day.
- UP lists the four-day cycle. **Reset plan** clears storage.
- The workout changes at local midnight. In the simulator, change the date/time to walk the cycle. Glance (the widget loop) shows the same day's title.

On a real watch, start Get Fitter from the activity list when you want a GPS run. Copy a built `.prg` into `GARMIN/APPS` over USB to sideload, or install an exported `.iq` the way you install other Connect IQ packages.
