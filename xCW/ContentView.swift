//
//  ContentView.swift
//  xCW
//
//  Created by Peter Bourget on 5/11/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI


extension EnvironmentObject
{
  var safeToUse: Bool {
    return (Mirror(reflecting: self).children.first(where: { $0.label == "_store"})?.value as? ObjectType) != nil
  }
}

// MARK: - Primary View ----------------------------------------------------------------------------

/**
 primary Content View for the application.
 */
struct ContentView: View {
  // initialize radio
  @EnvironmentObject var radioManager: RadioManager
  @Environment(\.presentationMode) var presentationMode
  
  @State private var isConnected = false
  @State private var cwText = CWMemoryModel(id: 0)
  @State private var showingRadios = false
  @State private var showingMemories = false
  
  var body: some View {
   
    HStack {
      VStack {
        FirstRowView().environmentObject(self.radioManager).disabled(!radioManager.isConnected)
        SecondRowView().environmentObject(self.radioManager).disabled(!radioManager.isConnected)
        
        Divider()
        
        HStack {
          FreeFormScrollView(cwText: cwText)
        }
        .frame(minWidth: 550, maxWidth: 550, minHeight: 110, maxHeight: 110)
        
        Divider()
        
        HStack(spacing: 25) {
          Button(action: {showDx(count: 20)}) {
            Text("Stop")
              .frame(minWidth: 78, maxWidth: 78)
          }.disabled(!radioManager.isConnected)
          
          Button(action: {sendFreeText()}) {
            Text("Send Text")
              .frame(minWidth: 78, maxWidth: 78)
          }.disabled(!radioManager.isConnected)
          
          // show the cw memory panel
          Button(action: {
            self.showingMemories.toggle()
          }) {
            Text("Memories")
              .frame(minWidth: 78, maxWidth: 78)
          }.disabled(!radioManager.isConnected)
          .sheet(isPresented: $showingMemories) {
            return CWMemoriesPicker().environmentObject(self.radioManager)
          }
          
          // show the radio picker
          Button(action: {
            self.showingRadios.toggle()
          }) {
            Text("Radio Picker")
              .frame(minWidth: 78, maxWidth: 78)
          }
          .sheet(isPresented: $showingRadios) {
            // https://stackoverflow.com/questions/58743004/swiftui-environmentobject-error-may-be-missing-as-an-ancestor-of-this-view
            // this is how to pass the radioManager
            return RadioPicker().environmentObject(self.radioManager)
          }
        }
        .frame(minWidth: 600, maxWidth: 600).padding(.bottom, 1)
        
        Divider()
        HStack(spacing: 30) {
          // this needs to be when
          // boundStationHandle == sliceHandle
          
          // first(where: $0.slicehandle == guiClienet.handle
          // guiClientModels.first(where: { $0.clientHandle == radioManager.guiClients.handle} )
          // radioManager.guiClients.filter({ $0.handle == radioManager.sliceModel.clientHandle }).first
          Text("Slice: \(radioManager.sliceModel.sliceLetter)").frame(minWidth: 100, maxWidth: 100)
          Text("Mode: \(radioManager.sliceModel.radioMode.rawValue)").frame(minWidth: 100, maxWidth: 100)
          Text("\(radioManager.sliceModel.frequency)").frame(minWidth: 100, maxWidth: 100)
          
          if radioManager.isConnected {
            Text("Connected to \(radioManager.sliceModel.associatedStationName)" )
          }
          else {
            Text("Disconnected")
          }
        }
        .padding(.bottom, 5)
      }
      .frame(minWidth: 600, maxWidth: 600)
    }
  } // end body
}

// MARK: - Sub Views ----------------------------------------------------------------------------

/**
 The first row of memory buttons.
 */
struct FirstRowView: View {
  @EnvironmentObject var rM: RadioManager
  
  var body: some View {
    HStack {
      Button(action: {self.rM.sendCWMessage(tag: "1")}) {
        Text("CW1")
          .frame(minWidth: 75, maxWidth: 75)//.background(Color.blue.opacity(0.20)).cornerRadius(5)
      }
      //.background(Color.blue.opacity(0.20)).cornerRadius(5)
      
      Button(action: {self.rM.sendCWMessage(tag: "2")}) {
        Text("CW2")
          .frame(minWidth: 75, maxWidth: 75)
      }
      //.background(Color.blue).cornerRadius(5)
      
      Button(action: {self.rM.sendCWMessage(tag: "3")}) {
        Text("CW3")
          .frame(minWidth: 75, maxWidth: 75)
      }
      
      Button(action: {self.rM.sendCWMessage(tag: "4")}) {
        Text("CW4")
          .frame(minWidth: 75, maxWidth: 75)
      }
      
      Button(action: {self.rM.sendCWMessage(tag: "5")}) {
        Text("CW5")
          .frame(minWidth: 75, maxWidth: 75)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: 25).padding(.top, 5)
  }
}

/**
 The second row of memory buttons.
 */
struct SecondRowView: View {
  @EnvironmentObject var rM: RadioManager
  
