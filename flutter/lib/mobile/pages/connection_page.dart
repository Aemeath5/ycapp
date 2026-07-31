import 'dart:async';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/connection_page_title.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_hbb/models/peer_model.dart';

import '../../common.dart';
import '../../common/widgets/peer_tab_page.dart';
import '../../common/widgets/autocomplete.dart';
import '../../consts.dart';
import '../../models/model.dart';
import '../../models/platform_model.dart';
import '../hyperos_theme.dart';
import 'home_page.dart';

/// Connection page for connecting to a remote peer.
class ConnectionPage extends StatefulWidget implements PageShape {
  ConnectionPage({Key? key, required this.appBarActions}) : super(key: key);

  @override
  final icon = const Icon(Icons.connected_tv);

  @override
  final title = translate("Connection");

  @override
  final List<Widget> appBarActions;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

/// State for the connection page.
class _ConnectionPageState extends State<ConnectionPage> {
  /// Controller for the id input bar.
  final _idController = IDTextEditingController();
  final RxBool _idEmpty = true.obs;

  final FocusNode _idFocusNode = FocusNode();
  final TextEditingController _idEditingController = TextEditingController();

  final AllPeersLoader _allPeersLoader = AllPeersLoader();

  StreamSubscription? _uniLinksSubscription;

  // https://github.com/flutter/flutter/issues/157244
  Iterable<Peer> _autocompleteOpts = [];

  _ConnectionPageState() {
    if (!isWeb) _uniLinksSubscription = listenUniLinks();
    _idController.addListener(() {
      _idEmpty.value = _idController.text.isEmpty;
    });
    Get.put<IDTextEditingController>(_idController);
  }

