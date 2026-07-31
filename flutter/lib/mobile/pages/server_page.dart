import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/desktop/pages/desktop_home_page.dart';
import 'package:flutter_hbb/mobile/widgets/dialog.dart';
import 'package:flutter_hbb/models/chat_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../common.dart';
import '../../common/widgets/dialog.dart';
import '../../consts.dart';
import '../../models/platform_model.dart';
import '../../models/server_model.dart';
import '../hyperos_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'home_page.dart';

class ServerPage extends StatefulWidget implements PageShape {
  @override
  final title = translate("Share screen");

  @override
  final icon = const Icon(Icons.mobile_screen_share);

  @override
  final appBarActions = (!bind.isDisableSettings() &&
          bind.mainGetBuildinOption(key: kOptionHideSecuritySetting) != 'Y')
      ? [_DropDownAction()]
      : [];

  ServerPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ServerPageState();
}

class _MiuiPopupEntry {
  const _MiuiPopupEntry.item({
    required this.value,
    required this.label,
    this.enabled = true,
    this.checked,
  }) : divider = false;

  const _MiuiPopupEntry.divider()
      : value = null,
        label = null,
        enabled = false,
        checked = null,
        divider = true;

  final String? value;
  final String? label;
  final bool enabled;
  final bool? checked;
  final bool divider;
}

class _DropDownAction extends StatelessWidget {
  const _DropDownAction();

  List<_MiuiPopupEntry> _entries() {
    final approveMode = gFFI.serverModel.approveMode;
    final verificationMethod = gFFI.serverModel.verificationMethod;
    final showPasswordOption = approveMode != 'click';
    final isApproveModeFixed = isOptionFixed(kOptionApproveMode);
    final isNumericOneTimePasswordFixed =
        isOptionFixed(kOptionAllowNumericOneTimePassword);
    final entries = <_MiuiPopupEntry>[];

    if (!isChangeIdDisabled()) {
      entries.add(
        _MiuiPopupEntry.item(
          value: 'changeID',
          label: 'Change ID',
          enabled: gFFI.serverModel.connectStatus > 0,
        ),
      );
      entries.add(const _MiuiPopupEntry.divider());
    }

    entries.addAll([
      _MiuiPopupEntry.item(
        value: 'AcceptSessionsViaPassword',
        label: 'Accept sessions via password',
        checked: approveMode == 'password',
        enabled: !isApproveModeFixed,
      ),
      _MiuiPopupEntry.item(
        value: 'AcceptSessionsViaClick',
        label: 'Accept sessions via click',
        checked: approveMode == 'click',
        enabled: !isApproveModeFixed,
      ),
      _MiuiPopupEntry.item(
        value: 'AcceptSessionsViaBoth',
        label: 'Accept sessions via both',
        checked: approveMode != 'password' && approveMode != 'click',
        enabled: !isApproveModeFixed,
      ),
    ]);

    if (showPasswordOption) {
      entries.add(const _MiuiPopupEntry.divider());
      if (verificationMethod != kUseTemporaryPassword &&
          !isChangePermanentPasswordDisabled()) {
        entries.add(
          const _MiuiPopupEntry.item(
            value: 'setPermanentPassword',
            label: 'Set permanent password',
          ),
        );
      }
      if (verificationMethod != kUsePermanentPassword) {
        entries.addAll([
          const _MiuiPopupEntry.item(
            value: 'setTemporaryPasswordLength',
            label: 'One-time password length',
          ),
          _MiuiPopupEntry.item(
            value: 'allowNumericOneTimePassword',
            label: 'Numeric one-time password',
            checked: gFFI.serverModel.allowNumericOneTimePassword,
            enabled: !isNumericOneTimePasswordFixed,
          ),
        ]);
      }
      entries.addAll([
        const _MiuiPopupEntry.divider(),
        _MiuiPopupEntry.item(
          value: kUseTemporaryPassword,
          label: 'Use one-time password',
          checked: verificationMethod == kUseTemporaryPassword,
        ),
        _MiuiPopupEntry.item(
          value: kUsePermanentPassword,
          label: 'Use permanent password',
          checked: verificationMethod == kUsePermanentPassword,
        ),
        _MiuiPopupEntry.item(
          value: kUseBothPasswords,
          label: 'Use both passwords',
          checked: verificationMethod != kUseTemporaryPassword &&
              verificationMethod != kUsePermanentPassword,
        ),
      ]);
    }

    return entries;
  }

