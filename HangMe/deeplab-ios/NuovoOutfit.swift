
import UIKit
import CoreData

class NuovoOutfit: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    
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
            //Tap to go on page of Williams sister
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapDetectedM))
            cell.img.isUserInteractionEnabled = true
            cell.img.addGestureRecognizer(singleTap)
            return cell
        } else if(collectionView == scarpe){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Scarpa", for: indexPath) as! Scarpe
                   cell.img.image =  UIImage(data: arrScarpa[indexPath.row].image!)
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapDetectedS))
            cell.img.isUserInteractionEnabled = true
            cell.img.addGestureRecognizer(singleTap)
            return cell
        } else {
             let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Pantalone", for: indexPath) as! Pantaloni
                   cell.img.image =  UIImage(data: arrPantalone[indexPath.row].image!)
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapDetectedP))
            cell.img.isUserInteractionEnabled = true
            cell.img.addGestureRecognizer(singleTap)
            return cell
        }
    }
    
    @IBAction func saveOutfit(_ sender: Any) {
        //todo aggiungere try catch che lancia un messaggio di errore a video se non sono stati scelti almeno un oggetto per ogni categoria
        let arr = DatabaseHelper.istance.getAllImages()
        let cardIndexM: Int = Int(maglie.contentOffset.x / maglie.frame.size.width)
        let cardIndexP: Int = Int(pantaloni.contentOffset.x / pantaloni.frame.size.width)
        let cardIndexS: Int = Int(scarpe.contentOffset.x / scarpe.frame.size.width)
        DatabaseHelper.istance.saveImageOutfitCoredata(idS: String(arr.count), imgDataM: arrMaglia[cardIndexM].image!, imgDataP: arrPantalone[cardIndexP].image!, imgDataS: arrScarpa[cardIndexS].image!)
        print("ok")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //DatabaseHelper.istance.clearCoreData()
    }
     override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)

       }
       
       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
         self.tabBarController?.tabBar.isHidden = false
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
    
  
    @objc func tapDetectedM() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC = storyboard.instantiateViewController(withIdentifier: "el")  as! EliminaVestito
        let cardIndexM: Int = Int(maglie.contentOffset.x / maglie.frame.size.width)
        secondVC.id = arrMaglia[cardIndexM].id!
        self.navigationController?.pushViewController(secondVC, animated: true)
    }
    
    @objc func tapDetectedP() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC = storyboard.instantiateViewController(withIdentifier: "el")  as! EliminaVestito
        let cardIndexP: Int = Int(pantaloni.contentOffset.x / pantaloni.frame.size.width)
        secondVC.id = arrPantalone[cardIndexP].id!
        self.navigationController?.pushViewController(secondVC, animated: true)
    }
    
    @objc func tapDetectedS() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC = storyboard.instantiateViewController(withIdentifier: "el")  as! EliminaVestito
        let cardIndexS: Int = Int(scarpe.contentOffset.x / scarpe.frame.size.width)
        secondVC.id = arrScarpa[cardIndexS].id!
        self.navigationController?.pushViewController(secondVC, animated: true)
    }
}
