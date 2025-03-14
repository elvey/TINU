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
import Command
import CommandSudo

extension InstallMediaCreationManager{
	
	struct ExecInfo{
		var path: Path
		var args: [String]
		var shouldNotUseSudo: Bool
	}
	
	func install(){
		
		log("\nStarting the process...")
		
		//to have an usable UI during the install we need to use a parallel thread
		DispatchQueue.global(qos: .background).async {
			//cvm.shared.process.isPreCreationInProgress = true
			cvm.shared.process.status = .preCreation
			
			var tCMD = ExecInfo(path: "", args: [], shouldNotUseSudo: true)
			
			//self.dname = cvm.shared.disk.current.driveName
			
			DispatchQueue.main.sync {
				self.setProgressValue(0)
			}
			
			var success = true
			
			preFor: for i in 1...InstallMediaCreationManager.preCount{
				
				if !success{
					break
				}
				
				//activity label text id calculation
				let userText: String = (i < 4 || i == 7) ? "activityLabel" + String(11 + i) : ""
				
				DispatchQueue.main.sync {
					self.addToProgressValue(InstallMediaCreationManager.unit)
					if !userText.isEmpty{
						self.setActivityLabelText(userText)
					}
				}
				
				switch i{
				case 1:
					success = self.killConflictingPrcesses()
					break
				case 2:
					success = self.unmountConflictingVolumes()
					break
				/*case 3:
				self.OtherOptionsBeforeformat(canFormat: &canFormat, useAPFS: &useAPFS)
				break*/
				case 4:
					if cvm.shared.options.execution.canFormat{
						success = self.formatTargetDrive()
					}
					break
				case 5:
					processLicense = ""
					break
				case 6:
					//if the process will install mac, special operations are performed before the beginning of the "startosinstall" process
					if cvm.shared.installMac{
						DispatchQueue.main.sync {
							self.setProgressValue(0.01)
							//self.setActivityLabelText("Applying options")
							self.setActivityLabelText("activityLabel10")
						}
						
						success = !(self.manageSpecialOperations() ?? false)
					}
					break
				case 7:
					//tCMD = self.buildCommandString(useAPFS: cvm.shared.options.execution.canUseApfs)
					tCMD = self.buildCommandStringNew(process: cvm.shared)
					
					log("The application that will be used is: " + cvm.shared.app.path )
					log("The target drive is: " + cvm.shared.disk.path )
					log("The script that will be performed is (including quotes): " + tCMD.path + " " + tCMD.args.stringLine() )
					
					break
				default:
					break
				}
				
				if success{
					success = (cvm.shared.disk.path != nil || (cvm.shared.disk.current.isDrive && (i < 4) ) && cvm.shared.app.path != nil && cvm.shared.disk.bSDDrive != nil)
					if !success{
						log("Data error: ")
						let err = "[ERROR: No data available]"
						log("    Choosen volume path is: \(cvm.shared.disk.path ?? err)")
						log("    Choosen volume BSDID is: \(cvm.shared.disk.bSDDrive?.rawValue ?? err)")
						log("    Choosen installer app path is: \(cvm.shared.app.path ?? err)")
					}
				}
			}
			
			if !success{
				print("Process failure detected")
				DispatchQueue.main.sync {
					self.viewController.goBack()
				}
				return
			}
			
			DispatchQueue.main.sync {
				self.setProgressValue(self.processUnit)
			}
			
			self.launchExecution(tCMD)
		}
	}
	
	fileprivate func launchExecution(_ info: ExecInfo){
		
		var check = info.path
		if check.first == "\""{
			check.removeFirst()
		}
		if check.last == "\""{
			check.removeLast()
		}
		
		if !FileManager.default.fileExists(atPath: check){
			DispatchQueue.main.sync {
				log("Invalid app executable")
				self.viewController.goBack()
			}
				
			return
		}
		
		cvm.shared.process.status = .creation
		
		//let args = ["-c", tCMD]
		//let exec = "/bin/zsh"
		
		//let args = ["-c", tCMD]
		//let exec = "/bin/zsh"
		
		#if noFirstAuth
		let noFAuth = true
		#else
		let noFAuth = false
		#endif
		
		cvm.shared.process.handle = (!info.shouldNotUseSudo || noFAuth) ? Command.start(cmd: info.path, args: info.args) : Command.Sudo.start(cmd: info.path, args: info.args)
		
		if cvm.shared.process.handle == nil{
			
			//here the auth is failed or some execution error
			DispatchQueue.main.sync {
				log("User authentication failed or aborted")
				self.viewController.goBack()
			}
			
			return
		}
		
		if cvm.shared.installMac{
			log("\n\nmacOS installation process started\n")
		}else{
			log("\n\nInstaller creation process started\n")
		}
		
		log(TextManager!.helpfoulMessage!)
		
		log("""
				
				Waiting for the \(cvm.shared.actualExecutableName) executable to finish...
				
				""")
		
		//UI setup
		DispatchQueue.main.sync {
			/*
			if sharedInstallMac{
			self.setActivityLabelText("Installing macOS\n(may take from 5 to 50 minutes)")
			}else{
			self.setActivityLabelText("Creating bootable macOS installer\n(may take from 5 to 50 minutes)")
			}*/
			
			self.setActivityLabelText("activityLabel11")
			
			//cancel button and the close button can be restored
			self.viewController.cancelButton.isEnabled = true
			
			if let ww = UIManager.shared.window{
				//ww.isMiniaturizeEnaled = false
				ww.isClosingEnabled = true
				//ww.canHide = false
			}
		}
		
		//here insted just uses a timer to see if the process has finished and stops this thread
		//assign processes variables
		cvm.shared.process.startTime = Date()
		
		
		DispatchQueue.main.sync {
			self.timer.invalidate()
			self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkProcessFinished(_:)), userInfo: nil, repeats: true)
		}
		
		//2 different aproces of handeling the process end detection
		if simulateNoTimer{
			//code used if the timer is not used
			cvm.shared.process.handle.process.waitUntilExit()
			
			DispatchQueue.main.sync {
				self.installFinished()
			}
		}
		
		
	}
	
}
