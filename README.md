
# Night Signal + PovoZka 1.0

A jailbreak horror experience made of:

- **PovoZka** — a fictional messenger where the story begins.
- **Night Signal** — game settings, language, testing, SAFE MODE / ОТКАТ and resume.
- **NightSignalTweak** — temporary visual SpringBoard, Lock Screen, Settings and Photos effects.

Target: **rootless arm64, iOS 15–16**.

## Version 1.0

### ОТКАТ is not an ending

`ОТКАТ` is now a temporary **SAFE MODE**.

Use it when you are in the middle of the story but need your phone to look normal:

1. Open Night Signal.
2. Tap **ОТКАТ / SAFE MODE**.
3. Night Signal pauses the story timeline.
4. All horror overlays stop applying after the respring.
5. Use the phone normally.
6. Open Night Signal again.
7. Tap **ПРОДОЛЖИТЬ / RESUME STORY**.
8. The story continues from the same story time.

The pause time is not counted toward the story.

### Two endings

Near the end, PovoZka presents a real story choice.

**Good ending**
- Disconnect MARA.
- The red SpringBoard state collapses.
- The wallpaper fades back to normal.
- Icon labels recover.
- PovoZka shows that the signal has been cut.

**Bad ending**
- Answer MARA with `03:33`.
- SpringBoard turns deep red.
- The Lock Screen becomes `MARA // 03:33`.
- Settings shows the fake MARA account/device overlay.
- Photos receives a stronger nightmare overlay.
- Final screamers run and the phone remains visually “infected” until SAFE MODE / ОТКАТ is used.

Neither ending changes the real Apple ID, hardware model or Photos library.

## Wallpaper behavior

Night Signal visually replaces the Home Screen mood with temporary injected wallpaper layers:

- cold blue stage;
- dark red stage;
- near-black stage;
- final ending wallpaper.

The user's actual wallpaper file is not overwritten. This lets SAFE MODE restore the original appearance reliably.

## Screen effects

The story now includes:

- gradual red-screen pulses;
- red SpringBoard corruption;
- icon tint changes;
- changing icon names;
- ghost icons;
- icon shaking;
- fake PovoZka calls;
- thought cards;
- several different screamers;
- fake Settings Apple ID/model panel;
- nightmare Photos layer;
- corrupted Lock Screen;
- two story resprings;
- a good/bad ending branch.

## SnowBoard

For the best experience, keep icon labels visible.

If SnowBoard is hiding labels, disable the option that hides app labels / `HideLabels`, because several story beats change icon names.

## Important

**Unsaved data in open apps may be lost during a story respring. Save important work first.**

## Build on GitHub

1. Upload this project to a new GitHub repository.
2. Open **Actions**.
3. Run **Build Night Signal DEB**.
4. Download the `NightSignal-PovoZka-DEB` artifact.
5. Install the `.deb` through Sileo/Zebra.

The project uses Theos rootless packaging for arm64.


## Ending behavior

The **good ending** performs a cleanup respring and returns original Home Screen labels/wallpaper appearance automatically.

The **bad ending** deliberately keeps the red MARA visual state active. This is still not permanent: open Night Signal and use **ОТКАТ / SAFE MODE** whenever you want the phone to look normal again. You can later resume the same bad-ending state if desired.


Developer: **thxrealx7**  
TikTok: **@thxrealx7**
