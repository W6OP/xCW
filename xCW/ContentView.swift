//
//  ContentView.swift
//  xCW
//
//  Created by Peter Bourget on 5/11/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  @State private var status = false
  @State private var cwText = CWText()
  @State private var showingDetail = false
  @Environment(\.presentationMode) var presentationMode
  
  let constHeightRatio : CGFloat = 0.55 //use for assembly with other fonts.
  let defaultHeight : CGFloat = 250 //use for assembly with other views.
  
  var body: some View {
    HStack {
      VStack {
        FirstRowView()
        SecondRowView()
        
        Divider()
        
        HStack {
          FreeFormTextView(cwText: cwText)
        }.frame(minWidth: 550, maxWidth: 550, minHeight: 110, maxHeight: 110)
        
        Divider()
        
        HStack(spacing: 25) {
          Button(action: {showDx(count: 20)}) {
            Text("Stop")//.frame(minWidth: 75, maxWidth: 75)
          }
          Button(action: {
            self.showingDetail.toggle()
          }) {
            Text("Radio Picker")
          }.sheet(isPresented: $showingDetail) {
            RadioPicker()
          }
          Text("Connected")//.frame(minWidth: 100, maxWidth: 100)
        }.frame(minWidth: 600, maxWidth: 600).padding(.bottom, 1)
        
        Divider()
        HStack(spacing: 30) {
          Text("Slice").frame(minWidth: 75, maxWidth: 75)
          Text("Mode").frame(minWidth: 75, maxWidth: 75)
          Text("Frequency").frame(minWidth: 75, maxWidth: 75)
          Button(action: {showDx(count: 20)}) {
            Text("Send Id").frame(minWidth: 75, maxWidth: 75)
          }
          // https://swiftwithmajid.com/2020/03/04/customizing-toggle-in-swiftui/
          Toggle(isOn: $status) {
            Text("Id Timer")
          }.frame(minWidth: 75, maxWidth: 75)
        }.padding(.bottom, 5)
      }.frame(minWidth: 600, maxWidth: 600)
      
    }
  } // end body
}

struct FirstRowView: View {
  var body: some View {
    HStack {
      //Text("Top").frame(maxWidth: .infinity, maxHeight: 100)
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
    }.frame(maxWidth: .infinity, maxHeight: 25).padding(.top, 5)
  }
}

struct SecondRowView: View {
  var body: some View {
    HStack {
      //Text("Top").frame(maxWidth: .infinity, maxHeight: 100)
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {showDx(count: 20)}) {
        Text("empty").frame(minWidth: 75, maxWidth: 75)
      }
    }.frame(maxWidth: .infinity, maxHeight: 25).padding(.bottom, 1)
  }
}

struct CWText {
  var line1: String = ""
  var line2: String = ""
  var line3: String = ""
  var line4: String = ""
  var line5: String = ""
}

struct FreeFormTextView: View {
  @State public var cwText: CWText
  
  var body: some View {
    
    VStack(spacing: 0) {
      TextField("Placeholder1", text: $cwText.line1)
      TextField("Placeholder2", text: $cwText.line2)
      TextField("Placeholder3", text: $cwText.line3)
      TextField("Placeholder4", text: $cwText.line4)
      TextField("Placeholder5", text: $cwText.line5)
    }.frame(minHeight: 100, maxHeight: 100)
  }
}

/**
 https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-new-view-using-sheets
 */
struct RadioPicker: View {
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    
//    HStack {
//        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
//         Text("Close Picker")
//        }
//    }
   
    let first = Radio(model: "Flex 6500", name: "DXSeeker", station: "Anya", isDefault: true)
    let second = Radio(model: "Flex 6500", name: "DXSeeker", station: "Char", isDefault: false )
    let third = Radio(model: "Flex 6500", name: "DXSeeker", station: "XYZZY", isDefault: false )
    
    let radios = [first, second, third]
    
    return VStack{
      HStack {
        List(radios, rowContent: RadioRow.init)
      }.frame(minWidth: 400, minHeight: 120)
      HStack {
          Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
           Text("Close Picker")
          }
      }
    }
  }
}

struct Radio: Identifiable {
  var id = UUID()
  
  var model: String = ""
  var name: String = ""
  var station: String = ""
  var isDefault: Bool = false
}

struct RadioRow: View {
    var radio: Radio

    var body: some View {
      
     Text("\(radio.model) : \(radio.name) : \(radio.station) : \(String(radio.isDefault))")
    }
}

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-view-dismiss-itself
func closePicker() {
  //self.presentationMode.wrappedValue.dismiss()
}

func showDx(count: Int) {
  
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}


/*
 https://stackoverflow.com/questions/57679966/how-to-create-a-multiline-textfield-in-swiftui-like-the-notes-app
 */

/**
 https://www.swiftdevjournal.com/using-text-views-in-a-swiftui-app/?utm_campaign=AppCoda%20Weekly&utm_medium=email&utm_source=Revue%20newsletter
 */
