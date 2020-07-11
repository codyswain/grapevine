
import UIKit
import CoreLocation
import MaterialComponents.MaterialDialogs

/// Manages the main workflow of the ban chamber screen.
class KarmaAbilitiesViewerViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //Changes colors of status bar so it will be visible in dark or light mode
        if Globals.ViewSettings.CurrentMode == .dark {
            return .lightContent
        }
        else{
            return .darkContent
        }
    }

    /// Manges the ban chamber screen.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dark/light mode from persistent storage
        let defaults = UserDefaults.standard
        if let curTheme = defaults.string(forKey: Globals.userDefaults.themeKey){
            if (curTheme == "dark") {
                super.overrideUserInterfaceStyle = .dark
                Globals.ViewSettings.BackgroundColor = Constants.Colors.extremelyDarkGrey
                Globals.ViewSettings.LabelColor = .white
            } else {
                super.overrideUserInterfaceStyle = .light
                Globals.ViewSettings.BackgroundColor = .white
                Globals.ViewSettings.LabelColor = .black
            }
        }
        
    }
    
}
