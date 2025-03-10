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

//public typealias BSDID = String
//public extension BSDID{
public struct BSDID: Codable, Hashable, Equatable, RawRepresentable{
	public var rawValue: String
	
	public init() {
		self.rawValue = ""
	}
	
	public var isValid: Bool{
		return BSDID.isValid(rawValue)
	}
	
	private static func isValid(_ str: String) -> Bool{
		return str.isAlphanumeric && str.starts(with: "disk") && !str.isEmpty
	}
	
	public init(rawValue: String){
		self.init(rawValue)
	}
	
	public init(_ str: String){
		
		assert(BSDID.isValid(str), "BSDID must be valid before using it")
		
		self.rawValue = str
		
		assert(isValid, "BSDID must be valid before using it")
	}
	
	public init(_ str: String.Element){
		self.init(rawValue: String(str))
	}
	
	public init(other: BSDID){
		self.rawValue = other.rawValue
	}
	
	public init?(fromMountPoint mp: Path){
		assert(!mp.isEmpty, "The mount point should be a valid mount point!")
		assert(FileManager.default.directoryExistsAtPath(mp), "The mount point should be a path to something accessible!")
		do{
			if let dict = try Decode.plistToDictionary(from: dm.getPlist(for: mp) ?? "") as? [String: Any]{
				if var str = (dict["DeviceIdentifier"] as? String){
					
					if str.starts(with: "/dev/"){
						str = String(str.split(separator: "/").last!)
					}
					
					print(str)
					
					self.init(str)
					return
				}
			}
		}catch let err{
			log("Failed to get the BSDID. Produced error: ")
			log(err.localizedDescription)
		}
		
		return nil
	}
	
	public var hashValue: Int { return self.rawValue.hashValue }
	public func hash(into hasher: inout Hasher){
		hasher.combine(self.rawValue)
	}
	
	public var driveID: BSDID{
		
		assert(isValid, "BSDID must be valid before using it")
		
		var tmpBSDName = ""
		var ns = 0
		
		for cc in self.rawValue{
			let c = String(cc)
			if c.lowercased() == "s"{
				ns += 1
			}
			if ns == 1{
				if let _ = Int(c){
					tmpBSDName += c
				}
			}else if ns > 1{
				break
			}
		}
		
		return BSDID("disk" + tmpBSDName)
	}
	
	public var isDrive: Bool{
		return driveID == self
	}
	
	public var isVolume: Bool{
		return driveID != self
	}
	
	public func getInfoPlist() -> String?{
		return dm.getPlist(for: self.rawValue)
	}
	
	public func getInfoPropertyString(named: String) -> String?{
		return dm.getProperty(for: self, named: named) as? String
	}
	
	public func getInfoPropertyBool(named: String) -> Bool?{
		return dm.getProperty(for: self, named: named) as? Bool
	}
	
	public func getInfoPropertyUInt64(named: String) -> UInt64?{
		return dm.getProperty(for: self, named: named) as? UInt64
	}
	
	public func freeSpace() -> UInt64?{
		if let size = getInfoPropertyUInt64(named: "APFSContainerFree"){
			return size
		}
		
		if let size = getInfoPropertyUInt64(named: "FreeSpace"){
			return size
		}
		
		return nil
	}
	
	public func driveName() -> String?{
		var property = "MediaName"
		
		if #available(OSX 10.12, *){
			property = "IORegistryEntryName"
		}
	
		guard var name = driveID.getInfoPropertyString(named: property) else {
			print("------------Can't get the drive name for this drive")
			return nil
		}
		
		if #available(OSX 10.12, *){
			name = name.deletingSuffix(" Media")
		}
		
		name = name.isEmpty ? "Untitled drive" : name
		
		print("------------Drive name: \(name)")
		
		return name
	}
	
	public func mountPoint() -> String?{
		guard let mp = getInfoPropertyString(named: "MountPoint") else { return nil }
		
		if mp.isEmpty{
			return nil
		}
		
		return mp
	}
	
	//checks if the drive exists if it can find it's mount point
	public func isMounted() -> Bool{
		return mountPoint() != nil
	}
	
	///Used to detect external hard drives
	public func isExternalHardDrive() -> Bool?{
		let property = "EjectableOnly"
		return (isDrive ? self : driveID).getInfoPropertyBool(named: property)
	}
	
	public func isRemovable() -> Bool?{
		var property = "Ejectable"
		
		if #available(OSX 10.12, *){
			property = "RemovableMediaOrExternalDevice"
		}
		
		return (isDrive ? self : driveID).getInfoPropertyBool(named: property)
	}
	
	public func fileSystemName() -> String?{
		return getInfoPropertyString(named: "FilesystemName")
	}
	
	public func mount(useAdminPrivileges: Bool = false) -> Bool?{
		return Diskutil.mount(bsdID: self, useAdminPrivileges: useAdminPrivileges)
	}
	
	public func unmount(useAdminPrivileges: Bool = false) -> Bool?{
		return Diskutil.unmount(bsdID: self, useAdminPrivileges: useAdminPrivileges)
	}
	
	public func eject(useAdminPrivileges: Bool = false) -> Bool?{
		return Diskutil.eject(bsdID: self, useAdminPrivileges: useAdminPrivileges)
	}
	
	public var driveNumber: UInt?{
		return UInt(self.driveID.rawValue.deletingPrefix("disk"))
	}
	
}
