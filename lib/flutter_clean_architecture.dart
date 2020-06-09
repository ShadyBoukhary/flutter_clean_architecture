library flutter_clean_architecture;

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/src/controller.dart';
import 'package:logging/logging.dart';
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

  /// Enables logging inside the `FlutterCleanArchitecture` package,
  static void debugModeOn() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      dynamic e = record.error;
      print('${record.loggerName}: ${record.level.name}: ${record.message} ');
      if (e != null) {
        print(e.toString());
      }
    });

<<<<<<< HEAD
    Logger.root.info('Logger initialized.');
=======
    Logger.root.info("Logger initialized.");
>>>>>>> 5a48f590c2e82682b6324085c66f3285102a48cd
  }
}
