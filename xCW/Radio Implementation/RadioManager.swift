
/**
 * Copyright (c) 2019 Peter Bourget W6OP
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/*
 RadioManager.swift
 xCW
 
 Created by Peter Bourget on 5/14/20.
 Copyright © 2020 Peter Bourget W6OP. All rights reserved.
 
 Description: This is a wrapper for the xLib6000 framework written by Doug Adams K3TZR
 The purpose is to simplify the interface into the API and allow the GUI to function
 without a reference to the API or even knowledge of the API.
 */

import Foundation
import xLib6000
import Repeat
import os

// MARK: Extensions ------------------------------------------------------------------------------------------------

/** breaks an array into chunks of a specific size, the last chunk may be smaller than the specified size
 this is used to split the audio buffer into 128 samples at a time to send to the vita parser
 via the rate timer
 */
extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}

extension String {
  subscript(_ range: CountableRange<Int>) -> String {
    let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
    let idx2 = index(startIndex, offsetBy: min(count, range.upperBound))
    return String(self[idx1..<idx2])
  }
}

// MARK: Helper Functions ------------------------------------------------------------------------------------------------

/** utility functions to run a UI or background thread
 // USAGE:
 BG() {
 everything in here will execute in the background
 }
 https://www.electrollama.net/blog/2017/1/6/updating-ui-from-background-threads-simple-threading-in-swift-3-for-ios
 */
func BG(_ block: @escaping ()->Void) {
  DispatchQueue.global(qos: .background).async(execute: block)
}

/**  USAGE:
 UI() {
 everything in here will execute on the main thread
 }
 */
func UI(_ block: @escaping ()->Void) {
  DispatchQueue.main.async(execute: block)
}

// MARK: - Enums ------------------------------------------------------------------------------------------------

public enum radioMode : String {
  case am = "AM"
  case usb = "USB"
  case lsb = "LSB"
  case fm = "FM"
  case cw = "CW"
  case digu = "DIGU"
  case digl = "DIGL"
  case rtty = "RTTY"
  case invalid = "Unknown"
}

public enum sliceStatus : String {
  case txEnabled
  case active
  case mode
  case frequency
}

// MARK: - Models ----------------------------------------------------------------------------

/**
 Data model for a radio and station selection in the Radio Picker.
 */
struct GUIClientModel: Identifiable {
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
struct CWMemoryModel: Identifiable {
  var id: Int
  
  var tag: String = ""
  var line: String = ""
}

/**
 var sliceView = [(sliceLetter: String, radioMode: radioMode, txEnabled: Bool, frequency: String, sliceHandle: UInt32)]()
 */
struct SliceModel: Identifiable {
  var id = UUID()
  
  var sliceLetter: String = ""
  var radioMode: radioMode
  var txEnabled: Bool = false
  var frequency: String = "00.000"
  var sliceHandle: UInt32
  var associatedStationName = ""
}

// MARK: - Class Definition ------------------------------------------------------------------------------------------------

/**
 Wrapper class for the FlexAPI Library xLib6000 written for the Mac by Doug Adams K3TZR.
 This class will isolate other apps from the API implemenation allowing reuse by multiple
 programs.
 */
class RadioManager:  ApiDelegate, ObservableObject {
  
  func addReplyHandler(_ sequenceNumber: SequenceNumber, replyTuple: ReplyTuple) {
    os_log("addReplyHandler added.", log: RadioManager.model_log, type: .info)
  }
  
  func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) {
    os_log("defaultReplyHandler added.", log: RadioManager.model_log, type: .info)
  }
  
  private var _observations = [NSKeyValueObservation]()
  
  // setup logging for the RadioManager
  static let model_log = OSLog(subsystem: "com.w6op.RadioManager-Swift", category: "xCW")
  
  // MARK: - Internal Radio properties ----------------------------------------------------------------------------
  
  // Radio currently running
  private var activeRadio: DiscoveryPacket?
  
  // this starts the discovery process - Api to the Radio
  private var api = Api.sharedInstance
  private let discovery = Discovery.sharedInstance
  
  // MARK: - Published properties ----------------------------------------------------------------------------
  
  @Published var guiClientModels = [GUIClientModel]()
  @Published var sliceModel = SliceModel(radioMode: radioMode.invalid, sliceHandle: 0)
  @Published var cwMemoryModels = [CWMemoryModel]()
  @Published var cwSpeed = 25
  
