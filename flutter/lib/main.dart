import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/overlay.dart';
import 'package:flutter_hbb/desktop/widgets/refresh_wrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'common.dart';
import 'consts.dart';
import 'mobile/hyperos_theme.dart';
import 'mobile/pages/home_page.dart';
import 'mobile/pages/server_page.dart';
import 'models/platform_model.dart';
import 'models/state_model.dart';
import 'utils/multi_window_manager.dart';

/// Compatibility globals retained for shared upstream models.
///
/// Android always runs in the main Flutter view, so these stay unset.
int? kWindowId;
WindowType? kWindowType;
late List<String> kBootArgs;

Future<void> main(List<String> args) async {
  earlyAssert();
  WidgetsFlutterBinding.ensureInitialized();
  kBootArgs = List<String>.from(args);

  await _initEnvironment();
  checkUpdate();
  androidChannelInit();
  platformFFI.syncAndroidServiceAppDirConfigPath();
  draggablePositions.load();
  await Future.wait([gFFI.abModel.loadCache(), gFFI.groupModel.loadCache()]);
  gFFI.userModel.refreshCurrentUser();

  runApp(const AndroidApp());
  await initUniLinks();
}

Future<void> _initEnvironment() async {
  await platformFFI.init(kAppTypeMain);
  await initGlobalFFI();
  updateSystemWindowTheme();
}

/// No-op compatibility hooks for models shared with the desktop connection
/// manager. That window does not exist in the Android-only application.
Future<void> showCmWindow({bool isStartup = false}) async {}

Future<void> hideCmWindow({bool isStartup = false}) async {}

class AndroidApp extends StatefulWidget {
  const AndroidApp({super.key});

  @override
  State<AndroidApp> createState() => _AndroidAppState();
}

class _AndroidAppState extends State<AndroidApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      final userPreference = MyTheme.getThemeModePreference();
      if (userPreference != ThemeMode.system) return;

      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      Get.changeThemeMode(
        brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      );
      updateSystemWindowTheme();
    };
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOrientation());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _updateOrientation();
  }

  void _updateOrientation() {
    final orientation = View.of(context).physicalSize.aspectRatio > 1
        ? Orientation.landscape
        : Orientation.portrait;
    stateGlobal.isPortrait.value = orientation == Orientation.portrait;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshWrapper(
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gFFI.ffiModel),
          ChangeNotifierProvider.value(value: gFFI.imageModel),
          ChangeNotifierProvider.value(value: gFFI.cursorModel),
          ChangeNotifierProvider.value(value: gFFI.canvasModel),
          ChangeNotifierProvider.value(value: gFFI.peerTabModel),
        ],
        child: GetMaterialApp(
          navigatorKey: globalKey,
          debugShowCheckedModeBanner: false,
          title: bind.mainGetAppNameSync(),
          theme: HyperosTheme.light(MyTheme.lightTheme),
          darkTheme: HyperosTheme.dark(MyTheme.darkTheme),
          themeMode: MyTheme.currentThemeMode(),
          home: HomePage(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          navigatorObservers: [BotToastNavigatorObserver()],
          builder: (context, child) => AccessibilityListener(
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
