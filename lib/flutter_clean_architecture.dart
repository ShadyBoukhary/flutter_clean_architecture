library flutter_clean_architecture;
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/src/controller.dart';
import 'package:provider/provider.dart';

export 'package:flutter_clean_architecture/src/controller.dart';
export 'package:flutter_clean_architecture/src/observer.dart';
export 'package:flutter_clean_architecture/src/presenter.dart';
export 'package:flutter_clean_architecture/src/usecase.dart';
export 'package:flutter_clean_architecture/src/view.dart';
export 'package:flutter_clean_architecture/src/background_usecase.dart';


class FlutterCleanArchitecture {
  /// Retrieves a Controller from the widget tree if one exists
  /// Can be used in widgets that exist in pages and need to use the same controller
  static Con getController<Con extends Controller>(BuildContext context) {
    return Provider.of<Con>(context);
  }
}