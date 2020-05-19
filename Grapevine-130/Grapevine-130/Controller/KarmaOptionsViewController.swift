import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialCards

/// Manages control flow of the score screen.
class KarmaOptionsViewController: UIViewController {
    fileprivate let pictures = [#imageLiteral(resourceName: "Grapevine Store Card 1"),#imageLiteral(resourceName: "Grapevine Store Card 2"), #imageLiteral(resourceName: "Grapevine Store Card 3")]

    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        collectionView.backgroundColor = UIColor(red:1, green:1, blue:1, alpha:0)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height*0.1).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: view.frame.height*0.8).isActive = true
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    fileprivate let collectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(CustomCell.self, forCellWithReuseIdentifier: "Cell")
//        collectionView.isPagingEnabled = true // enabling paging effect
        return collectionView
    }()

}

extension KarmaOptionsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
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
        let selectedCell = indexPath.row
        if selectedCell == 0 {
            self.performSegue(withIdentifier: "storeToBanChamber", sender: self)
        } else if selectedCell == 1 {
            
        } else if selectedCell == 2 {
            
        }
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