  var isConnected = false
  var isBoundToClient = false
  var boundStationName = ""
  var connectedStationName = ""
  var defaultStationName = ""
  var boundStationHandle: UInt32 = 0
  // internal collection for my use here only
  var sliceModels = [SliceModel]()
  
  // MARK: - Private properties ----------------------------------------------------------------------------
  
  private let clientProgramName = "xCW"
  
  // MARK: - RadioManager Initialization ----------------------------------------------------------------------------
  
  /**
   Initialize the class, create the RadioFactory, add notification listeners
   */
   init() {
    
    //super.init()
    
    // add notification subscriptions
    addNotificationListeners()
    
    api.delegate = self
    
    retrieveUserDefaults()
  }
  
   // MARK: - CW Memory Functions ----------------------------------------------------------------------------
  
  /**
   Save the memory set by the user.
   - parameters:
   - message: text entered by user
   - tag: key for UserDefaults
   */
  func saveCWMemory(message: String, tag: String) {
  
    let index = Int(tag)!
    
    //cwMemoryModels.First({where: $0 == tag}).line = message
    //cwMemoryModels.First({where: $0 == tag}).tag = tag
    cwMemoryModels[index - 1].line = String(message.prefix(50))
    cwMemoryModels[index - 1].tag = tag
    
    UserDefaults.standard.set(message, forKey: String(tag))
  }
  
  /**
  Save the speed set by the user.
  - parameters:
  - speed: speed in wpm.
  */
  func saveCWSpeed(speed: Int){
    UserDefaults.standard.set(speed, forKey: "cwSpeed")
  }
  
  /**
  Save the default staion to UserDefaults.
  - parameters:
  - stationName: name of the station to save.
  */
  func setDefaultRadio(stationName: String) {
    
    UserDefaults.standard.set(stationName, forKey: "defaultRadio")
    
    if var client = guiClientModels.first(where: { $0.isDefaultStation == true} ){
      self.guiClientModels.removeAll(where: { $0.isDefaultStation == true })
      client.isDefaultStation = false
      self.guiClientModels.append((client))
    }
    
    if var client = guiClientModels.first(where: { $0.stationName == stationName} ){
      UI() {
        self.guiClientModels.removeAll(where: { $0.stationName == stationName })
        client.isDefaultStation = true
        self.guiClientModels.append((client))
      }
    }
  }
  
  /**
  Retrieve a CW message from UserDefaults.
  - parameters:
  - tag: key for UserDefaults.
  */
  func retrieveCWMemory(tag: String) -> String {
    return(UserDefaults.standard.string(forKey: String(tag)) ?? "")
  }
  
  /**
   Retrieve all of the memories at startup.
   - parameters:
   */
  func retrieveUserDefaults() {
    
    for index in 1...10 {
      let cwTextModel = CWMemoryModel(id: index, tag: String(index), line: UserDefaults.standard.string(forKey: String(index)) ?? "")
      cwMemoryModels.append(cwTextModel)
    }
    
    cwSpeed = UserDefaults.standard.integer(forKey: "cwSpeed")
    defaultStationName = UserDefaults.standard.string(forKey: "defaultRadio") ?? ""
  }
  
  // MARK: - Open and Close Radio Methods - Required by xLib6000 - Not Used ----------------------------------------------------------------------------
  
  func sentMessage(_ text: String) {
    _ = 1 // unused in xVoiceKeyer
  }
  
  func receivedMessage(_ text: String) {
    // get all except the first character // unused in xVoiceKeyer
    //_ = String(text.dropFirst())
    os_log("Message received.", log: RadioManager.model_log, type: .info)
    
  }
  
  func defaultReplyHandler(_ command: String, seqNum: String, responseValue: String, reply: String) {
    // unused in xVoiceKeyer
    os_log("defaultReplyHandler called.", log: RadioManager.model_log, type: .info)
  }
  
  func vitaParser(_ vitaPacket: Vita) {
    // unused in xVoiceKeyer
    os_log("Vita parser added.", log: RadioManager.model_log, type: .info)
  }
  
  // MARK: - Notification Methods ----------------------------------------------------------------------------
  
