import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  //
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //
  final _form = GlobalKey<FormState>();
  final _room = TextEditingController(text: "demo");

  String userName = "Demo";
  String host = "https://meet.jit.si";
  String error = "";

  bool isInConference = false;

  bool isAudioOnly = false;
  bool isAudio = true;
  bool isVideo = true;

  @override
  void initState() {
    super.initState();
    JitsiMeet.addListener(
      JitsiMeetingListener(
        onConferenceWillJoin: _onConferenceWillJoin,
        onConferenceJoined: _onConferenceJoined,
        onConferenceTerminated: _onConferenceTerminated,
        onError: _onError,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: kIsWeb
          ? Container(
              alignment: Alignment.center,
              child: JitsiMeetConferencing(),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _form,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _room,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () => joinMeeting(),
                          onFieldSubmitted: (val) => joinMeeting(),
                          decoration: InputDecoration(
                            label: const Text("Room"),
                            labelStyle: const TextStyle(color: Colors.blue),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue, width: 1.0),
                            ),
                            disabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue.withOpacity(0.5), width: 1.0),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue, width: 1.0),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber.shade300, width: 1.0),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber, width: 1.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please fill Room";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: joinMeeting,
                        child: const Text("Join"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> joinMeeting() async {
    if (_form.currentState!.validate()) {
      PermissionStatus mic = await Permission.microphone.request();
      PermissionStatus cam = await Permission.camera.request();
      if (mic != PermissionStatus.granted) {
        setState(() {
          isAudio = false;
        });
      }
      if (cam != PermissionStatus.granted) {
        setState(() {
          isVideo = false;
        });
      }

      Map<FeatureFlagEnum, bool> featureFlags = {
        FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
      };
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
        } else if (Platform.isIOS) {
          featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
        }
      }
      String id = const Uuid().v4();
      String room = _room.text;
      var options = JitsiMeetingOptions(id: id, room: room)
        ..handle = "example"
        ..serverURL = host
        ..subject = "example"
        ..userDisplayName = userName
        ..userEmail = "$userName@demo.com"
        ..iosAppBarRGBAColor = "#0F955D"
        ..audioOnly = isAudioOnly
        ..audioMuted = isAudio ? false : true
        ..videoMuted = isVideo ? false : true
        ..featureFlags.addAll(featureFlags)
        ..webOptions = {
          "width": "100%",
          "height": "100%",
          "chromeExtensionBanner": null,
          "userInfo": {"displayName": userName}
        };

      await JitsiMeet.joinMeeting(
        options,
        listener: JitsiMeetingListener(
          onConferenceWillJoin: (message) {
            setState(() {
              isInConference = true;
            });
            debugPrint("${options.room} will join with message: $message");
          },
          onConferenceJoined: (message) {
            debugPrint("${options.room} joined with message: $message");
          },
          onConferenceTerminated: (message) {
            setState(() {
              isInConference = false;
            });
            debugPrint("${options.room} terminated with message: $message");
          },
          genericListeners: [
            JitsiGenericListener(
              eventName: 'readyToClose',
              callback: (dynamic message) {
                debugPrint("readyToClose callback");
              },
            ),
          ],
        ),
      );
    }
  }

  void _onConferenceWillJoin(message) {
    debugPrint("_onConferenceWillJoin broadcasted with message: $message");
  }

  void _onConferenceJoined(message) async {
    debugPrint("_onConferenceJoined broadcasted with message: $message");
  }

  void _onConferenceTerminated(message) async {
    debugPrint("_onConferenceTerminated broadcasted with message: $message");
    onClose();
  }

  _onError(error) {
    debugPrint("_onError broadcasted: $error");
  }

  Future<void> onClose() async {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }
}
