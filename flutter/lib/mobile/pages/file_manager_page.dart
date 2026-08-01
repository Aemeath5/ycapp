import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:flutter_hbb/models/file_model.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../common/widgets/dialog.dart';
import '../hyperos_theme.dart';
import '../widgets/miuix_widgets.dart';

class FileManagerPage extends StatefulWidget {
  FileManagerPage(
      {Key? key,
      required this.id,
      this.password,
      this.isSharedPassword,
      this.forceRelay})
      : super(key: key);
  final String id;
  final String? password;
  final bool? isSharedPassword;
  final bool? forceRelay;

  @override
  State<StatefulWidget> createState() => _FileManagerPageState();
}

enum SelectMode { local, remote, none }

extension SelectModeEq on SelectMode {
  bool eq(bool? currentIsLocal) {
    if (currentIsLocal == null) {
      return false;
    }
    if (currentIsLocal) {
      return this == SelectMode.local;
    } else {
      return this == SelectMode.remote;
    }
  }
}

extension SelectModeExt on Rx<SelectMode> {
  void toggle(bool currentIsLocal) {
    switch (value) {
      case SelectMode.local:
        value = SelectMode.none;
        break;
      case SelectMode.remote:
        value = SelectMode.none;
        break;
      case SelectMode.none:
        if (currentIsLocal) {
          value = SelectMode.local;
        } else {
          value = SelectMode.remote;
        }
        break;
    }
  }
}

class _FileManagerPageState extends State<FileManagerPage> {
  final model = gFFI.fileModel;
  final selectMode = SelectMode.none.obs;

  var showLocal = true;

  FileController get currentFileController =>
      showLocal ? model.localController : model.remoteController;
  FileDirectory get currentDir => currentFileController.directory.value;
  DirectoryOptions get currentOptions => currentFileController.options.value;
  final _uniqueKey = UniqueKey();

