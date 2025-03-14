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

import AppKit

public func parse(messange: String, keys: [String: String]) -> String{
	var ret = ""
	for piece in messange.split(separator: "$"){
		var s = String(piece)
		
		for key in keys{
			if s.starts(with: key.key){
				s.deletePrefix(key.key)
				s = key.value + s
				break
			}
		}
		
		ret += s
	}
	
	return ret
}

public func strFill(of section: String, length: UInt64, startSeq: String! = nil, endSeq: String! = nil, forget: Bool = false) -> String{
	struct FillData: Equatable, Hashable{
		let section: String
		let length: UInt64
		let startSeq: String!
		let endSeq: String!
		
		static var fills: [FillData: String] = [:]
	}
	
	let key = FillData(section: section, length: length, startSeq: startSeq, endSeq: endSeq)
	
	if let fill = FillData.fills[key]{
		if forget{
			FillData.fills[key] = nil
		}
		return fill
	}
	
	var tmp = startSeq ?? ""
	
	for _ in 0..<(length){
		tmp += section
	}
	
	tmp += (endSeq ?? "")
	
	if !forget{
		FillData.fills[key] = tmp
	}
	
	print(FillData.fills)
	
	return tmp
}
