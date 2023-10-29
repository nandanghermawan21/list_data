library list_data;

import 'package:error_handling/error_handling.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skeleton_text/skeleton_text.dart';

class ListDataComponent<T> extends StatefulWidget {
  final ListDataComponentController<T>? controller;
  final WidgetFromDataBuilder2Param<T?, int>? itemBuilder;
  final Widget? emptyWidget;
  final FutureObjectBuilderWith2Param<List<T>, int, String?>? dataSource;
  final ValueChanged2Param<List<T>, String?>? onDataReceived;
  final bool showSearchBox;
  final String? searchHint;
  final ListDataComponentMode listViewMode;
  final Widget? header;
  final ValueChanged<T?>? onSelected;
  final bool enableGetMore;
  final ObjectBuilderWith2Param<bool, T, int>? onWillReceiveDropedData;
  final ValueChanged2Param<T, int>? onReceiveDropedData;
  final WidgetFromDataBuilder2Param<T?, int>? dragFeedbackBuilder;
  final ObjectBuilderWith2Param<Object, T?, int>? dragDataBuilder;
  final bool enableDrag;
  final Widget? loaderWidget;
  final int? loaderCount;
  final bool autoSearch;
  final TextStyle? searchStyle;
  final Widget? searchIcon;
  final String? showMoreText;
  final String? emptyDataText;
  final TextStyle? emptyDataTextStyle;

  const ListDataComponent(
      {Key? key,
      this.controller,
      this.itemBuilder,
      this.dataSource,
      this.onDataReceived,
      this.showSearchBox = false,
      this.searchHint,
      this.listViewMode = ListDataComponentMode.listView,
      this.header,
      this.onSelected,
      this.emptyWidget,
      this.enableGetMore = true,
      this.onReceiveDropedData,
      this.onWillReceiveDropedData,
      this.dragFeedbackBuilder,
      this.dragDataBuilder,
      this.enableDrag = true,
      this.loaderWidget,
      this.loaderCount = 5,
      this.autoSearch = true,
      this.searchStyle,
      this.searchIcon,
      this.showMoreText,
      this.emptyDataText,
      this.emptyDataTextStyle})
      : super(
          key: key,
        );

  @override
  State<ListDataComponent<T>> createState() => _ListDataComponentState<T>();
}