  Future<void> _showMenu(BuildContext context) async {
    final entries = _entries();
    final value = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: HyperosTheme.isDark(context)
          ? const Color(0x66000000)
          : const Color(0x17000000),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 12,
                left: 32,
                bottom: 18,
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: (MediaQuery.of(dialogContext).size.width * 0.68)
                        .clamp(224.0, 288.0)
                        .toDouble(),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        decoration: BoxDecoration(
                          color: HyperosTheme.surface(dialogContext),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: HyperosTheme.border(dialogContext),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                HyperosTheme.isDark(dialogContext)
                                    ? 0.34
                                    : 0.18,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: entries.map((entry) {
                              if (entry.divider) {
                                return Divider(
                                  height: 13,
                                  thickness: 0.7,
                                  color: HyperosTheme.border(dialogContext),
                                );
                              }
                              return MiuiPreferenceTile(
                                title: Text(translate(entry.label!)),
                                trailing: entry.checked == null
                                    ? null
                                    : Icon(
                                        Icons.check_rounded,
                                        color: entry.checked!
                                            ? HyperosTheme.accent
                                            : Colors.transparent,
                                      ),
                                enabled: entry.enabled,
                                onTap: entry.enabled
                                    ? () => Navigator.pop(
                                          dialogContext,
                                          entry.value,
                                        )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                minHeight: 56,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            alignment: Alignment.topRight,
            scale: Tween<double>(begin: 0.96, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    );

    if (value != null) {
      await _handleSelected(value);
    }
  }

  Future<void> _handleSelected(String selectedValue) async {
    var value = selectedValue;
    if (value == 'changeID') {
      changeIdDialog();
    } else if (value == 'setPermanentPassword') {
      setPasswordDialog();
    } else if (value == 'setTemporaryPasswordLength') {
      setTemporaryPasswordLengthDialog(gFFI.dialogManager);
    } else if (value == 'allowNumericOneTimePassword') {
      gFFI.serverModel.switchAllowNumericOneTimePassword();
      gFFI.serverModel.updatePasswordModel();
    } else if (value == kUsePermanentPassword ||
        value == kUseTemporaryPassword ||
        value == kUseBothPasswords) {
      callback() {
        bind.mainSetOption(key: kOptionVerificationMethod, value: value);
        gFFI.serverModel.updatePasswordModel();
      }

      if (value == kUsePermanentPassword &&
          (await bind.mainGetCommon(key: 'permanent-password-set')) != 'true') {
        if (isChangePermanentPasswordDisabled()) {
          callback();
          return;
        }
        setPasswordDialog(notEmptyCallback: callback);
      } else {
        callback();
      }
    } else if (value.startsWith('AcceptSessionsVia')) {
      value = value.substring('AcceptSessionsVia'.length);
      if (value == 'Password') {
        gFFI.serverModel.setApproveMode('password');
      } else if (value == 'Click') {
        gFFI.serverModel.setApproveMode('click');
      } else {
        gFFI.serverModel.setApproveMode(defaultOptionApproveMode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: '',
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: () => _showMenu(context),
      ),
    );
  }
}

class _ServerPageState extends State<ServerPage> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateTimer = periodic_immediate(const Duration(seconds: 3), () async {
      await gFFI.serverModel.fetchID();
    });
    gFFI.serverModel.checkAndroidPermission();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    checkService();
    return ChangeNotifierProvider.value(
        value: gFFI.serverModel,
        child: Consumer<ServerModel>(
            builder: (context, serverModel, child) => SingleChildScrollView(
                  controller: gFFI.serverModel.controller,
                  physics: HyperosTheme.springPhysics,
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        buildPresetPasswordWarningMobile(),
                        gFFI.serverModel.isStart
                            ? ServerInfo()
                            : ServiceNotRunningNotification(),
                        const ConnectionManager(),
                        const PermissionChecker(),
                        SizedBox.fromSize(size: const Size(0, 15.0)),
                      ],
                    ),
                  ),
                )));
  }
}