  Widget _menuRow(IconData icon, String label, {bool selected = false}) {
    return Row(
      children: [
        MiuiIconContainer(
          size: 34,
          child: Icon(selected ? Icons.check_rounded : icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            translate(label),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    gFFI.start(widget.id,
        isFileTransfer: true,
        password: widget.password,
        isSharedPassword: widget.isSharedPassword,
        forceRelay: widget.forceRelay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gFFI.dialogManager
          .showLoading(translate('Connecting...'), onCancel: closeConnection);
    });
    gFFI.ffiModel.updateEventListener(gFFI.sessionId, widget.id);
    WakelockManager.enable(_uniqueKey);
  }

  @override
  void dispose() {
    model.close().whenComplete(() {
      gFFI.close();
      gFFI.dialogManager.dismissAll();
      WakelockManager.disable(_uniqueKey);
    });
    model.jobController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final compactTitle = screenWidth < 380;
    final availableTitleWidth = (screenWidth - 120).clamp(112.0, 220.0);
    return WillPopScope(
      onWillPop: () async {
        if (selectMode.value != SelectMode.none) {
          selectMode.value = SelectMode.none;
          setState(() {});
        } else {
          currentFileController.goBack();
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: translate('Close'),
            icon: const Icon(Icons.close_rounded),
            onPressed: () => clientClose(gFFI.sessionId, gFFI),
          ),
          centerTitle: true,
          title: SizedBox(
            width: availableTitleWidth.toDouble(),
            child: MiuiSegmentedControl<bool>(
              value: showLocal,
              items: [
                MiuiSegmentedItem(
                  value: true,
                  label: translate('Local'),
                  icon: compactTitle ? null : Icons.phone_android_rounded,
                ),
                MiuiSegmentedItem(
                  value: false,
                  label: translate('Remote'),
                  icon: compactTitle ? null : Icons.desktop_windows_rounded,
                ),
              ],
              onChanged: (value) => setState(() => showLocal = value),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
                tooltip: translate('More'),
                icon: const Icon(Icons.more_horiz_rounded),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: _menuRow(Icons.refresh_rounded, 'Refresh File'),
                      value: "refresh",
                    ),
                    PopupMenuItem(
                      enabled: currentDir.path != "/",
                      child: _menuRow(Icons.checklist_rounded, 'Multi Select'),
                      value: "select",
                    ),
                    PopupMenuItem(
                      enabled: currentDir.path != "/",
                      child: _menuRow(
                        Icons.create_new_folder_rounded,
                        'Create Folder',
                      ),
                      value: "folder",
                    ),
                    PopupMenuItem(
                      enabled: currentDir.path != "/",
                      child: _menuRow(
                        Icons.visibility_rounded,
                        'Show Hidden Files',
                        selected: currentOptions.showHidden,
                      ),
                      value: "hidden",
                    )
                  ];
                },
                onSelected: (v) {
                  if (v == "refresh") {
                    currentFileController.refresh();
                  } else if (v == "select") {
                    model.localController.selectedItems.clear();
                    model.remoteController.selectedItems.clear();
                    selectMode.toggle(showLocal);
                    setState(() {});
                  } else if (v == "folder") {
                    final name = TextEditingController();
                    String? errorText;
                    gFFI.dialogManager.show((setState, close, context) {
                      name.addListener(() {
                        if (errorText != null) {
                          setState(() {
                            errorText = null;
                          });
                        }
                      });
                      return CustomAlertDialog(
                          title: Text(translate("Create Folder")),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText:
                                      translate("Please enter the folder name"),
                                  errorText: errorText,
                                ),
                                controller: name,
                              ).workaroundFreezeLinuxMint(),
                            ],
                          ),
                          actions: [
                            dialogButton("Cancel",
                                onPressed: () => close(false), isOutline: true),
                            dialogButton("OK", onPressed: () {
                              if (name.value.text.isNotEmpty) {
                                if (!PathUtil.validName(
                                    name.value.text,
                                    currentFileController
                                        .options.value.isWindows)) {
                                  setState(() {
                                    errorText =
                                        translate("Invalid folder name");
                                  });
                                  return;
                                }
                                currentFileController.createDir(PathUtil.join(
                                    currentDir.path,
                                    name.value.text,
                                    currentOptions.isWindows));
                                close();
                              }
                            })
                          ]);
                    });
                  } else if (v == "hidden") {
                    currentFileController.toggleShowHidden();
                  }
                }),
          ],
        ),
        body: SafeArea(
          top: false,
          child: showLocal
              ? FileManagerView(
                  controller: model.localController,
                  selectMode: selectMode,
                )
              : FileManagerView(
                  controller: model.remoteController,
                  selectMode: selectMode,
                ),
        ),
        bottomSheet: bottomSheet(),
      ),
    );
  }

  Widget? bottomSheet() {
    return Obx(() {
      final selectedItems = getActiveSelectedItems();
      final jobTable = model.jobController.jobTable;

      final localLabel = selectedItems?.isLocal == null
          ? ""
          : " [${selectedItems!.isLocal ? translate("Local") : translate("Remote")}]";
      if (!(selectMode.value == SelectMode.none)) {
        final selectedItemsLen =
            "${selectedItems?.items.length ?? 0} ${translate("items")}";
        if (selectedItems == null ||
            selectedItems.items.isEmpty ||
            selectMode.value.eq(showLocal)) {
          return BottomSheetBody(
              leading: Icon(Icons.check),
              title: translate("Selected"),
              text: selectedItemsLen + localLabel,
              onCanceled: () {
                selectedItems?.items.clear();
                selectMode.value = SelectMode.none;
                setState(() {});
              },
              actions: [
                IconButton(
                  icon: Icon(Icons.compare_arrows),
                  onPressed: () => setState(() => showLocal = !showLocal),
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever),
                  onPressed: selectedItems != null
                      ? () async {
                          if (selectedItems.items.isNotEmpty) {
                            await currentFileController
                                .removeAction(selectedItems);
                            selectedItems.items.clear();
                            selectMode.value = SelectMode.none;
                          }
                        }
                      : null,
                )
              ]);
        } else {
          return BottomSheetBody(
              leading: Icon(Icons.input),
              title: translate("Paste here?"),
              text: selectedItemsLen + localLabel,
              onCanceled: () {
                selectedItems.items.clear();
                selectMode.value = SelectMode.none;
                setState(() {});
              },
              actions: [
                IconButton(
                  icon: Icon(Icons.compare_arrows),
                  onPressed: () => setState(() => showLocal = !showLocal),
                ),
                IconButton(
                  icon: Icon(Icons.paste),
                  onPressed: () {
                    selectMode.value = SelectMode.none;
                    final otherSide = showLocal
                        ? model.remoteController
                        : model.localController;
                    final thisSideData =
                        DirectoryData(currentDir, currentOptions);
                    otherSide.sendFiles(selectedItems, thisSideData);
                    selectedItems.items.clear();
                    selectMode.value = SelectMode.none;
                  },
                )
              ]);
        }
      }

      if (jobTable.isEmpty) {
        return Offstage();
      }

      // Find the first job that is in progress (the one actually transferring data)
      // Rust backend processes jobs sequentially, so the first inProgress job is the active one
      final activeJob = jobTable
              .firstWhereOrNull((job) => job.state == JobState.inProgress) ??
          jobTable.last;

      switch (activeJob.state) {
        case JobState.inProgress:
          return BottomSheetBody(
            leading: CircularProgressIndicator(),
            color: HyperosTheme.warning,
            title: translate("Waiting"),
            text:
                "${translate("Speed")}:  ${readableFileSize(activeJob.speed)}/s",
            onCanceled: () {
              model.jobController.cancelJob(activeJob.id);
              jobTable.clear();
            },
          );
        case JobState.done:
          return BottomSheetBody(
            leading: Icon(Icons.check),
            color: HyperosTheme.success,
            title: "${translate("Successful")}!",
            text: activeJob.display(),
            onCanceled: () => jobTable.clear(),
          );
        case JobState.error:
          return BottomSheetBody(
            leading: Icon(Icons.error),
            color: HyperosTheme.danger,
            title: "${translate("Error")}!",
            text: "",
            onCanceled: () => jobTable.clear(),
          );
        case JobState.none:
          break;
        case JobState.paused:
          // TODO: Handle this case.
          break;
      }
      return Offstage();
    });
  }

  SelectedItems? getActiveSelectedItems() {
    final localSelectedItems = model.localController.selectedItems;
    final remoteSelectedItems = model.remoteController.selectedItems;

    if (localSelectedItems.items.isNotEmpty &&
        remoteSelectedItems.items.isNotEmpty) {
      // assert unreachable
      debugPrint("Wrong SelectedItems state, reset");
      localSelectedItems.clear();
      remoteSelectedItems.clear();
    }

    if (localSelectedItems.items.isEmpty && remoteSelectedItems.items.isEmpty) {
      return null;
    }

    if (localSelectedItems.items.length > remoteSelectedItems.items.length) {
      return localSelectedItems;
    } else {
      return remoteSelectedItems;
    }
  }
}