class _ListDataComponentState<T> extends State<ListDataComponent<T>> {
  @override
  void initState() {
    widget.controller?.value.dataSource = widget.dataSource;
    widget.controller?.value.onDataReceived = widget.onDataReceived;
    widget.controller?.value.onSelected = widget.onSelected;
    super.initState();
    widget.controller?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: ValueListenableBuilder<ListDataComponentValue<T>>(
        valueListenable: widget.controller!,
        builder: (BuildContext context, value, Widget? child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.header != null ? widget.header! : const SizedBox(),
              widget.showSearchBox ? searchBox() : const SizedBox(),
              [ListDataComponentMode.listView, ListDataComponentMode.tile]
                      .contains(widget.listViewMode)
                  ? Expanded(child: childBuilder())
                  : childBuilder(),
            ],
          );
        },
      ),
    );
  }

  Widget searchBox() {
    return Container(
      height: 50,
      alignment: Alignment.center,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade400,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 50,
              color: Colors.transparent,
              child: Material(
                child: TextField(
                  controller: widget.controller?.value.searchController,
                  onChanged: (val) {
                    if (widget.autoSearch == true) {
                      widget.controller?.refresh();
                    }
                  },
                  onSubmitted: (val) {
                    if (widget.autoSearch == false) {
                      widget.controller?.refresh();
                    }
                  },
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp("[',\"]")),
                  ],
                  decoration: InputDecoration(
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.only(left: 15, right: 15),
                    hintText: widget.searchHint ?? 'Search',
                    hintStyle: widget.searchStyle ??
                        Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: widget.searchIcon ??
                  Icon(
                    Icons.search,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
            ),
          )
        ],
      ),
    );
  }

  Widget childBuilder() {
    switch (widget.controller?.value.state) {
      case ListDataComponentState.firstLoad:
        return SingleChildScrollView(
          controller: widget.controller?.value.scrollController,
          child: Column(
            children: List.generate(
              widget.loaderCount!,
              (index) {
                return loader();
              },
            ),
          ),
        );
      case ListDataComponentState.errorLoaded:
        return GestureDetector(
          onTap: widget.controller?.refresh,
          child: errorLoaded(),
        );
      default:
        return (widget.controller?.value.data.length ?? 0) > 0 ||
                (widget.controller?.value.state ==
                    ListDataComponentState.loading)
            ? listModeBuilder()
            : GestureDetector(
                onTap: widget.controller?.refresh,
                child: emptyData(),
              );
    }
  }

  Widget listModeBuilder() {
    switch (widget.listViewMode) {
      case ListDataComponentMode.column:
        return columnMode();
      case ListDataComponentMode.tile:
        return tilewMode();
      default:
        return listMode();
    }
  }

  Widget columnMode() {
    List<T> data = widget.controller?.value.data ?? [];
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Column(
            children: List.generate(
              (data.length ?? 0) +
                  (widget.controller?.value.state ==
                          ListDataComponentState.loading
                      ? widget.loaderCount!
                      : 0),
              (index) {
                if (widget.itemBuilder != null) {
                  if (index < (data.length ?? -1)) {
                    return GestureDetector(
                      onTap: () {
                        widget.controller?.value.selected = data[index];
                        widget.controller?.commit();
                        if (widget.onSelected != null) {
                          widget.onSelected!(data[index]);
                        }
                      },
                      child: item(data[index], index),
                    );
                  } else {
                    return loader();
                  }
                } else {
                  return emptyItem();
                }
              },
            ),
          ),
          widget.enableGetMore != true
              ? const SizedBox()
              : Container(
                  margin: const EdgeInsets.only(top: 5),
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                      widget.controller?.getOther();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.showMoreText ?? "Show More",
                        ),
                        const Icon(
                          FontAwesomeIcons.chevronDown,
                          size: 15,
                        )
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget tilewMode() {
    List<T> data = widget.controller?.value.data ?? [];
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      child: NotificationListener(
        onNotification: (n) {
          if (n is ScrollEndNotification) {
            var current =
                widget.controller?.value.scrollController.position.pixels;
            var min = widget
                .controller?.value.scrollController.position.minScrollExtent;
            var max = widget
                .controller?.value.scrollController.position.maxScrollExtent;
            if (widget.controller?.value.scrollController.position
                        .userScrollDirection ==
                    ScrollDirection.forward &&
                ((current ?? 0) <= (min ?? 0))) {
              widget.controller?.refresh();
            } else if (widget.controller?.value.scrollController.position
                        .userScrollDirection ==
                    ScrollDirection.reverse &&
                ((current ?? 0) >= (max ?? 0))) {
              if (widget.enableGetMore == true) widget.controller?.getOther();
            }
          }
          return true;
        },
        child: SingleChildScrollView(
          controller: widget.controller?.value.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Wrap(
            children: List.generate(
              (data.length ?? 0) +
                  (widget.controller?.value.state ==
                          ListDataComponentState.loading
                      ? widget.loaderCount!
                      : 0),
              (index) {
                if (widget.itemBuilder != null) {
                  if (index < (data.length ?? -1)) {
                    return GestureDetector(
                      onTap: () {
                        widget.controller?.value.selected = data[index];
                        widget.controller?.commit();
                        if (widget.onSelected != null) {
                          widget.onSelected!(data[index]);
                        }
                      },
                      child: IntrinsicWidth(
                        child: Container(
                          child: item(data[index], index),
                        ),
                      ),
                    );
                  } else {
                    return loader();
                  }
                } else {
                  return emptyItem();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget listMode() {
    List<T> data = widget.controller?.value.data ?? [];
    return NotificationListener(
      onNotification: (n) {
        if (n is ScrollEndNotification) {
          var current =
              widget.controller?.value.scrollController.position.pixels;
          var min = widget
              .controller?.value.scrollController.position.minScrollExtent;
          var max = widget
              .controller?.value.scrollController.position.maxScrollExtent;
          if (widget.controller?.value.scrollController.position
                      .userScrollDirection ==
                  ScrollDirection.forward &&
              ((current ?? 0) <= (min ?? 0))) {
            widget.controller?.refresh();
          } else if (widget.controller?.value.scrollController.position
                      .userScrollDirection ==
                  ScrollDirection.reverse &&
              ((current ?? 0) >= (max ?? 0))) {
            if (widget.enableGetMore == true) widget.controller?.getOther();
          }
        }
        return true;
      },
      child: ListView(
        controller: widget.controller?.value.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: List.generate(
          (data.length ?? 0) +
              (widget.controller?.value.state == ListDataComponentState.loading
                  ? widget.loaderCount!
                  : 0),
          (index) {
            if (widget.itemBuilder != null) {
              if (index < (data.length ?? -1)) {
                return GestureDetector(
                  onTap: () {
                    widget.controller?.value.selected = data[index];
                    widget.controller?.commit();
                    if (widget.onSelected != null) {
                      widget.onSelected!(data[index]);
                    }
                  },
                  child: item(data[index], index),
                );
              } else {
                return loader();
              }
            } else {
              return emptyItem();
            }
          },
        ),
      ),
    );
  }

  Widget item(T? data, int index) {
    List<Widget> _item = [
      draggable(data, index),
      Container(
        color: Colors.transparent,
        child: widget.enableDrag
            ? Draggable<Object>(
                dragAnchorStrategy: (drg, obj, offset) {
                  return const Offset(1, 1);
                },
                feedback: Material(
                  child: dragFeedBack(data, index),
                ),
                data: widget.dragDataBuilder != null
                    ? widget.dragDataBuilder!(data, index)
                    : data,
                child: widget.itemBuilder!(data, index),
              )
            : widget.itemBuilder!(data, index),
      ),
      index == (widget.controller?.value.data.length ?? 0) - 1
          ? draggable(data, index + 1)
          : const SizedBox(),
    ];

    return Container(
      color: Colors.transparent,
      child: Column(
        children: _item,
      ),
    );
  }

  Widget draggable(data, index) {
    return DragTarget<Object>(
      builder: (c, d, w) {
        return Container(
          height: widget.controller?.value.droppedItem != null ? null : 1,
          width: double.infinity,
          color: Colors.transparent,
          child: (widget.controller?.value.droppedItem != null &&
                  widget.controller?.value.droppedIndexTarget == index &&
                  widget.controller?.value.droppedItem != data)
              ? widget.itemBuilder!(widget.controller?.value.droppedItem, -1)
              : const SizedBox(),
        );
      },
      onMove: (object) {
        if (object.data is T) {
          if (widget.controller?.value.droppedItem == (object.data as T)) {
            return;
          }
          widget.controller?.value.droppedItem = (object.data as T);
          widget.controller?.value.droppedIndexTarget = index;
          widget.controller?.commit();
        }
      },
      onLeave: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
      },
      onWillAccept: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
        if (widget.onWillReceiveDropedData != null) {
          return widget.onWillReceiveDropedData!((object as T), index);
        } else {
          return true;
        }
      },
      onAccept: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
        if (widget.onReceiveDropedData != null) {
          widget.onReceiveDropedData!((object as T), index);
        }
      },
    );
  }

  Widget dragFeedBack(T? data, int index) {
    return widget.dragFeedbackBuilder != null
        ? widget.dragFeedbackBuilder!(data, index)
        : Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              border: Border.all(
                color: Colors.black,
              ),
            ),
            child: Center(
              child: FittedBox(
                child: Text("$index"),
              ),
            ),
          );
  }

  Widget loader() {
    return widget.loaderWidget != null
        ? widget.loaderWidget!
        : SkeletonAnimation(
            shimmerColor: Colors.grey.shade300,
            child: widget.itemBuilder != null
                ? widget.itemBuilder!(null, 0)
                : emptyItem(),
          );
  }

  Widget emptyItem() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      color: Colors.transparent,
    );
  }

  Widget errorLoaded() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.exclamationTriangle,
            color: Colors.red,
            size: 50,
          ),
          const SizedBox(
            height: 10,
          ),
          !(widget.controller?.value.errorMessage ?? "").contains("<div")
              ? Text(
                  widget.controller?.value.errorMessage ?? "Error",
                  textAlign: TextAlign.center,
                )
              : Container(
                  height: 300,
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    child:
                        HtmlWidget(widget.controller?.value.errorMessage ?? ""),
                  ),
                ),
        ],
      ),
    );
  }

  Widget emptyData() {
    return DragTarget<Object>(
      builder: (c, lo, ld) {
        if (widget.controller?.value.droppedItem != null) {
          return widget.itemBuilder!(widget.controller?.value.droppedItem, -1);
        } else {
          if (widget.controller?.value.droppedItem != null) {
            return widget.itemBuilder!(
                widget.controller?.value.droppedItem, -1);
          } else {
            return widget.emptyWidget ??
                Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        FontAwesomeIcons.database,
                        size: 50,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(widget.emptyDataText ?? "No Data",
                          style: widget.emptyDataTextStyle ??
                              Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                );
          }
        }
      },
      onMove: (object) {
        if (object.data is T) {
          if (widget.controller?.value.droppedItem == (object.data as T)) {
            return;
          }
          widget.controller?.value.droppedItem = (object.data as T);
          widget.controller?.commit();
        }
      },
      onLeave: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
      },
      onWillAccept: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
        if (widget.onWillReceiveDropedData != null) {
          return widget.onWillReceiveDropedData!((object as T), 0);
        } else {
          return true;
        }
      },
      onAccept: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
        if (widget.onReceiveDropedData != null) {
          widget.onReceiveDropedData!((object as T), 0);
        }
      },
    );
  }
}

