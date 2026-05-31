# Hand Tracking with Godot

This project is very similar to the existing [Virtual Hand Clone](https://github.com/trflorian/virtual-hand-clone) project where I used Python + Godot to track my hands and show them in a 3D world in Godot.
Here I use a Godot addon for mediapipe directly, so we don't need any Python process running anymore.
THis has the huge advantage of actually being redistributable, the entire project can be exported to mobile or desktop.


## Desktop

<img width="1421" height="855" alt="image" src="https://github.com/user-attachments/assets/5756203f-a17b-427d-92b3-cbf2f2772ad9" />

## Mobile

<img width="1453" height="876" alt="image" src="https://github.com/user-attachments/assets/2a32ea5d-5d26-427f-a15b-908340c42ac6" />

## Web

On web the camera feed is currently not supported.
There is an active PR open to support the webcam feed in Godot on web exports, you can follow this [PR](https://github.com/godotengine/godot-proposals/issues/12493).
