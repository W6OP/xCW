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

struct DefaultButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      //.font(.body)
      .padding(2)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

struct SelectButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      //.font(.body)
      .padding(2)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

struct ControlButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      //.font(.body)
      .padding(5)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

struct CWButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color
  //var disabledColor: Color
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding(2)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

extension View {
  func controlButton(
    foregroundColor: Color = .white,
    backgroundColor: Color = .gray,
    pressedColor: Color = .accentColor
  ) -> some View {
    self.buttonStyle(
      ControlButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        pressedColor: pressedColor
      )
    )
  }
  func selectButton(
    foregroundColor: Color = .black,
    backgroundColor: Color = .green,
    pressedColor: Color = .accentColor
  ) -> some View {
    self.buttonStyle(
      SelectButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor.opacity(0.30),
        pressedColor: pressedColor
      )
    )
  }
  func defaultButton(
    foregroundColor: Color = .black,
    backgroundColor: Color = .blue,
    pressedColor: Color = .accentColor
  ) -> some View {
    self.buttonStyle(
      DefaultButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor.opacity(0.30),
        pressedColor: pressedColor
      )
    )
  }
  func cwButton(
    foregroundColor: Color = .black,
    backgroundColor: Color = .blue,
    pressedColor: Color = .accentColor
    //disabledColor: Color = .gray
  ) -> some View {
    self.buttonStyle(
      CWButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor.opacity(0.30),
        pressedColor: pressedColor
        //disabledColor: disabledColor.opacity(0.30)
      )
    )
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
        FirstRowView()
          .environmentObject(self.radioManager).disabled(!radioManager.isConnected).disabled(radioManager.sliceModel.radioMode.rawValue != "CW" || !radioManager.sliceModel.txEnabled)
        SecondRowView()
          .environmentObject(self.radioManager).disabled(!radioManager.isConnected).disabled(radioManager.sliceModel.radioMode.rawValue != "CW" || !radioManager.sliceModel.txEnabled)
        
        Divider()
        
        HStack {
          FreeFormScrollView(cwText: cwText)
            .environmentObject(self.radioManager)
            .disabled(radioManager.sliceModel.radioMode.rawValue != "CW" || !radioManager.sliceModel.txEnabled)
        }
        .frame(minWidth: 550, maxWidth: 550, minHeight: 110, maxHeight: 110)
        
        Divider()
        
        HStack(spacing: 25) {
          Button(action: {self.radioManager.tuneRadio()}) {
            Text("Tune")
              .frame(minWidth: 58, maxWidth: 58)
          }
          .controlButton()
          .disabled(!radioManager.sliceModel.txEnabled)
          
          Button(action: {self.radioManager.setMox()}) {
            Text("Mox")
              .frame(minWidth: 58, maxWidth: 58)
          }
        .focusable()
        .touchBar {
            Button(action: {
              self.radioManager.setMox()
            }) {
              Text("MOX")
            }
        }
            
          .controlButton()
          .disabled(!radioManager.sliceModel.txEnabled)
          
          // show the cw memory panel
          Button(action: {
            self.showingMemories.toggle()
          }) {
            Text("Memories")
              .frame(minWidth: 100, maxWidth: 100)
          }
          .controlButton()
          .disabled(!radioManager.sliceModel.txEnabled)
          .sheet(isPresented: $showingMemories) {
            return CWMemoriesPicker().environmentObject(self.radioManager)
          }
          
          // show the radio picker
          Button(action: {
            self.showingRadios.toggle()
          }) {
            Text("Select Station")
              .frame(minWidth: 100, maxWidth: 100)
          }
          .sheet(isPresented: $showingRadios) {
            return StationPicker().environmentObject(self.radioManager)
          }
        }
        .frame(minWidth: 600, maxWidth: 600).padding(.bottom, 1)
        .controlButton()
        
        Divider()
        HStack(spacing: 30) {
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
    }//.onAppear(perform: { ContentView.view?.level = .floating})
  } // end body
}

// MARK: - Sub Views ----------------------------------------------------------------------------

/**
 The first row of memory buttons.
 */
struct FirstRowView: View {
  @EnvironmentObject var radioManager: RadioManager
  