  var body: some View {
    HStack {
      Button(action: {self.rM.sendCWMessage(tag: "6")}) {
        Text("CW6")
          .frame(minWidth: 75, maxWidth: 75)
      }
      
      Button(action: {self.rM.sendCWMessage(tag: "7")}) {
        Text("CW7")
          .frame(minWidth: 75, maxWidth: 75)
      }
      
      Button(action: {self.rM.sendCWMessage(tag: "8")}) {
        Text("CW8")
          .frame(minWidth: 75, maxWidth: 75)
      }
      
      Button(action: {self.rM.sendCWMessage(tag: "9")}) {
        Text("CW9")
          .frame(minWidth: 75, maxWidth: 75)
      }
      
      Button(action: {self.rM.sendCWMessage(tag: "10")}) {
        Text("CW10")
          .frame(minWidth: 75, maxWidth: 75)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: 25).padding(.bottom, 1)
  }
}

/**
 TextView for freeform cw
 */
struct  FreeFormScrollView: View {
  @State public var cwText: CWMemoryModel
  
  var body: some View{
    VStack{
      TextView(text: $cwText.line)
    }
  }
}


// MARK: - Radio Picker Sheet ----------------------------------------------------------------------------

/**
 View of the Radio Picker sheet.
 https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-new-view-using-sheets
 */
struct RadioPicker: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var radioManager: RadioManager
  
  var body: some View {
    
    return VStack{
      HStack{
        Text("Model").frame(minWidth: 70)//.padding(.leading, 2)
        Text("NickName").frame(minWidth: 100).padding(.leading, 20)
        Text("Station").frame(minWidth: 80).padding(.leading, 8)
        Text("Default Radio").frame(minWidth: 50).padding(.leading, 22)
      }
      .font(.system(size: 14))
      .foregroundColor(Color.blue)
      
      // this works but I can't get a handle to radioManager in the StationRow
      //      List(radioManager.guiClientModels, rowContent: StationRow.init)
      //        .frame(minWidth: 450, minHeight: 120)
      // Radio Picker
      ForEach(radioManager.guiClientModels.indices ) { guiClientModel in
        HStack {
          HStack {
            Text("\(self.radioManager.guiClientModels[guiClientModel].radioModel)").frame(minWidth: 70).padding(.leading, 2)
            
            Text("\(self.radioManager.guiClientModels[guiClientModel].radioNickname)").frame(minWidth: 120).padding(.leading, 25)
            
            Button(action: {connectToRadio( guiClientModel: self.radioManager.guiClientModels[guiClientModel], radioManager: self.radioManager); self.presentationMode.wrappedValue.dismiss()}) {
              Text("\(self.radioManager.guiClientModels[guiClientModel].stationName)")
            }
//            Text("\(self.radioManager.guiClientModels[guiClientModel].stationName)").frame(minWidth: 90).padding(.leading, 5).tag(self.radioManager.guiClientModels[guiClientModel].stationName)
            
            Button(action: {setDefault(stationName: self.radioManager.guiClientModels[guiClientModel].stationName, radioManager: self.radioManager)}) {
              Text("\(String(self.radioManager.guiClientModels[guiClientModel].isDefaultStation))")//.frame(minWidth: 65, maxWidth: 65)
            }
          }
          .border(Color.black)
        }
        .background(Color.blue.opacity(0.15))
      }

      HStack {
//        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
//          Text("Set as Default").padding(.bottom, 5)
//        }
        
//        Button(action: {self.radioManager.connectToRadio( guiclientModel: self.radioManager.guiClientModels[0], didConnect: true); self.presentationMode.wrappedValue.dismiss()}) {
//          Text("Connect")
//        }
//        .padding(.leading, 25).padding(.bottom, 5)
        
        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
          Text("Cancel")
        }
        .padding(.leading, 25).padding(.bottom, 5)
      }
    }
    .background(Color.gray.opacity(0.20))
  }
}

// MARK: - CW Message Panel ----------------------------------------------------------------------------