class FileManagerView extends StatefulWidget {
  final FileController controller;
  final Rx<SelectMode> selectMode;

  FileManagerView({required this.controller, required this.selectMode});

  @override
  State<StatefulWidget> createState() => _FileManagerViewState();
}

class _FileManagerViewState extends State<FileManagerView> {
  final _listScrollController = ScrollController();
  final _breadCrumbScroller = ScrollController();
  StreamSubscription? _directorySubscription;
  late final ascending = Rx<bool>(controller.sortAscending);

  bool get isLocal => widget.controller.isLocal;
  FileController get controller => widget.controller;
  SelectedItems get _selectedItems => widget.controller.selectedItems;

  @override
  void initState() {
    super.initState();
    _directorySubscription =
        controller.directory.listen((e) => breadCrumbScrollToEnd());
  }

  @override
  void dispose() {
    _directorySubscription?.cancel();
    _listScrollController.dispose();
    _breadCrumbScroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      headTools(),
      Expanded(child: Obx(() {
        final entries = controller.directory.value.entries;
        if (entries.isEmpty) {
          return MiuiStatusView(
            icon: Icons.folder_open_rounded,
            title: translate('Empty Directory'),
            description: controller.directory.value.path,
            actionLabel: translate('Refresh File'),
            onAction: controller.refresh,
            compact: HyperosTheme.compactLayout(context),
          );
        }
        return ListView.builder(
          controller: _listScrollController,
          physics: HyperosTheme.springPhysics,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 104),
          itemCount: entries.length + 1,
          itemBuilder: (context, index) {
            if (index >= entries.length) {
              return listTail();
            }
            var selected = false;
            if (widget.selectMode.value != SelectMode.none) {
              selected = _selectedItems.items.contains(entries[index]);
            }

            final sizeStr = entries[index].isFile
                ? readableFileSize(entries[index].size.toDouble())
                : "";

            final showCheckBox = () {
              return widget.selectMode.value != SelectMode.none &&
                  widget.selectMode.value.eq(controller.selectedItems.isLocal);
            }();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MiuiSectionCard(
                child: MiuiPreferenceTile(
                leading: entries[index].isDrive
                    ? Image(
                        image: iconHardDrive,
                        width: 24,
                        height: 24,
                        fit: BoxFit.scaleDown,
                        color: HyperosTheme.accent,
                      )
                    : Icon(
                        entries[index].isFile
                            ? Icons.description_rounded
                            : Icons.folder_rounded,
                      ),
                decorateLeading: true,
                title: Text(
                  entries[index].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selected,
                subtitle: entries[index].isDrive
                    ? null
                    : Text(
                        "${entries[index].lastModified().toString().replaceAll(".000", "")}  $sizeStr",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: entries[index].isDrive
                    ? null
                    : showCheckBox
                        ? MiuiCheckBox(
                            value: selected,
                            onChanged: (v) {
                              if (v && !selected) {
                                _selectedItems.add(entries[index]);
                              } else if (!v && selected) {
                                _selectedItems.remove(entries[index]);
                              }
                              setState(() {});
                            })
                        : PopupMenuButton<String>(
                            tooltip: translate('More'),
                            icon: const Icon(Icons.more_horiz_rounded),
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem(
                                  child: Text(
                                    translate('Delete'),
                                    style: const TextStyle(
                                      color: HyperosTheme.danger,
                                    ),
                                  ),
                                  value: "delete",
                                ),
                                PopupMenuItem(
                                  child: Text(translate("Multi Select")),
                                  value: "multi_select",
                                ),
                                PopupMenuItem(
                                  child: Text(translate("Properties")),
                                  value: "properties",
                                  enabled: false,
                                ),
                                if (!entries[index].isDrive &&
                                    versionCmp(gFFI.ffiModel.pi.version,
                                            "1.3.0") >=
                                        0)
                                  PopupMenuItem(
                                    child: Text(translate("Rename")),
                                    value: "rename",
                                  )
                              ];
                            },
                            onSelected: (v) {
                              if (v == "delete") {
                                final items = SelectedItems(isLocal: isLocal);
                                items.add(entries[index]);
                                controller.removeAction(items);
                              } else if (v == "multi_select") {
                                _selectedItems.clear();
                                widget.selectMode.toggle(isLocal);
                                setState(() {});
                              } else if (v == "rename") {
                                controller.renameAction(
                                    entries[index], isLocal);
                              }
                            }),
                onTap: () {
                  if (showCheckBox) {
                    if (selected) {
                      _selectedItems.remove(entries[index]);
                    } else {
                      _selectedItems.add(entries[index]);
                    }
                    setState(() {});
                    return;
                  }
                  if (entries[index].isDirectory || entries[index].isDrive) {
                    controller.openDirectory(entries[index].path);
                  } else {
                    // Perform file-related tasks.
                  }
                },
                onLongPress: entries[index].isDrive
                    ? null
                    : () {
                        _selectedItems.clear();
                        widget.selectMode.toggle(isLocal);
                        if (widget.selectMode.value != SelectMode.none) {
                          _selectedItems.add(entries[index]);
                        }
                        setState(() {});
                      },
                ),
              ),
            );
          },
        );
      }))
    ]);
  }

  void breadCrumbScrollToEnd() {
    final duration = HyperosTheme.duration(
      context,
      const Duration(milliseconds: 200),
    );
    Future.delayed(duration, () {
      if (_breadCrumbScroller.hasClients) {
        final target = _breadCrumbScroller.position.maxScrollExtent;
        if (duration == Duration.zero) {
          _breadCrumbScroller.jumpTo(target);
        } else {
          _breadCrumbScroller.animateTo(
            target,
            duration: duration,
            curve: Curves.fastLinearToSlowEaseIn,
          );
        }
      }
    });
  }

  Widget headTools() => MiuiSectionCard(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
          Expanded(child: Obx(() {
            final home = controller.options.value.home;
            final isWindows = controller.options.value.isWindows;
            return BreadCrumb(
              items: getPathBreadCrumbItems(controller.shortPath, isWindows,
                  () => controller.goToHomeDirectory(), (list) {
                var path = "";
                if (home.startsWith(list[0])) {
                  // absolute path
                  for (var item in list) {
                    path = PathUtil.join(path, item, isWindows);
                  }
                } else {
                  path += home;
                  for (var item in list) {
                    path = PathUtil.join(path, item, isWindows);
                  }
                }
                controller.openDirectory(path);
              }),
              divider: Icon(
                Icons.chevron_right_rounded,
                color: HyperosTheme.secondaryText(context),
              ),
              overflow: ScrollableOverflow(controller: _breadCrumbScroller),
            );
          })),
          Row(
            children: [
              IconButton(
                tooltip: translate('Back'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: controller.goBack,
              ),
              IconButton(
                tooltip: translate('Parent directory'),
                icon: const Icon(Icons.arrow_upward_rounded),
                onPressed: controller.goToParentDirectory,
              ),
              PopupMenuButton<SortBy>(
                  tooltip: translate('Sort'),
                  icon: const Icon(Icons.sort_rounded),
                  itemBuilder: (context) {
                    return SortBy.values
                        .map((e) => PopupMenuItem(
                              child: Text(translate(e.toString())),
                              value: e,
                            ))
                        .toList();
                  },
                  onSelected: (sortBy) {
                    // If selecting the same sort option, flip the order
                    // If selecting a different sort option, use ascending order
                    if (controller.sortBy.value == sortBy) {
                      ascending.value = !controller.sortAscending;
                    } else {
                      ascending.value = true;
                    }
                    controller.changeSortStyle(sortBy,
                        ascending: ascending.value);
                  }),
            ],
          )
          ],
        ),
      );

  Widget listTail() => Obx(() => Container(
        height: 92,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(30, 5, 30, 0),
              child: Text(
                controller.directory.value.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: HyperosTheme.secondaryText(context)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(2),
              child: Text(
                "${translate('Total')}: ${controller.directory.value.entries.length} ${translate('items')}",
                style: TextStyle(color: HyperosTheme.secondaryText(context)),
              ),
            )
          ],
        ),
      ));

  List<BreadCrumbItem> getPathBreadCrumbItems(String shortPath, bool isWindows,
      void Function() onHome, void Function(List<String>) onPressed) {
    final list = PathUtil.split(shortPath, isWindows);
    final breadCrumbList = [
      BreadCrumbItem(
          content: IconButton(
        icon: Icon(Icons.home_filled),
        onPressed: onHome,
      ))
    ];
    breadCrumbList.addAll(list.asMap().entries.map((e) => BreadCrumbItem(
        content: TextButton(
            child: Text(e.value),
            style:
                ButtonStyle(minimumSize: MaterialStateProperty.all(Size(0, 0))),
            onPressed: () => onPressed(list.sublist(0, e.key + 1))))));
    return breadCrumbList;
  }
}

class BottomSheetBody extends StatelessWidget {
  BottomSheetBody(
      {required this.leading,
      required this.title,
      required this.text,
      this.onCanceled,
      this.actions,
      this.color = HyperosTheme.accent});

  final Widget leading;
  final String title;
  final String text;
  final VoidCallback? onCanceled;
  final List<Widget>? actions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final actionWidgets = <Widget>[
      ...?actions,
      IconButton(
        tooltip: translate('Close'),
        icon: const Icon(Icons.close_rounded),
        onPressed: onCanceled,
      ),
    ];
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: HyperosTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(color: HyperosTheme.border(context)),
          ),
          boxShadow: HyperosTheme.capsuleShadow(context),
        ),
        child: Row(
          children: [
            MiuiIconContainer(color: color, child: leading),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: HyperosTheme.text(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: HyperosTheme.secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: actionWidgets),
          ],
        ),
      ),
    );
  }
}
