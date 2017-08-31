//
//  ApiManager.swift
//  Pods
//
//  Created by Jakub Kozák on 30/08/2017.
//
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import RealmSwift
import ObjectMapper
import ReachabilitySwift

public let kNoInternetNotification = Notification.Name(rawValue: "kNoInternetNotification")
public let kInternetIsBackNotification = Notification.Name(rawValue: "kInternetIsBackNotification")

/** Api manager class
 - important: Use as singleton only with attribute **.shared**
 */
public class SimpleApi: NSObject {
    
    //MARK: - public attributes
    public var autoSaveToRealm: Bool = true {
        didSet{ saveToRealm() }
    }
    public var callLastApiCallAfterInternetComesBack = true {
        didSet{ saveToRealm() }
    }
    public var defaultMethod: CallMethod = .get {
        didSet{ saveToRealm() }
    }
    public var defaultParamEncoding: ParamsEncoding = .standard {
        didSet{ saveToRealm() }
    }
    public var defaultHeaders: [String: String]? = nil {
        didSet{ saveToRealm() }
    }
    public static let shared = SimpleApi()
    
    //MARK: - private attributes
    private let reachability = Reachability()!
    private var firstChange:Bool = true
    private var lastCalled:()->Void = {}
    private var delegates:[SimpleApiDelegate] = []
    private var isLoading:Bool = false
    
    typealias successParam = ()->Void
    typealias failureParam = (_ error:String)->Void
    
