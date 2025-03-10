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

class ChoseAppViewController: GenericViewController, ViewID {
	let id: String = "ChoseAppViewController"
	
    private var empty: Bool = false{
        didSet{
            if self.empty{
                scoller.drawsBackground = false
                scoller.borderType = .noBorder
                ok.title = TextManager.getViewString(context: self, stringID: "nextButtonFail")
				ok.image = NSImage(named: NSImage.goRightTemplateName)
				ok.image = NSImage(named: NSImage.stopProgressTemplateName)
                ok.isEnabled = true
            }else{
                //viewDidSetVibrantLook()
				
				if let document = scoller.documentView{
					if document.identifier?.rawValue == spacerID{
						document.frame = NSRect(x: 0, y: 0, width: self.scoller.frame.width - 2, height: self.scoller.frame.height - 2)
						if let content = document.subviews.first{
							content.frame.origin = NSPoint(x: document.frame.width / 2 - content.frame.width / 2, y: 0)
						}
						self.scoller.documentView = document
					}
				}
				
				ok.title = TextManager.getViewString(context: self, stringID: "nextButton")
				ok.image = NSImage(named: NSImage.goRightTemplateName)
                ok.isEnabled = false
				
				if !look.isRecovery(){
					scoller.drawsBackground = false
					scoller.borderType = .noBorder
				}else{
					scoller.drawsBackground = true
					scoller.borderType = .bezelBorder
				}
            }
        }
    }
    
    @IBOutlet weak var ok: NSButton!
    
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    @IBOutlet weak var refreshButton: NSButton!
	
	@IBOutlet weak var DownloadAppsAlways: NSButton!
    
    @IBOutlet weak var normalOpen: NSButton!
    
	@IBOutlet weak var back: NSButton!
	
	private var tempRefresh: CGFloat = 0
    
    private let spacerID = "spacer"
	
	private var opened = false
	
	@IBOutlet weak var scoller: HorizontalScrollview!
    
    @IBAction func goBack(_ sender: Any) {
        let _ = swapCurrentViewController("ChoseDrive")
    }
    
    @IBAction func next(_ sender: Any) {
        if !empty || opened {
            /*if sharedInstallMac{
             openSubstituteWindow(windowStoryboardID: "Confirm", sender: sender)
             }else{*/
			
			
			if cvm.shared.installMac{
				showProcessLicense = true
				swapCurrentViewController("License")
			}else{
				
				cvm.shared.options.check()
				let _ = self.swapCurrentViewController("Confirm")
			}
			
            //openSubstituteWindow(windowStoryboardID: "Customize", sender: sender)
            //}
			
        }else{
            NSApplication.shared.terminate(self)
        }
    }
	
    @IBAction func refreshPressed(_ sender: Any) {
        //loadApps()
		loadAppsNew()
    }
	
	@IBAction func chooseElsewere( _ sender: Any){
		chooseExternal()
	}
	
