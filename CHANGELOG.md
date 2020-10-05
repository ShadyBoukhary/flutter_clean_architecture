## [4.0.2] - Monday, October 5th, 2020
- Updated example android build requirements for flutter 1.22
- Created `didChangeViewDependencies` on `ViewState` to enable access to controller on `didChangeDependencies`

## [4.0.1] - Sunday, September 27st, 2020
- Created `initViewState` on `ViewState` to enable access to controller on initialize.

## [4.0.0] - Thursday, September 24st, 2020
### What's New
- Created `ControlledWidget` to create `StatelessWidgets` refreshable by `Controller`
    - Now, to create refreshable widgets, use `ControlledWidget` builder.
    - When `Controller.refreshUI` is called, only `ControlledWidgets` will re-render
    - To create controlled `StatefulWidgets`, please check `FlutterCleanArchitecture.getController` approach
- Improves `ResponsiveViewState` with watch interface
- Added `FlutterCleanArchitecture.setDefaultViewBreakpoints` to configure view breakpoints globally
- Added `mobileBuilder` to `ResponsiveViewState`
- Added `tabletBuilder` to `ResponsiveViewState`
- Added `desktopBuilder` to `ResponsiveViewState`
- Added `watchBuilder` to `ResponsiveViewState`

### Breaking Changes
- Removed getter `controller` from `ViewState`
- Removed `buildTabletView()`
- Removed `buildMobileView()`
- Removed `buildDesktopView()`

## [3.1.1] - Monday, September 21st, 2020

- Added an option to pass listen:false when calling getController() outside of the build method.

## [3.1.0] - Monday, June 8th, 2020
- Created Github Actions to run analyze and tests on package
- Created responsive view to improve the usage on flutter web
- Fixed lint rules to fit pedantic 1.9.0

## [3.0.2] - Wednesday, January 8th, 2020

- OnResumed bug fix

## [3.0.1] - Wednesday, January 8th, 2020

- Fixed typo in documentation.

## [3.0.0] - Wednesday, January 8th, 2020
### What's New
- Improves performance of the library by using the [Provider package](https://pub.dev/packages/provider) internally.
- Added an option to enable debug mode via `FlutterCleanArchitecture.debugModeOn()`
- Added the ability to use a common `Controller` for widgets that exist within a page.
The widgets can access the `Controller` in the tree via the `FlutterCleanArchitecture.getController<Controller>(context)` method.

### Breaking Changes
- `ViewState`'s `build()` method can no longer be overridden.
- `ViewState` UI code must now go into `buildPage()` method.
- `callHandler()` is now removed
- Removed `loadOnStart()`
- Removed `startLoading()`
- Removed `dismissLoading()`

## [2.0.2] - Thursday, December 26th, 2019

* Fixed an issue where `Controller.getContext()` throws due to losing context because lifecycle events where triggered after the `View` had already been dismounted.

## [2.0.1] - Thursday, December 26th, 2019

* Fixed error in docs

## [2.0.0] - Thursday, December 26th, 2019

* Updated RxDart dependency
* Breaking changes
  * All Observable return types are now changed to Streams
* Updated documentation

## [1.1.0] - Tuesday, December 17th, 2019

* Added the ability to create a usecase that executes on a different isolate.
    * `BackgroundUseCase`
        * Usecase class that executes on a different isolate
        * Create a static method in the class that conforms to `UseCaseTask` signature
        * Return the reference to that method inside the `buildUseCaseTask` method
    * `BackgroundUseCaseParameters`
        * Contains the input data provided to to the isolate
        * Passed to the static method as a parameter
    * `BackgroundUseCaseMessage`
        * Provides output data and information such as completion status and errors
    * The usecase usage in the presenter does not change, this class can be used identically
    * Check `README.md` for more details
* Added and improved documentation
* Updated README.md

## [1.0.8] - Tuesday, December 12th, 2019

* Bug fix

## [1.0.7] - Tuesday, December 12th, 2019

* Bug fix

## [1.0.6] - Tuesday, December 11th, 2019

* Flutter v1.12.5 compatibility
* Changed onSuspending to onDetatched

## [1.0.5] - Tuesday, August 27th, 2019

* Updated dependencies

## [1.0.4] - Tuesday, August 27th, 2019

* Updated dependencies

## [1.0.3] - Tuesday, July 2nd, 2019

* Add missing files to example

## [1.0.2] - Thursday, May 9th, 2019

* Fixed documentation typos
* Changed misleading assertion messages
* Cleaned documentation

## [1.0.1] - Tuesday, April 30th, 2019

* Fixed documentation typos

## [1.0.0] - Tuesday, April 30th, 2019

* Added example application
* Addded documentation

## [0.0.1] - Tuesday, April 30th, 2019

* Implementation of the Clean Architecture by Uncle Bob in Flutter Library
  * View class
  * Controller class
  * Presenter class
  * UseCase class
  * Observer class
* Can be used to set up a Flutter project using the Clean Architecture