  var body: some View {
    HStack {
      Button(action: {self.radioManager.sendCWMessage(tag: "1", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[0].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "1", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[0].line)
        }
      }
      
      Button(action: {self.radioManager.sendCWMessage(tag: "2", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[1].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "2", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[1].line)
        }
      }
      
      Button(action: {self.radioManager.sendCWMessage(tag: "3", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[2].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "3", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[2].line)
        }
      }
      
      Button(action: {self.radioManager.sendCWMessage(tag: "4", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[3].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "4", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[3].line)
        }
      }
      
      Button(action: {self.radioManager.sendCWMessage(tag: "5", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[4].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "5", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[4].line)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: 25).padding(.top, 10)
  }
}

/**
 The second row of memory buttons.
 */
struct SecondRowView: View {
  @EnvironmentObject var radioManager: RadioManager
  
  var body: some View {
    HStack {
      Button(action: {self.radioManager.sendCWMessage(tag: "6", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[5].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "6", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[5].line)
        }
      }
      
      Button(action: {self.radioManager.sendCWMessage(tag: "7", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[6].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "7", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[6].line)
        }
      }
      
      Button(action: {self.radioManager.sendCWMessage(tag: "8", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[7].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "8", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[7].line)
        }
      }
      
      Button(action: {self.radioManager.sendCWMessage(tag: "9", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[8].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "9", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[8].line)
        }
      }
      
      Button(action: {self.radioManager.sendCWMessage(tag: "10", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[9].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      .touchBar {
        Button(action: {
          self.radioManager.sendCWMessage(tag: "10", freeText: "")
        }) {
          Text(self.radioManager.cwMemoryModels[9].line)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: 25).padding(.bottom, 1).padding(.top, 10)
  }
}

/**
 TextView for freeform cw
 */
struct  FreeFormScrollView: View {
  @EnvironmentObject var radioManager: RadioManager
  @State public var cwText: CWMemoryModel
  @State private var isBuffered = true
  
  var body: some View{
    VStack{
      //TextView(text: $cwText.line)
      HStack {
        TextField("Enter text here", text: $cwText.line)
      }
      
      HStack {
        Button(action: {self.radioManager.sendCWMessage(tag: "0", freeText: "\(self.cwText.line)")}) {
          Text("Send Text")
            .frame(minWidth: 78, maxWidth: 78)
        }
        .disabled(self.cwText.line == "")
        .focusable()
        .touchBar {
            Button(action: {
              self.radioManager.sendCWMessage(tag: "0", freeText: "\(self.cwText.line)")
            }) {
              Text("Send")
            }
        }
        
        Button(action: {self.cwText.line = ""}) {
          Text("Clear Text")
            .frame(minWidth: 78, maxWidth: 78)
        }
        .disabled(self.cwText.line == "")
        
        Toggle(isOn: $isBuffered) {
          Text("Buffer Text")
        }
        .disabled(true)
      }
      
      HStack {
        HStack {
          Button(action: {self.radioManager.stopTransmitting()}) {
            Text("Stop")
              .frame(minWidth: 78, maxWidth: 78)
          }
        }
        
        Spacer()
          .frame(maxWidth: 95)
        
        HStack {
          Text("Set Speed")
          Stepper(value: self.$radioManager.cwSpeed, in: 5...80,onEditingChanged: { _ in self.radioManager.saveCWSpeed(speed: self.radioManager.cwSpeed) }, label: { Text("\(self.radioManager.cwSpeed)") })
        }
      }
    }
  }
}


// MARK: - Radio Picker Sheet ----------------------------------------------------------------------------

/**
 View of the Radio Picker sheet.
 https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-new-view-using-sheets
 */
struct StationPicker: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var radioManager: RadioManager
  
  var body: some View {
    
    return VStack{
      HStack{
        VStack{
          Text("Model")
        }.frame(minWidth: 80, maxWidth: 80)//.padding(.leading, 2)//.border(Color.black)//.padding(.leading, 2).border(Color.black)
        
        Spacer()
        
        VStack{
          Text("NickName").frame(minWidth: 80, maxWidth: 80)//.border(Color.black) //.multilineTextAlignment(.leading)
        }.frame(minWidth: 80, maxWidth: 80)//.border(Color.black)
        
        Spacer()
        
        VStack{
          Text("Connect")//.frame(minWidth: 70, maxWidth: 70).padding(.leading, 30).border(Color.black)
        }.frame(minWidth: 80, maxWidth: 80)//.border(Color.black)
        Spacer()
        
        VStack{
          Text("Set Default")
        }.frame(minWidth: 80, maxWidth: 80)
      }
      .frame(minWidth: 450, maxWidth: 450)
      .padding(.leading, 5).padding(.trailing, 5)
      .font(.system(size: 14))
      .foregroundColor(Color.black)
      
      Divider()
        .border(Color.black)
      
      
      // Radio Picker
      ForEach(radioManager.guiClientModels.indices, id: \.self ) { index in
        HStack {
          HStack {
            Text("\(self.radioManager.guiClientModels[index].radioModel)")
              .frame(minWidth: 100, maxWidth: 100)
            
            Text("\(self.radioManager.guiClientModels[index].radioNickname)")
              .frame(minWidth: 120, maxWidth: 120)
            
            Button(action: {self.radioManager.connectToRadio(guiClientModel: self.radioManager.guiClientModels[index]);self.presentationMode.wrappedValue.dismiss()}) {
              Text("\(self.radioManager.guiClientModels[index].stationName)").frame(minWidth: 100, maxWidth: 100) //
            }
            .selectButton()
            
            Button(action: {self.radioManager.setDefaultRadio(stationName: self.radioManager.guiClientModels[index].stationName)}) {
              Text("\(String(self.radioManager.guiClientModels[index].isDefaultStation))").frame(minWidth: 100)
            }
            .defaultButton()
            
          } // end inner stack
            .padding(.top, 5)
            .padding(.bottom, 5)
        } // end outer stack
          .frame(minWidth: 450, maxWidth: 450)
        
      }
      
      HStack {
        Button(action: {self.presentationMode.wrappedValue.dismiss()}) {
          Text("Cancel")
        }
        .padding(.leading, 25).padding(.bottom, 5).padding(.top, 5)
        .controlButton()
      }
    }
    .background(Color.gray.opacity(0.50))
    //.frame(minWidth: 445, maxWidth: 445)
  }
}

// MARK: - CW Message Panel ----------------------------------------------------------------------------

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
          }
        }
        .frame(minWidth: 400, maxWidth: 400)
      }
      .frame(minWidth: 450, maxWidth: 450)
      
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
func sendFreeText(transmit: Bool) {
  
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


//struct TextView: NSViewRepresentable {
//
//  @Binding var text: String
//
//  func makeCoordinator() -> Coordinator {
//    Coordinator(self)
//  }
//
//  func makeNSView(context: Context) -> NSTextView {
//
//    let myTextView = NSTextView()
//    myTextView.delegate = context.coordinator
//
//    myTextView.font = NSFont(name: "HelveticaNeue", size: 15)
//    //        myTextView.isScrollEnabled = true
//    myTextView.isEditable = true
//    myTextView.backgroundColor = NSColor(white: 0.0, alpha: 0.15)
//
//    return myTextView
//  }
//
//  func updateNSView(_ nsView: NSTextView, context: Context) {
//    nsView.string = text
//  }
//
//  class Coordinator : NSObject, NSTextViewDelegate {
//
//    var parent: TextView
//
//    init(_ nsTextView: TextView) {
//      self.parent = nsTextView
//    }
//
//    func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString text: String?) -> Bool {
//      var newText = textView.string
//
//              newText.removeAll { (character) -> Bool in
//                  return character == " " || character == "\n"
//              }
//
//      return newText.count < 500
//      //return true
//    }
//
//    func textViewDidChange(_ textView: NSTextView) {
//      //print("text now: \(String(describing: textView.text!))")
//      self.parent.text = textView.string
//    }
//  }
//}


/*
 https://stackoverflow.com/questions/57679966/how-to-create-a-multiline-textfield-in-swiftui-like-the-notes-app
 */

/**
 https://www.swiftdevjournal.com/using-text-views-in-a-swiftui-app/?utm_campaign=AppCoda%20Weekly&utm_medium=email&utm_source=Revue%20newsletter
 */
