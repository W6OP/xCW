//
//  RadioBinder.swift
//  xCW
//
//  Created by Peter Bourget on 5/14/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Foundation
import SwiftUI

class RadioBinder: ObservableObject {
  
  //let objectWillChange = PassthroughSubject<Void, Never>()
  
  var show = false {
      willSet {
          objectWillChange.send()
      }
  }

} // end class

//class GUIClientModel: ObservableObject {
//
//  @Published var guiClientModel = [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: UInt32)]()
//
//
//
//
//
//} // end class
