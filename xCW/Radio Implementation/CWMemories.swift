//
//  CWMemories.swift
//  xCW
//
//  Created by Peter Bourget on 5/17/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import Foundation

class CWMemories: ObservableObject {
  
   
    
    init() {
       
    }
    
  func saveCWMemories(message: String, tag: String) {
    
    UserDefaults.standard.set(message, forKey: String(tag))
  }
  
  func retrieveCWMemory(tag: String) -> String {
    return(UserDefaults.standard.string(forKey: String(tag)) ?? "")
  }
  
} // end class
