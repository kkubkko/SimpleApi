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

let kNoInternetNotification = Notification.Name(rawValue: "kNoInternetNotification")
let kInternetIsBackNotification = Notification.Name(rawValue: "kInternetIsBackNotification")

/** Api manager class
 - important: Use as singleton only with attribute **.shared**
 */
public class SimpleApi: NSObject {
    
    public var autoSaveToRealm: Bool = true
    public var callLastApiCallAfterInternetComesBack = true
    public var defaultMethod: CallMethod = .get
    public var defaultParamEncoding: ParamsEncoding = .standard
    public var defaultHeaders: [String: String]? = nil
    
    public static let shared = SimpleApi()
    private let reachability = Reachability()!
    private var firstChange:Bool = true
    private var lastCalled:()->Void = {}
    
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
              saveResponseToRealm:Bool? = false,
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
                          saveResponseToRealm:Bool? = false,
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
            //on first change, don't react to the notification if online
            if firstChange == true {
                firstChange = false
                return
            }
            
            if self.callLastApiCallAfterInternetComesBack {
                lastCalled()
            }
            NotificationCenter.default.post(Notification(name: kInternetIsBackNotification))
            if reachability.isReachableViaWiFi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
                
            }
        } else {
            print("Network not reachable")
            NotificationCenter.default.post(Notification(name: kNoInternetNotification))
        }
    }
    
    public func isReachable()->Bool{
        return reachability.isReachable
    }
}

public enum ParamsEncoding {
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
    
    func getAll <T:Object> (type:T.Type) -> Results<T> {
        let realm = try! Realm()
        return realm.objects(type)
    }
    
    func get<T:Object> (type:T.Type, identifier:String) -> T {
        let realm = try! Realm()
        if let result = realm.object(ofType: type, forPrimaryKey: identifier) {
            return result
        }
        return T()
    }
    
    func doInWriteBlock(closure:() -> (), completion: ()->Void = {}) {
        let realm = try! Realm()
        try! realm.write {
            closure()
            completion()
        }
    }
}
