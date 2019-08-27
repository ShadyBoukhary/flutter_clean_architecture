# flutter_clean_architecture Package
[![CircleCI](https://circleci.com/gh/ShadyBoukhary/flutter_clean_architecture.svg?style=shield)](https://circleci.com/gh/ShadyBoukhary/flutter_clean_architecture) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) ![pub package](https://img.shields.io/pub/v/flutter_clean_architecture.svg)

## Overview
A Flutter package that makes it easy and intuitive to implement [Uncle Bob's Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) in Flutter. This package provides basic classes that are tuned to work with Flutter and are designed according to the Clean Architecture.

## Installation

### 1. Depend on It
Add this to your package's pubspec.yaml file:

```yaml

dependencies:
  flutter_clean_architecture: ^1.0.4

```

### 2. Install it
You can install packages from the command line:

with Flutter:

```shell
$ flutter packages get
```

Alternatively, your editor might support `flutter packages get`. Check the docs for your editor to learn more.

### 3. Import it
Now in your Dart code, you can use:

```dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
```

## Flutter Clean Architecture Primer
### Introduction
It is architecture based on the book and blog by Uncle Bob. It is a combination of concepts taken from the Onion Architecture and other architectures. The main focus of the architecture is separation of concerns and scalability. It consists of four main modules: `App`, `Domain`, `Data`, and `Device`.

### The Dependency Rule
**Source code dependencies only point inwards**. This means inward modules are neither aware of nor dependent on outer modules. However, outer modules are both aware of and dependent on inner modules. Outer modules represent the mechanisms by which the business rules and policies (inner modules) operate. The more you move inward, the more abstraction is present. The outer you move the more concrete implementations are present. Inner modules are not aware of any classes, functions, names, libraries, etc.. present in the outer modules. They simply represent **rules** and are completely independent from the implementations.

### Layers

#### Domain
The `Domain` module defines the business logic of the application. It is a module that is independent from the development platform i.e. it is written purely in the programming language and does not contain any elements from the platform. In the case of `Flutter`, `Domain` would be written purely in `Dart` without any `Flutter` elements. The reason for that is that `Domain` should only be concerned with the business logic of the application, not with the implementation details. This also allows for easy migration between platforms, should any issues arise.

##### Contents of Domain
`Domain` is made up of several things.
* **Entities**
  * Enterprise-wide business rules
  * Made up of classes that can contain methods
  * Business objects of the application
  * Used application-wide
  * Least likely to change when something in the application changes
* **Usecases**
  * Application-specific business rules
  * Encapsulate all the usecases of the application
  * Orchestrate the flow of data throughout the app
  * Should not be affected by any UI changes whatsoever
  * Might change if the functionality and flow of application change
* **Repositories**
  * Abstract classes that define the expected functionality of outer layers
  * Are not aware of outer layers, simply define expected functionality
    * E.g. The `Login` usecase expects a `Repository` that has `login` functionality
  * Passed to `Usecases` from outer layers

`Domain` represents the inner-most layer. Therefore, it the most abstract layer in the architecture.

#### App
`App` is the layer outside `Domain`. `App` crosses the bounderies of the layers to communicate with `Domain`. However, the **Dependency Rule** is never violated. Using `polymorphism`, `App` communicates with `Domain` using inherited class: classes that implement or extend the `Repositories` present in the `Domain` layer. Since `polymorphism` is used, the `Repositories` passed to `Domain` still adhere to the **Dependency Rule** since as far as `Domain` is concerned, they are abstract. The implementation is hidden behind the `polymorphism`.

##### Contents of App
Since `App` is the presentation layer of the application, it is the most framework-dependent layer, as it contains the UI and the event handlers of the UI. For every page in the application, `App` defines at least 3 classes: a `Controller`, a `Presenter`, and a `View`.

* **View**
  * Represents only the UI of the page. The `View` builds the page's UI, styles it, and depends on the `Controller` to handle its events. The `View` **has-a** `Controller`.
  * In the case of Flutter
    * The `View` is comprised of 2 classes
      * One that extends `View`, which would be the root `Widget` representing the `View`
      * One that extends `ViewState` with the template specialization of the other class and its `Controller`. 
    * The `ViewState` contains the `build` method, which is technically the UI
    * `StatefulWidget` contains the `State` as per `Flutter`
    * The `StatefulWidget` only serves to pass arguments to the `State` from other pages such as a title etc.. It only instantiates the `State` object (the `ViewState`) and provides it with the `Controller` it needs.
    * The `StatefulWidget`  **has-a** `State` object (the `ViewState`) which **has-a** `Controller`
    * In summary, both the `StatefulWidget` and the `State` are represented by a  `View` and `ViewState` of the page.
    * The `ViewState` class maintains a `GlobalKey` that can be used as a key in its scaffold. If used, the `Controller` can easily access it via `getState()` in order to show snackbars and other dialogs. This is helpful but optional.
    * 
* **Controller**
  * Every `ViewState` **has-a** `Controller`. The `Controller` provides the needed member data of the `ViewState` i.e. dynamic data. The `Controller` also implements the event-handlers of the `ViewState` widgets, but has no access to the `Widgets` themselves. The `ViewState` uses the `Controller`, not the other way around. When the `ViewState` calls a handler from the `Controller`, it wraps it with a `callHandler(fn)` function if the `ViewState` needs to be rebuilt by calling `setState()` before calling the event-handler. The `callHandler(fn)` method will handle refreshing the state.
  * Every `Controller` extends the `Controller` abstract class, which implements `WidgetsBindingObserver`. Every `Controller` class is responsible for handling lifecycle events for the `View` and can override:
    * **void onInActive()**
    * **void onPaused()** 
    * **void onResumed()** 
    * **void onSuspending()**
    * **void onDidPop()**
    * etc..
  * Also, every `Controller` **has** to implement **initListeners()** that initializes the listeners for the `Presenter` for consistency.
  * The `Controller` **has-a** `Presenter`. The `Controller` will pass the `Repository` to the `Presenter`, which it communicate later with the `Usecase`. The `Controller` will specify what listeners the `Presenter` should call for all success and error events as mentioned previously. Only the `Controller` is allowed to obtain instances of a `Repository` from the `Data` or `Device` module in the outermost layer.
  * The `Controller` has access to the `ViewState` and can refresh the UI via `refreshUI()`. Alternatively, handlers can be wrapped in `callHandler()` which automatically refreshes the UI after it's completed.
* **Presenter**
  * Every `Controller` **has-a** `Presenter`. The `Presenter` communicates with the `Usecase` as mentioned at the beginning of the `App` layer. The `Presenter` will have members that are functions, which are optionally set by the `Controller` and will be called if set upon the `Usecase` sending back data, completing, or erroring.
  * The `Presenter` is comprised of two classes
    * `Presenter` e.g. `LoginPresenter`
      * Contains the event-handlers set by the `Controller`
      * Contains the `Usecase` to be used
      * Intitializes and executes the usecase with the `Observer<T>` class and the appropriate arguments. E.g. with `username` and `password` in the case of a `LoginPresenter`
    * A class that implements `Observer<T>`
      * Has reference to the `Presenter` class. Ideally, this should be an inner class but `Dart` does not yet support them.
      * Implements 3 functions
        * **onNext(T)**
        * **onComplete()**
        * **onError()**
      * These 3 methods represent all possible outputs of the `Usecase`
        * If the `Usecase` returns an object, it will be passed to `onNext(T)`. 
        * If it errors, it will call `onError(e)`. 
        * Once it completes, it will call `onComplete()`. 
       * These methods will then call the corresponding methods of the `Presenter` that are set by the `Controller`. This way, the event is passed to the `Controller`, which can then manipulate data and update the `ViewState`
* Extra
  * `Utility` classes (any commonly used functions like timestamp getters etc..)
  * `Constants` classes (`const` strings for convenience)
  * `Navigator` (if needed)
  
#### Data
Represents the data-layer of the application. The `Data` module, which is a part of the outermost layer, is responsible for data retrieval. This can be in the form of API calls to a server, a local database, or even both. 

##### Contents of Data
* **Repositories**
  * Every `Repository` **should** implement `Repository` from the **Domain** layer.
  * Using `polymorphism`, these repositories from the data layer can be passed accross the bounderies of layers, starting from the `View` down to the `Usecases` through the `Controller` and `Presenter`.
  * Retrieve data from databases or other methods. 
  * Responsible for any API calls and high-level data manipulation such as
    * Registering a user with a database
    * Uploading data
    * Downloading data
    * Handling local storage
    * Calling an API
* **Models** (not a must depending on the applicaiton)
  * Extensions of `Entities` with the addition of extra members that might be platform-dependent. For example, in the case of local databases, this can be manifested as an `isDeleted` or an `isDirty` entry in the local database. Such entries cannot be present in the `Entities` as that would violate the **Dependency Rule** since **Domain** should not be aware of the implementation.
  * In the case of our application, models in the `Data` layer will not be necessary as we do not have a local database. Therefore, it is unlikely that we will need extra entries in the `Entities` that are platform-dependent.
* **Mappers**
  * Map `Entity` objects to `Models` and vice-versa.
  * Static classes with static methods that receive either an `Entity` or a `Model` and return the other.
  * Only necessary in the presence of `Models`
* Extra
  * `Utility` classes if needed
  * `Constants` classes if needed

#### Device
Part of the outermost layer, `Device` communicates directly with the platform i.e. Android and iOS. `Device` is responsible for Native functionality such as `GPS` and other functionality present within the platform itself like the filesystem. `Device` calls all Native APIs. 

##### Contents of Data
* **Devices**
  * Similar to `Repositories` in `Data`, `Devices` are classes that communicate with a specific functionality in the platform.
  * Passed through the layers the same way `Repositories` are pass across the bounderies of the layer: using polymorphism between the `App` and `Domain` layer. That means the `Controller` passes it to the `Presenter` then the `Presenter` passes it polymorphically to the `Usecase`, which recieves it as an abstract class.
* Extra
  * `Utility` classes if needed
  * `Constants` classes if needed
## Usage

### Folder structure

```
lib/
    app/                          <--- application layer
        pages/                        <-- pages or screens
          login/                        <-- some page in the app
            login_controller.dart         <-- login controller extends `Controller`
            login_presenter.dart          <-- login presenter extends `Presenter`
            login_view.dart               <-- login view, 2 classes extend `View` and `ViewState` resp.
        widgets/                      <-- custom widgets
        utils/                        <-- utility functions/classes/constants
        navigator.dart                <-- optional application navigator
    data/                         <--- data layer
        repositories/                 <-- repositories (retrieve data, heavy processing etc..)
          data_auth_repo.dart           <-- example repo: handles all authentication
        helpers/                      <-- any helpers e.g. http helper
        constants.dart                <-- constants such as API keys, routes, urls, etc..
    device/                       <--- device layer
        repositories/                 <--- repositories that communicate with the platform e.g. GPS
        utils/                        <--- any utility classes/functions
    domain/                       <--- domain layer (business and enterprise) PURE DART
        entities/                   <--- enterprise entities (core classes of the app)
          user.dart                   <-- example entity
          manager.dart                <-- example entity
        usecases/                   <--- business processes e.g. Login, Logout, GetUser, etc..
          login_usecase.dart          <-- example usecase extends `UseCase` or `CompletableUseCase`
        repositories/               <--- abstract classes that define functionality for data and device layers
    main.dart                     <--- entry point

```

### Example Code
Checkout a small example [here](./example/) and a full application built [here](https://github.com/ShadyBoukhary/Axion-Technologies-HnH).

#### View 

```dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
class CounterPage extends View {
    @override
     // Dependencies can be injected here
     State<StatefulWidget> createState() => CounterState(CounterState());
}

class CounterState extends ViewState<CounterPage, CounterController> {
     CounterState(CounterController controller) : super(controller);

     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         title: 'Flutter Demo',
      home: Scaffold(
        key: globalKey, // using the built-in global key of the `View` for the scaffold or any other
                        // widget provides the controller with a way to access them via getContext(), getState(), getStateKey()
        body: Column(
          children: <Widget>[
            Center(
              // show the number of times the button has been clicked
              child: Text(controller.counter.toString()),
            ),
            // wrapping the controller.increment with callHandler() automatically
            // refreshes the state after the counter is incremented
            // you can also refresh manually inside the controller
            // using refreshUI()
            MaterialButton(onPressed: () => callHandler(controller.increment)),
            FlatButton(onPressed: () => controller.login, child: Text('Login')),

          ],
        ),
      ),
    );
  }
}
```
#### Controller 

```dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

class CounterController extends Controller {
  int counter;
  final LoginPresenter presenter;
  CounterController() : counter = 0, presenter = LoginPresenter(), super();

  void increment() {
    counter++;
  }

  /// Shows a snackbar
  void showSnackBar() {
    ScaffoldState scaffoldState = getState(); // get the state, in this case, the scaffold
    scaffoldState.showSnackBar(SnackBar(content: Text('Hi')));
  }

  @override
  void initListeners() {
    // Initialize presenter listeners here
    // These will be called upon success, failure, or data retrieval after usecase execution
     presenter.loginOnComplete = () => print('Login Successful');
     presenter.loginOnError = (e) => print(e);
     presenter.loginOnNext = () => print("onNext");
  }

  void login() {
      // pass appropriate credentials here
      // assuming you have text fields to retrieve them and whatnot
      presenter.login();
  }
}

```
#### Presenter
```dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

class LoginPresenter() {

  Function loginOnComplete; // alternatively `void loginOnComplete();`
  Function loginOnError;
  Function loginOnNext; // not needed in the case of a login presenter

  final LoginUseCase loginUseCase;
  // dependency injection from controller
  LoginPresenter(authenticationRepo): loginUseCase = LoginUseCase(authenticationRepo);

  /// login function called by the controller
  void login(String email, String password) {
    loginUseCase.execute(_LoginUseCaseObserver(this), LoginUseCaseParams(email, password));
  }

   /// Disposes of the [LoginUseCase] and unsubscribes
   @override
   void dispose() {
     _loginUseCase.dispose();
   }
}

/// The [Observer] used to observe the `Observable` of the [LoginUseCase]
class _LoginUseCaseObserver implements Observer<void> {

  // The above presenter
  // This is not optimal, but it is a workaround due to dart limitations. Dart does
  // not support inner classes or anonymous classes.
  final LoginPresenter loginPresenter;

  _LoginUseCaseObserver(this.loginPresenter);

  /// implement if the `Observable` emits a value
  // in this case, unnecessary
  void onNext(_) {}

  /// Login is successfull, trigger event in [LoginController]
  void onComplete() {
    // any cleaning or preparation goes here
    assert(loginPresenter.loginOnComplete != null);
    loginPresenter.loginOnComplete();

  }

  /// Login was unsuccessful, trigger event in [LoginController]
  void onError(e) {
    // any cleaning or preparation goes here
    assert(loginPresenter.loginOnError != null);
    loginPresenter.loginOnError(e);
  }
}

```
#### UseCase
```dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

// In this case, no parameters were needed. Hence, void. Otherwise, change to appropriate.
class LoginUseCase extends CompletableUseCase<LoginUseCaseParams> {
  final AuthenticationRepository _authenticationRepository; // some dependency to be injected
                                          // the functionality is hidden behind this
                                          // abstract class defined in the Domain module
                                          // It should be implemented inside the Data or Device
                                          // module and passed polymorphically.

  LoginUseCase(this._authenticationRepository);

  @override
  // Since the parameter type is void, `_` ignores the parameter. Change according to the type
  // used in the template.
  Future<Observable<void>> buildUseCaseObservable(params) async {
    final StreamController controller = StreamController();
    try {
        // assuming you pass credenntials here
      await _authenticationRepository.authenticate(email: params.email, password: params.password);
      logger.finest('LoginUseCase successful.');
      // triggers onComplete
      controller.close();
    } catch (e) {
      print(e);
      logger.severe('LoginUseCase unsuccessful.');
      // Trigger .onError
      controller.addError(e);
    }
    return Observable(controller.stream);
  }
}

class LoginUseCaseParams {
    final String email;
    final String password;
    LoginUseCaseParams(this.email, this.password);
}
```

#### Repository in Domain

```dart

abstract class AuthenticationRepository {
  Future<void> register(
      {@required String firstName,
      @required String lastName,
      @required String email,
      @required String password});

  /// Authenticates a user using his [username] and [password]
  Future<void> authenticate(
      {@required String email, @required String password});

  /// Returns whether the [User] is authenticated.
  Future<bool> isAuthenticated();

  /// Returns the current authenticated [User].
  Future<User> getCurrentUser();

  /// Resets the password of a [User]
  Future<void> forgotPassword(String email);

  /// Logs out the [User]
  Future<void> logout();
}

```
This repository should be implemented in **Data** layer

```dart

class DataAuthenticationRepository extends AuthenticationRepository {
  // singleton
  static DataAuthenticationRepository _instance = DataAuthenticationRepository._internal();
  DataAuthenticationRepository._internal();
  factory DataAuthenticationRepository() => _instance;

    @override
  Future<void> register(
      {@required String firstName,
      @required String lastName,
      @required String email,
      @required String password}) {
          // TODO: implement
      }

  /// Authenticates a user using his [username] and [password]
  @override
  Future<void> authenticate(
      {@required String email, @required String password}) {
          // TODO: implement
      }

  /// Returns whether the [User] is authenticated.
  @override
  Future<bool> isAuthenticated() {
      // TODO: implement
  }

  /// Returns the current authenticated [User].
  @override
  Future<User> getCurrentUser() {
      // TODO: implement
  }

  /// Resets the password of a [User]
  @override
  Future<void> forgotPassword(String email) {
      // TODO: implement
  }

  /// Logs out the [User]
  @override
  Future<void> logout() {
      // TODO: implement
  }
}
```
If the repository is platform-related, implement it in the **Device** layer.

#### Entity 
Defined in **Domain** layer.
```dart

class User {
    final String name;
    final String email;
    final String uid;
    User(this.name, this.email, this.uid);
}

```

Checkout a small example [here](./example/) and a full application built [here](https://github.com/ShadyBoukhary/Axion-Technologies-HnH).

## Authors
**Shady Boukhary** 
