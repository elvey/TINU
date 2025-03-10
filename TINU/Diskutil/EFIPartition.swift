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

public class EFIPartition: Codable, Equatable, Hashable, RawRepresentable{
	
	public var rawValue: BSDID
	
	required public init?(rawValue: BSDID){
		if !EFIPartition.genericCheck(rawValue){
			return nil
		}
		
		self.rawValue = rawValue
	}
	
	public func mount() -> Bool{
		log("Try to mount the EFI partition: \(rawValue)")
		
		if !check(){
			return false
		}
		
		var adminPriv = false
		
		if #available(macOS 10.13.3, *){
			adminPriv = true
		}
		
		let res = rawValue.mount(useAdminPrivileges: adminPriv) ?? false
		
		if res{
			log("EFI partition mounted with success: \(rawValue)")
		}else{
			log("EFI Partition not mounted !!!")
		}
		
		return res
	}
	
	public func unmount() -> Bool{
		log("Try to unmount the EFI partition: \(rawValue)")
		
		if !check(){
			return false
		}
		
		let res = rawValue.unmount() ?? false
		
		if res{
			log("EFI partition unmounted with success: \(rawValue)")
		}else{
			log("EFI Partition not unmounted: \(rawValue)")
		}
		
		return res
	}
	
	private static var partitionsCache: [BSDID]! = nil
	
	private static var isUpdatingPartitionsCache = false
	
	public static func clearPartitionsCache(){
		EFIPartition.partitionsCache?.removeAll()
		EFIPartition.partitionsCache = nil
	}
	
	public static func unmountAllPartitions() -> Bool{
		log("Unmounting all EFI partitions")
		
		guard let ps = listPartitions() else {
			log("Can't get the EFI partitions list!!")
			return false
		}
		
		for p in ps{
			log("      Unmounting EFI partition \(p.rawValue)")
			
			if !p.unmount(){
				log("      Unmounting EFI partition \(p.rawValue) failed!!!")
				return false
			}else{
				log("      Unmounting EFI partition \(p.rawValue) was successfoul")
			}
		}
		
		log("All EFI partitions successfully unmounted")
		
		return true
		
	}
	
	public func check() -> Bool{
		return EFIPartition.genericCheck(rawValue)
	}
	
	private static func genericCheck( _ id: BSDID) -> Bool{
		guard let list = EFIPartition.listIDs() else {
			print("    Invalid EFI partition list")
			return false
		}
		
		if !list.contains(id){
			print("    Invalid EFI partition: \(id)")
			return false
		}
		
		return true
	}
	
	private static func listIDs() -> [BSDID]!{
		if !(partitionsCache == nil || partitionsCache == []){
			return partitionsCache
		}
		
		isUpdatingPartitionsCache = true
		
		var usableDrives: [BSDID]! = nil
		
		guard let list = Diskutil.List() else {
			isUpdatingPartitionsCache = false
			clearPartitionsCache()
			return nil
		}
		
		for drive in list.allDisksAndPartitions{
			guard let efi = drive.getEFIPartition() else {
				continue
			}
			
			if usableDrives == nil{
				usableDrives = []
			}
			
			usableDrives.append(efi.DeviceIdentifier)
		}
		
		isUpdatingPartitionsCache = false
		
		if usableDrives != nil{
			partitionsCache = usableDrives
		}
		
		return usableDrives
	}
	
	public static func listPartitions() -> [EFIPartition]!{
		guard let ids = listIDs() else{
			print("Can't get valid partitions list, aborting")
			return nil
		}
		
		var ret = [EFIPartition]()
		
		for id in ids{
			guard let item = EFIPartition(rawValue: id) else{
				print("Can't allocate EFI Item for: \(id.rawValue)")
				continue
			}
			
			ret.append(item)
		}
		
		return ret
	}
}
