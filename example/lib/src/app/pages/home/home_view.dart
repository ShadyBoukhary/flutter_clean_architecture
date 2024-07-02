import './home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart' as clean;
import '../../../data/repositories/data_users_repository.dart';

class HomePage extends clean.View {
  const HomePage({Key? key, this.title = ""}) : super(key: key);

  final String title;

  @override
  HomePageState createState() =>
      // inject dependencies inwards
      HomePageState();
}

class HomePageState extends clean.ViewState<HomePage, HomeController> {
  HomePageState() : super(HomeController(DataUsersRepository()));

  @override
  Widget get view {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Scaffold(
        key:
            globalKey, // built in global key for the ViewState for easy access in the controller
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              clean.ControlledWidgetBuilder<HomeController>(
                builder: (context, controller) {
                  return Text(
                    'Button pressed ${controller.counter} times.',
                  );
                },
              ),
              const Text(
                'The current user is',
              ),
              clean.ControlledWidgetBuilder<HomeController>(
                builder: (context, controller) {
                  return Text(
                    controller.user == null ? '' : '${controller.user}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
              clean.ControlledWidgetBuilder<HomeController>(
                builder: (context, controller) {
                  return ElevatedButton(
                    onPressed: controller.getUser,
                    child: const Text(
                      'Get User',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
              clean.ControlledWidgetBuilder<HomeController>(
                builder: (context, controller) {
                  return ElevatedButton(
                    onPressed: controller.getUserwithError,
                    child: const Text(
                      'Get User Error',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: clean.ControlledWidgetBuilder<HomeController>(
        builder: (context, controller) {
          return FloatingActionButton(
            onPressed: () => controller.buttonPressed(),
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          );
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
