//
//  MemoryView.swift
//  xCW
//
//  Created by Peter Bourget on 8/8/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI

struct CWMemoriesPicker: View {
    @Environment(\.presentationMode) var presentationMode
      @EnvironmentObject var radioManager: RadioManager
      @State private var entry = ""
      
      var body: some View {
        
        return VStack{
          HStack{
            Text("CW Memory Panel").frame(minWidth: 50).padding(.leading, 5)
          }
          .font(.system(size: 14))
          .foregroundColor(Color.blue)
          
          VStack {
            ForEach(radioManager.cwMemoryModels.indices, id: \.self ) { index in
              HStack {
                Button(action: { self.radioManager.sendCWMessage(tag: self.radioManager.cwMemoryModels[index].tag, freeText: "") }) {
                  Text(self.radioManager.cwMemoryModels[index].line)
                    .frame(minWidth: 50, maxWidth: 50)
                }
                .padding(.leading, 5).padding(.trailing, 5)
                .disabled(self.radioManager.sliceModel.radioMode.rawValue != "CW")
                
                // https://www.reddit.com/r/SwiftUI/comments/fauxsb/error_binding_textfield_to_object_in_array/
                TextField("Enter Text Here", text: self.$radioManager.cwMemoryModels[index].line,
                          onEditingChanged: { _ in
                            self.radioManager.saveCWMemory(message:
                              self.radioManager.cwMemoryModels[index].line, tag:
                              self.radioManager.cwMemoryModels[index].tag); print("TextField changed focus")},
                          onCommit: {
                            print("Committed!")
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
              }
            }
            .frame(minWidth: 400, maxWidth: 400)
          }
          .frame(minWidth: 450, maxWidth: 450)
          
          // syncs with main panel
          HStack {
            Text("Set Speed")
            Stepper(value: self.$radioManager.cwSpeed, in: 5...80,onEditingChanged: { _ in self.radioManager.saveCWSpeed(speed: self.radioManager.cwSpeed) }, label: { Text("\(self.radioManager.cwSpeed)") })
            
            Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
              Text("Close")
            }
            .padding(.leading, 150).padding(.bottom, 5)
          }
        }
        .background(Color.gray.opacity(0.20))
      }
    }

struct CWMemoriesPicker_Previews: PreviewProvider {
    static var previews: some View {
        CWMemoriesPicker().environmentObject(RadioManager())
    }
}
