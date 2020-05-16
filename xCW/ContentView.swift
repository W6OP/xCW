//
//  ContentView.swift
//  xCW
//
//  Created by Peter Bourget on 5/11/20.
//  Copyright © 2020 Peter Bourget. All rights reserved.
//

import SwiftUI

// MARK: - Primary View ----------------------------------------------------------------------------

/**
 primary Content View for the application.
 */
struct ContentView: View {
  // initialize radio
  //@ObservedObject private var radioManager = RadioManager()
  @EnvironmentObject var radioManager: RadioManager
  @Environment(\.presentationMode) var presentationMode
  
  @State private var isConnected = false
  @State private var isBound = false
  @State private var status = false
  @State private var cwText = CWText()
  @State private var showingDetail = false
  @State private var isEnabled = false
  //@ObservedObject var isEnabled = false
  
  
  var body: some View {
    HStack {
      VStack {
        FirstRowView(isEnabled: $isEnabled)
        SecondRowView()
        
        Divider()
        
        HStack {
          //FreeFormTextView(cwText: cwText)
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
            self.showingDetail.toggle()
          }) {
            Text("Radio Picker")
          }.sheet(isPresented: $showingDetail) {
            //RadioPicker() - should work
            // https://stackoverflow.com/questions/58743004/swiftui-environmentobject-error-may-be-missing-as-an-ancestor-of-this-view
            // this is how to pass the radioManager
            return RadioPicker().environmentObject(self.radioManager)
          }
          
          if radioManager.guiClientModels.count > 0 {
            Text("Found \(radioManager.guiClientModels[0].stationName)" )
          }
          else {
            Text("Disconnected")
          }
          
        }.frame(minWidth: 600, maxWidth: 600).padding(.bottom, 1)
        
        Divider()
        HStack(spacing: 30) {
          Text("Slice").frame(minWidth: 75, maxWidth: 75)
          Text("Mode").frame(minWidth: 75, maxWidth: 75)
          Text("Frequency").frame(minWidth: 75, maxWidth: 75)
//          Button(action: {showDx(count: 20)}) {
//            Text("Send Id").frame(minWidth: 75, maxWidth: 75)
//          }
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
    }.frame(maxWidth: .infinity, maxHeight: 25).padding(.top, 5)
  }
}

/**
The second row of memory buttons.
*/
struct SecondRowView: View {
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
  @State public var cwText: CWText
  // @ObjectBinding var cwText: CWText
  
  var body: some View{
    VStack{
        TextView(text: $cwText.line1)
    }
  }
}

/**
 View of the freeform text area.
 */
//struct FreeFormTextView: View {
//  @State public var cwText: CWText
//
//  var body: some View {
//
//    VStack(spacing: 0) {
//      TextField("Placeholder1", text: $cwText.line1)
//      TextField("Placeholder2", text: $cwText.line2)
//      TextField("Placeholder3", text: $cwText.line3)
//      TextField("Placeholder4", text: $cwText.line4)
//      TextField("Placeholder5", text: $cwText.line5)
//    }.frame(minHeight: 100, maxHeight: 100)
//  }
//}

// MARK: - Radio Picker Sheet ----------------------------------------------------------------------------

/**
 View of the Radio Picker sheet.
 https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-new-view-using-sheets
 */
struct RadioPicker: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var radioManager: RadioManager
  @State private var selectedStation = 0
  var body: some View {
    
//    var first = StationSelection(radioModel: "", radioNickname: "", stationName: "", isDefaultStation: false)
//    var second = StationSelection(radioModel: "", radioNickname: "", stationName: "", isDefaultStation: false )
//
//    if radioManager.guiClientView.count > 0 {
//      first = StationSelection(radioModel: "\(radioManager.stationView[0].radioModel)", radioNickname: "\(radioManager.stationView[0].radioNickname)", stationName: "\(radioManager.stationView[0].stationName)", isDefaultStation: Bool("\(radioManager.stationView[0].isDefaultStation)") ?? false)
//    }
//
//    if radioManager.guiClientView.count > 1 {
//      second = StationSelection(radioModel: "\(radioManager.guiClientView[1].model)", radioNickname: "\(radioManager.guiClientView[1].nickname)", stationName: "\(radioManager.guiClientView[1].stationName)", isDefaultStation: Bool("\(radioManager.guiClientView[1].default)") ?? false)
//    }
    
    //let radios = radioManager.stationView // radioManager.$stationView //
    
//    ForEach(0 ..< radioManager.guiClientView.count) {
//      radios.append(StationSelection(radioModel: "\(radioManager.guiClientView[$0].model)", radioNickname: "\(radioManager.guiClientView[$0].nickname)", stationName: "\(radioManager.guiClientView[$0].stationName)", isDefaultStation: Bool("\(radioManager.guiClientView[$0].default)") ?? false))
//    }
    
    
    
    return VStack{
      HStack{
        Text("Model").frame(minWidth: 50).padding(.leading, 5)
        Text("NickName").frame(minWidth: 90).padding(.leading, 28)
        Text("Station").frame(minWidth: 70).padding(.leading, 8)
        Text("Default Radio").frame(minWidth: 50).padding(.leading, 22)
      }.font(.system(size: 14))
        .foregroundColor(Color.blue)
      HStack {
        List(radioManager.guiClientModels, rowContent: StationRow.init)
      }.frame(minWidth: 400, minHeight: 120)
      HStack {
        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
          Text("Set as Default")
        }
        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
          Text("Connect")
        }
        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
          Text("Cancel")
        }
      }
    }.background(Color.gray.opacity(0.5))
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
        Text("\(String(station.isDefaultStation))").frame(minWidth: 50).border(Color.black).padding(.leading, 25)
        }.border(Color.black) // may want to add min/max width
      }
    }
}


// https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-view-dismiss-itself
//func closePicker() {
//  //self.presentationMode.wrappedValue.dismiss()
//}

// MARK: - Button Implementation ----------------------------------------------------------------------------

func sendFreeText() {
  
}
func showDx(count: Int) {
  
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