	@objc func chooseExternal() {
		let open = NSOpenPanel()
		open.allowsMultipleSelection = false
		open.canChooseDirectories = false
		open.canChooseFiles = true
		open.isExtensionHidden = false
		open.showsHiddenFiles = true
		open.allowedFileTypes = ["app"]
		
		open.beginSheetModal(for: self.window, completionHandler: { [self]response in
			
			if response != NSApplication.ModalResponse.OK{
				return
			}
			
			if open.urls.isEmpty{
				msgboxWithManager(self, name: "errorOpening")
				return
			}
			
			let replist = ["{fileName}" : ((open.urls.first?.lastPathComponent != nil) ? ", \"\(open.urls.first!.lastPathComponent)\"," : "")]
			
			guard let capp = cvm.shared.app.validate(at: open.urls.first!) else {
				//TODO: change this dialog to indicate generic opening erros
				msgboxWithManager(self, name: "errorOpening")
				return
			}
			
			switch capp.status{
				case .usable, .legacy:
					if capp.url != nil {
						cvm.shared.app.current = capp
						
						self.opened = true
						
						self.next(self)
					}else{
						msgboxWithManager(self, name: "invalidAliasDialog", parseList: replist)
					}
					return
				case .broken, .notInstaller:
					msgboxWithManager(self, name: "invalidAppDialog", parseList: replist)
					return
				case .tooBig:
					msgboxWithManager(self, name: "invalidAppDialogSize", parseList: replist)
					return
				case .tooLittle:
					msgboxWithManager(self, name: "invalidAppDialogLSize", parseList: replist)
					return
				case .badAlias:
					msgboxWithManager(self, name: "invalidAliasDialog", parseList: replist)
					return
			case .unsupported:
				msgboxWithManager(self, name: "invalidAppDialog", parseList: replist)
				return
			}
			
		})
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		
		//self.setTitleLabel(text: "Choose the macOS installer app to use for the macOS installer")
		
		self.setTitleLabel(text: TextManager.getViewString(context: self, stringID: "title"))
		self.showTitleLabel()
		
		self.refreshButton.title = TextManager.getViewString(context: self, stringID: "buttonRefresh")
		self.DownloadAppsAlways.title = TextManager.getViewString(context: self, stringID: "buttonGetInstaller")
		self.normalOpen.title = TextManager.getViewString(context: self, stringID: "buttonOpen")
		self.back.title = TextManager.getViewString(context: self, stringID: "backButton")
		self.ok.title = TextManager.getViewString(context: self, stringID: "nextButton")
		
		if !look.isRecovery(){
			scoller.frame = CGRect.init(x: 0, y: scoller.frame.origin.y, width: self.view.frame.width, height: scoller.frame.height)
			scoller.drawsBackground = false
			scoller.borderType = .noBorder
		}else{
			scoller.frame = CGRect.init(x: 20, y: scoller.frame.origin.y, width: self.view.frame.width - 40, height: scoller.frame.height)
			scoller.drawsBackground = true
			scoller.borderType = .bezelBorder
		}
		
		showProcessLicense = false
		
		/*
        if sharedInstallMac{
            titleLabel.stringValue = "Choose the macOS installer app to use to install macOS"
        }*/
        
        tempRefresh = refreshButton.frame.origin.x
		
		self.scoller.scrollerStyle = .legacy
		
        //loadApps()
		loadAppsNew()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    /*@IBAction func openAppDownload(_ sender: Any) {
		if downloadAppWindowController == nil{
			downloadAppWindowController = DownloadAppWindowController()
		}
		
		downloadAppWindowController?.showWindow(sender)
    }*/
	
	@objc func openGetAnApp(){
		self.presentAsSheet(UIManager.shared.storyboard.instantiateController(withIdentifier: "DownloadAppVC") as! NSViewController)
	}
	
	private func loadAppsNew(){
		//fs = sharedVolumeNeedsFormat
		
		scoller.isHidden = true
		spinner.isHidden = false
		spinner.startAnimation(self)
		
		print("--- Apps detection started")
		scoller.documentView = NSView(frame: scoller.frame)
		scoller.hasHorizontalScroller = false
		
		self.DownloadAppsAlways.isHidden = Recovery.status
		
		self.hideFailureLabel()
		self.hideFailureImage()
		self.hideFailureButtons()
		
		self.normalOpen.isHidden = false
		
		self.refreshButton.frame.origin.x = self.tempRefresh
		
		cvm.shared.app.current = nil
		
		//here loads drives
		//let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey]
		
		ok.isEnabled = false
		
		DispatchQueue.global(qos: .background).async {
			
			var h: CGFloat = 0
			
			DispatchQueue.main.sync {
				h = ((self.scoller.frame.height - 17) / 2) - (DriveView.itemSize.height / 2)
			}
			
			var drives = [DriveView]()
			let appList = cvm.shared.app.listApps()
			
			print("--- App detection complete")
			
			print("Taking care of the UI")
			
			for capp in appList {
				print("    Adding app to UI: \(capp.url!.path)")
				
				DispatchQueue.main.sync {
					
					let drive = DriveView(frame: NSRect(x: 0, y: h, width: DriveView.itemSize.width, height: DriveView.itemSize.height))
					drive.current = capp as UIRepresentable
					
					drive.isEnabled = capp.status == .usable || capp.status == .legacy
					
					drives.append(drive)
					
				}
				
			}
			
			print("UI objects created")
			
			DispatchQueue.main.sync {
				
				self.scoller.hasVerticalScroller = false
				
				self.empty = simulateNoUsableApps ? true : (drives.count == 0)
				
				if !Recovery.status{
					self.DownloadAppsAlways.isHidden = self.empty
				}
				
				if self.empty {
					
					self.scoller.isHidden = true
					self.normalOpen.isHidden = true
					
					if self.failureLabel == nil || self.failureImageView == nil || self.failureButtons.isEmpty{
						self.defaultFailureImage()
						
						self.setFailureLabel(text: TextManager.getViewString(context: self, stringID: "failureText"))
						//"failureButtonGetInstaller"
						if !Recovery.status{
							self.addFailureButton(buttonTitle: TextManager.getViewString(context: self, stringID: "failureButtonGetInstaller"), target: self, selector: #selector(ChoseAppViewController.openGetAnApp), image: NSImage(named: NSImage.networkName))
						}
						
						self.addFailureButton(buttonTitle: TextManager.getViewString(context: self, stringID: "failureButtonOpen"), target: self, selector: #selector(ChoseAppViewController.chooseExternal), image: NSImage(named: NSImage.folderName))
					}
					
					self.showFailureImage()
					self.showFailureLabel()
					self.showFailureButtons()
					
					self.refreshButton.frame.origin.x = self.view.frame.width / 2 - self.refreshButton.frame.width / 2
					
					print("UI Failure mode!")
				}else{
					
					let content = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: self.scoller.frame.size.height - 17))
					
					self.scoller.hasHorizontalScroller = true
					
					DispatchQueue.global(qos: .background).sync {
						var temp: CGFloat = 20
						for d in drives{
							d.frame.origin.x = temp
							//if !blockShadow{
							temp += d.frame.width + (( look != .recovery ) ? 15 : 0)
							//}else{
							//	temp += d.frame.width
							//}
							content.addSubview(d)
						}
						
						content.frame.size.width = temp + ((look != .recovery) ? 5 : 20)
					}
					
					//TODO: this is not ok for resizable windows
					if content.frame.size.width < self.scoller.frame.width{
						let spacer = NSView(frame: NSRect(x: 0, y: 0, width: self.scoller.frame.width - 2, height: self.scoller.frame.height - 2))
						spacer.backgroundColor = NSColor.transparent
						spacer.identifier = NSUserInterfaceItemIdentifier(rawValue: self.spacerID)
						content.frame.origin = NSPoint(x: spacer.frame.width / 2 - content.frame.width / 2, y: 15 / 2)
						spacer.addSubview(content)
						self.scoller.documentView = spacer
					}else{
						self.scoller.documentView = content
					}
					
					if let documentView = self.scoller.documentView{
						documentView.scroll(NSPoint.init(x: 0, y: documentView.bounds.size.height))
						self.scoller.automaticallyAdjustsContentInsets = true
					}
					
					self.scoller.usesPredominantAxisScrolling = true
					
					print("UI Success")
				}
				
				self.spinner.stopAnimation(self)
				self.spinner.isHidden = true
				self.scoller.isHidden = false
			}
			
			print("UI taken care of")
		}
	}
	
}
