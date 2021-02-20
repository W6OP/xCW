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

// MARK: Event Delegates ------------------------------------------------------------------------------------------------

/**
 Implement in your View Controller to receive messages from the radio manager (legacy)
 */
protocol RadioManagerDelegate: class {
  // radio and gui clients were discovered - notify GUI
  func didDiscoverStations(discoveredStations: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: UInt32)], isGuiClientUpdate: Bool)
  
  func didAddStations(discoveredStations: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: UInt32)], isGuiClientUpdate: Bool)
  
  func didUpdateStations(discoveredStations: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: UInt32)], isStationUpdate: Bool)
 
  func didRemoveStation(discoveredStations: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: UInt32)], isStationUpdate: Bool)
  
  func didAddSlice(slice: [(sliceLetter: String, radioMode: radioMode, txEnabled: Bool, frequency: String, sliceHandle: UInt32)])
  
  func didRemoveSlice(sliceHandle: UInt32, sliceLetter: String)
  
  func didUpdateSlice(sliceHandle: UInt32, sliceLetter: String, sliceStatus: sliceStatus, newValue: Any)
  
  // notify the GUI the tcp connection to the radio was closed
  func didDisconnectFromRadio()
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

public enum daxChannels: UInt16, Identifiable, CaseIterable {
  case Dax_None = 0
  case Dax_One = 1
  case Dax_Two = 2
  case Dax_Three = 3
  case Dax_Four = 4
  
  public var id: UInt16 { self.rawValue }
}

// MARK: - Models ----------------------------------------------------------------------------

/**
 Data model for a radio and station selection in the Radio Picker.
 */
struct StationModel: Identifiable, Equatable {
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
  
  var sliceId: UInt16 = 99
  var sliceLetter: String = ""
  var radioMode: radioMode
  var txEnabled: Bool = false
  var frequency: String = "00.000"
  var clientHandle: UInt32 = 0
  var associatedStationName = ""
}

// MARK: - Class Definition ------------------------------------------------------------------------------------------------

/**
 Wrapper class for the FlexAPI Library xLib6000 written for the Mac by Doug Adams K3TZR.
 This class will isolate other apps from the API implementation allowing reuse by multiple
 programs.
 */
class RadioManager:  ApiDelegate, StreamHandler, ObservableObject {
  
  //let cwprocessor = CWProcessor()

  // cCWReader Specific
  let inputQueue = DispatchQueue(
      label: "com.w6op.cwreaderIn.serial",
      qos: .userInitiated
  )
  
  let outputQueue = DispatchQueue(
      label: "com.w6op.cwreaderOut.serial",
      qos: .userInitiated,
      attributes: .concurrent
  )
  
  func addReplyHandler(_ sequenceNumber: SequenceNumber, replyTuple: ReplyTuple) {
    os_log("addReplyHandler added.", log: RadioManager.model_log, type: .info)
  }
  
