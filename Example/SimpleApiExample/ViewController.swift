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

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet private weak var tableView: UITableView!
    
    //MARK: - basic
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
    
    //MARK: - table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell") as! BasicCell
        //even rows handle network changes with notifications
        //odd rows handle network changes with delegate method
        cell.setType(indexPath.row % 2 == 0 ? .delegate : .notification)
        return cell
    }
}

//MARK: - BasicCell
class BasicCell:UITableViewCell, SimpleApiDelegate{
    
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var statusView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        statusView.layer.cornerRadius = statusView.bounds.size.width/2
        //init color of status view
        statusView.backgroundColor = SimpleApi.shared.isReachable() ? UIColor.green : UIColor.red
    }
    
    func reachabilityChanged(sender: SimpleApi, isReachable: Bool, via: ConnectionType) {
        //change status color based on delegate method call
        statusView.backgroundColor = isReachable ? UIColor.green : UIColor.red
    }
    
    func setType(_ type:CellListenerType){
        switch type {
        case .delegate:
            typeLabel.text = "Delegate"
            //add delegate
            SimpleApi.shared.addDelegate(self)
        case .notification:
            typeLabel.text = "Notification"
            //add notification observers
            NotificationCenter.default.addObserver(self, selector: #selector(noInternet(sender:)), name: kNoInternetNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(internetIsBack(sender:)), name: kInternetIsBackNotification, object: nil)
        }
    }
    
    //MARK: - notification handlers
    func noInternet(sender:Notification){
        statusView.backgroundColor = UIColor.red
    }
    
    func internetIsBack(sender:Notification){
        statusView.backgroundColor = UIColor.green
    }
}

//MARK: - enums
enum CellListenerType{
    case delegate
    case notification
}

//MARK: - realm object
class TestObject: Object, Mappable {
    dynamic var name = ""
    
    func mapping(map: Map) {
        name <- map["name"]
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
}
