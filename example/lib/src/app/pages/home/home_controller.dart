import 'package:example/src/app/pages/home/home_presenter.dart';
import 'package:example/src/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

class HomeController extends Controller {

  int _counter;
  User _user;
  int get counter => _counter;
  User get user => _user;
  final HomePresenter homePresenter;
  HomeController(usersRepo): _counter = 0, homePresenter = HomePresenter(usersRepo), super();

  @override
  void initListeners() {
    homePresenter.getUserOnNext = (User user) { 
      print(user.toString());
      _user = user;
      refreshUI();
    };
    homePresenter.getUserOnComplete = () { 
      print('User retrieved');
    };

    homePresenter.getUserOnError = (e) { 
      print('Could not retrieve user.');
      ScaffoldState state = getState();
      state.showSnackBar(SnackBar(content: Text(e.message)));
      _user = null;
      refreshUI();
    };
  }

  void getUser() => homePresenter.getUser('test-uid');
  void getUserwithError() => homePresenter.getUser('test-uid231243');

  void buttonPressed() {
    _counter++;
  }
  
  @override
  void dispose() {
    homePresenter.dispose();
    super.dispose();
  }
  
}