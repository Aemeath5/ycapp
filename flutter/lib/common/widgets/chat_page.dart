import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/chat_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../mobile/hyperos_theme.dart';
import '../../mobile/pages/home_page.dart';

enum ChatPageType {
  mobileMain,
  desktopCM,
}

class ChatPage extends StatelessWidget implements PageShape {
  late final ChatModel chatModel;
  final ChatPageType? type;

  ChatPage({ChatModel? chatModel, this.type}) {
    this.chatModel = chatModel ?? gFFI.chatModel;
  }

  @override
  final title = translate("Chat");

  @override
  final icon = unreadTopRightBuilder(gFFI.chatModel.mobileUnreadSum);

  @override
  final appBarActions = [
    PopupMenuButton<MessageKey>(
        tooltip: translate('Chat'),
        icon: unreadTopRightBuilder(
          gFFI.chatModel.mobileUnreadSum,
          icon: const Icon(
            Icons.people_alt_rounded,
            color: HyperosTheme.accent,
          ),
        ),
        itemBuilder: (context) {
          // only mobile need [appBarActions], just bind gFFI.chatModel
          final chatModel = gFFI.chatModel;
          return chatModel.messages.entries.map((entry) {
            final key = entry.key;
            final user = entry.value.chatUser;
            final client = gFFI.serverModel.clients
                .firstWhereOrNull((e) => e.id == key.connId);
            final connected =
                gFFI.serverModel.clients.any((e) => e.id == key.connId);
            return PopupMenuItem<MessageKey>(
              height: 52,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: HyperosTheme.accentSurface(context),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      key.isOut
                          ? Icons.call_made_rounded
                          : Icons.call_received_rounded,
                      color: HyperosTheme.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${user.firstName}  ${user.id}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (connected)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: HyperosTheme.success,
                      ),
                    ).marginOnly(left: 7),
                  if (client != null)
                    unreadMessageCountBuilder(client.unreadChatMessageCount)
                        .marginOnly(left: 4)
                ],
              ),
              value: key,
            );
          }).toList();
        },
        onSelected: (key) {
          gFFI.chatModel.changeCurrentKey(key);
        })
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: chatModel,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Consumer<ChatModel>(
          builder: (context, chatModel, child) {
            final isEmptyMobileChat = type == ChatPageType.mobileMain &&
                (chatModel.currentUser == null ||
                    chatModel.currentKey.peerId.isEmpty);
            if (isEmptyMobileChat) {
              return _buildEmptyMobileChat(context);
            }

            final readOnly = type == ChatPageType.mobileMain &&
                    (chatModel.currentKey.connId == ChatModel.clientModeID ||
                        gFFI.serverModel.clients.every((e) =>
                            e.id != chatModel.currentKey.connId ||
                            chatModel.currentUser == null)) ||
                type == ChatPageType.desktopCM &&
                    gFFI.serverModel.clients
                            .firstWhereOrNull(
                                (e) => e.id == chatModel.currentKey.connId)
                            ?.disconnected ==
                        true;
            return Stack(
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final useHyperosStyle = isMobile;
                  final chat = DashChat(
                    onSend: chatModel.send,
                    currentUser: chatModel.me,
                    messages: chatModel
                            .messages[chatModel.currentKey]?.chatMessages ??
                        [],
                    readOnly: readOnly,
                    inputOptions: InputOptions(
                      focusNode: chatModel.inputNode,
                      textController: chatModel.textController,
                      inputTextStyle: TextStyle(
                        fontSize: useHyperosStyle ? 15 : 14,
                        color: useHyperosStyle
                            ? HyperosTheme.text(context)
                            : Theme.of(context).textTheme.titleLarge?.color,
                      ),
                      inputDecoration: useHyperosStyle
                          ? InputDecoration(
                              isDense: true,
                              hintText: translate('Write a message'),
                              filled: true,
                              fillColor: HyperosTheme.surfaceMuted(context),
                              hintStyle: TextStyle(
                                color:
                                    HyperosTheme.secondaryText(context),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: HyperosTheme.border(context),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: HyperosTheme.accent,
                                  width: 1.2,
                                ),
                              ),
                            )
                          : InputDecoration(
                              isDense: true,
                              hintText: translate('Write a message'),
                              filled: true,
                              fillColor:
                                  Theme.of(context).colorScheme.background,
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  width: 1,
                                  style: BorderStyle.solid,
                                ),
                              ),
                            ),
                      sendButtonBuilder: defaultSendButton(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        color: useHyperosStyle
                            ? HyperosTheme.accent
                            : MyTheme.accent,
                        icon: Icons.send_rounded,
                      ),
                    ),
                    messageOptions: MessageOptions(
                      showOtherUsersAvatar: false,
                      showOtherUsersName: false,
                      textColor: Colors.white,
                      maxWidth: constraints.maxWidth *
                          (useHyperosStyle ? 0.76 : 0.7),
                      messageTextBuilder: (message, _, __) {
                        final isOwnMessage = useHyperosStyle
                            ? message.user.id == chatModel.me.id
                            : message.user.id.isBlank!;
                        final foreground = !useHyperosStyle || isOwnMessage
                            ? Colors.white
                            : HyperosTheme.text(context);
                        return Column(
                          crossAxisAlignment: isOwnMessage
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              message.text,
                              style: TextStyle(
                                color: foreground,
                                fontSize: useHyperosStyle ? 15 : null,
                                height: useHyperosStyle ? 1.35 : null,
                              ),
                            ),
                            Text(
                              "${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                color: useHyperosStyle
                                    ? foreground.withOpacity(0.66)
                                    : Colors.white,
                                fontSize: useHyperosStyle ? 10 : 8,
                              ),
                            ).marginOnly(top: 3),
                          ],
                        );
                      },
                      messageDecorationBuilder:
                          (message, previousMessage, nextMessage) {
                        final isOwnMessage = useHyperosStyle
                            ? message.user.id == chatModel.me.id
                            : message.user.id.isBlank!;
                        if (!useHyperosStyle) {
                          return defaultMessageDecoration(
                            color: isOwnMessage
                                ? MyTheme.accent
                                : Colors.blueGrey,
                            borderTopLeft: 8,
                            borderTopRight: 8,
                            borderBottomRight: isOwnMessage ? 2 : 8,
                            borderBottomLeft: isOwnMessage ? 8 : 2,
                          );
                        }
                        return BoxDecoration(
                          color: isOwnMessage
                              ? HyperosTheme.accent
                              : HyperosTheme.surfaceMuted(context),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(
                              isOwnMessage ? 18 : 6,
                            ),
                            bottomRight: Radius.circular(
                              isOwnMessage ? 6 : 18,
                            ),
                          ),
                          border: isOwnMessage
                              ? null
                              : Border.all(
                                  color: HyperosTheme.border(context),
                                ),
                        );
                      },
                    ),
                  ).workaroundFreezeLinuxMint();
                  return SelectionArea(child: chat);
                }),
              ],
            ).paddingOnly(bottom: 8);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyMobileChat(BuildContext context) {
    return ColoredBox(
      color: HyperosTheme.background(context),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 62, 24, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: HyperosTheme.accentSurface(context),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: HyperosTheme.accent,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  translate('empty_chat_tip'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HyperosTheme.secondaryText(context),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
