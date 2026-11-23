import UIKit
import CoreData


class EliminaVestito: UIViewController {

    var id: String! = ""
    
    @IBOutlet weak var img: UIImageView!
    @IBAction func elimina(_ sender: Any) {
        DatabaseHelper.istance.deleteProfile(withID: id)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(id)
        let arr = DatabaseHelper.istance.getAllImages()
        img.image =  UIImage(data: arr[Int(id)!].image!)
    }
    
    @IBAction func share(_ sender: Any) {
        let firstActivityItem = "Share"
        let secondActivityItem : NSURL = NSURL(string: "http//:hangme")!
        // If you want to put an image
        let image : UIImage =  img.image!

        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem, secondActivityItem, image], applicationActivities: nil)

        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)

        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)

        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo,
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.postToTwitter,
        ]

        self.present(activityViewController, animated: true, completion: nil)
    }
    
}