  /**
   Add subscriptions to Notifications from the xLib6000 API
   */
  func addNotificationListeners() {
    let nc = NotificationCenter.default
    
    // Available Radios changed
    nc.addObserver(forName:Notification.Name(rawValue:"discoveredRadios"),
                   object:nil, queue:nil,
                   using:discoveryPacketsReceived)
    
    nc.addObserver(forName:Notification.Name(rawValue:"guiClientHasBeenAdded"),
                   object:nil, queue:nil,
                   using:guiClientsAdded)
    
    nc.addObserver(forName:Notification.Name(rawValue:"guiClientHasBeenUpdated"),
                   object:nil, queue:nil,
                   using:guiClientsUpdated)
    
    nc.addObserver(forName:Notification.Name(rawValue:"guiClientHasBeenRemoved"),
                   object:nil, queue:nil,
                   using:guiClientsRemoved)
    
    nc.addObserver(forName: Notification.Name(rawValue: "sliceHasBeenAdded"), object:nil, queue:nil,
                   using:sliceHasBeenAdded)
    
    nc.addObserver(forName: Notification.Name(rawValue: "sliceWillBeRemoved"), object:nil, queue:nil,
                   using:sliceWillBeRemoved)
  }
  
  // MARK: - Connect and Bind ----------------------------------------------------------------------------
  
  /**
   Exposed function for the GUI to indicate which radio to connect to.
   - parameters:
   - serialNumber: a string representing the serial number of the radio to connect
   - station: station name for the connection
   - clientId: client id if available
   - doConnect: bool returning true if the connect was successful
   */
  func connectToRadio(guiClientModel: GUIClientModel) {
    
    if isConnected {
      bindToStation(clientId: guiClientModel.clientId, station: guiClientModel.stationName)
      return
    }
    
    isConnected = false
    connectedStationName = ""
    boundStationName = ""
    
    os_log("Connect to the Radio.", log: RadioManager.model_log, type: .info)
    
    // allow time to hear the UDP broadcasts
    usleep(1500)
    
      for (_, foundRadio) in discovery.discoveredRadios.enumerated() where foundRadio.serialNumber == guiClientModel.serialNumber {
        
        activeRadio = foundRadio
        
        if api.connect(activeRadio!, program: clientProgramName, clientId: nil, isGui: false) {
          os_log("Connected to the Radio.", log: RadioManager.model_log, type: .info)
          isConnected = true
          connectedStationName = guiClientModel.stationName
        }
    }
  }
  
  /**
   Bind to a specific station so we get their messages and updates
   - parameters:
   - clientId: the client id to bind with represented as a string
   - station: station name used to find the key which is the guiClient handle
   */
  func bindToStation(clientId: String, station: String)  { //-> UInt32
    
    cleanUp()
    
    api.radio?.boundClientId = clientId
    
    for radio in discovery.discoveredRadios {
      
      if let guiClient = radio.guiClients.filter({ $0.value.station == station }).first {
        let handle = guiClient.key
        
        boundStationName = station
        boundStationHandle = handle
        
        self.sliceModel = sliceModels.first(where: { $0.sliceHandle == boundStationHandle} )!
        self.sliceModel.associatedStationName = boundStationName

        os_log("Bound to the Radio.", log: RadioManager.model_log, type: .info)
        
      }
    }
  }
  
  /**
   Stop the active radio. Remove observations of Radio properties.
   Perform an orderly close of the Radio resources.
   */
  func closeRadio() {
    activeRadio = nil
  }
  
  // MARK: - Dicovery Methods ----------------------------------------------------------------------------
  
  /**
   Notification that one or more radios were discovered.
   - parameters:
   - note: a Notification instance
   */
  func discoveryPacketsReceived(_ note: Notification) {
    // receive the updated list of Radios
    let discoveryPacket = (note.object as! [DiscoveryPacket])
    
    
    // just collect the radio's gui clients
    for radio in discoveryPacket {
      for guiClient in radio.guiClients {
        
        let handle = guiClient.key
        
        let guiClientModel = GUIClientModel(radioModel: radio.model, radioNickname: radio.nickname, stationName: guiClient.value.station, serialNumber: radio.serialNumber, clientId: guiClient.value.clientId ?? "", handle: handle, isDefaultStation: self.isDefaultStation(stationName: guiClient.value.station))
        
        if guiClient.value.station != "" {
          UI() {
            self.guiClientModels.append(guiClientModel)
          }
        }
        os_log("Discovery packet received.", log: RadioManager.model_log, type: .info)
        
        if guiClient.value.station == defaultStationName {
          connectToRadio(guiClientModel: guiClientModel)
        }
      }
    }
  }
  