void checkService() async {
  gFFI.invokeMethod("check_service");
  // for Android 10/11, request MANAGE_EXTERNAL_STORAGE permission from system setting page
  if (AndroidPermissionManager.isWaitingFile() && !gFFI.serverModel.fileOk) {
    AndroidPermissionManager.complete(kManageExternalStorage,
        await AndroidPermissionManager.check(kManageExternalStorage));
    debugPrint("file permission finished");
  }
}

class ServiceNotRunningNotification extends StatelessWidget {
  ServiceNotRunningNotification({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);

    return PaddingCard(
        title: translate("Service is not running"),
        titleIcon:
            const Icon(Icons.warning_amber_sharp, color: Colors.redAccent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(translate("android_start_service_tip"),
                    style:
                        const TextStyle(fontSize: 12, color: MyTheme.darkGray))
                .marginOnly(bottom: 8),
            ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  if (gFFI.userModel.userName.value.isEmpty &&
                      bind.mainGetLocalOption(key: "show-scam-warning") !=
                          "N") {
                    showScamWarning(context, serverModel);
                  } else {
                    serverModel.toggleService();
                  }
                },
                label: Text(translate("Start service")))
          ],
        ));
  }
}

class ScamWarningDialog extends StatefulWidget {
  final ServerModel serverModel;

  ScamWarningDialog({required this.serverModel});

  @override
  ScamWarningDialogState createState() => ScamWarningDialogState();
}

class ScamWarningDialogState extends State<ScamWarningDialog> {
  int _countdown = bind.isCustomClient() ? 0 : 12;
  bool show_warning = false;
  late Timer _timer;
  late ServerModel _serverModel;

  @override
  void initState() {
    super.initState();
    _serverModel = widget.serverModel;
    startCountdown();
  }

