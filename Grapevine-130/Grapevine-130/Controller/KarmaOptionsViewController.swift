import Foundation
import UIKit
import CoreLocation
import MaterialComponents.MaterialCards

/// Manages control flow of the score screen.
class KarmaOptionsViewController: UIViewController {
    /// Intializes the score screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        collectionView.backgroundColor = .white
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
        collectionView.register(MDCCardCollectionCell.self, forCellWithReuseIdentifier: "Cell")
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
                                                    for: indexPath) as! MDCCardCollectionCell
        cell.isSelectable = false
        cell.cornerRadius = 10
        cell.setShadowColor(UIColor.black, for: .highlighted)
        
//        cell.setImage(UIImage(systemName: "scribble"), for: .normal)
//        cell.setImageTintColor(.black, for: .normal)
//        
//        let card = MDCCard(frame: CGRect(x: 50, y: 50, width: 0, height: 0))
//        card.backgroundColor = UIColor(red:1, green:1, blue:1, alpha:0.0)
//        card.largeContentImage = UIImage(named: "Party")
//        cell.backgroundView = card
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // do something when item was selected
    }
}
