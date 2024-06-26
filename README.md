# glide-swift-sdk



## Introduction

`glide-swift-sdk` is our SDK for integrating with our systems


## Installation

### Cocoapods

[Cocoapods](https://cocoapods.org/#install) is a dependency manager for Swift projects. To use glide-swift-sdk with CocoaPods, add it in your `Podfile`.

```ruby
pod 'glide-swift-sdk'
```


### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. To use glide-swift-sdk with Swift Package Manger, add it to `dependencies` in your `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/ClearBlockchain/glide-swift-sdk.git")
]
```


## Usage

Firstly, import `glide_swift_sdk`.

```swift
import glide_swift_sdk
```

Second, configure the SDK, recommended in `didFinishLaunchingWithOptions` in `AppDelegare.swift`.

```swift
Glide.configure()
```


