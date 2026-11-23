
import UIKit
import CoreData

class OutfitSalvati: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {

    @IBOutlet weak var outfit: UICollectionView!
    var arrOutfit: [Vestiti] = []
    @IBOutlet weak var outfit2: UICollectionView!
     var arrOutfit1: [Vestiti] = []
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == outfit){
              print(arrOutfit.count)
            return arrOutfit.count
        } else {
              print(arrOutfit1.count)
            return arrOutfit1.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == outfit){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Outfit", for: indexPath) as! Outfit
            cell.m.image =  UIImage(data: arrOutfit[indexPath.row].image!)
            cell.p.image =  UIImage(data: arrOutfit[indexPath.row].image2!)
            cell.s.image =  UIImage(data: arrOutfit[indexPath.row].image3!)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Outfit1", for: indexPath) as! Outfit
            cell.m.image =  UIImage(data: arrOutfit1[indexPath.row].image!)
            cell.p.image =  UIImage(data: arrOutfit1[indexPath.row].image2!)
            cell.s.image =  UIImage(data: arrOutfit1[indexPath.row].image3!)
            return cell
        }
     
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //DatabaseHelper.istance.clearCoreData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let arr = DatabaseHelper.istance.getAllImages()
        arrOutfit = []
        arrOutfit1 = []
       
        var j = 0
        if(arr.count != 0){
            for i in 0...arr.count-1{
                if(arr[i].tipo == "Outfit"){
                    if(j % 2 == 0){
                        arrOutfit.append(arr[i])
                    } else {
                        arrOutfit1.append(arr[i])
                    }
                    j = j + 1
                }
            }
        }
        print(arrOutfit.count)
        print(arrOutfit1.count)

        outfit.reloadData()
        outfit2.reloadData()

    }
}