struct CWMemoriesPicker: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var radioManager: RadioManager
  
  var body: some View {
    
    return VStack{
      HStack{
        Text("CW Memory Panel").frame(minWidth: 50).padding(.leading, 5)
      }
      .font(.system(size: 14))
      .foregroundColor(Color.blue)
      
      VStack {
        ForEach(radioManager.cwMemoryModels.indices ) { cwMemoryModel in
          HStack {
            Button(action: { sendMemory(tag: self.radioManager.cwMemoryModels[cwMemoryModel].tag, radioManager: self.radioManager) }) {
              Text(self.radioManager.cwMemoryModels[cwMemoryModel].tag)
                .frame(minWidth: 30)
            }
            .padding(.leading, 5).padding(.trailing, 5)
            
            // https://www.reddit.com/r/SwiftUI/comments/fauxsb/error_binding_textfield_to_object_in_array/
            TextField("Enter Text Here", text: self.$radioManager.cwMemoryModels[cwMemoryModel].line,
                      onEditingChanged: { _ in
                        self.radioManager.saveCWMemories(message:
                          self.radioManager.cwMemoryModels[cwMemoryModel].line, tag:
                          self.radioManager.cwMemoryModels[cwMemoryModel].tag)  })
          }
        }
        .frame(minWidth: 400, maxWidth: 400)
      }
      .frame(minWidth: 450, maxWidth: 450)
      
      HStack {
        
//        Text("Set Speed")
//        Stepper(value: self.$radioManager.cwSpeed, in: 5...80) {
//            Text("\(self.radioManager.cwSpeed)")
//        }
        
        Text("Set Speed")
        Stepper(value: self.$radioManager.cwSpeed, in: 5...80,onEditingChanged: { _ in setCWSpeed(cwSpeed: self.radioManager.cwSpeed, radioManager: self.radioManager) }, label: { Text("\(self.radioManager.cwSpeed)") })

        
        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
          Text("Close")
        }
        .padding(.leading, 150).padding(.bottom, 5)
      }
    }
    .background(Color.gray.opacity(0.20))
  }
}

/**
 View of rows of stations to select from.
 */
//struct StationRow: View {
//  var guiClient: GUIClientModel
//
//  var body: some View {
//    HStack {
//      HStack {
//        Text("\(guiClient.radioModel)").frame(minWidth: 70).padding(.leading, 2)
//        Text("\(guiClient.radioNickname)").frame(minWidth: 120).padding(.leading, 25)
//        Text("\(guiClient.stationName)").frame(minWidth: 90).padding(.leading, 5).tag(guiClient.stationName)
//
//        Button(action: {setDefault(stationName: self.guiClient.stationName)}) {
//          Text("\(String(guiClient.isDefaultStation))").frame(minWidth: 65, maxWidth: 65)
//        }
//      }
//      .border(Color.black)
//    }
//    .background(Color.blue.opacity(0.15))
//  }
//}

/**
 Button(action: {
 self.selectedBtn = item
 }){
 Text(self.box.title)
 .foregroundColor(.white)
 }
 .frame(width: 130, height: 50)
 .background(self.selectedBtn == item ? Color.red : Color.blue)
 .cornerRadius(25)
 .shadow(radius: 10)
 .padding(10)
 */


// MARK: - Button Implementation ----------------------------------------------------------------------------
func sendMemory(tag: String, radioManager: RadioManager )
{
  radioManager.sendCWMessage(tag: tag)
}

func sendFreeText() {
  
}
func showDx(count: Int) {
  
}

func setCWSpeed(cwSpeed: Int, radioManager: RadioManager) {
  radioManager.saveCWSpeed(speed: cwSpeed)
}

func connectToRadio(guiClientModel: GUIClientModel, radioManager: RadioManager){
  
  radioManager.connectToRadio(guiClientModel: guiClientModel)
}

func setDefault(stationName: String, radioManager: RadioManager) {
  radioManager.setDefaultRadio(stationName: stationName)
}

func selectStation(stationName: String, radioManager: RadioManager )  {
 
}

// MARK: - Preview Provider ----------------------------------------------------------------------------
/**
 Preview provider.
 */
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

// MARK: - TextView Wrapper ----------------------------------------------------------------------------


struct TextView: NSViewRepresentable {
  
  @Binding var text: String
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  func makeNSView(context: Context) -> NSTextView {
    
    let myTextView = NSTextView()
    myTextView.delegate = context.coordinator
    
    myTextView.font = NSFont(name: "HelveticaNeue", size: 15)
    //        myTextView.isScrollEnabled = true
    myTextView.isEditable = true
    myTextView.backgroundColor = NSColor(white: 0.0, alpha: 0.15)
    
    return myTextView
  }
  
  func updateNSView(_ nsView: NSTextView, context: Context) {
    nsView.string = text
  }
  
  class Coordinator : NSObject, NSTextViewDelegate {
    
    var parent: TextView
    
    init(_ nsTextView: TextView) {
      self.parent = nsTextView
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString text: String?) -> Bool {
      let newText = textView.string
      
      //        newText.removeAll { (character) -> Bool in
      //            return character == " " || character == "\n"
      //        }
      
      return newText.count < 500
      //return true
    }
    
    func textViewDidChange(_ textView: NSTextView) {
      //print("text now: \(String(describing: textView.text!))")
      self.parent.text = textView.string
    }
  }
}


/*
 https://stackoverflow.com/questions/57679966/how-to-create-a-multiline-textfield-in-swiftui-like-the-notes-app
 */

/**
 https://www.swiftdevjournal.com/using-text-views-in-a-swiftui-app/?utm_campaign=AppCoda%20Weekly&utm_medium=email&utm_source=Revue%20newsletter
 */
