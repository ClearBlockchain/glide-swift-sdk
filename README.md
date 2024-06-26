# GlideSwiftSDK



## Introduction

`GlideSwiftSDK` is our SDK for integrating with our systems


## Installation

### Cocoapods

[Cocoapods](https://cocoapods.org/#install) is a dependency manager for Swift projects. To use GlideSwiftSDK with CocoaPods, add it in your `Podfile`.

```ruby
pod 'GlideSwiftSDK'
```


### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. To use GlideSwiftSDK with Swift Package Manger, add it to `dependencies` in your `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/ClearBlockchain/GlideSwiftSDK.git")
]
```


## Usage

Firstly, import `GlideSwiftSDK`.

```swift
import GlideSwiftSDK
```

Second, configure the SDK, recommended in `didFinishLaunchingWithOptions` in `AppDelegare.swift`.

```swift
Glide.configure()
```


