import UIKit
import CoreData

class NuovaVestito: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var displayView: UIImageView!
    var tipo = "Maglia"
    
    var sourceImg: UIImage! {
        didSet {
            displayView.image = sourceImg
        }
    }
       
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "isFirstTime") == nil {
            defaults.set("No", forKey:"isFirstTime")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let secondVC = storyboard.instantiateViewController(withIdentifier: "mm")  as! tutorial
            self.navigationController?.pushViewController(secondVC, animated: true)
        } else{}
        sourceImg = UIImage.init(named: "unnamed.jpg")!
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if(pants.isSelected == false || shooes.isSelected == false){
        shirt.isSelected = true
        } else {shirt.isSelected = false}
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     self.tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(true, animated: animated)
        shirt.isSelected = true
        pants.isSelected = false
        shooes.isSelected = false
    }
    
    @IBOutlet weak var pants: UIButton!
    @IBOutlet weak var shooes: UIButton!
    @IBOutlet weak var shirt: UIButton!
    
    
    @IBAction func shirtTap(_ sender: Any) {
        tipo = "Maglia"
       shirt.isSelected = true
        pants.isSelected = false
        shooes.isSelected = false
    }
    @IBAction func pantsTap(_ sender: Any) {
        tipo = "Pantalone"
        
        shirt.isSelected = false
        pants.isSelected = true
        shooes.isSelected = false
    }
    @IBAction func shoesTap(_ sender: Any) {
        tipo = "Scarpa"
        shirt.isSelected = false
        pants.isSelected = false
        shooes.isSelected = true
    }
    @IBAction func save(_ sender: Any) {
        let _ = self.displayView.image?.jpegData(compressionQuality: 0.75)
        if let png = self.displayView.image?.pngData(){
            let arr = DatabaseHelper.istance.getAllImages()
            DatabaseHelper.istance.saveImageCoredata(idS: String(arr.count), imgData: png,type: tipo)
        }
//        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        let ac = UIAlertController(title: "Saved!", message: "Your altered image has been hanged to your wardrobe.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        print("ok")
    }
    
    @IBAction func PickYourPicture(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            
            let actionSheet = UIAlertController(title:"Photo Source", message: "Choose a Source", preferredStyle: .actionSheet)
                                     actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler:{ (action:UIAlertAction) in
                
                if UIImagePickerController.isSourceTypeAvailable(.camera){
                imagePickerController.sourceType = .camera
                    self.present(imagePickerController, animated: true, completion: nil)  }
                    
                else
                {print (" Camera is not aviable")}
                
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler:{ (action:UIAlertAction) in
                if UIImagePickerController.isSourceTypeAvailable(.camera){
                    
                    imagePickerController.sourceType = .photoLibrary
                    self.present(imagePickerController, animated: true, completion: nil)
                } else
                {print (" Photo Gallery is not aviable")}
                
                
            }))
            
             actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(actionSheet, animated: true, completion: nil)
        
        
    }
    @IBAction func scontorna(_ sender: Any) {
        if let cgImg = self.sourceImg.segmentation(){
                  let filter = GraySegmentFilter()
                  filter.inputImage = CIImage.init(cgImage: self.sourceImg.cgImage!)
                  filter.maskImage = CIImage.init(cgImage: cgImg)
                  let output = filter.value(forKey:kCIOutputImageKey) as! CIImage
                  
                  let ciContext = CIContext(options: nil)
                  let cgImage = ciContext.createCGImage(output, from: output.extent)!
                  self.displayView.image = UIImage(cgImage: cgImage)
              }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
         sourceImg = pickedImage.resize(size: CGSize(width: 1200, height: 1200 * (pickedImage.size.height / pickedImage.size.width)))
        }

        picker.dismiss(animated: true, completion: nil)
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
     displayView.image = image
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
           if let error = error {
               let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
               ac.addAction(UIAlertAction(title: "OK", style: .default))
               present(ac, animated: true)
           } else {
               let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
               ac.addAction(UIAlertAction(title: "OK", style: .default))
               present(ac, animated: true)
           }
       }
     
    var check : CGFloat = 0
    @IBAction func pickCategories(_ sender: UIButton) {
        if sender.isSelected  {
                sender.isSelected = false
                check -= 1
        } else {
            sender.isSelected = true
            check += 1
                
            }
    }
        
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
 
    
    
     
}


