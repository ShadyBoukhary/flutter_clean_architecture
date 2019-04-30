import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/src/controller.dart';

abstract class ViewState<Page extends View, Con extends Controller> extends State<Page> {
  final GlobalKey<State<StatefulWidget>> globalKey = GlobalKey<State<StatefulWidget>>();
  final Con controller;

  ViewState(this.controller) {
    controller.initController(globalKey, callHandler);
    WidgetsBinding.instance.addObserver(controller);
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    if (widget.routeObserver != null) {
      widget.routeObserver.subscribe(controller, ModalRoute.of(context));
    }
    super.didChangeDependencies();
  }

  void callHandler(Function fn, {Map<String, dynamic> params}) {
    setState(() {
      if (params == null) {
        fn();
      } else {
        fn(params);
      }
    });
  }

  @override 
  @mustCallSuper
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

abstract class View extends StatefulWidget {
  final RouteObserver routeObserver;
  final Key key;
  View({this.routeObserver, this.key}): super(key: key);
}