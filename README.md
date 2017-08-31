# SimpleApi

SimpleApi is all in one framework for iOS written in Swift (includes [Realm](http://realm.io), [Alamofire](https://github.com/Alamofire/Alamofire), [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper), [AlamofireObjectMapper](https://github.com/tristanhimmelman/AlamofireObjectMapper), [ReachabilitySwift](https://github.com/ashleymills/Reachability.swift)). With SimpleApi you can easily call any REST API calls, parse its JSON response and directly save created object to Realm with one line of code without pain in the ass. It also informs you about internet connection changes via notifications or delegate method.

## About
I recommend you to use this framework with [Realm](http://realm.io) database and their [notifications](https://realm.io/docs/swift/latest/#notifications). That allows you to use SimpleApi without completion blocks, because you are notified through Realm database that your data has been refreshed.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory.
In the example you can see internet connection changes handling and simple data downloading.

## Requirements

- iOS 10.3+
- Xcode 8.1+
- Swift 3.0+

## Installation

SimpleApi is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'SimpleApi', :git => 'https://github.com/kkubkko/SimpleApi.git'
```

## Usage

Firstly, you have to import framework to your file

```swift
import SimpleApi
```

### Creating required object

Secondly, create required object of type `Object` implementing `Mappable` protocol.
More information about object mapping can be found [here](https://github.com/Hearst-DD/ObjectMapper)

```swift
class TestObject: Object, Mappable {
    dynamic var name = ""
    
    func mapping(map: Map) {
        name <- map["name"]
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
}
```

### Calling API
And the final step is to call a method for downloading objects.
This method use default parameters of SimpleApi calls, parses object from received JSON and saves it to Realm database.

```swift
SimpleApi.shared.get(type: TestObject.self, url: "url")
```

All parameters in the method call are optional so your method call can looks like above, but you can add all of parameters so it will look like this

```swift
SimpleApi.shared.get(type: TestObject.self,
                     url: "url",
                     method: .get,
                     parameters: ["param1" : "value1"],
                     paramsEncoding: .httpBody,
                     headers: ["token" : "tokenValue"],
                     saveResponseToRealm: false,
success: { (object) in
    print("I have received: \(object)")
}) { (apiError, error) in
    print("Api failed due to: \(apiError)")
}
```

There is also second method that you should use when you are expecting array of objects

```swift
SimpleApi.shared.getArray(type: TestObject.self, url: "url")
```

In case that you don't define parameters in method call, default parameters are used. You can edit them at the beginning, so every call will use them. Here they are

```swift
public var autoSaveToRealm: Bool = true
public var callLastApiCallAfterInternetComesBack = true
public var defaultMethod: CallMethod = .get
public var defaultParamEncoding: ParamsEncoding = .standard
public var defaultHeaders: [String: String]? = nil
```

### Internet connection changes
SimpleApi can also inform you about internet connection changes. This can be done via notifications or delegate methods.

```swift
//use notifications
NotificationCenter.default.addObserver(self, 
                                       selector: #selector(noInternet(sender:)),
                                       name: kNoInternetNotification,
                                       object: nil)
NotificationCenter.default.addObserver(self,
                                       selector: #selector(internetIsBack(sender:)),
                                       name: kInternetIsBackNotification,
                                       object: nil)
                                       
                                       
//or add delegate and implement delegate method
SimpleApi.shared.addDelegate(self)

func reachabilityChanged(sender: SimpleApi, isReachable: Bool, via: ConnectionType) {
    //behaviour here
}            
```


## Author

kkubkko, kkubkko@gmail.com
Pali tiež trochu pomohol...

## License

SimpleApi is available under the MIT license. See the LICENSE file for more info.