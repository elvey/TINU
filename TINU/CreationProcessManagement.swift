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
import Command

extension CreationProcess{
	
	//TODO: put this into it's own file
	class Management {
		
		enum Status: UInt8, CaseIterable, Codable, Equatable{
			case configuration = 0
			case preCreation
			case creation
			case postCreation
			case doneSuccess
			case doneFailure
			
			func isBusy() -> Bool{
				return (self == .creation || self == .preCreation || self == .postCreation)
			}
		}
		
		public var status: Status = .configuration
		public var startTime = Date()
		public var handle: Command.Handle!
	}

}
