Skip to content
altureny17-wq
juodylive
Repository navigation
Code
Issues
Pull requests
Actions
Projects
Security
Insights
Settings
Build Flutter APK
Update LiveViewersModel.dart #615
All jobs
Run details
Annotations
1 error and 1 warning
build
failed 2 minutes ago in 14m 5s
Search logs
1s
2s
40s
5s
1m 2s
4s
42s
3s
11m 21s
Run flutter build apk --release --target-platform android-arm64
Running Gradle task 'assembleRelease'...                        
Checking the license for package NDK (Side by side) 27.0.12077973 in /usr/local/lib/android/sdk/licenses
License for package NDK (Side by side) 27.0.12077973 accepted.
Preparing "Install NDK (Side by side) 27.0.12077973 v.27.0.12077973".
"Install NDK (Side by side) 27.0.12077973 v.27.0.12077973" ready.
Installing NDK (Side by side) 27.0.12077973 in /usr/local/lib/android/sdk/ndk/27.0.12077973
"Install NDK (Side by side) 27.0.12077973 v.27.0.12077973" complete.
"Install NDK (Side by side) 27.0.12077973 v.27.0.12077973" finished.
[ZEGO][PLUGIN] Download native dependency
[ZEGO][PLUGIN] Native version: 3.23.0.47729
[ZEGO][PLUGIN] Done!
Checking the license for package Android SDK Platform 31 in /usr/local/lib/android/sdk/licenses
License for package Android SDK Platform 31 accepted.
Preparing "Install Android SDK Platform 31 (revision 1)".
"Install Android SDK Platform 31 (revision 1)" ready.
Installing Android SDK Platform 31 in /usr/local/lib/android/sdk/platforms/android-31
"Install Android SDK Platform 31 (revision 1)" complete.
"Install Android SDK Platform 31 (revision 1)" finished.
Checking the license for package Android SDK Platform 33 in /usr/local/lib/android/sdk/licenses
License for package Android SDK Platform 33 accepted.
Preparing "Install Android SDK Platform 33 (revision 3)".
"Install Android SDK Platform 33 (revision 3)" ready.
Installing Android SDK Platform 33 in /usr/local/lib/android/sdk/platforms/android-33
"Install Android SDK Platform 33 (revision 3)" complete.
"Install Android SDK Platform 33 (revision 3)" finished.
lib/home/prebuild_live/multi_users_live_screen.dart:48:8: Error: Error when reading 'lib/home/prebuild_live/gift/components/float_message_overlay.dart': No such file or directory
import 'gift/components/float_message_overlay.dart';
       ^
lib/home/prebuild_live/prebuild_audio_room_screen.dart:44:8: Error: Error when reading 'lib/home/prebuild_live/gift/components/float_message_overlay.dart': No such file or directory
import 'gift/components/float_message_overlay.dart';
       ^
lib/home/prebuild_live/prebuild_live_screen.dart:55:8: Error: Error when reading 'lib/home/prebuild_live/gift/components/float_message_overlay.dart': No such file or directory
import 'gift/components/float_message_overlay.dart';
       ^
lib/home/game_live/game_live_screen.dart:37:8: Error: Error when reading 'lib/home/prebuild_live/gift/components/float_message_overlay.dart': No such file or directory
import '../prebuild_live/gift/components/float_message_overlay.dart';
       ^
lib/home/prebuild_live/multi_users_live_screen.dart:2160:15: Error: Not a constant expression.
        const FloatMessageOverlay(),
              ^^^^^^^^^^^^^^^^^^^
lib/home/prebuild_live/prebuild_audio_room_screen.dart:756:16: Error: The method 'FloatMessageButton' isn't defined for the type '_PrebuildAudioRoomScreenState'.
 - '_PrebuildAudioRoomScreenState' is from 'package:juodylive/home/prebuild_live/prebuild_audio_room_screen.dart' ('lib/home/prebuild_live/prebuild_audio_room_screen.dart').
Try correcting the name to the name of an existing method, or defining a method named 'FloatMessageButton'.
        child: FloatMessageButton(
               ^^^^^^^^^^^^^^^^^^
lib/home/prebuild_live/prebuild_audio_room_screen.dart:1392:15: Error: Not a constant expression.
        const FloatMessageOverlay(),
              ^^^^^^^^^^^^^^^^^^^
lib/home/prebuild_live/prebuild_live_screen.dart:1657:15: Error: Not a constant expression.
        const FloatMessageOverlay(),
              ^^^^^^^^^^^^^^^^^^^
lib/home/prebuild_live/prebuild_live_screen.dart:2012:16: Error: The method 'FloatMessageButton' isn't defined for the type 'PreBuildLiveScreenState'.
 - 'PreBuildLiveScreenState' is from 'package:juodylive/home/prebuild_live/prebuild_live_screen.dart' ('lib/home/prebuild_live/prebuild_live_screen.dart').
Try correcting the name to the name of an existing method, or defining a method named 'FloatMessageButton'.
        child: FloatMessageButton(
               ^^^^^^^^^^^^^^^^^^
lib/home/game_live/game_live_screen.dart:353:17: Error: Not a constant expression.
          const FloatMessageOverlay(),
                ^^^^^^^^^^^^^^^^^^^
Target kernel_snapshot_program failed: Exception


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileFlutterBuildRelease'.
> Process 'command '/opt/hostedtoolcache/flutter/stable-3.41.5-x64/bin/flutter'' finished with non-zero exit value 1

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 11m 18s
Running Gradle task 'assembleRelease'...                          679.7s
Gradle task assembleRelease failed with exit code 1
Error: Process completed with exit code 1.
0s
0s
1s
0s
0s
