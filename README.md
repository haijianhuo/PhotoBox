# PhotoBox
Cloud Photos for iOS.

## About

PhotoBox is written in Swift 3/Objective C.

The following design patterns or skills were used:

Creational: Singleton.
Structural: MVC, Decorator (Extensions and Delegation), Facade.

Behavioral: Observer (notifications, KVO), Memento (NSUserDefaults).


KVC, RESTfull API.

Core data stack with collection view.

Data sync with cloud for all devices.

Storyboard adaptive auto layout with size classes.

Swift cocoapods.

Objective C cocoapods/classes via bridging header or import.

Cloud services with 3rd party iOS SDK.

## How to run the app

Sign up at https://backendless.com/ to get a free Backendless cloud server account.
Create an iOS app on your account. 
Replace the APP_ID and SECRET_KEY in BackendlessClient.swift with the Application ID and the iOS Secret Key from your account.
Build and run the app with Xcode, the server side table schema will be created automatically once the first photo is uploaded.

## Requirements

- iOS 9.0+
- Xcode 8.3.2