  void startCountdown() {
    const oneSecond = Duration(seconds: 1);
    _timer = Timer.periodic(oneSecond, (timer) {
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isButtonLocked = _countdown > 0;

    return AlertDialog(
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xffe242bc),
                  Color(0xfff4727c),
                ],
              ),
            ),
            padding: EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_sharp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      translate("Warning"),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/scam.png',
                    width: 180,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  translate("scam_title"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22.0,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  "${translate("scam_text1")}\n\n${translate("scam_text2")}\n",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Row(
                  children: <Widget>[
                    Checkbox(
                      value: show_warning,
                      onChanged: (value) {
                        setState(() {
                          show_warning = value!;
                        });
                      },
                    ),
                    Text(
                      translate("Don't show again"),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: 150),
                      child: ElevatedButton(
                        onPressed: isButtonLocked
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                _serverModel.toggleService();
                                if (show_warning) {
                                  bind.mainSetLocalOption(
                                      key: "show-scam-warning", value: "N");
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: Text(
                          isButtonLocked
                              ? "${translate("I Agree")} (${_countdown}s)"
                              : translate("I Agree"),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Container(
                      constraints: BoxConstraints(maxWidth: 150),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: Text(
                          translate("Decline"),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      contentPadding: EdgeInsets.all(0.0),
    );
  }
}

class ServerInfo extends StatelessWidget {
  final model = gFFI.serverModel;
  final emptyController = TextEditingController(text: "-");

  ServerInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);

    const Color colorPositive = Colors.green;
    const Color colorNegative = Colors.red;
    const double iconMarginRight = 15;
    const double iconSize = 24;
    const TextStyle textStyleHeading = TextStyle(
        fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey);
    const TextStyle textStyleValue =
        TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold);

    void copyToClipboard(String value) {
      Clipboard.setData(ClipboardData(text: value));
      showToast(translate('Copied'));
    }

    Widget ConnectionStateNotification() {
      if (serverModel.connectStatus == -1) {
        return Row(children: [
          const Icon(Icons.warning_amber_sharp,
                  color: colorNegative, size: iconSize)
              .marginOnly(right: iconMarginRight),
          Expanded(child: Text(translate('not_ready_status')))
        ]);
      } else if (serverModel.connectStatus == 0) {
        return Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
              .marginOnly(left: 4, right: iconMarginRight),
          Expanded(child: Text(translate('connecting_status')))
        ]);
      } else {
        return Row(children: [
          const Icon(Icons.check, color: colorPositive, size: iconSize)
              .marginOnly(right: iconMarginRight),
          Expanded(child: Text(translate('Ready')))
        ]);
      }
    }

    final showOneTime = serverModel.approveMode != 'click' &&
        serverModel.verificationMethod != kUsePermanentPassword;
    return PaddingCard(
        title: translate('Your Device'),
        child: Column(
          // ID
          children: [
            Row(children: [
              const Icon(Icons.perm_identity,
                      color: Colors.grey, size: iconSize)
                  .marginOnly(right: iconMarginRight),
              Text(
                translate('ID'),
                style: textStyleHeading,
              )
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                model.serverId.value.text,
                style: textStyleValue,
              ),
              IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.copy_outlined),
                  onPressed: () {
                    copyToClipboard(model.serverId.value.text.trim());
                  })
            ]).marginOnly(left: 39, bottom: 10),
            // Password
            Row(children: [
              const Icon(Icons.lock_outline, color: Colors.grey, size: iconSize)
                  .marginOnly(right: iconMarginRight),
              Text(
                translate('One-time Password'),
                style: textStyleHeading,
              )
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                !showOneTime ? '-' : model.serverPasswd.value.text,
                style: textStyleValue,
              ),
              !showOneTime
                  ? SizedBox.shrink()
                  : Row(children: [
                      IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.refresh),
                          onPressed: () => bind.mainUpdateTemporaryPassword()),
                      IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.copy_outlined),
                          onPressed: () {
                            copyToClipboard(
                                model.serverPasswd.value.text.trim());
                          })
                    ])
            ]).marginOnly(left: 40, bottom: 15),
            ConnectionStateNotification()
          ],
        ));
  }
}

class PermissionChecker extends StatefulWidget {
  const PermissionChecker({Key? key}) : super(key: key);

  @override
  State<PermissionChecker> createState() => _PermissionCheckerState();
}

class _PermissionCheckerState extends State<PermissionChecker> {
  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);
    final hasAudioPermission = androidVersion >= 30;
    final hideStopService = isAndroid &&
        bind.mainGetBuildinOption(key: kOptionHideStopService) == 'Y';
    return PaddingCard(
        title: translate("Permissions"),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          serverModel.mediaOk && !hideStopService
              ? ElevatedButton.icon(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red)),
                      icon: const Icon(Icons.stop),
                      onPressed: serverModel.toggleService,
                      label: Text(translate("Stop service")))
                  .marginOnly(bottom: 8)
              : SizedBox.shrink(),
          if (!hideStopService || !serverModel.mediaOk)
            PermissionRow(
                translate("Screen Capture"),
                serverModel.mediaOk,
                !serverModel.mediaOk &&
                        gFFI.userModel.userName.value.isEmpty &&
                        bind.mainGetLocalOption(key: "show-scam-warning") != "N"
                    ? () => showScamWarning(context, serverModel)
                    : serverModel.toggleService),
          PermissionRow(translate("Input Control"), serverModel.inputOk,
              serverModel.toggleInput),
          PermissionRow(translate("Transfer file"), serverModel.fileOk,
              serverModel.toggleFile),
          hasAudioPermission
              ? PermissionRow(translate("Audio Capture"), serverModel.audioOk,
                  serverModel.toggleAudio)
              : Row(children: [
                  Icon(Icons.info_outline).marginOnly(right: 15),
                  Expanded(
                      child: Text(
                    translate("android_version_audio_tip"),
                    style: const TextStyle(color: MyTheme.darkGray),
                  ))
                ]),
          PermissionRow(translate("Enable clipboard"), serverModel.clipboardOk,
              serverModel.toggleClipboard),
        ]));
  }
}

