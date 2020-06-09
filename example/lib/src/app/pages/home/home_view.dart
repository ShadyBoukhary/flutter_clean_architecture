import './home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../data/repositories/data_users_repository.dart';

class HomePage extends View {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() =>
      // inject dependencies inwards
      _HomePageState();
}

class _HomePageState extends ViewState<HomePage, HomeController> {
  _HomePageState() : super(HomeController(DataUsersRepository()));

  @override
  Widget buildPage() {
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
              Text(
                // use data provided by the controller
                'Button pressed ${controller.counter} times.',
              ),
              Text(
                'The current user is',
              ),
              Text(
                controller.user == null ? '' : '${controller.user}',
                style: Theme.of(context).textTheme.headline4,
              ),
              RaisedButton(
                onPressed: controller.getUser,
                child: Text(
                  'Get User',
                  style: TextStyle(color: Colors.white),
                ),
                color: Colors.blue,
              ),
              RaisedButton(
                onPressed: controller.getUserwithError,
                child: Text(
                  'Get User Error',
                  style: TextStyle(color: Colors.white),
                ),
                color: Colors.blue,
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.buttonPressed(),
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