  func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) {
    os_log("defaultReplyHandler added.", log: RadioManager.model_log, type: .info)
  }
  
  private var _observations = [NSKeyValueObservation]()
  
  // setup logging for the RadioManager
  static let model_log = OSLog(subsystem: "com.w6op.RadioManager-Swift", category: "xCW")
  
  // delegate to pass messages back to View Controller (legacy)
  //weak var radioManagerDelegate: RadioManagerDelegate?
  
  // MARK: - Internal Radio properties ----------------------------------------------------------------------------
  
  // Radio currently running
  private var activeRadio: DiscoveryPacket?
  
  // this starts the discovery process - Api to the Radio
  private var api = Api.sharedInstance
  private let discovery = Discovery.sharedInstance
  
  // xCWReader Specific
  private var daxRxAudioStreamRequested = false
  
  // MARK: - Published properties ----------------------------------------------------------------------------
  
  @Published var stationModels = [StationModel]()
  @Published var sliceModel = SliceModel(radioMode: radioMode.invalid, clientHandle: 0)
  
  // xCW Specific
  @Published var cwMemoryModels = [CWMemoryModel]()
  @Published var cwSpeed = 25
  
  var isConnected = false // should I publish this ?
  var isBoundToClient = false
  var boundStationName = ""
  var connectedStationName = ""
  var defaultStationName = ""
  var boundStationHandle: UInt32 = 0
  // internal collection for my use here only
  var sliceModels = [SliceModel]()
  
  // xCWReader
  //var audioManager: AudioManager
  var daxRxStreamId: StreamId
  
  // xCWReader Specific
  @Published var audioData = [CGFloat]()
  // move this to a controller stub
  @Published var receive = (daxChannel: UInt16(1), state: false) { didSet {
    if receive.state {startAudioReceive(daxChannel: receive.daxChannel)}}}
  
  @Published var level: Double = 0.001 { didSet {
    //print("level: \(level / 10000)")
    //sendClusterCommand(tag: clusterCommand.tag, command: clusterCommand.command)
    }
  }
  
  // MARK: - Private properties ----------------------------------------------------------------------------
  
  // Notification observers collection
  private var notifications = [NSObjectProtocol]()
  
  //private let clientProgram = "xCW"
  private let clientProgramName = Bundle.main.infoDictionary?["CFBundleName"] as? String
  
  private var daxTxAudioStreamRequested = false
  private var audioBuffer = [Float]()
  // not used in this program
  //private var audioStreamTimer :Repeater? // timer to meter audio chunks to radio at 24khz sample rate
  private var xmitGain = 35
  
  // MARK: - RadioManager Initialization ----------------------------------------------------------------------------
  
  /**
   Initialize the class, create the RadioFactory, add notification listeners
   */
   init() {
    
    daxRxStreamId = UInt32(0)
    
    // add notification subscriptions
    addNotificationListeners()
    
    api.delegate = self
    
    retrieveUserDefaults()
    // retrieveFromBuffer()
  }
  
   // MARK: - xCW Specific ----------------------------------------------------------------------------
  
  /**
   Save the memory set by the user.
   - parameters:
   - message: text entered by user
   - tag: key for UserDefaults
   */
  func saveCWMemory(message: String, tag: String) {
  
    let index = Int(tag)!
    
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
  Save the default station to UserDefaults.
  - parameters:
  - stationName: name of the station to save.
  */
  func setDefaultRadio(stationName: String) {
    
    var oldClientStationName = ""
    
    // find the station that is set to true - remove it
    // now set it to false and add it back
    if var client = stationModels.first(where: { $0.isDefaultStation == true} ){
      oldClientStationName = client.stationName
      self.stationModels.removeAll(where: { $0.isDefaultStation == true })
      client.isDefaultStation = false
      self.stationModels.append((client))
      UserDefaults.standard.set("", forKey: "defaultRadio")
    }
    
    // now find the guiClient where the station name matches but isn't the last one
    if var client = stationModels.first(where: { $0.stationName == stationName && $0.stationName != oldClientStationName} ){
      UI() {
        self.stationModels.removeAll(where: { $0.stationName == stationName })
        client.isDefaultStation = true
        self.stationModels.append((client))
      }
      UserDefaults.standard.set(stationName, forKey: "defaultRadio")
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
  
  // MARK: xCWReader Specific
  
  
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
  func connectToRadio(serialNumber: String, station: String, clientId: String, didConnect: Bool) -> Bool {
    
    os_log("Connect to the Radio.", log: RadioManager.model_log, type: .info)
    
    // allow time to hear the UDP broadcasts
    usleep(1500)
    
    if isConnected {
      _ = bindToStation(clientId: clientId, station: station)
      return false
    }
    
    connectedStationName = ""
    boundStationName = ""
    
    os_log("Connect to the Radio.", log: RadioManager.model_log, type: .info)
    
    if (didConnect){
      for (_, foundRadio) in discovery.discoveryPackets.enumerated() where foundRadio.serialNumber == serialNumber {
        
        activeRadio = foundRadio
        
        // TODO: How do I know it connected?
        api.connect(activeRadio!, program: clientProgramName ?? "my program", clientId: nil, isGui: false)
        
        isConnected = true
        connectedStationName = station
        
        os_log("Connected to the Radio.", log: RadioManager.model_log, type: .info)
        // check if radio is null
        return true
      }
    }
    return false
  }
  
  /**
   Bind to a specific station so we get their messages and updates
   - parameters:
   - clientId: the client id to bind with represented as a string
   - station: station name used to find the key which is the guiClient handle
   */
  func bindToStation(clientId: String, station: String) -> UInt32 {
    
    cleanUp()
    
    api.radio?.boundClientId = clientId
    
    for radio in discovery.discoveryPackets {
      
      if let guiClient = radio.guiClients.filter({ $0.station == station }).first {
        
        boundStationName = station
        boundStationHandle = guiClient.handle
        connectedStationName = station
        
        updateSliceModel()
        
        os_log("Bound to the Radio.", log: RadioManager.model_log, type: .info)
        
      }
    }
    
    // legacy for xVoiceKeyer
    return boundStationHandle
  }
  
  /**
   Stop the active radio. Remove observations of Radio properties.
   Perform an orderly close of the Radio resources.
   */
  func closeRadio() {
    activeRadio = nil
  }
  
  // MARK: - Discovery Methods ----------------------------------------------------------------------------
  
  /**
   Notification that one or more radios were discovered. Each station for each radio
   is added to an array and sent to the view controller.
   - parameters:
   - note: a Notification instance
   */
  func discoveryPacketsReceived(_ note: Notification) {
    // receive the updated list of Radios
    let discoveryPackets = (note.object as! [DiscoveryPacket])
    
    // just collect the radio's gui clients
    for radio in discoveryPackets {
      for station in radio.guiClients {
        let stationModel = StationModel(radioModel: radio.model, radioNickname: radio.nickname, stationName: station.station, serialNumber: radio.serialNumber, clientId: station.clientId ?? "", handle: station.handle, isDefaultStation: self.isDefaultStation(stationName: station.station))
        UI {
          if !self.stationModels.contains(stationModel) { self.stationModels.append(stationModel) }

          if station.station == self.defaultStationName {
            _ = self.connectToRadio(serialNumber: radio.serialNumber, station: station.station, clientId: station.clientId ?? "", didConnect: true)
          }
        }
      }
    }
    
    os_log("Discovery packets received.", log: RadioManager.model_log, type: .info)
    
  }
  
  /**
   For debugging
   */
  func printStations(stationModel: StationModel, source: String) {
    print("Source: \(source)")
    print("clientID: \(stationModel.clientId)")
    print("handle: \(stationModel.handle)")
    print("model: \(stationModel.radioModel)")
    print("nickName: \(stationModel.radioNickname)")
    print("stationName: \(stationModel.stationName)")
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
    
    if (note.object as? [GuiClient]) != nil {
      
      for radio in discovery.discoveryPackets {
        for station in radio.guiClients {
          let stationModel = StationModel(radioModel: radio.model, radioNickname: radio.nickname, stationName: station.station, serialNumber: radio.serialNumber, clientId: station.clientId ?? "", handle: station.handle, isDefaultStation: self.isDefaultStation(stationName: station.station))
          UI {
            if !self.stationModels.contains(stationModel) { self.stationModels.append(stationModel) }
          }
        }
      }
      
      os_log("GUI clients have been added.", log: RadioManager.model_log, type: .info)
    }
  }
  
  /**
   When a GUI client is updated we receive a notification.
   Let the view controller know there has been an update.
   - parameters:
   - note: a Notification instance
   */
  func guiClientsUpdated(_ note: Notification) {
    
    //var stationView = [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: UInt32)]()
    
    if (note.object as? [GuiClient]) != nil {
  
      for radio in discovery.discoveryPackets {
        for station in radio.guiClients {
          let stationModel = StationModel(radioModel: radio.model, radioNickname: radio.nickname, stationName: station.station, serialNumber: radio.serialNumber, clientId: station.clientId ?? "", handle: station.handle, isDefaultStation: self.isDefaultStation(stationName: station.station))
          UI {
            self.stationModels.removeAll { $0.stationName == stationModel.stationName }
            self.stationModels.append(stationModel)
          }
        }
      }
      
      os_log("GUI clients have been updated.", log: RadioManager.model_log, type: .info)
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
        self.stationModels.removeAll(where: { $0.stationName == guiClient.station })
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
    var stationName = ""
    
    addObservations(slice: slice)
    
    // get the station this slice belongs to
    if let index = self.stationModels.firstIndex(where: {$0.handle == slice.clientHandle}) {
      stationName = stationModels[index].stationName
    }
    
    // check if it already exists, may have been left on a crash
    if let index = self.sliceModels.firstIndex(where: {$0.sliceId == slice.id && $0.clientHandle == slice.clientHandle}) {
      self.sliceModels.remove(at: index)
    }
    
    // build and add the new one
    let sliceModel = SliceModel(sliceId: slice.id, sliceLetter: slice.sliceLetter ?? "Unknown", radioMode: mode, txEnabled: slice.txEnabled, frequency: frequency, clientHandle: slice.clientHandle, associatedStationName: stationName)
    
    sliceModels.append(sliceModel)
    
    // probably don't care when addded
    // I really only care about a slice that is tx enabled
    if slice.txEnabled && sliceModel.clientHandle == slice.clientHandle {
      UI() {
          self.sliceModel = sliceModel
      }
    }
    
    os_log("Slice has been addded.", log: RadioManager.model_log, type: .info)
  }
  
  /**
   Notification that one or more slices were removed. Iterate through collection
   and remove the slice from the array of available slices.
   - parameters:
   - note: a Notification instance
   */
  func sliceWillBeRemoved(_ note: Notification){
    
    let slice: xLib6000.Slice = (note.object as! xLib6000.Slice)
    let clientHandle = slice.clientHandle
    let sliceId = slice.id
    
    os_log("Slice has been removed.", log: RadioManager.model_log, type: .info)
    
    if let index = self.sliceModels.firstIndex(where: {$0.clientHandle == clientHandle && $0.sliceId == sliceId}) {
      self.sliceModels.remove(at: index)
    }
    
    UI() {
      if self.sliceModel.clientHandle == clientHandle && self.sliceModel.sliceId == sliceId {
        self.sliceModel = SliceModel(radioMode: radioMode.invalid)
      }
    }
  }
  
  /**
   Observer handler to update the slice information for the labels on the GUI
   when a slice is updated.
   - parameters:
   - slice:
   */
  func updateSliceStatus(_ slice: xLib6000.Slice, sliceStatus: sliceStatus,  _ change: Any) {
    
    let mode: radioMode = radioMode(rawValue: slice.mode) ?? radioMode.invalid
    let frequency: String = convertFrequencyToDecimalString (frequency: slice.frequency)
    
    // find the slice, update it
      if let index = self.sliceModels.firstIndex(where: {$0.sliceId == slice.id && $0.clientHandle == slice.clientHandle}) {
      
      switch sliceStatus {
      case .active:
        break
      case .frequency:
        self.sliceModels[index].frequency = frequency
      case .mode:
        self.sliceModels[index].radioMode = mode
      case .txEnabled:
        self.sliceModels[index].txEnabled = slice.txEnabled
      }
     
      UI() {
        if self.sliceModels[index].clientHandle == self.sliceModel.clientHandle {
          
          self.sliceModel = self.getTxEnabledSlice(clientHandle: self.sliceModels[index].clientHandle)
        }
      }
    }
    os_log("Slice has been updated.", log: RadioManager.model_log, type: .info)
  }
  
  /**
   Return the current slice that is txEnabled or an invalid slice
   */
  func getTxEnabledSlice(clientHandle: UInt32) -> SliceModel {

    if let model = sliceModels.first(where: { $0.clientHandle == clientHandle && $0.txEnabled}) {
      return model
    }
    
    return sliceModels.first(where: { $0.clientHandle == clientHandle }) ?? SliceModel(radioMode: .invalid)
  }
  
  /**
   Update the slice model for the GUI when the bound station is changed
   */
  func updateSliceModel(){
    
    for sliceModel in sliceModels {
      if sliceModel.clientHandle == boundStationHandle {
        if sliceModel.txEnabled {
          UI() {
            self.sliceModel = SliceModel(sliceId: sliceModel.sliceId, sliceLetter: sliceModel.sliceLetter, radioMode: sliceModel.radioMode, txEnabled: sliceModel.txEnabled, frequency: sliceModel.frequency, clientHandle: sliceModel.clientHandle, associatedStationName: self.boundStationName)
          }
          break
        } else {
          UI() {
            self.sliceModel = SliceModel(sliceId: sliceModel.sliceId, sliceLetter: sliceModel.sliceLetter, radioMode: sliceModel.radioMode, txEnabled: sliceModel.txEnabled, frequency: sliceModel.frequency, clientHandle: sliceModel.clientHandle, associatedStationName: self.boundStationName)
          }
        }
      }
    }
  }
  
  // MARK: - Utility Functions for Slices
  
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
  
  /**
   Prepare to key the selected Radio. Create the audio stream to be sent.
   - parameters:
   - doTransmit: true create and send an audio stream, false will unkey MOX
   - buffer: an array of floats representing an audio sample in PCM format
   */
  func keyRadio(doTransmit: Bool, buffer: [Float]? = nil, xmitGain: Int) {
    
    self.xmitGain = xmitGain
    
    // temp code
    if buffer == nil {
      if doTransmit  {
        if (api.radio?.mox == false)  {
          api.radio?.mox = true
        } else {
          api.radio?.mox = false
        }
        return
      }
    }
  }
    
  // cleanup so we can bind with another station
  func cleanUp() {
    
    boundStationName = ""
    api.radio?.boundClientId = nil
    
    self.sliceModel = SliceModel(radioMode: .invalid)
  }
  
  /*
   Tune button was clicked
   */
  func tuneRadio() {
    if api.radio?.transmit.tune == false {
      api.radio?.transmit.tune = true
    } else {
      api.radio?.transmit.tune = false
    } 
  }
  
  /*
   MOX button clicked
   */
  func setMox() {
    if (api.radio?.mox == false)  {
      api.radio?.mox = true
    } else {
      api.radio?.mox = false
    }
  }
  
  func stopTransmitting() {
    api.radio?.cwx.clearBuffer()
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
   
    if message != "" {
      api.radio?.cwx.wpm = cwSpeed
      api.radio?.cwx.send(message)
    }
  }
  
  // MARK: Audio Methods (xCWReader) ----------------------------------------------------------------------------
  
  func startAudioReceive(daxChannel: UInt16)  {
    
    if daxRxAudioStreamRequested == false {
      
      api.radio!.requestDaxRxAudioStream(String(daxChannel), callback: updateDaxRxStreamId)
      daxRxAudioStreamRequested = true
      
      os_log("Audio stream requested.", log: RadioManager.model_log, type: .info)
    }
    else{
      // do something else
    }
  }
  
  func daxRxAudioStreamHasBeenAdded(_ note: Notification){
    
    if (note.object as? DaxRxAudioStream) != nil {
      os_log("Audio stream added.", log: RadioManager.model_log, type: .info)
    }
  }
  
  
  /**
   Callback for the TX Stream Request command.
   - Parameters:
   - command:        the original command
   - sequenceNumber: the Sequence Number of the original command
   - responseValue:  the response value
   - reply:          the reply
   */
  func updateDaxRxStreamId(_ command: String, sequenceNumber: UInt, responseValue: String, reply: String) {
    
    os_log("Audio stream updated.", log: RadioManager.model_log, type: .info)
    
    guard responseValue == "0" else {
      // Anything other than 0 is an error, log it and ignore the Reply
      os_log("Error requesting rx audio stream ID.", log: RadioManager.model_log, type: .error)
      // TODO: notify GUI
      return
    }
    
    // check if we have a stream requested
    if !daxRxAudioStreamRequested {
      os_log("Unsolicited audio stream received.", log: RadioManager.model_log, type: .error)
      return
    }
    
    // dax channel == 0
    if reply.streamId != 0 {
      if let streamId = reply.streamId {
        let audioStream = api.radio?.daxRxAudioStreams[streamId]
        audioStream?.delegate = self //audioManager
      }
    }
  }
  
  // MARK: - StreamHandler Handler Implementation (xCWReader)
  
  var tempArray = [CGFloat]()
  
  func streamHandler<T>(_ streamFrame: T) {
    guard let frame = streamFrame as? DaxRxAudioFrame else { return }
    processFrame(frame: frame)
  }
  
  /**
   timing specification for morse code:
   
   A dash is three times as long as a dot.
   The space between dots/dashes within one character is equally long as a dot.
   The space between two characters is three times as long as a dot.
   The space between two words is seven times as long as a dot.
   */
  func processFrame(frame: DaxRxAudioFrame) {
    
    var temp = [Float]()
    temp.reserveCapacity(128)
    
    // just need one audio channel since they are identical
    // SHOULD be able to just nomalize into temp or itself
    let result = frame.rightAudio //normalizeData(rawData: frame.rightAudio)
    
    // now have array with just positive values but all negatives are added
    // as positives for greater precision
    for item in result {
      temp.append(abs(item)) // change bottom half of sine wave to positive to expand sample
    }
    
    // need to clip bottom according to slider value (min threshold)
    temp = clipArray(source: temp, level: Float(level / 10000))
    
    temp = preProcessFrame(source: temp)
    
    // get average value
    let sumArray = temp.reduce(0, +)
    let avgArrayValue = sumArray / Float(temp.count)
    
    // I look at average and init a new array with all 1.0 or all 0.0
    // need to average over multiple frames - sort of like I do in preProcessFrame()
    if avgArrayValue > 0.3 {
      let floats = [Float](repeating: 1.0, count: 128)
      temp = floats
    } else {
      let floats = [Float](repeating: 0.0, count: 128)
      temp = floats
    }
    
    // --------------------------------
    
         addToBuffer(source: temp)
    
    // --------------------------------
    
    // make float array a cgfloat array
    let dataCGFloat = temp.map{CGFloat($0)}
    
    UI { [self] in
      for item in dataCGFloat {
        audioData.append(item / 5) // audioData.append(item * 5)
      }
      
      if audioData.count > 24576 {
        audioData.removeSubrange(0..<128)
      }
    }
  }
  
  
  // use a queue here
  func addToBuffer(source: [Float]) {
    
    //inputQueue.async() { [self] in
        //cwprocessor.addToBuffer(frame: source)
      print("\(source.count) items added to buffer")
    //}
    
    //if !rbuf.isEmpty() {
    //  retrieveFromBuffer()
    //}
  }
  
  //var oneCount = 0;
  //var zeroCount = 0
  
  func retrieveFromBuffer() {

//    outputQueue.async() { [self] in
//      while true {
//        //let element = cwprocessor.retrievefromBuffer()
//      //if element == 1 {
//       // print("element: \(element)")
//      //}
//        //cwprocessor.processElement(element: element)
//      }
//     }
  }
  
  
  /// try to reduce the number of spikes from noise
  /// analyze a block of 4 bits at a time
  /// 0000 - 0xx0 - 0x0x -
  func preProcessFrame(source: [Float]) -> [Float] {
    var temp = [Float]()
    var count = 0
    
    // process in 4 float increments
    let result = source.chunked(into: 4)
    
    for index in 0...result.count - 1 {
      
      count += 1
      
      switch result[index] {
      
      // all blocks - if the first and last are 0 then all are 0
      // 0xx0 -> 0000
      case _ where result[index][1] == 0 && result[index][3] == 0:
        temp.append(contentsOf: result[index].map { _ in 0 })
        
      // all blocks - if the first and last are > 0 then all are > 0.09
      // XxxX -> XXXX
      //case _ where result[index][1] > 0 && result[index][3] > 0:
      //  temp.append(contentsOf: result[index].map { _ in 0.09 })
      
      // first block only - if third = 0 then first and second = 0
      // 0x0x -> 0000
      case _ where index == 0 && result[index][2] == 0:
        temp.append(contentsOf: [0,0,0])
        temp.append(1.0) //result[index][3])
        break
        
      // first block only - if second = 0 then one = 0
      // x0xx -> 0000
      case _ where index == 0 && result[index][1] == 0:
        temp.append(contentsOf: [0,0])
        temp.append(contentsOf: [1,1])
        break
        
      // all but first block - last one of last group and last one of this group are 0 then all are 0
      // xxx0xxx0 -> xxx00000
      case _ where index > 0 && result[index - 1][3] == 0 && result[index][3] == 0:
        temp.append(contentsOf: result[index].map { _ in 0 })
        break
        
      // all but first block - last one of last group = 0 and third one of this group = 0
      // xxx0xx0x -> xxx0000x
      case _ where index > 0 && result[index - 1][3] == 0 && result[index][2] == 0:
        temp.append(contentsOf: [0,0,0])
        temp.append(1.0) //(result[index][3])
      
      // all but first block - last one of last group = 0 and second one of this group = 0
      // xxx0x0xx -> xxx000xx
      case _ where index > 0 && result[index - 1][3] == 0 && result[index][1] == 0:
        temp.append(contentsOf: [0,0])
        temp.append(contentsOf: [1,1])
      
      // all but first block - last one of last group = 0 and second one of this group = 0
      // xxx0x0xx -> xxx000xx
      //      case _ where index > 0 && result[index - 1][3] == 0 && result[index][1] == 0:
      //        temp.append(0)
      //        temp.append(0)
      //        temp.append(0.06) //(result[index][2])
      //        temp.append(0.06) //(result[index][3])
      
      default:
        //temp.append(contentsOf: result[index])
        temp.append(contentsOf: result[index].map { _ in 1.0 })
        if index == 0 {
          //print("Default: \(result[index].map { _ in 0.06 })")
        } else {
          //print("Default: \(result[index - 1].map { _ in 0.06 }):\(result[index].map { _ in 0.06 })")
        }
      }
    }
    
    // every time the count gets to 8 we need to re-evaluate
    
    // if not all 0 then display
    //    if !temp.dropFirst().allSatisfy({ $0 == 0 }) {
    //print(temp)
    //    }
    
    //analyzeData(source: temp)
    
    //print("Count: \(temp.count)")
    return temp
    
  }
  
  /**
   
   
   */
  
  /// clip the peaks, if above average set to average
  /// if below average set to 0
  /// just making an assumption that the average is the noise level
  func clipArray(source: [Float], level: Float) -> [Float] {
    var temp = [Float]()
    
    for item in source {
      var a = item
      //      if item < 0 {
      //        //a = 0 //abs(item)
      //      }
      //print("level: \(level) -- a: \(a)")
      // this should be the average of the peaks above average
      if a > level {
        a = 1.0
        temp.append(a)
      } else {
        temp.append(0)
      }
    }
    
    return temp
  }
  
  
  // make everything positive
  func normalizeData(rawData: [Float]) -> [Float] {
    
    let results = rawData.map { ($0 - (-1)) / (1 - (-1)) }
    
    return results
  }
  
  func analyzeData(source: [Float]) {
    
    //print(source)
    
  }
  
} // end class

