//
//  PetsVC.swift
//  SimpleApiExample
//
//  Created by Jakub Kozák on 31/08/2017.
//  Copyright © 2017 kkubkko. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper
import SimpleApi

class PetsVC: UIViewController, UITableViewDataSource {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var realm = try! Realm()
    private var pets = try! Realm().objects(Pet.self)
    private var realmToken: NotificationToken!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
        
        //call method that prepares RealmNotificationToken
        prepareToken()
    }
    
    //MARK: - actions
    @IBAction func goBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PetCell") as! PetCell
        cell.setPet(pets[indexPath.row])
        return cell
    }
    
    //MARK: - actions
    @IBAction func downloadPets(_ sender: UIButton) {
        //this one line of code downloads our pets
        //we don't have to implement success block, because realmToken informs us about objects changes
        SimpleApi.shared.getArray(type: Pet.self, url: "https://private-1b6702-simpleapibp.apiary-mock.com/pets")
        
        //in case we need information when the call has ended (e.g. for HUD showing) we can implement it like this:
        //SimpleApi.shared.getArray(type: Pet.self, url: "https://private-1b6702-simpleapibp.apiary-mock.com/pets", success: { objects in print("Objects successfully downloaded") })
    }
    
    @IBAction func deleteAllPets(_ sender: UIButton) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(pets)
        }
    }
    
    //MARK: - realm token
    private func prepareToken() {
        //I think that this code functionality is obvious. If it's not, look at Realm page
        realmToken = realm.observe({ notification, realm in
            guard let tableView = self.tableView else { return }
            tableView.reloadData()
        })
        
//        realmToken = pets.addNotificationBlock{ [weak self] (changes: RealmCollectionChange) in
//            guard let tableView = self?.tableView else { return }
//
//            switch changes {
//            case .initial, .update(_, deletions: _, insertions: _, modifications: _):
//                // Results are now populated and can be accessed without blocking the UI
//                tableView.reloadData()
//                break
//            case .error(let error):
//                // An error occurred while opening the Realm file on the background worker thread
//                fatalError("\(error)")
//                break
//            }
//        }
    }

}

//MARK: - pet cell
class PetCell:UITableViewCell {
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var typeLabel: UILabel!
    
    func setPet(_ pet:Pet) {
        nameLabel.text = pet.name
        typeLabel.text = pet.type
    }
}

//MARK: - realm object
//Example of simple Realm Object that implements Mappable protocol. Thanks to this it can be parsed easily.
class Pet: Object, Mappable {
    @objc dynamic var name: String = ""
    @objc dynamic var type: String = ""
    @objc dynamic var age: Int = 0
    
    func mapping(map: ObjectMapper.Map) {
        name <- map["name"]
        type <- map["type"]
        age <- map["age"]
    }
    
    override class func primaryKey() -> String? {
        return "name"
    }
    
    required convenience init?(map: ObjectMapper.Map) {
        self.init()
    }
}