class PermissionRow extends StatelessWidget {
  const PermissionRow(this.name, this.isOk, this.onPressed, {Key? key})
      : super(key: key);

  final String name;
  final bool isOk;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MiuiPreferenceTile(
      title: Text(name),
      switchValue: isOk,
      onToggle: (_) => onPressed(),
      contentPadding: const EdgeInsets.symmetric(vertical: 7),
    );
  }
}

class ConnectionManager extends StatelessWidget {
  const ConnectionManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);
    return Column(
        children: serverModel.clients
            .map((client) => PaddingCard(
                title: translate(
                    client.isFileTransfer ? "Transfer file" : "Share screen"),
                titleIcon: client.isFileTransfer
                    ? Icon(Icons.folder_outlined)
                    : Icon(Icons.mobile_screen_share),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: ClientInfo(client)),
                      Expanded(
                          flex: -1,
                          child: client.isFileTransfer || !client.authorized
                              ? const SizedBox.shrink()
                              : IconButton(
                                  onPressed: () {
                                    gFFI.chatModel.changeCurrentKey(
                                        MessageKey(client.peerId, client.id));
                                    final bar = navigationBarKey.currentWidget;
                                    if (bar != null) {
                                      bar as BottomNavigationBar;
                                      bar.onTap!(1);
                                    }
                                  },
                                  icon: unreadTopRightBuilder(
                                      client.unreadChatMessageCount)))
                    ],
                  ),
                  client.authorized
                      ? const SizedBox.shrink()
                      : Text(
                          translate("android_new_connection_tip"),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ).marginOnly(bottom: 5),
                  client.authorized
                      ? _buildDisconnectButton(client)
                      : _buildNewConnectionHint(serverModel, client),
                  if (client.incomingVoiceCall && !client.inVoiceCall)
                    ..._buildNewVoiceCallHint(context, serverModel, client),
                ])))
            .toList());
  }

  Widget _buildDisconnectButton(Client client) {
    final disconnectButton = ElevatedButton.icon(
      style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.red)),
      icon: const Icon(Icons.close),
      onPressed: () {
        bind.cmCloseConnection(connId: client.id);
        gFFI.invokeMethod("cancel_notification", client.id);
      },
      label: Text(translate("Disconnect")),
    );
    final buttons = [disconnectButton];
    if (client.inVoiceCall) {
      buttons.insert(
        0,
        ElevatedButton.icon(
          style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Colors.red)),
          icon: const Icon(Icons.phone),
          label: Text(translate("Stop")),
          onPressed: () {
            bind.cmCloseVoiceCall(id: client.id);
            gFFI.invokeMethod("cancel_notification", client.id);
          },
        ),
      );
    }

    if (buttons.length == 1) {
      return Container(
        alignment: Alignment.centerRight,
        child: disconnectButton,
      );
    } else {
      return Row(
        children: buttons,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      );
    }
  }

  Widget _buildNewConnectionHint(ServerModel serverModel, Client client) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton(
          child: Text(translate("Dismiss")),
          onPressed: () {
            serverModel.sendLoginResponse(client, false);
          }).marginOnly(right: 15),
      if (serverModel.approveMode != 'password')
        ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: Text(translate("Accept")),
            onPressed: () {
              serverModel.sendLoginResponse(client, true);
            }),
    ]);
  }

  List<Widget> _buildNewVoiceCallHint(
      BuildContext context, ServerModel serverModel, Client client) {
    return [
      Text(
        translate("android_new_voice_call_tip"),
        style: Theme.of(context).textTheme.bodyMedium,
      ).marginOnly(bottom: 5),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(
            child: Text(translate("Dismiss")),
            onPressed: () {
              serverModel.handleVoiceCall(client, false);
            }).marginOnly(right: 15),
        if (serverModel.approveMode != 'password')
          ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(translate("Accept")),
              onPressed: () {
                serverModel.handleVoiceCall(client, true);
              }),
      ])
    ];
  }
}