class ListDataComponentController<T>
    extends ValueNotifier<ListDataComponentValue<T>> {
  ListDataComponentController({ListDataComponentValue<T>? value})
      : super(value ?? ListDataComponentValue<T>());

  void addAll(List<T> datas) {
    value.data.addAll(datas);
    commit();
  }

  void refresh({
    refreshDelayed,
  }) {
    value.state = ListDataComponentState.loading;
    value.data = [];
    commit();
    if (value.dataSource == null) {
      value.state = ListDataComponentState.loaded;
      commit();
      return;
    }
    Future.delayed(Duration(seconds: refreshDelayed ?? value.refreshDelayed))
        .then((waiting) {
      value.dataSource!(0, value.searchController.text).then((datas) {
        value.data = (datas);
        if (value.onDataReceived != null) {
          value.onDataReceived!(datas, value.searchController.text);
        }
        value.state = ListDataComponentState.loaded;
        setSelectedData();
        commit();
      }).catchError(
        (onError) {
          value.state = ListDataComponentState.errorLoaded;
          value.errorMessage = ErrorHandlingUtil.handleApiError(onError);
          commit();
        },
      );
    });
  }

  void clear() {
    value.data = [];
    commit();
  }

  void getOther() {
    double _latPosition = 0;
    try {
      _latPosition = value.scrollController.position.pixels;
    } catch (e) {
      debugPrint("");
    }
    value.state = ListDataComponentState.loading;
    commit();
    if (value.dataSource == null) {
      value.state = ListDataComponentState.loaded;
      value.selected ??= value.data.first;
      commit();
      return;
    }
    value.dataSource!(total, value.searchController.text).then((datas) {
      value.data.addAll(datas);
      if (value.onDataReceived != null) {
        value.onDataReceived!(datas, value.searchController.text);
      }
      value.state = ListDataComponentState.loaded;
      setSelectedData();
      commit();
      try {
        value.scrollController.jumpTo(_latPosition);
      } catch (e) {
        debugPrint("");
      }
    }).catchError(
      (onError) {
        value.state = ListDataComponentState.errorLoaded;
        value.errorMessage = ErrorHandlingUtil.handleApiError(onError);
        commit();
      },
    );
  }

  void setSelectedData() {
    if (value.data.isNotEmpty) {
      value.selected ??= value.data.first;
      if (value.onSelected != null) {
        value.onSelected!(value.selected);
      }
    }
  }

  int get total {
    return value.data.length;
  }

  void commit() {
    notifyListeners();
  }

  void startLoading() {
    value.state = ListDataComponentState.loading;
    commit();
  }

  void stopLoading() {
    value.state = ListDataComponentState.loaded;
    commit();
  }
}

class ListDataComponentValue<T> {
  T? droppedItem;
  int? droppedIndexTarget;
  List<T> data = [];
  T? selected;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  int totalAllData = 0;
  ListDataComponentState state = ListDataComponentState.firstLoad;
  FutureObjectBuilderWith2Param<List<T>, int, String?>? dataSource;
  ValueChanged2Param<List<T>, String?>? onDataReceived;
  ValueChanged<T?>? onSelected;
  String? errorMessage;
  int refreshDelayed = 0;
}

enum ListDataComponentState {
  firstLoad,
  loading,
  loaded,
  errorLoaded,
}

enum ListDataComponentMode {
  listView,
  column,
  tile,
}

typedef WidgetFromDataBuilder2Param<T, T2> = Widget Function(T value, T2 index);
typedef FutureObjectBuilderWith2Param<T, T2, T3> = Future<T> Function(T2, T3);
typedef ValueChanged2Param<T, T2> = void Function(T value, T2 value2);
typedef ObjectBuilderWith2Param<T, T1, T2> = T Function(T1, T2);