    //MARK: - basic
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(sender:)), name: ReachabilityChangedNotification, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
        loadFromRealm()
    }
    
    deinit {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    //MARK: - generic calls
    /**
     - important: All params except **type** and **url** are optional
     - parameters:
         - type: Object type
         - url: String with url
         - method: Use this parameter in your method call if you want to override *defaultMethod* property
         - parameters: Call parameters in `[String:Any]` format
         - paramsEncoding: Use this parameter in your method call if you want to override *defaultParamEncoding* property
         - headers: Use this parameter in your method call if you want to override *defaultHeaders* property
         - saveResponseToRealm: Use this parameter in your method call if you want to override *automaticalySaveToRealm* property
         - success: Success completion block with received object
         - object: Object that is included in success completion block
         - fail: Failure completion block with *SimpleApiError* param. If this param is **.fail**, additional *Error* param is included
         - apiError: Always included in fail block
         - error: Appears in fail block if *apiErrors* value is **.fail**
     */
    public func get <T:Object>(type:T.Type,
              url:String,
              method:CallMethod? = nil,
              parameters:[String: Any]? = nil,
              paramsEncoding:ParamsEncoding? = nil,
              headers:[String: String]? = nil,
              saveResponseToRealm:Bool? = nil,
              success:@escaping (_ object:T)->Void = {_ in },
              fail:@escaping (_ apiError:SimpleApiError, _ error:Error?)->Void = {_ in })
        where T:Mappable {
            
            if isReachable() == false {
                lastCalled = { self.get(type: type, url: url, method: method, parameters: parameters, paramsEncoding: paramsEncoding, headers: headers, saveResponseToRealm: saveResponseToRealm, success: success, fail: fail) }
                fail(.noInternet, nil)
                return
            }
            
            //params preparation
            let al_method = method == nil ? HTTPMethod(rawValue: defaultMethod.rawValue)! : HTTPMethod(rawValue: method!.rawValue)!
            let encoding = paramsEncoding == nil ? defaultParamEncoding : paramsEncoding
            let al_encoding = encoding == .standard ? URLEncoding.default : URLEncoding.httpBody
            let al_headers = headers == nil ? defaultHeaders : headers
            
            Alamofire.request(url, method: al_method, parameters: parameters, encoding: al_encoding, headers: al_headers).responseObject { (response: DataResponse<T>) in
                switch response.result {
                case .success(_):
                    guard (response.result.value != nil) else {
                        fail(.emptyResponse, nil)
                        return
                    }
                    let shouldSaveToRealm = saveResponseToRealm == nil ? self.autoSaveToRealm : saveResponseToRealm!
                    if shouldSaveToRealm {
                        DispatchQueue.background.async {
                            let object = response.result.value!
                            DataManager.shared.save(object: object)
                            success(object)
                        }
                    } else {
                        let object = response.result.value!
                        success(object)
                    }
                case .failure(let error):
                    fail(.fail, error)
                }
            }
    }
    
    /**
     - important: All params except **type** and **url** are optional
     - parameters:
         - type: Object type
         - url: String with url
         - method: Use this parameter in your method call if you want to override *defaultMethod* property
         - parameters: Call parameters in `[String:Any]` format
         - paramsEncoding: Use this parameter in your method call if you want to override *defaultParamEncoding* property
         - headers: Use this parameter in your method call if you want to override *defaultHeaders* property
         - saveResponseToRealm: Use this parameter in your method call if you want to override *automaticalySaveToRealm* property
         - success: Success completion block with received object
         - objects: Objects that are included in success completion block
         - fail: Failure completion block with *SimpleApiError* param. If this param is **.fail**, additional *Error* param is included
         - apiError: Always included in fail block
         - error: Appears in fail block if *apiErrors* value is **.fail**
     */
    public func getArray<T:Object>(type:T.Type,
                          url:String,
                          method:CallMethod? = nil,
                          parameters:[String: Any]? = nil,
                          paramsEncoding:ParamsEncoding? = nil,
                          headers:[String: String]? = nil,
                          saveResponseToRealm:Bool? = nil,
                          success:@escaping (_ objects:[T])->Void = {_ in },
                          fail:@escaping (_ apiError:SimpleApiError, _ error:Error?)->Void = {_ in }) where T:Mappable {
        if isReachable() == false {
            lastCalled = { self.getArray(type: type, url: url, method: method, parameters: parameters, paramsEncoding: paramsEncoding, headers: headers, saveResponseToRealm: saveResponseToRealm, success: success, fail: fail) }
            fail(.noInternet, nil)
            return
        }
        
        //params preparation
        let al_method = method == nil ? HTTPMethod(rawValue: defaultMethod.rawValue)! : HTTPMethod(rawValue: method!.rawValue)!
        let encoding = paramsEncoding == nil ? defaultParamEncoding : paramsEncoding
        let al_encoding = encoding == .standard ? URLEncoding.default : URLEncoding.httpBody
        let al_headers = headers == nil ? defaultHeaders : headers
        
        Alamofire.request(url, method: al_method, parameters: parameters, encoding: al_encoding, headers: al_headers).responseArray { (response: DataResponse<[T]>) in
            switch response.result {
            case .success(_):
                guard (response.result.value != nil) else {
                    fail(.emptyResponse, nil)
                    return
                }
                let shouldSaveToRealm = saveResponseToRealm == nil ? self.autoSaveToRealm : saveResponseToRealm!
                if shouldSaveToRealm {
                    DispatchQueue.background.async {
                        let objectsArr = response.result.value!
                        DataManager.shared.save(objects: objectsArr)
                        success(objectsArr)
                    }
                } else {
                    let objectsArr = response.result.value!
                    success(objectsArr)
                }
            case .failure(let error):
                fail(.fail, error)
            }
        }
    }
    
    //MARK: - Reachability
    func reachabilityChanged(sender: NSNotification) {
        
        let reachability = sender.object as! Reachability
        
        if reachability.isReachable {
            //on first change, don't react to the notification of connection change
            if firstChange == true {
                firstChange = false
                return
            }
            
            if self.callLastApiCallAfterInternetComesBack {
                lastCalled()
            }
            NotificationCenter.default.post(Notification(name: kInternetIsBackNotification))
            if reachability.isReachableViaWiFi {
                reachabilityNotifyDelegates(internetConnection: true, via: .wifi)
            } else {
                reachabilityNotifyDelegates(internetConnection: true, via: .cellular)
            }
        } else {
            NotificationCenter.default.post(Notification(name: kNoInternetNotification))
            reachabilityNotifyDelegates(internetConnection: false, via: .noInternet)
        }
    }
    
    public func isReachable()->Bool{
        return reachability.isReachable
    }
    
    //MARK: - delegates handling
    public func addDelegate(_ delegate:SimpleApiDelegate) {
        self.delegates.append(delegate)
    }
    
    public func removeDelegate(_ delegate:SimpleApiDelegate) {
        if let index = self.delegates.index(where: { (item) -> Bool in item === delegate }) {
            self.delegates.remove(at: index)
        }
    }
    
    private func reachabilityNotifyDelegates(internetConnection:Bool, via:ConnectionType) {
        for delegate in delegates {
            delegate.reachabilityChanged(sender: self, isReachable: internetConnection, via: via)
        }
    }
    
    //MARK: - private saving/loading
    private func loadFromRealm(){
        isLoading = true
        
        let object = DataManager.shared.get(type: SimpleApiRealm.self, identifier: "SimpleApiRealm")
        autoSaveToRealm = object.autoSaveToRealm
        callLastApiCallAfterInternetComesBack = object.callLastApiCallAfterInternetComesBack
        defaultMethod = object.defaultMethod
        defaultParamEncoding = object.defaultParamEncoding
        defaultHeaders = object.defaultHeaders
        
        isLoading = false
    }
    
    private func saveToRealm(){
        if isLoading { return }
        
        let object = SimpleApiRealm()
        object.autoSaveToRealm = autoSaveToRealm
        object.callLastApiCallAfterInternetComesBack = callLastApiCallAfterInternetComesBack
        object.defaultMethod = defaultMethod
        object.defaultParamEncoding = defaultParamEncoding
        object.defaultHeaders = defaultHeaders
        DataManager.shared.save(object: object)
    }
}

