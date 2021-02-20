//
//  SwiftUIExtensions.swift
//  xSpaceWeather
//
//  Created by Peter Bourget on 12/12/20.
//

import Foundation
import SwiftUI

/**
 Custom button template for the default button style.
 */
struct DefaultButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding(2)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

/**
Custom button template for the select button style.
*/
struct SelectButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding(2)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

/**
Custom button template for the control button style.
*/
struct ControlButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding(5)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

/**
Custom button template for the cw button style.
*/
struct CWButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding(2)
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}
/**
 Extension to apply custom button styles.
 */
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
  
  func memoryButton(
    foregroundColor: Color = .black,
    backgroundColor: Color = .blue,
    pressedColor: Color = .accentColor
  ) -> some View {
    self.buttonStyle(
      ControlButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor.opacity(0.30),
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
  ) -> some View {
    self.buttonStyle(
      CWButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor.opacity(0.30),
        pressedColor: pressedColor
      )
    )
  }
}
