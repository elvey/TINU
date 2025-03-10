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

//the view controller of the log window
class LogViewController: GenericViewController, NSSharingServicePickerDelegate, NSSharingServiceDelegate, ViewID {
	let id: String = "LogViewController"
    @IBOutlet var content: NSTextView!
    @IBOutlet weak var scroller: NSScrollView!
    
    var timer: Timer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		
		self.view.superview?.wantsLayer = true
		self.view.wantsLayer = true
		
		content.font = NSFont(name: "Menlo", size: 12)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
		
		content.textColor = NSColor.textColor
		
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.updateLog(_:)), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
		invalidateTimer()
    }
	
	deinit {
		invalidateTimer()
	}
	
	private func invalidateTimer(){
		timer.invalidate()
		timer = nil
	}
    
	@objc func updateLog(_ sender: AnyObject){
		//print("Log updated")
		//if let l = LogManager.read(){
		DispatchQueue.global(qos: .background).async {
			guard let l = LogManager.readAllLog() else{ return }
			DispatchQueue.main.sync {
				if l != self.content.text{
					self.content.text = l
				}
			}
		}
	}
	
	/*
	@objc func copyLog( _ sender: Any){
		if let win = self.window.windowController as? LogWindowController{
			win.copyLog(sender)
		}else{
			log("win controller is not of the right kind")
		}
	}
	
	@objc func shareLog( _ sender: Any){
		if let win = self.window.windowController as? LogWindowController{
			win.shareLog(sender)
		}else{
			log("win controller is not of the right kind")
		}
	}
	
	@objc func saveLog( _ sender: Any){
		if let win = self.window.windowController as? LogWindowController{
			win.saveLog(sender)
		}else{
			log("win controller is not of the right kind")
		}
	}*/
	
	@IBAction func saveLog( _ sender: Any){
		guard let win = self.window else {
			log("Wrong view controller!")
			return }
		
		let vc = self
		
		let open = NSSavePanel()
		open.isExtensionHidden = false
		//open.showsHiddenFiles = true
		
		open.allowedFileTypes = ["txt"]
		
		open.beginSheetModal(for: win, completionHandler: { response in
			if response == NSApplication.ModalResponse.OK{
				return
			}
			
			guard let u = open.url?.path else { return }
			//read ui stuff just from the main thread
			
			
			DispatchQueue.global(qos: .userInteractive).async {
				do{
					let text = LogManager.readAllLog() ?? ""
					try text.write(toFile: u, atomically: true, encoding: .utf8)
				}catch let error{
					log(error.localizedDescription)
					//msgBoxWarning("Error while saving the log file", "There was an error while saving the log file: \n\n" + error.localizedDescription)
					let prev = Alert.window
					Alert.window = win
					msgboxWithManager(vc, name: "saveError", parseList: ["{desc}" : error.localizedDescription])
					Alert.window = prev
				}
			}
			
		})
		
	}
	
	@IBAction func copyLog( _ sender: Any){
		DispatchQueue.global(qos: .background).async {
			
			NSPasteboard.general.clearContents()
			NSPasteboard.general.writeObjects([NSString(string: LogManager.readAllLog() ?? "")])
			
			Notifications.justSendWith(id: "copyLog", icon: nil)
		}
		
		print("Log copied to clipboard")
	}
	
	@IBAction func shareLog( _ sender: Any){
		print("Shared called")
		
		DispatchQueue.global(qos: .userInteractive).async {
			let text = LogManager.readAllLog() ?? ""
			
			DispatchQueue.main.sync {
				guard let sen = sender as? NSView else { return }
				
				print("Share good")
				
				let service = NSSharingServicePicker(items: [text])
				service.delegate = self
				service.show(relativeTo: sen.bounds, of: sen, preferredEdge: .minY)
				
			}
			
		}
	}
	
}
