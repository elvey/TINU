/*
TINU, the open tool to create bootable macOS installers.
Copyright (C) 2017-2021 Pietro Caruso (ITzTravelInTime)

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

import Cocoa
import TINURecovery

//the first screen of the app, it has just some labels and a button
class InfoViewController: GenericViewController, ViewID{
	let id: String = "InfoViewController"
    @IBOutlet weak var infoField: NSTextField!
    
    @IBOutlet weak var backButton: NSButton!
    
	@IBOutlet weak var getInstallerButton: NSButton!
	
	@IBOutlet weak var driveIcon: NSImageView!
    @IBOutlet weak var appIcon: NSImageView!
    
    @IBOutlet weak var driveLabel: NSTextField!
    @IBOutlet weak var appLabel: NSTextField!
    
    @IBOutlet weak var tinuLabel: NSTextField!
    @IBOutlet weak var sloganLabel: NSTextField!
    
    @IBOutlet weak var stuffContainer: NSView!
    
    @IBOutlet weak var sep: NSBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		
		/*if !sharedIsOnRecovery{
			//backButton.isHidden = true
        }else{*/
			self.setTitleLabel(text: TextManager.getViewString(context: self, stringID: "title"))
			self.showTitleLabel()
		
			self.titleLabel.frame.origin.y = 229
		
            let delta = titleLabel.frame.origin.y - tinuLabel.frame.origin.y
            
            titleLabel.frame.origin.y -= delta
            
            stuffContainer.frame.origin.y = sep.frame.origin.y - stuffContainer.frame.size.height
            
            //stuffContainer.frame.origin.y = self.view.frame.height / 2 - stuffContainer.frame.height / 2
            
            sep.isHidden = true
            
            tinuLabel.isHidden = true
            sloganLabel.isHidden = true
		
			getInstallerButton.isHidden = true//sharedIsOnRecovery
		
		
        //}
		
		#if macOnlyMode
		if !isOnRecovery{
			backButton.isHidden = true
		}
		#endif
		
		appIcon.image = IconsManager.shared.genericInstallerAppIcon.themedImage()
        
        if cvm.shared.installMac{
            
            //infoField.stringValue = "This is a tool that helps you to create a bootable macOS installer and also to install macOS\nBefore starting you need:\n   - At least a 20 gb drive or partition\n   - A copy of the macOS installer app (of any version starting from El Capitan) in\n     the root of a storage device connected to the computer"
			
			driveIcon.image = IconsManager.shared.internalDiskIcon.themedImage()
			
            //driveLabel.stringValue = "A drive or partition of 20 GB or higher"
            
            //appLabel.stringValue = "A macOS installer app downloaded from the App Store\n(El Capitan or more recent)"
			
			#if macOnlyMode
				sloganLabel.stringValue = "TINU: The macOS tool"
			#else
				sloganLabel.stringValue = "TINU Is Not Unib***t: The macOS tool"
			#endif
            
            //titleField.stringValue = "To install macOS you need:"
		}else{
			#if macOnlyMode
				sloganLabel.stringValue = "TINU: The bootable macOS installer creation tool"
			#else
				sloganLabel.stringValue = "TINU Is Not Unib***t: The bootable macOS installer creation tool"
			#endif
			
			driveIcon.image = IconsManager.shared.removableDiskIcon.themedImage()
			
		}
		
		if #available(macOS 11.0, *), look.usesSFSymbols() {
			//driveIcon.image = driveIcon.image?.withSymbolWeight(.thin)
			driveIcon.contentTintColor = .systemGray
			//appIcon.image = appIcon.image?.withSymbolWeight(.thin)
			appIcon.contentTintColor = .systemGray
		}
		
		driveLabel.stringValue = TextManager.getViewString(context: self, stringID: "driveInfo")
		
		appLabel.stringValue = TextManager.getViewString(context: self, stringID: "appInfo")
		
		DispatchQueue.global(qos: .background).async {
			EFIFolderReplacementManager.reset()
		}
    }
	
	override func viewDidAppear() {
		super.viewDidAppear()
		
		if #available(OSX 10.15, *){
			if !CurrentUser.isRoot{
				SIPManager.checkStatusAndLetTheUserKnow()
			}
		}
		
		#if noFirstAuth
			if !isOnRecovery{
				msgBoxWarning("WARNING", "This app has been compiled with first step authentication disabled.\nIt may be less secure to use, use it at your own risk!")
			}
		#endif
	}

    @IBAction func ok(_ sender: Any) {
        if UIManager.shared.showLicense{
            let _ = swapCurrentViewController("License")
        }else{
            let _ = swapCurrentViewController("ChoseDrive")
        }
    }

    @IBAction func back(_ sender: Any) {
        swapCurrentViewController("chooseSide")
    }
}
