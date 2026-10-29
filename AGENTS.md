# AGENTS.md

Guidance for AI coding agents working in this repo. See `README.md` for user-facing docs.

## Project

Mikelito is a native macOS menu bar app (SwiftUI `MenuBarExtra`, Swift 5.9+, macOS 13+) that nudges the mouse pointer while the user is idle. It is a Swift package with one executable target, `Mikelito`:

- `MouseMover`: start-up, the timer, the pointer nudge, and the lock-screen pause (power assertion released and nudges skipped while locked, unless `moveWhenLocked`).
- `MikelitoApp`: app entry point and the menu.
- `AutoQuit`: optional quit timer, driven by the saved `quitEnabled` / `quitSeconds` preferences (off by default, 1 minute to 99 h 59 min).
- Launch at login uses `SMAppService.mainApp` in `PreferencesView`. macOS owns that state, so read it from `SMAppService` instead of storing a copy.
- `AppDelegate`: opening the app again while it runs shows Preferences (the menu bar icon can be hidden when the bar is full, so Preferences must stay reachable and has a Quit button).
- `MenuIcon`: draws the menu bar "M" as a template image.
- `PreferencesView` / `PreferencesWindow`: the Preferences window (a plain `NSWindow`, because the SwiftUI `Settings` scene does not open reliably in a menu bar app); `Prefs` holds the saved interval (default 240 s, range 1 s to 24 h).

There is no Xcode project. Everything builds with the Swift toolchain only.

## Commands

| Task | Command |
|---|---|
| Debug build | `swift build` (or `make debug`) |
| Release build | `swift build -c release` (or `make build`) |
| Build `.app` bundle into `./build` | `make app` |
| Rebuild and launch | `make run` |
| Copy to `~/Applications` (no admin) | `make install` |
| Tests | `swift test` (no tests exist yet) |
| Clean | `make clean` |
| All targets | `make help` |

Before finishing a change, make sure `swift build` succeeds. Run `swift test` too once tests exist.

## Conventions

- Keep it minimal: four settings (launch at login, the interval, move-when-locked and auto-quit), no on/off switch, and no new dependencies unless needed.
- Match the surrounding style: small files, minimal comments.
- `scripts/build_app.sh` generates `Info.plist` inline (`LSUIElement` keeps the app out of the Dock). The preferred workflow is `make run` from `./build`. `make install` is an option for users without admin rights, so it defaults to `~/Applications`, never `/Applications`. Update the Permissions table in `README.md` if a new permission is added.
- Don't commit `.build/` or `build/`. Both are in `.gitignore`.

## Testing notes

- Posting mouse events needs Accessibility permission. Verify manually with `make run`.
- The package is macOS-only, so it will not build on Linux.

## Git and PRs

- Never commit or push directly to `main`. Always work on a branch and open a PR.
- Open PRs from a `feature/`, `bugfix/` or `hotfix/` branch, not from `main`.
- The only author name to use is `douernesto`, in files, commit authorship and PRs.
