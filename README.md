# drawer-view [![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)

[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-yellow.svg)]()
[![Language](https://img.shields.io/badge/language-Swift-orange.svg)]()
[![Coverage](https://img.shields.io/badge/coverage-32%2C65%25-red.svg)]()
[![Documentation](https://img.shields.io/badge/docs-100%25-magenta.svg)]()
[![CocoaPod](https://img.shields.io/badge/pod-1.6.0-lightblue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)]()

**Last Update: 29/November/2018.**

![](logo-drawer_view.png)

# ✍️ About
📤 Drawer View is a custom UI component replication of Apple's Apple Music player and Shorcuts `components` view (also can be seen in `Maps` app).

# 🏗 Installation
## CocoaPods
`drawer-view` is availabe via `CocoaPods`

```
pod 'drawer-view', '~> 1.0.0' 
```
## Manual
You can always use `copy-paste` the sources method 😄. Or you can compile the framework and include it with your project.

# 📺 Example


# 🍱 Features

- **Easy to use** 
  - You only need to instantiate a class called `DrawerView` and add your UI components.
- **Flexible `API`**
  - Includes a number of customization points that allows to decorate the `DrawerView` as you'd like.
- **Callbacks**
  - You can use built-in callbacks in order to integrate animations or get the state changes.
- **Behavior** 
  - You may tell the component to close the drawer when the device is rotated or user interacts with the child components.
- **Autolayout**
  - You don't need to do anything related to autolayout - the component properly handles all the changes. The only thing you need to do is to add your `UI` components and make sure that aulayout constraints are properly setup for them.  

# 📚 Code Examples

## Instantiation

The most simple instantiation: you only need to provide the `superview`:
```swift
let _ = DrawerView(superView: view)
```

You can specify how much space will be between top anchor of the `DrawerView` and the `superview` by setting `bottomSpacing` property and how tall the `DrawerView` will be when it is closed by setting `closedHeight` property:
```swift
let _ = DrawerView(bottomSpacing: 100, closedHeight: 82, superView: view)
```

You can specify `blur` effect and its type. It will be animated alongside with the drawer view. There are several styles for `blur`:
```swift
let _ = DrawerView(blurStyle: .light, superView: view)
```

By default the `DrawerView` will include a visual indicator called `LineArrow`. `LineArrow` is an indicator that decorates the view and helps a user with interation. You can change the properties of the indicator by setting its `height`, `width` and `color`:
```swift
let _ = DrawerView(lineArrow: (height: 8, width: 82, color: .black), superView: view)
// Or you can set `nil` in order to turn the indicator off
```

You can change the behavior of the component when a device is rotated. By default the `DrawerView` will not be closed when a device is rotated. However, you can change this behavior:
```swift
drawerView.closeOnRotation = true
```

You can programmatically change the state of the component:
```swift
drawerView.change(state: .open, shouldAnimate: true)
```

By default, interactions with the child views don't affect the `DrawerView` anyhow. However, you can change this behavior and allow the `DrawerView` to be dismissed when one of the child views are interacted:
```swift
drawerView.closeOnChildViewTaps = true
```

There is an animation closure that is used to animate the external components alongside with the `DrawerView`:
```swift
drawerView.animationClosure = { state in
    switch state {
    case .open:
      someOtherView.alpha = 1.0
    case .closed:
      someOtherView.alpha = 0.0
  }
}
```

You can optionally specify a completion closure that gets called when animation is completed:
```swift
drawerView.completionClosure = { state in
  switch state {
    case .open:
      service.launch()
    case .closed:
      service.dismiss()
    }
}
```

The third and final callback closure can be used to get `DrawerView`state changes:
```swift
drawerView.onStateChangeClosure = { state in
  state == .closed ? showDialog() : doNothing()
}
```

Also there are many other properties that be customized:
```swift
drawerView.cornerRadius = 60
drawerView.animationDuration = 2.5
drawerView.animationDampingRatio = 0.9
drawerView.shadowRadius = 0.25
drawerView.shadowOpacity = 0.132
```

# 👨‍💻 Author 
[Astemir Eleev](https://github.com/jVirus)

# 🔖 Licence
The project is available under [MIT licence](https://github.com/jVirus/drawer-voew/blob/master/LICENSE)