class PaddingCard extends StatelessWidget {
  const PaddingCard({Key? key, required this.child, this.title, this.titleIcon})
      : super(key: key);

  final String? title;
  final Icon? titleIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final children = [child];
    if (title != null) {
      children.insert(
          0,
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Row(
                children: [
                  if (titleIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 13),
                      child: MiuiIconContainer(
                        size: 42,
                        color: titleIcon!.color ?? HyperosTheme.accent,
                        child: titleIcon!,
                      ),
                    ),
                  Expanded(
                    child: Text(title!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            )),
                  )
                ],
              )));
    }
    return MiuiSectionCard(
      margin: const EdgeInsets.fromLTRB(12, 7, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(children: children),
    );
  }
}

class ClientInfo extends StatelessWidget {
  final Client client;
  ClientInfo(this.client);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          Row(
            children: [
              Expanded(
                  flex: -1,
                  child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildAvatar(context))),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(client.name, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(client.peerId, style: const TextStyle(fontSize: 10))
                  ]))
            ],
          ),
        ]));
  }

  Widget _buildAvatar(BuildContext context) {
    final fallback = CircleAvatar(
      backgroundColor: str2color(client.name,
          Theme.of(context).brightness == Brightness.light ? 255 : 150),
      child: Text(client.name.isNotEmpty ? client.name[0] : '?'),
    );
    return buildAvatarWidget(
          avatar: client.avatar,
          size: 40,
          fallback: fallback,
        ) ??
        fallback;
  }
}

void androidChannelInit() {
  gFFI.setMethodCallHandler((method, arguments) {
    debugPrint("flutter got android msg,$method,$arguments");
    try {
      switch (method) {
        case "start_capture":
          {
            gFFI.dialogManager.dismissAll();
            gFFI.serverModel.updateClientState();
            break;
          }
        case "on_state_changed":
          {
            var name = arguments["name"] as String;
            var value = arguments["value"] as String == "true";
            debugPrint("from jvm:on_state_changed,$name:$value");
            gFFI.serverModel.changeStatue(name, value);
            break;
          }
        case "on_android_permission_result":
          {
            var type = arguments["type"] as String;
            var result = arguments["result"] as bool;
            AndroidPermissionManager.complete(type, result);
            break;
          }
        case "on_media_projection_canceled":
          {
            gFFI.serverModel.stopService();
            break;
          }
        case "msgbox":
          {
            var type = arguments["type"] as String;
            var title = arguments["title"] as String;
            var text = arguments["text"] as String;
            var link = (arguments["link"] ?? '') as String;
            msgBox(gFFI.sessionId, type, title, text, link, gFFI.dialogManager);
            break;
          }
        case "stop_service":
          {
            print(
                "stop_service by kotlin, isStart:${gFFI.serverModel.isStart}");
            if (gFFI.serverModel.isStart) {
              gFFI.serverModel.stopService();
            }
            break;
          }
      }
    } catch (e) {
      debugPrintStack(label: "MethodCallHandler err:$e");
    }
    return "";
  });
}

void showScamWarning(BuildContext context, ServerModel serverModel) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ScamWarningDialog(serverModel: serverModel);
    },
  );
}
