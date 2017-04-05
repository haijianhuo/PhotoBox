//
//  ViewController.swift
//  PhotoBox
//
//  Created by Haijian Huo on 3/30/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//


import UIKit
import CoreData
import JSQCoreDataKit
import SDWebImage
import JTSImageViewController
import ImagePicker

let kServerError = "The server is busy, try again later!"

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    var refreshControl: UIRefreshControl!
    
    var frc: NSFetchedResultsController<PhotoItem>!
    var blockOperations: [BlockOperation] = []
    var shouldReloadCollectionView = false
    
    let refreshDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        return dateFormatter
    }()

    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    var selectedIndexPath: IndexPath?
    
    // MARK: -
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "photo_background")!)
        
        self.deleteButton.isEnabled = false

        if APP_ID == "" && SECRET_KEY == "" {
            self.needCloudAccount()
        }
        else {
            self.setupRefreshControl()
            
            self.setupFRC()
            
            self.setupCollectionView()
            
            self.setupImageView()
            
            self.setupNotifications()
            
            self.syncData()
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func needCloudAccount() {
        let alertViewController = Utils.alertViewController(withTitle: "Need a cloud account!", message: "Please sign up at https://backendless.com/ to get a free Backendless cloud server account. Create an iOS app on your account. Replace the APP_ID and SECRET_KEY in BackendlessClient.swift with the Application ID and the iOS Secret Key from your account.", tapDismiss: false)!
        
        alertViewController.addAction(NYAlertAction(title: "OK and Quit", style: .destructive) { (action: NYAlertAction?) in
            self.dismiss(animated: true, completion: nil)
            exit(0)
        })
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    

    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        let alertViewController = Utils.alertViewController(withTitle: nil, message: "Delete the selected photo", tapDismiss: true)!
        
        alertViewController.addAction(NYAlertAction(title: "Delete", style: .destructive) { (action: NYAlertAction?) in
            self.dismiss(animated: true, completion: nil)
            self.deletePhotoItem()
        })
        
        alertViewController.addAction(NYAlertAction(title: "Cancel", style: .cancel) { (action: NYAlertAction?) in
            self.dismiss(animated: true, completion: nil)
        })
        
        self.present(alertViewController, animated: true, completion: nil)
        
    }
    
    func selectFirstPhotoItem() {
        self.deleteButton.isEnabled = false
        self.imageView.image =  nil
        if self.objectsCount() > 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            self.selectedIndexPath = indexPath
            self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
            let item = self.frc.object(at: indexPath)
            self.imageView.image = SDImageCache.shared().imageFromCache(forKey: item.imageUrl)
            self.deleteButton.isEnabled = true
        }
    }
    
    func deletePhotoItem() {
        
        let item = self.frc.object(at: self.selectedIndexPath!)
        
        photoAPI.deletePhotoItem(item: item, successBlock: { (response: Any?) in
            print("deletePhotoItem success")
        }) { (fault: Fault?) in
            print("deletePhotoItem error")
            ProgressHUD.showError(kServerError)
        }
    }
    

    // MARK: - KVC

    @IBAction func addButtonTapped(_ sender: Any) {
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        var config = Configuration()
        config.doneButtonTitle = "Upload"
        config.noImagesTitle = "Sorry! There are no images here!"
        config.recordLocation = false
        
        let imagePicker = ImagePickerController()
        imagePicker.configuration = config
        imagePicker.imageLimit = 1
        imagePicker.delegate = self

        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func tapHandler(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            self.zoomImage(imageView: self.imageView, imageUrl: nil)
        }
    }
    
    
    // MARK: - KVO setup

    func zoomImage(imageView: UIImageView, imageUrl: String?) {

        guard let image = imageView.image else { return }
            
        let imageInfo = JTSImageInfo()
        
        if let imageUrl = imageUrl {
            if let image = SDImageCache.shared().imageFromCache(forKey: imageUrl) {
                imageInfo.image = image
            }
            else {
                imageInfo.imageURL = URL(string: imageUrl)
            }
        }
        else {
            imageInfo.image = image
        }

        imageInfo.referenceRect = imageView.frame
        imageInfo.referenceView = imageView.superview
        
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode:JTSImageViewControllerMode.image, backgroundStyle: JTSImageViewControllerBackgroundOptions.scaled)!
        
        imageViewer.dismissalDelegate = self
        imageViewer.addObserver(self, forKeyPath: "image", options: NSKeyValueObservingOptions.new, context: nil)

        imageViewer.show(from: self, transition: JTSImageViewControllerTransition.fromOriginalPosition)
    }

    func setupImageView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        //self.imageView.image = nil //UIImage(named: "launch")
        self.imageView.addGestureRecognizer(tapGestureRecognizer)
        self.imageView.isUserInteractionEnabled = true

    }
    

    func setupCollectionView() {
        self.collectionView.allowsMultipleSelection = false
    }
    
    override public var traitCollection: UITraitCollection {
        if (UIDevice.current.orientation.isLandscape) {
            let collections = [UITraitCollection(verticalSizeClass: .compact)]
            return UITraitCollection(traitsFrom: collections)
        }
        else {
            return super.traitCollection
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "image" {
            if let image = change?[.newKey] as? UIImage {
                self.imageView.image = image
            }
        }
    }

    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.objectsCount()
        
        if count == 0 {
            let messageLabel = UILabel.init(frame: self.collectionView.bounds)
            
            messageLabel.text = "No photo is currently available on cloud server. Please touch the ➕ button to upload photo or pull down to refresh."
            messageLabel.textColor = .black
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont(name: "Palatino-Italic", size: 20)
            messageLabel.sizeToFit()
            
            self.collectionView.backgroundView = messageLabel
        }
        else {
            self.collectionView.backgroundView = nil
        }
        

        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoItemCollectionViewCell", for: indexPath) as! PhotoItemCollectionViewCell
        let object = frc.object(at: indexPath)
        cell.setGalleryItem(object)
        return cell
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.deleteButton.isEnabled = true
        self.selectedIndexPath = indexPath
        
        let item = frc.object(at: indexPath)
        self.imageView.image = nil //UIImage(named: "launch")
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoItemCollectionViewCell
        self.zoomImage(imageView: cell.itemImageView, imageUrl: item.imageUrl)
     }

     // MARK: - UICollectionViewFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let picDimension = collectionView.frame.size.width / 4.0
        return CGSize(width: picDimension, height: picDimension)
    }
    
    // MARK: - RefreshControl
    
    func setupRefreshControl() {
        self.collectionView!.alwaysBounceVertical = true
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = .purple
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(ViewController.syncData), for: UIControlEvents.valueChanged)
        self.collectionView.addSubview(refreshControl)
    }
    
    func syncData() {
        
        DispatchQueue.main.async() {
            
            photoAPI.getPhotoItems(successBlock: { (count: Int) in
                print("syncData count: \(count)")
                self.shouldReloadCollectionView = true
                DispatchQueue.main.async() {
                    self.updateRefreshDate()
                    self.refreshControl.endRefreshing()
                    ProgressHUD.dismiss()
                }
            }, errorBlock: { (fault: Fault?) in
                print("getPhotoItems error")
                DispatchQueue.main.async() {
                    self.refreshControl.endRefreshing()
                    ProgressHUD.showError(kServerError)
                }
            })
        }
    }

    func updateRefreshDate() {
        let title = "Last update: \(self.refreshDateFormatter.string(from: Date()))"
        let attrsDictionary = [NSForegroundColorAttributeName: UIColor.white]
        let attributedTitle = NSAttributedString.init(string: title, attributes: attrsDictionary)
        self.refreshControl.attributedTitle = attributedTitle
    }
    
    // MARK: - Notifications
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector:#selector(applicationDidBecomeActiveNotification(_:)), name:NSNotification.Name.UIApplicationDidBecomeActive, object:nil)
    }
    
    func applicationDidBecomeActiveNotification(_ notification: NSNotification?) {
        self.syncData()
    }

    
    // MARK: - CoreData
    
    func setupFRC() {
        frc = photoAPI.getPhotoItemFRC()
        frc.delegate = self
        fetchData()
    }
    
    func fetchData() {
        do {
            try frc.performFetch()
            self.collectionView.reloadData()
            DispatchQueue.main.async() {
                self.selectFirstPhotoItem()
            }
        } catch {
            assertionFailure("Failed to fetch: \(error)")
        }
    }
    func objectsCount() -> Int {
        let count = self.frc?.fetchedObjects?.count ?? 0
        return count
    }
    
}


