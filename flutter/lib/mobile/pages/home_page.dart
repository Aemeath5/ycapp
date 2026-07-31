import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/mobile/pages/server_page.dart';
import 'package:flutter_hbb/mobile/pages/settings_page.dart';
import 'package:get/get.dart';
import '../../common.dart';
import '../../common/widgets/chat_page.dart';
import '../../models/platform_model.dart';
import '../hyperos_theme.dart';
import 'connection_page.dart';

abstract class PageShape extends Widget {
  final String title = "";
  final Widget icon = Icon(null);
  final List<Widget> appBarActions = [];
}

class HomePage extends StatefulWidget {
  static final homeKey = GlobalKey<HomePageState>();

  HomePage() : super(key: homeKey);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  var _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  final List<PageShape> _pages = [];
  int _chatPageTabIndex = -1;
  bool get isChatPageCurrentTab => isAndroid
      ? _selectedIndex == _chatPageTabIndex
      : false; // change this when ios have chat page

  void refreshPages() {
    setState(() {
      initPages();
    });
  }

  @override
  void initState() {
    super.initState();
    initPages();
  }

  void initPages() {
    _pages.clear();
    if (!bind.isIncomingOnly()) {
      _pages.add(ConnectionPage(appBarActions: []));
    }
    if (isAndroid && !bind.isOutgoingOnly()) {
      _chatPageTabIndex = _pages.length;
      _pages.addAll([ChatPage(type: ChatPageType.mobileMain), ServerPage()]);
    }
    _pages.add(SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: HyperosTheme.background(context),
        appBar: AppBar(
          toolbarHeight: isChatPageCurrentTab ? 64 : 88,
          centerTitle: isChatPageCurrentTab,
          titleSpacing: isChatPageCurrentTab ? 16 : 24,
          title: appTitle(),
          actions: _pages.elementAt(_selectedIndex).appBarActions,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 24),
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: 240,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: HyperosTheme.shadow(context),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: HyperosTheme.isDark(context)
                            ? const Color(0xFA2C2C2C)
                            : Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: HyperosTheme.isDark(context)
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: BottomNavigationBar(
                        key: navigationBarKey,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        items: _pages.map(_buildNavigationItem).toList(),
                        currentIndex: _selectedIndex,
                        type: BottomNavigationBarType.fixed,
                        selectedItemColor: HyperosTheme.accent,
                        unselectedItemColor: HyperosTheme.secondaryText(
                          context,
                        ).withOpacity(0.58),
                        showSelectedLabels: false,
                        showUnselectedLabels: false,
                        selectedFontSize: 0,
                        unselectedFontSize: 0,
                        iconSize: 23,
                        onTap: (index) => setState(() {
                          // close chat overlay when go chat page
                          if (_selectedIndex != index) {
                            _selectedIndex = index;
                            if (isChatPageCurrentTab) {
                              gFFI.chatModel.hideChatIconOverlay();
                              gFFI.chatModel.hideChatWindowOverlay();
                              gFFI.chatModel.mobileClearClientUnread(
                                gFFI.chatModel.currentKey.connId,
                              );
                            }
                          }
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _pages.elementAt(_selectedIndex),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationItem(PageShape page) {
    return BottomNavigationBarItem(
      icon: SizedBox(
        width: 42,
        height: 36,
        child: Center(child: page.icon),
      ),
      activeIcon: SizedBox(
        width: 42,
        height: 36,
        child: IconTheme(
          data: const IconThemeData(color: HyperosTheme.accent, size: 23),
          child: Center(child: page.icon),
        ),
      ),
      label: page.title,
    );
  }

  Widget appTitle() {
    final currentUser = gFFI.chatModel.currentUser;
    final currentKey = gFFI.chatModel.currentKey;
    if (isChatPageCurrentTab &&
        currentUser != null &&
        currentKey.peerId.isNotEmpty) {
      final connected = gFFI.serverModel.clients.any(
        (e) => e.id == currentKey.connId,
      );
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: currentKey.isOut
                ? translate('Outgoing connection')
                : translate('Incoming connection'),
            child: Icon(
              currentKey.isOut
                  ? Icons.call_made_rounded
                  : Icons.call_received_rounded,
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${currentUser.firstName}   ${currentUser.id}"),
                  if (connected)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 133, 246, 199),
                      ),
                    ).marginSymmetric(horizontal: 2),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      _pages.elementAt(_selectedIndex).title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontSize: 32,
        height: 1.05,
      ),
    );
  }
}
