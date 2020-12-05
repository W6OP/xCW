//
//  CWPreferencesView.swift
//  xCW
//
//  Created by Peter Bourget on 5/17/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI

struct CWPreferencesView: View {
  @State private var cwText = CWMemoryModel(id: 0)
  
    var body: some View {
     
      FreeFormTextView(cwText: cwText)
      
    }
}

struct FreeFormTextView: View {
  @State public var cwText: CWMemoryModel
  @State private var cwString1: String = UserDefaults.standard.string(forKey: "cw1") ?? ""
  @State private var name: String = "Tim"
  
  var body: some View {
    
    VStack(spacing: 0) {
      TextField("Placeholder1", text: $cwString1)
      .textFieldStyle(RoundedBorderTextFieldStyle())
    }.frame(minHeight: 100, maxHeight: 100)
    
  }
  
}

struct CWPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        CWPreferencesView()
    }
}
