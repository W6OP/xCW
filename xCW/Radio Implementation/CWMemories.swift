//
//  CWMemories.swift
//  xCW
//
//  Created by Peter Bourget on 5/17/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Foundation

///**
// Data model for the text in the freeform text section.
// */
//struct CWText: Hashable {
//  var id = UUID()
//  
//  var line1: String = ""
//  var line2: String = ""
//  var line3: String = ""
//  var line4: String = ""
//  var line5: String = ""
//  var line6: String = ""
//  var line7: String = ""
//  var line8: String = ""
//  var line9: String = ""
//  var line10: String = ""
//}

//class CWMemories: ObservableObject {
//
//  @Published var cwText = CWTextModel()
//
//    init() {
//       retrieveAllCWmemories()
//    }
//
//  func saveCWMemories(message: String, tag: String) {
//
//    UserDefaults.standard.set(message, forKey: String(tag))
//  }
//
//  func retrieveCWMemory(tag: String) -> String {
//    return(UserDefaults.standard.string(forKey: String(tag)) ?? "")
//  }
//
//  func retrieveAllCWmemories() {
//
//    cwText.line1 = "Line1" //UserDefaults.standard.string(forKey: String("cw1")) ?? ""
//    cwText.line2 = "Line 2" //UserDefaults.standard.string(forKey: String("cw2")) ?? ""
//    cwText.line3 = UserDefaults.standard.string(forKey: String("cw3")) ?? ""
//    cwText.line4 = UserDefaults.standard.string(forKey: String("cw4")) ?? ""
//    cwText.line5 = UserDefaults.standard.string(forKey: String("cw5")) ?? ""
//    cwText.line6 = UserDefaults.standard.string(forKey: String("cw6")) ?? ""
//    cwText.line7 = UserDefaults.standard.string(forKey: String("cw7")) ?? ""
//    cwText.line8 = UserDefaults.standard.string(forKey: String("cw8")) ?? ""
//    cwText.line9 = UserDefaults.standard.string(forKey: String("cw9")) ?? ""
//    cwText.line10 = UserDefaults.standard.string(forKey: String("cw10")) ?? ""
//  }
//
//} // end class