  /**
   Return true if this is the default station
   */
  func isDefaultStation (stationName: String) -> Bool {
    
    let defaultStation = UserDefaults.standard.string(forKey: "defaultRadio") ?? ""
    
    if stationName == defaultStation {
      return true
    }
    
    return false
  }
  
  /**
   When another GUI client appears we receive a notification.
   Let the view controller know there has been an add.
   - parameters:
   - note: a Notification instance
   */
  func guiClientsAdded(_ note: Notification) {
    
    if let guiClient = note.object as? GuiClient {
      
      for radio in discovery.discoveredRadios {
        if let client = radio.guiClients.first(where: { $0.value.station == guiClient.station} ){
          let handle = client.key
          
          let guiClientModel = GUIClientModel(radioModel: radio.model, radioNickname: radio.nickname, stationName: guiClient.station, serialNumber: radio.serialNumber, clientId: guiClient.clientId ?? "", handle: handle, isDefaultStation: self.isDefaultStation(stationName: guiClient.station))
          
          UI() {
            self.guiClientModels.append(guiClientModel)
          }
          os_log("GUI clients have been added.", log: RadioManager.model_log, type: .info)
          
          if !isConnected && guiClient.station == defaultStationName {
            connectToRadio(guiClientModel: guiClientModel)
          }
        }
      }
    }
  }
  
  /**
   When a GUI client is updated we receive a notification.
   Let the view controller know there has been an update.
   Do bind after this
   - parameters:
   - note: a Notification instance
   */
  func guiClientsUpdated(_ note: Notification) {
    
    if let guiClient = note.object as? GuiClient {
      
      for radio in discovery.discoveredRadios {
        if let client = radio.guiClients.first(where: { $0.value.station == guiClient.station} ){
          let handle = client.key
          UI() {
            // first remove the old one
            self.guiClientModels.removeAll(where: { $0.stationName == guiClient.station })
            
            self.guiClientModels.append( GUIClientModel(radioModel: radio.model, radioNickname: radio.nickname, stationName: guiClient.station, serialNumber: radio.serialNumber, clientId: guiClient.clientId ?? "", handle: handle, isDefaultStation: self.isDefaultStation(stationName: guiClient.station)))
            
            if guiClient.station == self.connectedStationName {
              if guiClient.clientId != "" {
                self.bindToStation(clientId: guiClient.clientId ?? "", station: self.connectedStationName)
              }
            }
          }
          os_log("GUI clients have been updated.", log: RadioManager.model_log, type: .info)
        }
      }
    }
  }
  
  /**
   When a GUI client is removed we receive a notification.
   Let the view controller know there has been an update.
   - parameters:
   - note: a Notification instance
   */
  func guiClientsRemoved(_ note: Notification) {
    
    if let guiClient = note.object as? GuiClient {
      UI() {
        self.guiClientModels.removeAll(where: { $0.stationName == guiClient.station })
      }
      os_log("GUI clients have been removed.", log: RadioManager.model_log, type: .info)
      
    }
  }
  
  // MARK: - Slice handling ----------------------------------------------------------------------------
  
  /**
   Notification that one or more slices were added.
   The slice that is added becomes the active slice.
   - parameters:
   - note: a Notification instance
   */
  func sliceHasBeenAdded(_ note: Notification){
    
    let slice: xLib6000.Slice = (note.object as! xLib6000.Slice)
    let mode: radioMode = radioMode(rawValue: slice.mode) ?? radioMode.invalid
    let frequency: String = convertFrequencyToDecimalString (frequency: slice.frequency)
    
    addObservations(slice: slice)
    
    // I really only care about a slice that is tx enabled
    if slice.txEnabled {
      UI() {
//        self.sliceModel = SliceModel(sliceLetter: slice.sliceLetter ?? "Unknown", radioMode: mode, txEnabled: slice.txEnabled, frequency: frequency, sliceHandle: slice.clientHandle)
      
        self.sliceModels.append(SliceModel(sliceLetter: slice.sliceLetter ?? "Unknown", radioMode: mode, txEnabled: slice.txEnabled, frequency: frequency, sliceHandle: slice.clientHandle))
      }
    }
    
    os_log("Slice has been addded.", log: RadioManager.model_log, type: .info)
    print("\(slice.txEnabled)")
  }
  
