# Mikelito

A tiny native macOS menu bar app that gently moves your mouse pointer while you are away from the keyboard.

## Features

- Lives in the menu bar as a minimal **M**. No Dock icon, no main window.
- Starts working as soon as it launches. There is no on/off switch: quit the app to stop it.
- Every interval, if you have not touched the mouse, it nudges the pointer one pixel and back. If you are using the Mac, it does nothing.
- Four options in **Preferences**, all saved between launches: launch at login, how often to move the mouse, whether to keep going while the screen is locked, and quit automatically.
- Native macOS, Swift and SwiftUI. Runs on Intel and Apple Silicon.

## Requirements

- macOS 13 or later
- Swift 5.9+ toolchain. The Xcode Command Line Tools are enough; full Xcode is not required.
- Intel or Apple Silicon. `make app` builds for the Mac you run it on; `make universal` builds both.

Run `make check` to verify these before building. `make app` runs the same check first.

## Quick start

```sh
make run
```

This builds `build/Mikelito.app`, stops any running copy, and launches the new build. The app runs straight from `build/`, so nothing needs installing.

The first time it launches, macOS asks for Accessibility access (see [Permissions](#permissions)). Grant it and the app starts by itself.

The app is ad-hoc signed. If macOS blocks it on another Mac, right-click the app in Finder and choose **Open**.

### Installing (optional)

`make run` is the preferred way. If you would rather keep the app in an Applications folder, for example because you have no admin rights:

```sh
make install     # copies the app to ~/Applications
make uninstall   # removes it again
```

`~/Applications` is your own folder, so no admin rights are needed. Use `INSTALL_DIR=/path make install` to choose another folder. `/Applications` works too, but may need admin rights.

## Using Mikelito

Click the **M** in the menu bar:

| Menu item | What it does |
|---|---|
| **Preferences…** (⌘,) | Opens the Preferences window |
| **About Mikelito** | Shows the version and project link |
| **Quit Mikelito** (⌘Q) | Stops the app |

If the menu bar is full, macOS hides the icons that do not fit, and Mikelito's can be one of them. Open Mikelito again (from Finder, Spotlight, or `open build/Mikelito.app`) and the Preferences window appears. It has a **Quit** button, so you can always reach Preferences and quit the app without the icon. Making room (quit another menu bar app, or hide some icons) brings the icon back.

The **M** is drawn as a plain letter while the app waits for Accessibility access, and turns into a solid badge once it is active.

## Preferences

Open **Preferences…** from the menu or press ⌘,. Changes apply immediately and are remembered the next time you launch.

| Option | Default | Range | Notes |
|---|---|---|---|
| **Launch at login** | Off | On / Off | Starts Mikelito when you log in to your Mac |
| **Move when the screen is locked** | Off | On / Off | When off, Mikelito pauses while the screen is locked |
| **Move the mouse every** | 4 minutes | 1 second to 24 hours | Choose seconds, minutes or hours. Values outside the range are adjusted to the nearest limit |
| **Quit Mikelito now** | | Button | Quits the app. Useful when the menu bar icon is hidden |
| **Quit automatically** | Off | 1 minute to 99 hours 59 minutes | Closes the app after the time you set. When off, the app runs until you quit it |

Details:

- **Launch at login** is owned by macOS, not by the app. The switch reads the real state each time Preferences opens, so it also reflects changes you make in System Settings › General › Login Items & Extensions. The login item points to wherever the app is when you turn it on: if you move, reinstall or delete the app afterwards, switch it off and on again.
- **Move the mouse every** (under **Mouse Nudge**) is the idle time before a nudge, not a fixed clock. If you used the mouse recently, the app waits for the remainder of the interval.
- **Move when the screen is locked** is off by default. While the screen is locked and this is off, the app does not nudge the pointer and releases its power assertion, so the Mac can behave normally. It resumes as soon as you unlock. Turn it on if you want the app to keep working behind the lock screen.
- **Quit automatically** counts from launch, or from the moment you change the option while the app is running. Typing a value such as 90 minutes is converted to 1 hour 30 minutes.

## Permissions

| Feature | Permission | Where to change it |
|---|---|---|
| Moving the pointer | Accessibility | System Settings › Privacy & Security › Accessibility |
| Launch at login | Login Items (no prompt; macOS may show a notice) | System Settings › General › Login Items & Extensions |

The first time the app launches, macOS asks for Accessibility access. Grant it and the app starts by itself; nothing else to do. Until access is granted the app checks every couple of seconds and does not move the mouse.

Rebuilding the app changes its signature, so macOS may ask for Accessibility access again after a rebuild.

## Make targets

Run `make help` for the full list.

| Command | What it does |
|---|---|
| `make run` | Stop any running copy, rebuild, and launch |
| `make app` | Build the signed `.app` for this Mac (Intel or Apple Silicon) into `./build` |
| `make universal` | Build a universal (Apple Silicon + Intel) `.app` into `./build` |
| `make build` / `make debug` | Compile the release or debug binary only |
| `make install` | Copy the app to `~/Applications` (override with `INSTALL_DIR=...`). No admin rights needed |
| `make uninstall` | Remove the installed copy |
| `make quit` | Stop the running app |
| `make logs` | Stream the app's log output |
| `make crash-report` | Print the latest crash report's exception and stack |
| `make check` | Check that this Mac can build the app |
| `make clean` | Delete `.build/` and `build/` |

## Troubleshooting

| Problem | What to do |
|---|---|
| The mouse never moves and the **M** stays a plain letter | Grant Accessibility access in System Settings › Privacy & Security › Accessibility. If Mikelito is already listed, switch it off and on, or remove it and add it again |
| Access was granted before but the app stopped moving the mouse after a rebuild | The rebuild changed the app's signature. Remove Mikelito from the Accessibility list and let the app ask again |
| The **M** is missing from the menu bar | The menu bar is full and macOS hid it. Open Mikelito again to get the Preferences window, or free some room in the menu bar |
| Mikelito did not start at login after I moved it | Open Preferences, switch **Launch at login** off and on |
| `make run` shows old behaviour | An old copy was still running. Run `make quit`, then `make run` |
| macOS says the app cannot be opened (on another Mac) | Right-click the app in Finder and choose **Open** |
| I want to reset all preferences | Quit the app, then run `defaults delete com.douernesto.mikelito` |

## Project layout

```
Package.swift                 Swift package: one executable target
scripts/build_app.sh          Wraps the binary into Mikelito.app with an Info.plist and icon, and signs it
scripts/check_env.sh          Checks that this Mac can build the app (make check)
Makefile                      Developer commands
Resources/AppIcon.png         1024x1024 app icon, converted to .icns at build time
Sources/Mikelito/
  MikelitoApp.swift           App entry point and menu bar menu
  MouseMover.swift            Start-up, the timer and the pointer nudge
  AutoQuit.swift              Quits the app after the saved time
  AppDelegate.swift           Opens Preferences when the app is opened again while running
  MenuIcon.swift              The menu bar "M" icon
  PreferencesView.swift       Preferences UI and the saved values
  PreferencesWindow.swift     Creates and shows the Preferences window
```

## How it works

- A timer fires every interval and checks how long it has been since the last mouse movement. If it is at least one interval, it posts two synthetic mouse-move events: the pointer goes one pixel to the right and straight back, so it ends where it started. Otherwise it waits for the remainder.
- Posting those events needs Accessibility access. Until it is granted the app polls every 2 seconds, then starts by itself.
- Preferences are stored in `UserDefaults` under `com.douernesto.mikelito`: `intervalSeconds`, `moveWhenLocked`, `quitEnabled` and `quitSeconds`. Launch at login is not stored by the app: it uses `SMAppService` and the switch reads the state from macOS.
- Once active, the app holds a power assertion, which is released when you quit, and also while the screen is locked (unless **Move when the screen is locked** is on). Lock state comes from the system's lock and unlock notifications, and is checked again before every nudge.
- The Preferences window is a plain `NSWindow` sized once from its content. SwiftUI's own `Settings` scene does not open reliably in a menu bar app, and letting SwiftUI keep resizing the window crashes it.

## Contributing

Never commit or push directly to `main`. Make every change on a `feature/`, `bugfix/` or `hotfix/` branch and open a pull request.

## Known limitations

- Only mouse movement counts as activity; keyboard use alone does not postpone a nudge.
- If the Mac is asleep when the auto-quit time passes, the app should quit shortly after it wakes (not tested).
- There are no automated tests in the repo yet.

## License

MIT. See [LICENSE](LICENSE).
