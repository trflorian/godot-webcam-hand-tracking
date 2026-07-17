# Hand Tracking with Godot

This project is very similar to the existing [Virtual Hand Clone](https://github.com/trflorian/virtual-hand-clone)
project, where I used Python and Godot to track my hands and show them in a 3D world. Here, I use a Godot addon
for MediaPipe directly, so no Python process needs to run alongside Godot. This makes the project redistributable
to mobile and desktop.

## Setup from a fresh clone

The repository does not contain the GDMP addon or the MediaPipe hand-landmarker model. Install both **before
opening the project in Godot**. Without GDMP, Godot cannot resolve the `MediaPipe*` types used by the scripts and
will report many parse errors.

### Requirements

- [Godot 4.6](https://godotengine.org/download/) with the compatibility renderer
- A webcam
- [GDMP v0.6](https://github.com/j20001970/GDMP/releases/tag/v0.6)
- The MediaPipe Hand Landmarker model

### Linux and macOS

Run these commands from the project root:

```bash
curl -L https://github.com/j20001970/GDMP/releases/download/v0.6/GDMP-v0.6.zip \
  -o /tmp/GDMP-v0.6.zip
unzip /tmp/GDMP-v0.6.zip -d .

mkdir -p tasks
curl -L \
  https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task \
  -o tasks/hand_landmarker.task
```

The resulting files should include:

```text
addons/GDMP/plugin.cfg
addons/GDMP/GDMP.gdextension
tasks/hand_landmarker.task
```

Then open `project.godot` in Godot. The GDMP plugin is already listed as enabled in the project configuration.
Check **Project > Project Settings > Plugins** and enable **GDMP** if it is not enabled.

### Windows or manual installation

1. Download `GDMP-v0.6.zip` from the
   [GDMP v0.6 release](https://github.com/j20001970/GDMP/releases/tag/v0.6).
2. Extract it into the project root. The final path must be `addons/GDMP`, not a nested
   `GDMP-v0.6/addons/GDMP` directory.
3. Create a `tasks` directory in the project root.
4. Download
   [`hand_landmarker.task`](https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task)
   into `tasks/hand_landmarker.task`.
5. Open the project and verify that **GDMP** is enabled under **Project > Project Settings > Plugins**.

### If the project was opened before installing GDMP

Godot may disable and remove the missing plugin from the enabled-plugin list. After installing GDMP:

1. Close and reopen the project so Godot imports the GDExtension.
2. Open **Project > Project Settings > Plugins**.
3. Enable **GDMP**.
4. Restart the editor if the `MediaPipe*` types still show as unknown.

Errors such as `Could not find type "MediaPipeNormalizedLandmarks"`, `Unrecognized UID`, and
`Addon 'res://addons/GDMP/plugin.cfg' failed to load` indicate that GDMP has not been installed or loaded
correctly.

The `addons/` directory is ignored by Git because the prebuilt GDMP package is large and platform-specific.

## Desktop

<img width="1421" height="855" alt="image" src="https://github.com/user-attachments/assets/5756203f-a17b-427d-92b3-cbf2f2772ad9" />

## Mobile

<img width="1453" height="876" alt="image" src="https://github.com/user-attachments/assets/2a32ea5d-5d26-427f-a15b-908340c42ac6" />

## Web

On web the camera feed is currently not supported.
There is an active PR open to support the webcam feed in Godot on web exports, you can follow this [PR](https://github.com/godotengine/godot-proposals/issues/12493).
