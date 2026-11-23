
import UIKit
import CoreData

class ViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    
    @IBOutlet weak var maglie: UICollectionView!
    var arrMaglia: [Vestiti] = []
    @IBOutlet weak var scarpe: UICollectionView!
     var arrScarpa: [Vestiti] = []
    @IBOutlet weak var pantaloni: UICollectionView!
    var arrPantalone: [Vestiti] = []
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == maglie){
            return arrMaglia.count
        } else if(collectionView == scarpe){
            return arrScarpa.count
        } else {
            return arrPantalone.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == maglie){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Maglia", for: indexPath) as! Maglie
            cell.img.image =  UIImage(data: arrMaglia[indexPath.row].image!)
            return cell
        } else if(collectionView == scarpe){
             let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Scarpa", for: indexPath) as! Scarpe
                   cell.img.image =  UIImage(data: arrScarpa[indexPath.row].image!)
            return cell
        } else {
             let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Pantalone", for: indexPath) as! Pantaloni
                   cell.img.image =  UIImage(data: arrPantalone[indexPath.row].image!)
            return cell
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //DatabaseHelper.istance.clearCoreData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        let arr = DatabaseHelper.istance.getAllImages()
        arrMaglia = []
        arrScarpa = []
        arrPantalone = []
        
        if(arr.count != 0){
            for i in 0...arr.count-1{
                if(arr[i].tipo == "Maglia"){
                    arrMaglia.append(arr[i])
                } else if(arr[i].tipo == "Pantalone"){
                    arrPantalone.append(arr[i])
                } else if(arr[i].tipo == "Scarpa"){
                    arrScarpa.append(arr[i])
                } else {}
            }
        }

        
        maglie.reloadData()
        pantaloni.reloadData()
        scarpe.reloadData()
    }
}
