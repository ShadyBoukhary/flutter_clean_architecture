## [3.0.0] - Wednesday, January 8th, 2020


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
