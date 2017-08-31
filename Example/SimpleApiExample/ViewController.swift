//
//  ViewController.swift
//  SimpleApi
//
//  Created by Jakub Kozák on 30/08/2017.
//  Copyright © 2017 kkubkko. All rights reserved.
//
import UIKit
import RealmSwift
import ObjectMapper
import SimpleApi

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        SimpleApi.shared.get(type: TestObject.self, url: "url")
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
        
        SimpleApi.shared.getArray(type: TestObject.self, url: "url")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

class TestObject: Object, Mappable {
    dynamic var name = ""
    
    func mapping(map: Map) {
        name <- map["name"]
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
}
