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

import Foundation
import AppKit
import Command
import CommandSudo

public extension Diskutil{
	
	//TODO: multithreaded bug!
	class func performCommand(withArgs args: [String], useAdminPrivileges: Bool = false) -> Command.Result?{
		var ret: Command.Result? = nil
		
		DispatchQueue.global(qos: .background).sync {
			
			let exec = "/usr/sbin/diskutil"
			
			ret = (useAdminPrivileges ? Command.Sudo.run(cmd: exec, args: args, shouldActuallyUseSudo: false) : Command.run(cmd: exec, args: args))
			
		}
		
		if ret?.errorString().contains("(-128)") ?? false{
			return nil
		}
		
		return ret
	}
	
	internal class func mount(bsdID: BSDID, useAdminPrivileges: Bool = false) -> Bool?{
		assert(bsdID.isValid, "BSDID must be a valid device identifier")
		if bsdID.isDrive{
			return nil
		}
		
		if let mount = bsdID.mountPoint() {
			if FileManager.default.directoryExistsAtPath(mount){
				log("Partition already mounted: \(bsdID) at mount point: \(mount)")
				return true
			}
		}
		
		guard let res = performCommand(withArgs: ["mount", bsdID.rawValue], useAdminPrivileges: useAdminPrivileges) else { return nil }
		
		let text = res.output.stringList()
		
		return res.errorString().isEmpty && ((text.contains("mounted") && (text.contains("Volume EFI on") || text.contains("Volume (null) on") || (text.contains("Volume ") && text.contains("on")))) || (text.isEmpty))
	}
	
	internal class func unmount( bsdID: BSDID, useAdminPrivileges: Bool = false) -> Bool?{
		assert(bsdID.isValid, "BSDID must be a valid device identifier")
		
		if bsdID.isDrive{
			guard let res = performCommand(withArgs: ["unmountDisk", bsdID.rawValue], useAdminPrivileges: useAdminPrivileges) else { return nil }
			
			let text = res.outputString()
			
			return text.contains("was successful") || text.isEmpty
		}
		
		if let mount = bsdID.mountPoint() {
			if !FileManager.default.directoryExistsAtPath(mount){
				log("Partition already unmounted: \(bsdID)")
				return true
			}
		}
		
		guard let res = performCommand(withArgs: ["unmount", bsdID.rawValue], useAdminPrivileges: useAdminPrivileges) else { return nil }
		
		let text = res.outputString()
			
		return ((text.contains("unmounted") && (text.contains("Volume EFI on") || text.contains("Volume (null) on") || (text.contains("Volume ") && text.contains("on")) || (text.contains("was already")) )) || (text.isEmpty))
	}
	
	internal class func eject(mountedDiskAtPath path: Path) -> Bool{
		return NSWorkspace.shared.unmountAndEjectDevice(atPath: path)
	}
	
	internal class func eject(bsdID: BSDID, useAdminPrivileges: Bool = false) -> Bool?{
		assert(bsdID.isValid, "BSDID must be a valid device identifier")
		guard let result = performCommand(withArgs: ["eject", bsdID.rawValue], useAdminPrivileges: useAdminPrivileges) else { return nil }
		
		var res = false
		let text = result.outputString()
		
		if !text.isEmpty && result.errorString().isEmpty{
		let resSrc: [(Bool, [String])] = [(true, [""]), (false, ["Unmount of all volumes on", "was successful"]), (false, ["Disk", "ejected"])]
			
		for s in resSrc{
			if !s.0{
				var breaked = false
				for r in s.1{
					if !text.contains(r){
						breaked = true
						break
					}
				}
				if breaked{
					continue
				}
			}else if !s.1.isEmpty{
				if text != s.1.first!{
					continue
				}
			}
			
			res = true
		}
			
			
		}
		
		return res
	}
	
	class func eraseHFS(bsdID: BSDID, newVolumeName: String , useAdminPrivileges: Bool = false) -> Bool?{
		assert(bsdID.isValid, "BSDID must be a valid device identifier")
		guard let result = performCommand(withArgs: ["eraseDisk", "JHFS+", "\"\(newVolumeName)\"", "/dev/" + bsdID.rawValue], useAdminPrivileges: useAdminPrivileges) else { return nil }
		
		if !result.errorString().isEmpty{
			log("----Volume format process fail: ")
			log("         Format script output: \n" + result.outputString())
			log("         Format script error: \n" + result.errorString())
			return false
		}
		
		//output separated in parts
		let c = result.outputString().components(separatedBy: "\n")
		
		if c.isEmpty{
			log("Failed to get outut from the format process")
			return false
		}
		
		if (c.count <= 1 && c.first!.isEmpty){
			//too less output from the process
			log("Failed to get valid output for the format process")
			return false
		}
		
		//checks if the erase has been completed with success
		if !c.last!.contains("Finished erase on disk"){
			
			//the format has failed, so the boolean is false and a screen with installer creation failed will be displayed
			log("----Volume format process fail: ")
			log("         Format script output: \n" + result.outputString())
			
			return false
		}
		
		return true
	}
	
}
