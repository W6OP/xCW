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
  @EnvironmentObject var radioManager: RadioManager
  @Environment(\.presentationMode) var presentationMode
  
  //@State private var isConnected = false
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
          .padding(.top, 5)
        
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
          .controlButton()
          .disabled(!radioManager.sliceModel.txEnabled)
          
          // show the cw memory panel
          Button(action: {
            self.showingMemories.toggle()
          }) {
            Text("Memories")
              .frame(minWidth: 100, maxWidth: 100)
          }
          .memoryButton()
          .sheet(isPresented: $showingMemories) {
            //.disabled(!radioManager.sliceModel.txEnabled)
  
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
        
        // status labels
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
    }
  } // end body
}

// MARK: - Sub Views ----------------------------------------------------------------------------

/**
 The first row of cw memory buttons.
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
      
      Button(action: {self.radioManager.sendCWMessage(tag: "2", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[1].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      
      Button(action: {self.radioManager.sendCWMessage(tag: "3", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[2].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      
      Button(action: {self.radioManager.sendCWMessage(tag: "4", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[3].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      
      Button(action: {self.radioManager.sendCWMessage(tag: "5", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[4].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
    }
    .frame(maxWidth: .infinity, maxHeight: 25).padding(.top, 10)
  }
}

/**
 The second row of cw memory buttons.
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
      
      Button(action: {self.radioManager.sendCWMessage(tag: "7", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[6].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      
      Button(action: {self.radioManager.sendCWMessage(tag: "8", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[7].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      
      Button(action: {self.radioManager.sendCWMessage(tag: "9", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[8].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
      
      Button(action: {self.radioManager.sendCWMessage(tag: "10", freeText: "")}) {
        Text(self.radioManager.cwMemoryModels[9].line)
          .frame(minWidth: 100, maxWidth: 100)
      }
      .cwButton()
    }
    .frame(maxWidth: .infinity, maxHeight: 25).padding(.bottom, 1).padding(.top, 10)
  }
}

/**
 Text area for freeform cw input
 */
struct  FreeFormScrollView: View {
  @EnvironmentObject var radioManager: RadioManager
  @State public var cwText: CWMemoryModel
  @State private var isBuffered = true
  
  var body: some View{
    VStack{
      HStack {
        TextField("Enter text here", text: $cwText.line)
      }
      .textFieldStyle(RoundedBorderTextFieldStyle())
      
      HStack {
        Button(action: {self.radioManager.sendCWMessage(tag: "0", freeText: "\(self.cwText.line)")}) {
          Text("Send Text")
            .frame(minWidth: 78, maxWidth: 78)
        }
        .disabled(self.cwText.line == "")
        
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
        
        // the value here syncs with the memory panel
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
        }
        .frame(minWidth: 80, maxWidth: 80)
        
        Spacer()
        
        VStack{
          Text("NickName").frame(minWidth: 80, maxWidth: 80)
        }
        .frame(minWidth: 80, maxWidth: 80)
        
        Spacer()
        
        VStack{
          Text("Connect")
        }
          .frame(minWidth: 80, maxWidth: 80)
        
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
      
      // Station Picker
      ForEach(radioManager.stationModels.indices, id: \.self ) { index in
        HStack {
          HStack {
            Text("\(self.radioManager.stationModels[index].radioModel)")
              .frame(minWidth: 100, maxWidth: 100)
            
            Text("\(self.radioManager.stationModels[index].radioNickname)")
              .frame(minWidth: 120, maxWidth: 120)
            
            /**
             self.radioManager.connectToRadio(guiClientModel: self.radioManager.guiClientModels[index])
             */
            Button(action: {
                    let station = self.radioManager.stationModels[index]
                    _ = self.radioManager.connectToRadio(serialNumber: station.serialNumber, station: station.stationName, clientId: station.clientId, didConnect: false)
                    ;self.presentationMode.wrappedValue.dismiss()}) {
              Text("\(self.radioManager.stationModels[index].stationName)").frame(minWidth: 100, maxWidth: 100)
            }
            .selectButton()
            
            Button(action: {self.radioManager.setDefaultRadio(stationName: self.radioManager.stationModels[index].stationName)}) {
              Text("\(String(self.radioManager.stationModels[index].isDefaultStation))").frame(minWidth: 100)
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
  }
}

// MARK: - CW Message Panel ----------------------------------------------------------------------------
// moved to separate file


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

// MARK: - Preview Provider ----------------------------------------------------------------------------
/**
 Preview provider.
 */
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environmentObject(RadioManager())
  }
}


/*
 https://stackoverflow.com/questions/57679966/how-to-create-a-multiline-textfield-in-swiftui-like-the-notes-app
 */

/**
 https://www.swiftdevjournal.com/using-text-views-in-a-swiftui-app/?utm_campaign=AppCoda%20Weekly&utm_medium=email&utm_source=Revue%20newsletter
 */
