import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/mobile/pages/server_page.dart';
import 'package:flutter_hbb/mobile/pages/settings_page.dart';
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
  bool get _hasActiveChatConversation =>
      isChatPageCurrentTab &&
      gFFI.chatModel.currentUser != null &&
      gFFI.chatModel.currentKey.peerId.isNotEmpty;

  void refreshPages() {
    setState(() {
      initPages();
    });
  }

  @override
  void initState() {
    super.initState();
    initPages();
    gFFI.chatModel.addListener(_onChatModelChanged);
  }

  @override
  void dispose() {
    gFFI.chatModel.removeListener(_onChatModelChanged);
    super.dispose();
  }

  void _onChatModelChanged() {
    if (mounted && isChatPageCurrentTab) {
      setState(() {});
    }
  }

  void initPages() {
    _pages.clear();
    _chatPageTabIndex = -1;
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final titleMotion =
        reduceMotion ? Duration.zero : HyperosTheme.motionStandard;
    final chatConversationHeader = _hasActiveChatConversation;
    final page = _pages.elementAt(_selectedIndex);
    final appBarActions = isChatPageCurrentTab &&
            gFFI.chatModel.messages.isEmpty
        ? const <Widget>[]
        : page.appBarActions;
    final navWidth = (MediaQuery.of(context).size.width - 32)
        .clamp(0.0, 240.0)
        .toDouble();

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
          toolbarHeight: chatConversationHeader ? 64 : 88,
          centerTitle: chatConversationHeader,
          titleSpacing: chatConversationHeader ? 16 : 24,
          title: AnimatedSwitcher(
            duration: titleMotion,
            switchInCurve: HyperosTheme.motionCurve,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: appTitle(),
            ),
          ),
          actions: appBarActions,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 34),
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: navWidth,
              height: 50,
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: HyperosTheme.capsuleShadow(context),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                      child: Container(
                        decoration: BoxDecoration(
                          color: HyperosTheme.isDark(context)
                              ? const Color(0xFA2C2C2C)
                              : Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: HyperosTheme.isDark(context)
                                ? Colors.white.withOpacity(0.10)
                                : HyperosTheme.border(context),
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
                          iconSize: 22,
                          onTap: _selectPage,
                        ),
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

  void _selectPage(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
      if (isChatPageCurrentTab) {
        gFFI.chatModel.hideChatIconOverlay();
        gFFI.chatModel.hideChatWindowOverlay();
        gFFI.chatModel.mobileClearClientUnread(
          gFFI.chatModel.currentKey.connId,
        );
      }
    });
  }

  BottomNavigationBarItem _buildNavigationItem(PageShape page) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return BottomNavigationBarItem(
      icon: SizedBox(width: 42, height: 32, child: Center(child: page.icon)),
      activeIcon: TweenAnimationBuilder<double>(
        duration: reduceMotion ? Duration.zero : HyperosTheme.motionStandard,
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.86, end: 1),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 42,
          height: 32,
          decoration: BoxDecoration(
            color: HyperosTheme.accentSurface(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconTheme(
            data: const IconThemeData(color: HyperosTheme.accent, size: 22),
            child: Center(child: page.icon),
          ),
        ),
      ),
      label: page.title,
    );
  }

  Widget appTitle() {
    final currentUser = gFFI.chatModel.currentUser;
    final currentKey = gFFI.chatModel.currentKey;
    if (_hasActiveChatConversation && currentUser != null) {
      final connected = gFFI.serverModel.clients.any(
        (e) => e.id == currentKey.connId,
      );
      return Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: HyperosTheme.accentSurface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Tooltip(
              message: currentKey.isOut
                  ? translate('Outgoing connection')
                  : translate('Incoming connection'),
              child: Icon(
                currentKey.isOut
                    ? Icons.call_made_rounded
                    : Icons.call_received_rounded,
                color: HyperosTheme.accent,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              "${currentUser.firstName}  ${currentUser.id}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HyperosTheme.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (connected) ...[
            const SizedBox(width: 8),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: HyperosTheme.success,
              ),
            ),
          ],
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