  /**
   Notification that one or more slices were removed. Iterate through collection
   and remove the slice from the array of available slices.
   - parameters:
   - note: a Notification instance
   */
  func sliceWillBeRemoved(_ note: Notification){
    
    let slice: xLib6000.Slice = (note.object as! xLib6000.Slice)
    
    os_log("Slice has been removed.", log: RadioManager.model_log, type: .info)
    
    UI() {
      if self.sliceModel.sliceHandle == slice.clientHandle {
        self.sliceModel = SliceModel(radioMode: radioMode.invalid, sliceHandle: 0)
      }
    }
  }
  
  /**
   Observer handler to update the slice information for the labels on the GUI
   when a new slice is added.
   - parameters:
   - slice:
   */
  func updateSliceStatus(_ slice: xLib6000.Slice, sliceStatus: sliceStatus,  _ change: Any) {
    
    let mode: radioMode = radioMode(rawValue: slice.mode) ?? radioMode.invalid
    let frequency: String = convertFrequencyToDecimalString (frequency: slice.frequency)
    
    if slice.txEnabled {
      UI() {
//        self.sliceModel = SliceModel(sliceLetter: slice.sliceLetter ?? "Unknown", radioMode: mode, txEnabled: slice.txEnabled, frequency: frequency, sliceHandle: slice.clientHandle)
        self.sliceModels.append(SliceModel(sliceLetter: slice.sliceLetter ?? "Unknown", radioMode: mode, txEnabled: slice.txEnabled, frequency: frequency, sliceHandle: slice.clientHandle))
      }
    } else {
      if self.sliceModel.sliceHandle == slice.clientHandle {
        // don't think this is correct
        self.sliceModel = SliceModel(radioMode: radioMode.invalid, sliceHandle: 0)
      }
    }
  }
  
  // MARK: - Utlity Functions for Slices
  
  /**
   Respond to a change in a slice
   - parameters:
   - slice:
   */
  func addObservations(slice: xLib6000.Slice ) {
    
    _observations.append( slice.observe(\.active, options: [.initial, .new]) { [weak self] (slice, change) in
      self?.updateSliceStatus(slice,sliceStatus: sliceStatus.active, change) })
    
    _observations.append( slice.observe(\.mode, options: [.initial, .new]) { [weak self] (slice, change) in
      self?.updateSliceStatus(slice, sliceStatus: sliceStatus.mode, change) })
    
    _observations.append(  slice.observe(\.txEnabled, options: [.initial, .new]) { [weak self] (slice, change) in
      self?.updateSliceStatus(slice,sliceStatus: sliceStatus.txEnabled, change) })
    
    _observations.append( slice.observe(\.frequency, options: [.initial, .new]) { [weak self] (slice, change) in
      self?.updateSliceStatus(slice,sliceStatus: sliceStatus.frequency, change) })
  }
  
  /**
   Convert the frequency (10136000) to a string with a decimal place (10136.000)
   Use an extension to String to format frequency correctly
   */
  func convertFrequencyToDecimalString (frequency: Int) -> String {
    
    // 160M = 7 digits - 80M - 40
    // 30 M = 8
    let frequencyString = String(frequency)
    
    switch frequencyString.count {
    case 7:
      let start = frequencyString[0..<1]
      let end = frequencyString[1..<4]
      let extend = frequencyString[4..<6]
      return ("\(start).\(end).\(extend)")
    default:
      let start = frequencyString[0..<2]
      let end = frequencyString[2..<5]
      let extend = frequencyString[5..<7]
      return ("\(start).\(end).\(extend)")
    }
  }
  
  // MARK: Transmit methods ----------------------------------------------------------------------------
  
  // cleanup so we can bind with another station
  func cleanUp() {
    api.radio?.boundClientId = nil
  }
  
  /**
   Send a CW message to the radio
   */
  func sendCWMessage(tag: String, freeText: String)
  {
    var message = UserDefaults.standard.string(forKey: String(tag)) ?? ""
    
    if tag == "0" {
      message = freeText
    }
    
    print("Tag: \(tag)  Message: \(message)   Speed: \(cwSpeed)")
    
    if message != "" {
      api.radio?.cwx.wpm = cwSpeed
      api.radio?.cwx.send(message)
    }
    
  }
} // end class

