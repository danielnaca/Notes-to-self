//
//  Styling.swift
//  Notes to self
//
//  Created by Daniel Nacamuli on 6/15/25.
//

import SwiftUI

// MARK: - Colors
struct AppColors {
    // Base Color Palette
    static let accent = Color(red: 209/255, green: 72/255, blue: 54/255)
    static let white = Color.white
    static let black = Color.black
    static let palegrey = Color.gray.opacity(0.3)
    static let darkgrey = Color.gray.opacity(0.7)
    
    // ----- Notes_to_selfApp.swift -----
    static let composerBackground = accent
    static let listBackground = white
    static let appBackground = palegrey
    static let background = white
    static let inputBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let noteText = black
    static let placeholderText = palegrey
    static let secondaryText = darkgrey
    static let tertiaryText = Color.gray.opacity(0.5)
    static let textFieldBorder = palegrey
    static let settingsButton = accent
    
    // ----- NotesToSelfWidget.swift -----
    static let widgetBackground = accent
    static let widgetText = white
    static let widgetButtonInvisible = Color(red: 0/255, green: 0/255, blue: 105/255)
    static let widgetButtonVisible = white
    static let widgetButtonBorder = white
}

// MARK: - Dimensions
struct AppDimensions {
    // ----- Notes_to_selfApp.swift -----
    static let textInputMaxHeight: CGFloat = 120
    static let settingsButtonSize: CGFloat = 44
    static let baseTextHeight: CGFloat = UIFont.preferredFont(forTextStyle: .body).lineHeight + 24
    static let textFieldCornerRadius: CGFloat = 20
    static let textFieldBorderWidth: CGFloat = 1
    
    // ----- NotesToSelfWidget.swift -----
    static let widgetButtonInvisibleSize: CGFloat = 80  // Large tap target for easier tapping
    static let widgetButtonVisibleSize: CGFloat = 60  // Doubled for visibility
}

// MARK: - Padding
struct AppPadding {
    // ----- Notes_to_selfApp.swift -----
    static let composerAllSides: CGFloat = 12
    static let listBottom: CGFloat = 200
    static let textFieldInner: CGFloat = 4
    static let placeholderHorizontal: CGFloat = 8
    static let placeholderVertical: CGFloat = 12
    static let hiddenTextMeasurement = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
    
    // ----- NotesToSelfWidget.swift -----
    static let widgetTextPadding: CGFloat = 1
}

// MARK: - Positioning
struct AppPositioning {
    // ----- Notes_to_selfApp.swift -----
    static let settingsButtonFromRight: CGFloat = 30
    static let settingsButtonFromTop: CGFloat = 22
    static let hiddenTextWidthOffset: CGFloat = 24 // for geometry.size.width - 24
    
    // ----- NotesToSelfWidget.swift -----
    // Widget button positioning is at geometry.size.width, geometry.size.height (no offset)
    static let widgetButtonXOffset: CGFloat = 0
    static let widgetButtonYOffset: CGFloat = 0
}

// MARK: - Typography
struct AppTypography {
    // ----- Notes_to_selfApp.swift -----
    static let bodyFont = Font.body
    
    // ----- NotesToSelfWidget.swift -----
    static let widgetSmallFont = Font.system(size: 16)
    static let widgetLargeFont = Font.system(size: 16)
} 
