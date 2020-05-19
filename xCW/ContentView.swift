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
  @State private var isBound = false
  @State private var status = false
  @State private var cwText = CWMemoryModel(id: 0)
  @State private var showingDetail = false
  @State private var showingMemories = false
  @State private var isEnabled = false
  @State private var cwTextMessage = ""
  
  var body: some View {
    
    //let txt = _radioManager.safeToUse ? radioManager : nil
    //return RadioManager(txt)
    
    HStack {
      VStack {
        FirstRowView(isEnabled: $isEnabled).environmentObject(self.radioManager)
        SecondRowView(isEnabled: $isEnabled).environmentObject(self.radioManager)
        
        Divider()
        
        HStack {
          FreeFormScrollView(cwText: cwText)
        }.frame(minWidth: 550, maxWidth: 550, minHeight: 110, maxHeight: 110)
        
        Divider()
        
        HStack(spacing: 25) {
          Button(action: {sendFreeText()}) {
            Text("Send Free Text")//.frame(minWidth: 75, maxWidth: 75)
          }
          Button(action: {showDx(count: 20)}) {
            Text("Stop")//.frame(minWidth: 75, maxWidth: 75)
          }
          
          Button(action: {
            self.showingMemories.toggle()
          }) {
            Text("Memories")
          }.sheet(isPresented: $showingMemories) {
            // this is how to pass the radioManager
            return CWMemoriesPicker(cwTextMemoryModel: self.cwText, cwTextMessage: self.cwTextMessage).environmentObject(self.radioManager)
          }
          
          Button(action: {
            self.showingDetail.toggle()
          }) {
            Text("Radio Picker")
          }.sheet(isPresented: $showingDetail) {
            //RadioPicker() - should work
            // https://stackoverflow.com/questions/58743004/swiftui-environmentobject-error-may-be-missing-as-an-ancestor-of-this-view
            // this is how to pass the radioManager
          return RadioPicker().environmentObject(self.radioManager)
          }
          
          if radioManager.isConnected {
            Text("Connected to \(radioManager.guiClientModels[0].stationName)" )
          }
          else {
            Text("Disconnected")
          }
          
        }.frame(minWidth: 600, maxWidth: 600).padding(.bottom, 1)
        
        Divider()
        HStack(spacing: 30) {
          Text("Slice: \(radioManager.sliceModel.sliceLetter)").frame(minWidth: 100, maxWidth: 100)
          Text("Mode: \(radioManager.sliceModel.radioMode.rawValue)").frame(minWidth: 100, maxWidth: 100)
          Text("\(radioManager.sliceModel.frequency)").frame(minWidth: 100, maxWidth: 100)
          // https://swiftwithmajid.com/2020/03/04/customizing-toggle-in-swiftui/
//          Toggle(isOn: $status) {
//            Text("Id Timer")
//          }.frame(minWidth: 75, maxWidth: 75)
        }.padding(.bottom, 5)
      }.frame(minWidth: 600, maxWidth: 600)
      
    }
  } // end body
}

// MARK: - Sub Views ----------------------------------------------------------------------------

/**
 The first row of memory buttons.
 */
struct FirstRowView: View {
  @EnvironmentObject var radioManager: RadioManager
  //@ObservedObject var memories = CWMemories()
  @Binding var isEnabled: Bool
  
  var body: some View {
    HStack {
      Button(action: {self.radioManager.sendCWMessage(message: self.radioManager.retrieveCWMemory(tag: "cw1"))}) {
        Text("W6OP").frame(minWidth: 75, maxWidth: 75)
        }
      Button(action: {self.radioManager.sendCWMessage(message: self.radioManager.retrieveCWMemory(tag: "cw2"))}) {
        Text("CW2").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {self.radioManager.sendCWMessage(message: self.radioManager.retrieveCWMemory(tag: "cw3"))}) {
        Text("CW3").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {self.radioManager.sendCWMessage(message: self.radioManager.retrieveCWMemory(tag: "cw4"))}) {
        Text("CW4").frame(minWidth: 75, maxWidth: 75)
      }
      Button(action: {self.radioManager.sendCWMessage(message: self.radioManager.retrieveCWMemory(tag: "cw5"))}) {
        Text("CW5").frame(minWidth: 75, maxWidth: 75)
      }
    }.frame(maxWidth: .infinity, maxHeight: 25).padding(.top, 5)
  }
}

/**
The second row of memory buttons.
*/
struct SecondRowView: View {
  @EnvironmentObject var radioManager: RadioManager
  //@ObservedObject var memories = CWMemories()
  @Binding var isEnabled: Bool
  
