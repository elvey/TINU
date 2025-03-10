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

public final class App{
	
	#if !isTool && TINU
	
	public static var isTesting: Bool{
		
		struct MEM{
			static var checked: Bool! = nil
		}
		
		if let c = MEM.checked{
			return c
		}
		
		//log(AppBanner.banner)
		
		//LogManager.clear(true)
		LogManager.clearLog()
		
		let testingConditions = [
			simulateFormatFail,
			simulateFormatSkip,
			simulateNoUsableApps,
			simulateNoUsableDrives,
			simulateFirstAuthCancel,
			simulateAbnormalExitcode,
			simulateSecondAuthCancel,
			simulateConfirmGetDataFail,
			simulateCreateinstallmediaFail != nil,
			simulateNoSpecialOperations != nil,
			simulateSpecialOperationsFail,
			simulateRecovery,
			simulateSIPStatus != nil,
			simulateHIDPIStatus != nil,
			simulateReachabilityStatus != nil,
			simulateLook != nil
		]
		
		MEM.checked = false
		
		for tc in testingConditions{
			if !tc { continue }
				
			MEM.checked = true
			print("This copy of \(Bundle.main.name ?? "TINU") is running in a testing mode")
			break
			
		}
		
		return MEM.checked
	}
	
	#endif
	
	class func getApplicationSupportDirectory(create: Bool = true, subFolderName: String! = nil) -> String!{
		let fm = FileManager.default
		let paths = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
		
		if paths.count <= 0 { return nil }
		guard let start = paths.first?.path else { return nil }
		guard let folderName = Bundle.main.bundleIdentifier else { return nil }
		
		let directory = start + "/" + folderName + "/" + (subFolderName ?? "")
		
		if !fm.fileExists(atPath: directory){
			do {
				try fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
			}catch let err{
				print(err.localizedDescription)
				return nil
			}
		}
			
		return directory
	}
	
	public final class Settings{
		//use for settings management
		private static var defaults = UserDefaults.init()
		
		public enum Keys: String, Codable, Equatable, CaseIterable, RawRepresentable{
			#if !isTool && TINU
			case test = "test"
			#else
			#if EFIPM
			case startsAsMenuKey = "startsAsMenuItem"
			#else
			case test = "test"
			#endif
			#endif
		}
		
		//this function gets saved settings, should be called only once at app startapp
		public class func check(){
			if !Recovery.status {
				#if !isTool && TINU
				#else
					#if EFIPM
						setBool(key: Keys.startsAsMenuKey, variable: &startsAsMenu)
					#endif
				#endif
			}
		}
		
		//those functions are used to manage settings from the app load, the key is the "id" of the setting, and the value is the variable that will store the setting value, it needs to be initialized to the default value for the variable
		public class func get<T>(key: Keys, variable: inout T) -> Bool{
			guard let s = defaults.object(forKey: key.rawValue) as? T else{
				defaults.set(variable, forKey: key.rawValue)
				return false
			}
			
			variable = s
			return true
		}
		
		public class func get<T>(key: Keys, defaultValue: T) -> T{
			var variable: T = defaultValue
			let _ = get(key: key, variable: &variable)
			return variable
		}
		
		public class func getBool(key: Keys, defaultValue: Bool = false) -> Bool{
			return get(key: key, defaultValue: defaultValue)
		}
		
		public class func getString(key: Keys, defaultValue: String = "") -> String{
			return get(key: key, defaultValue: defaultValue)
		}
		
		public class func getInt(key: Keys, defaultValue: Int = 0) -> Int{
			return get(key: key, defaultValue: defaultValue)
		}
		
		public class func set<T>(key: Keys, variable: T){
			defaults.set(variable, forKey: key.rawValue)
		}
		
		public class func setBool(key: Keys, variable: Bool){
			set(key: key, variable: variable)
		}
		
		public class func setString(key: Keys, variable: String){
			set(key: key, variable: variable)
		}
		
		public class func setInt(key: Keys, variable: Int){
			set(key: key, variable: variable)
		}
		
	}
	
}
