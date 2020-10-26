
import UIKit
import CoreLocation
import MaterialComponents.MaterialDialogs
import MaterialComponents.MaterialBottomNavigation
import MaterialComponents.MaterialCards

/// Manages the main workflow of the ban chamber screen.
class KarmaAbilitiesViewerViewController: UIViewController {
    fileprivate let pictures = [#imageLiteral(resourceName: "Grapevine Store Card 1"),#imageLiteral(resourceName: "Grapevine Store Card 2"), #imageLiteral(resourceName: "Grapevine Store Card 3")]

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStatusBarStyle()
    }

    /// Manges the ban chamber screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dark/light mode from persistent storage
        setTheme(curView: self)
        
        // Add collection view
        view.addSubview(collectionView)
        collectionView.backgroundColor = UIColor(red:1, green:1, blue:1, alpha:0)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant:85).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        collectionView.heightAnchor.constraint(lessThanOrEqualToConstant: view.frame.height*0.8).isActive = true
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    class MyCollectionViewFlowLayout : UICollectionViewFlowLayout{
        override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
            var offsetAdjustment = CGFloat.greatestFiniteMagnitude
            let horizontalOffset = proposedContentOffset.x
            let targetRect = CGRect(origin: CGPoint(x: proposedContentOffset.x, y: 0), size: self.collectionView!.bounds.size)

            for layoutAttributes in super.layoutAttributesForElements(in: targetRect)! {
                let itemOffset = layoutAttributes.frame.origin.x
                if (abs(itemOffset - horizontalOffset) < abs(offsetAdjustment)) {
                    offsetAdjustment = itemOffset - horizontalOffset
                }
            }

            return CGPoint(x: proposedContentOffset.x + offsetAdjustment - self.collectionView!.bounds.width * 0.055, y: proposedContentOffset.y)
        }
    }
    
    fileprivate let collectionView:UICollectionView = {
            let layout = MyCollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.register(CustomCell.self, forCellWithReuseIdentifier: "Cell")
            collectionView.isPagingEnabled = false // must be disabled for our custom paging
            collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
            return collectionView
        }()
    }

    extension UIView {
        func fadeTransition(_ duration:CFTimeInterval) {
            let animation = CATransition()
            animation.timingFunction = CAMediaTimingFunction(name:
                CAMediaTimingFunctionName.easeInEaseOut)
            animation.type = CATransitionType.fade
            animation.duration = duration
            layer.add(animation, forKey: CATransitionType.fade.rawValue)
        }
    }

    extension KarmaAbilitiesViewerViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: view.frame.width*0.8, height: view.frame.height * 0.8)
        }
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return 3
        }
        
        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                        for: indexPath) as! CustomCell
            cell.isSelectable = false
            cell.cornerRadius = 10
            cell.setShadowElevation(ShadowElevation(rawValue: 0), for: .normal)
            cell.image = self.pictures[indexPath.item]

            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // do something when item was selected
//            let selectedCell = indexPath.row
            self.alertUseInFeed()
        }
        
        /// Displays a popup that let's the user know that they do not have enough points to ban other users.
        func alertUseInFeed(){
            let alert = MDCAlertController(title: "Abilities are now on the main feed.", message: "Just tap the '$' button on the post you want to perform the ability on!")
            alert.addAction(MDCAlertAction(title: "Ok"))
            makePopup(alert: alert, image: "x.circle.fill")
            self.present(alert, animated: true)
        }

    }


    class CustomCell: MDCCardCollectionCell {
        var image: UIImage? {
            didSet {
                guard let im = image else { return }
                bg.image = im
            }
        }
        
        fileprivate let bg: UIImageView = {
           let iv = UIImageView()
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 10
            return iv
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            contentView.addSubview(bg)
            bg.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            bg.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
            bg.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
            bg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        }
        
        // Xcode required me to have this
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
