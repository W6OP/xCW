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
  @State private var status = false
  @State private var cwText = CWText()
  @State private var showingDetail = false
  @Environment(\.presentationMode) var presentationMode
  
  // radio
  var radioManager: RadioManager!
  
  var body: some View {
    HStack {
      VStack {
        FirstRowView()
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
            RadioPicker()
          }
          Text("Connected")//.frame(minWidth: 100, maxWidth: 100)
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
  
  var body: some View{
    VStack{
      //ScrollView(.vertical, showsIndicators: true) {
        TextView(text: $cwText.line1)
      //}.frame(minHeight: 100, maxHeight: 100)
    }
  }
}

/**
 View of the freeform text area.
 */
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

// MARK: - Radio Picker Sheet ----------------------------------------------------------------------------

/**
 View of the Radio Picker sheet.
 https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-new-view-using-sheets
 */
struct RadioPicker: View {
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {

    let first = StationSelection(radioModel: "Flex 6500", radioNickname: "DXSeeker", stationName: "40 Meters CW", isDefaultStation: true)
    let second = StationSelection(radioModel: "Flex 6500", radioNickname: "DXSeeker", stationName: "15 Meters DIGI", isDefaultStation: false )
    let third = StationSelection(radioModel: "Flex 6500", radioNickname: "DXSeeker", stationName: "20 meters USB", isDefaultStation: false )
    
    let radios = [first, second, third]
    
    return VStack{
      HStack{
        Text("Model").frame(minWidth: 50).padding(.leading, 5)
        Text("NickName").frame(minWidth: 90).padding(.leading, 28)
        Text("Station").frame(minWidth: 70).padding(.leading, 8)
        Text("Default Radio").frame(minWidth: 50).padding(.leading, 22)
      }.font(.system(size: 14))
      .foregroundColor(Color.blue)
      HStack {
        List(radios, rowContent: StationRow.init)
      }.frame(minWidth: 400, minHeight: 120)
      HStack {
          Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
           Text("Close Picker")
          }
      }
    }.background(Color.gray.opacity(0.5))
  }
}



/**
 View of rows of stations to select from.
 */
struct StationRow: View {
    var station: StationSelection

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


// MARK: - Models ----------------------------------------------------------------------------

/**
 Data model for a radio and station selection in the Radio Picker.
 // var stations = [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: UInt32)]()
 */
struct StationSelection: Identifiable {
  var id = UUID()
  
  var radioModel: String = ""
  var radioNickname: String = ""
  var stationName: String = ""
  var serialNumber: String = ""
  var clientId: String = ""
  var handle: UInt32 = 0
  var isDefaultStation: Bool = false
}

/**
 Data model for the text in the freeform text section.
 */
struct CWText {
  var line1: String = ""
  var line2: String = ""
  var line3: String = ""
  var line4: String = ""
  var line5: String = ""
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
//        myTextView.isUserInteractionEnabled = true
        myTextView.backgroundColor = NSColor(white: 0.0, alpha: 0.05)

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
