//
//  DatabaseHelper.swift
//  deeplab-ios
//
//  Created by Antonio Cimino on 29/02/2020.
//  Copyright © 2020 xyh. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class DatabaseHelper{
    static let istance = DatabaseHelper()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func saveImageCoredata(idS: String, imgData: Data, type: String){
        let vestito = NSEntityDescription.insertNewObject(forEntityName: "Vestiti", into: context) as! Vestiti
        vestito.id = idS
        vestito.image = imgData
        vestito.tipo = type
        do{
            try context.save()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func saveImageOutfitCoredata(idS: String, imgDataM: Data, imgDataP: Data, imgDataS: Data ){
         let outfit = NSEntityDescription.insertNewObject(forEntityName: "Vestiti", into: context) as! Vestiti
        outfit.id = idS
        outfit.image = imgDataM
        outfit.image2 = imgDataP
        outfit.image3 = imgDataS
        outfit.tipo = "Outfit"
         do{
             try context.save()
         } catch let error {
             print(error.localizedDescription)
         }
     }
    
    func getAllImages() -> [Vestiti]{
        var arrVestiti = [Vestiti]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Vestiti")
        do{
            arrVestiti = try context.fetch(fetchRequest) as! [Vestiti]
        } catch let error{
            print(error.localizedDescription)
        }
        return arrVestiti
    }
    
   func clearCoreData() {
       // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Vestiti")

        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(batchDeleteRequest)

        } catch {
            // Error Handling
        }
    }
    
    func deleteProfile(withID: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Vestiti")
        fetchRequest.predicate = NSPredicate.init(format: "id==\(withID)")
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                context.delete(object as! NSManagedObject)
            }
            try context.save()
        } catch _ {
            // error handling
        } }
}