  @override
  void initState() {
    super.initState();
    _allPeersLoader.init(setState);
    _idFocusNode.addListener(onFocusChanged);
    if (_idController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final lastRemoteId = await bind.mainGetLastRemoteId();
        if (lastRemoteId != _idController.id) {
          setState(() {
            _idController.id = lastRemoteId;
          });
        }
      });
    }
    Get.put<TextEditingController>(_idEditingController);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<FfiModel>(context);
    return ColoredBox(
      color: HyperosTheme.background(context),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!bind.isCustomClient() && !isIOS)
                  Obx(() => _buildUpdateUI(stateGlobal.updateUrl.value)),
                _buildRemoteIDTextField(),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverFillRemaining(
              hasScrollBody: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                decoration: BoxDecoration(
                  color: HyperosTheme.surface(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: const PeerTabPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Callback for the connect button.
  /// Connects to the selected peer.
  void onConnect() {
    var id = _idController.id;
    connect(context, id);
  }

  void onFocusChanged() {
    _idEmpty.value = _idEditingController.text.isEmpty;
    if (_idFocusNode.hasFocus) {
      if (_allPeersLoader.needLoad) {
        _allPeersLoader.getAllPeers();
      }

      final textLength = _idEditingController.value.text.length;
      // Select all to facilitate removing text, just following the behavior of address input of chrome.
      _idEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: textLength,
      );
    }
  }

  /// UI for software update.
  /// If _updateUrl] is not empty, shows a button to update the software.
  Widget _buildUpdateUI(String updateUrl) {
    return updateUrl.isEmpty
        ? const SizedBox(height: 0)
        : Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: HyperosTheme.accentSurface(context),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await launchUrl(Uri.parse('https://rustdesk.com/download'));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: HyperosTheme.accent.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.system_update_alt_rounded,
                          color: HyperosTheme.accent,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          translate('Download new version'),
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontSize: 15),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: HyperosTheme.secondaryText(context),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  /// UI for the remote ID TextField.
  /// Search for a peer and connect to it if the id exists.
  Widget _buildRemoteIDTextField() {
    final w = Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HyperosTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: HyperosTheme.accentSurface(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: HyperosTheme.accent,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translate('New Connection'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      translate('Enter Remote ID'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HyperosTheme.secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
            decoration: BoxDecoration(
              color: HyperosTheme.surfaceMuted(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RawAutocomplete<Peer>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    _autocompleteOpts = const Iterable<Peer>.empty();
                  } else if (_allPeersLoader.peers.isEmpty &&
                      !_allPeersLoader.isPeersLoaded) {
                    Peer emptyPeer = Peer(
                      id: '',
                      username: '',
                      hostname: '',
                      alias: '',
                      platform: '',
                      tags: [],
                      hash: '',
                      password: '',
                      forceAlwaysRelay: false,
                      rdpPort: '',
                      rdpUsername: '',
                      loginName: '',
                      device_group_name: '',
                      note: '',
                    );
                    _autocompleteOpts = [emptyPeer];
                  } else {
                    String textWithoutSpaces = textEditingValue.text.replaceAll(
                      " ",
                      "",
                    );
                    if (int.tryParse(textWithoutSpaces) != null) {
                      textEditingValue = TextEditingValue(
                        text: textWithoutSpaces,
                        selection: textEditingValue.selection,
                      );
                    }
                    String textToFind = textEditingValue.text.toLowerCase();

                    _autocompleteOpts = _allPeersLoader.peers
                        .where(
                          (peer) =>
                              peer.id.toLowerCase().contains(textToFind) ||
                              peer.username.toLowerCase().contains(
                                textToFind,
                              ) ||
                              peer.hostname.toLowerCase().contains(
                                textToFind,
                              ) ||
                              peer.alias.toLowerCase().contains(textToFind),
                        )
                        .toList();
                  }
                  return _autocompleteOpts;
                },
                focusNode: _idFocusNode,
                textEditingController: _idEditingController,
                fieldViewBuilder:
                    (
                      BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      updateTextAndPreserveSelection(
                        fieldTextEditingController,
                        _idController.text,
                      );
                      return AutoSizeTextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        minFontSize: 18,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        // keyboardType: TextInputType.number,
                        onChanged: (String text) {
                          _idController.id = text;
                        },
                        style: const TextStyle(
                          fontFamily: 'WorkSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 29,
                          color: HyperosTheme.accent,
                        ),
                        decoration: InputDecoration(
                          labelText: translate('Remote ID'),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          helperStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: HyperosTheme.secondaryText(context),
                          ),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.2,
                            color: HyperosTheme.secondaryText(context),
                          ),
                        ),
                        inputFormatters: [IDTextInputFormatter()],
                        onSubmitted: (_) {
                          onConnect();
                        },
                      );
                    },
                onSelected: (option) {
                  setState(() {
                    _idController.id = option.id;
                    FocusScope.of(context).unfocus();
                  });
                },
                optionsViewBuilder:
                    (
                      BuildContext context,
                      AutocompleteOnSelected<Peer> onSelected,
                      Iterable<Peer> options,
                    ) {
                      options = _autocompleteOpts;
                      double maxHeight = options.length * 50;
                      if (options.length == 1) {
                        maxHeight = 52;
                      } else if (options.length == 3) {
                        maxHeight = 146;
                      } else if (options.length == 4) {
                        maxHeight = 193;
                      }
                      maxHeight = maxHeight.clamp(0, 200);
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: HyperosTheme.surface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: HyperosTheme.border(context),
                            ),
                            boxShadow: HyperosTheme.shadow(context),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Material(
                              color: HyperosTheme.surface(context),
                              elevation: 0,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: maxHeight,
                                  maxWidth: 320,
                                ),
                                child:
                                    _allPeersLoader.peers.isEmpty &&
                                        !_allPeersLoader.isPeersLoaded
                                    ? Container(
                                        height: 80,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : ListView(
                                        padding: EdgeInsets.only(top: 5),
                                        children: options
                                            .map(
                                              (peer) => AutocompletePeerTile(
                                                onSelect: () =>
                                                    onSelected(peer),
                                                peer: peer,
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Obx(
                  () => Offstage(
                    offstage: _idEmpty.value,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _idController.clear();
                        });
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: HyperosTheme.secondaryText(context),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: HyperosTheme.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                      onPressed: onConnect,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final child = Column(
      children: [
        if (isWebDesktop)
          getConnectionPageTitle(
            context,
            true,
          ).marginOnly(bottom: 10, top: 15, left: 12),
        w,
      ],
    );
    return Align(
      alignment: Alignment.topCenter,
      child: Container(constraints: kMobilePageConstraints, child: child),
    );
  }

  @override
  void dispose() {
    _uniLinksSubscription?.cancel();
    _idController.dispose();
    _idFocusNode.removeListener(onFocusChanged);
    _allPeersLoader.clear();
    _idFocusNode.dispose();
    _idEditingController.dispose();
    if (Get.isRegistered<IDTextEditingController>()) {
      Get.delete<IDTextEditingController>();
    }
    if (Get.isRegistered<TextEditingController>()) {
      Get.delete<TextEditingController>();
    }
    super.dispose();
  }
}