//MARK: - protocol
public protocol SimpleApiDelegate: class {
    func reachabilityChanged(sender:SimpleApi, isReachable:Bool, via:ConnectionType)
}

//MARK: - enums
public enum ConnectionType {
    case wifi
    case cellular
    case noInternet
}

public enum ParamsEncoding: Int {
    case standard
    case httpBody
}

public enum CallMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
}

public enum SimpleApiError: String {
    case noInternet = "There's no internet connection"
    case emptyResponse = "Response exited with success but result value is empty"
    case fail
}

//MARK: -
fileprivate extension DispatchQueue {
    static var background : DispatchQueue {
        return DispatchQueue(label: "com.simpleApi.dispatch", qos: DispatchQoS.background, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    }
}

//MARK: - SimpleApi realm object
class SimpleApiRealm: Object {
    
    dynamic var id: String = "SimpleApiRealm"
    dynamic var autoSaveToRealm: Bool = true
    dynamic var callLastApiCallAfterInternetComesBack = true
    dynamic private var defaultMethodString: String = "GET"
    var defaultMethod:CallMethod{
        get{ return CallMethod(rawValue: defaultMethodString)! }
        set{ defaultMethodString = newValue.rawValue }
    }
    dynamic private var defaultParamsEncodingInt:Int = 0
    var defaultParamEncoding: ParamsEncoding{
        get{ return ParamsEncoding(rawValue: defaultParamsEncodingInt)! }
        set{ defaultParamsEncodingInt = newValue.rawValue }
    }
    private let defaultHeadersData = List<DictionaryPair>()
    var defaultHeaders: [String: String]? {
        get {
            if defaultHeadersData.count == 0 {
                return nil
            }
            
            var dict = [String:String]()
            for pair in defaultHeadersData {
                dict[pair.key] = pair.value
            }
            return dict
        }
        set {
            if newValue == nil {
                defaultHeadersData.removeAll()
            } else {
                defaultHeadersData.removeAll()
                for item in newValue! {
                    defaultHeadersData.append(DictionaryPair(key: item.key, value: item.value))
                }
            }
        }
    }
    
    override static func ignoredProperties() -> [String] {
        return ["defaultHeaders", "defaultParamEncoding", "defaultMethod"]
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
}

class DictionaryPair: Object{
    
    dynamic var key:String = ""
    dynamic var value:String = ""
    
    convenience init(key:String, value:String){
        self.init()
        self.key = key
        self.value = value
    }
}


//MARK: - Data manager
fileprivate class DataManager: NSObject {
    
    static let shared = DataManager()
    
    private override init() {}
    
    func save(object:Object) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(object, update:true)
        }
    }
    
    func save(objects:[Object], completion: ()->Void = {}) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(objects, update: true)
        }
        completion()
    }
    
    func get<T:Object> (type:T.Type, identifier:String) -> T {
        let realm = try! Realm()
        if let result = realm.object(ofType: type, forPrimaryKey: identifier) {
            return result
        }
        return T()
    }
}