  var body: some View {
    HStack {
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
        Text("Model").frame(minWidth: 50).padding(.leading, 5)
        Text("NickName").frame(minWidth: 90).padding(.leading, 28)
        Text("Station").frame(minWidth: 70).padding(.leading, 8)
        Text("Default Radio").frame(minWidth: 50).padding(.leading, 22)
      }.font(.system(size: 14))
        .foregroundColor(Color.blue)

        List(radioManager.guiClientModels, rowContent: StationRow.init).frame(minWidth: 400, minHeight: 120)

      HStack {
        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
          Text("Set as Default").padding(.bottom, 5)
        }
        
        Button(action: {self.radioManager.connectToRadio( guiclientModel: self.radioManager.guiClientModels[0], didConnect: true); self.presentationMode.wrappedValue.dismiss()}) {
          Text("Connect")
        }
        .padding(.leading, 25).padding(.bottom, 5)
        
        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
          Text("Cancel")
          }
        .padding(.leading, 25).padding(.bottom, 5)
      }
    }.background(Color.gray.opacity(0.20))
  }
}

// MARK: - CW Message Panel ----------------------------------------------------------------------------

struct CWMemoriesPicker: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var radioManager: RadioManager
  @State var cwTextMemoryModel: CWMemoryModel
  @State var cwTextMessage: String
  
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
            Button(action: { sendMemory(tag: "") }) {
              Text("Send")
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
        .frame(minWidth: 350, maxWidth: 350)
      }
      .frame(minWidth: 400, maxWidth: 400)
      
      /**
       List {
           ForEach(1...10, id: \.self) { index in
               HStack {
                 TextField("\(self.radioManager.cwMemoryModels[index].line)", text: self.$radioManager.cwMemoryModels[index].line)
               }
           }
       }
       */
      
      HStack {
        Button(action: {sendFreeText(); self.presentationMode.wrappedValue.dismiss()}) {
          Text("Send")
        }.padding(.leading, 25).padding(.bottom, 5)
        
        Button(action: {sendFreeText(); self.presentationMode.wrappedValue.dismiss()}) {
          Text("Close")
        }.padding(.leading, 125).padding(.bottom, 5)
      }
    }.background(Color.gray.opacity(0.20))
  }
}

/**
 View of rows of stations to select from.
 */
struct StationRow: View {
  var station: GUIClientModel
  
  var body: some View {
    HStack {
      HStack {
        Text("\(station.radioModel)").frame(minWidth: 50).padding(.leading, 2)
        Text("\(station.radioNickname)").frame(minWidth: 90).border(Color.black).padding(.leading, 25)
        Text("\(station.stationName)").frame(minWidth: 70).padding(.leading, 5).tag(station.stationName)
        
        Button(action: {showDx(count: 20)}) {
          Text("\(String(station.isDefaultStation))").frame(minWidth: 75, maxWidth: 75).background(Color.green.opacity(0.15))
        }
      }.border(Color.black)
    }.background(Color.blue.opacity(0.15))
  }
}

//struct CWTextRow: View {
//  var station: CWTextModel
//  //@State var cwText = ""
//
//  var body: some View {
//    VStack {
//      HStack {
//        Button(action: {showDx(count: 20)}) {
//          Text("\(String(station.tag))")
//            .foregroundColor(.blue)
//            .cornerRadius(25)
//          .shadow(radius: 10)
//          .padding(10)
//        }
//        //TextField("\(station.line)", text: cwText).tag
//          Text("\(station.line)").frame(minWidth: 200).border(Color.black).padding(.leading, 2)
//        }
//    }.background(Color.blue.opacity(0.15))
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

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-view-dismiss-itself
//func closePicker() {
//  //self.presentationMode.wrappedValue.dismiss()
//}

// MARK: - Button Implementation ----------------------------------------------------------------------------
func sendMemory(tag: String)
{
  
}

func sendFreeText() {
  
}
func showDx(count: Int) {
  
}

func selectStation(stationName: String, radioManager: RadioManager )  {
  
//  for guiClient in radioManager.guiClientModels{
////  if let client = guiClient.first(where: { $0.value.station == stationName} ){
////  }
//  }
  
  
  
//  radioManager.connectToRadio(serialNumber: self.radioManager.guiClientModels[0].serialNumber, station: self.radioManager.guiClientModels[0].stationName, clientId: self.radioManager.guiClientModels[0].clientId, didConnect: true)
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
