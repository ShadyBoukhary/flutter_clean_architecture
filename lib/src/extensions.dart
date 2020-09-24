import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './controller.dart';

extension ConsumerWidget<Con extends Controller> on Widget {
  Widget get consumerWidget => Consumer<Con>(builder: (ctx, _, __) => this);
}