// MARK: - NSFetchedResultsControllerDelegate

extension ViewController: NSFetchedResultsControllerDelegate
{
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == NSFetchedResultsChangeType.insert {
            //print("Insert Object: \(newIndexPath)")
            
            if (collectionView?.numberOfSections)! > 0 {
                
                if collectionView?.numberOfItems( inSection: newIndexPath!.section ) == 0 {
                    self.shouldReloadCollectionView = true
                } else {
                    blockOperations.append(
                        BlockOperation(block: { [weak self] in
                            if let this = self {
                                DispatchQueue.main.async {
                                    this.collectionView!.insertItems(at: [newIndexPath!])
                                }
                            }
                        })
                    )
                }
                
            } else {
                self.shouldReloadCollectionView = true
            }
        }
        else if type == NSFetchedResultsChangeType.update {
            //print("Update Object: \(indexPath)")
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        DispatchQueue.main.async {
                            
                            this.collectionView!.reloadItems(at: [indexPath!])
                        }
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.move {
            //print("Move Object: \(indexPath)")
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        DispatchQueue.main.async {
                            this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                        }
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            //print("Delete Object: \(indexPath)")
            if collectionView?.numberOfItems( inSection: indexPath!.section ) == 1 {
                self.shouldReloadCollectionView = true
            } else {
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            DispatchQueue.main.async {
                                this.collectionView!.deleteItems(at: [indexPath!])
                            }
                        }
                    })
                )
            }
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if type == NSFetchedResultsChangeType.insert {
            //print("Insert Section: \(sectionIndex)")
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        DispatchQueue.main.async {
                            this.collectionView!.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            //print("Update Section: \(sectionIndex)")
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        DispatchQueue.main.async {
                            this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            //print("Delete Section: \(sectionIndex)")
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        DispatchQueue.main.async {
                            this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    }
                })
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // Checks if we should reload the collection view to fix a bug @ http://openradar.appspot.com/12954582
        if (self.shouldReloadCollectionView) {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.selectFirstPhotoItem()
            }
        } else {
            DispatchQueue.main.async {
                self.collectionView!.performBatchUpdates({ () -> Void in
                    for operation: BlockOperation in self.blockOperations {
                        operation.start()
                    }
                }, completion: { (finished) -> Void in
                    self.blockOperations.removeAll(keepingCapacity: false)
                })
            }
        }
    }
}

// MARK: - JTSImageViewControllerDismissalDelegate, KVO removal

extension ViewController: JTSImageViewControllerDismissalDelegate
{
    func imageViewerDidDismiss(_ imageViewer: JTSImageViewController!) {
        
        imageViewer.removeObserver(self, forKeyPath: "image")
        
        if let imageURL = imageViewer.imageInfo.imageURL {
            if let image = imageViewer.image {
                SDImageCache.shared().store(image, forKey: imageURL.absoluteString, completion: {
                    //print("store image: \(imageURL.absoluteString)")
                })
            }
        }
    }

}

// MARK: - ImagePickerDelegate

extension ViewController: ImagePickerDelegate
{
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if images.count > 0 {
            
            ProgressHUD.show("Uploading...", interaction: true)
            
            let image = images[0]
            
            photoAPI.uploadImages(image: image, successBlock: { (imageUrl: String?) in
                print("uploadImages success")
                if let imageUrl = imageUrl {
                    SDImageCache.shared().store(image, forKey: imageUrl, completion: {
                        //print("store image: \(imageUrl)")
                        DispatchQueue.main.async() {
                            self.syncData()
                        }
                    })
                }
            }, errorBlock: { (fault: Fault?) in
                ProgressHUD.showError(kServerError)
                print("uploadImages error")
            })
            
        }
        
    }

}
