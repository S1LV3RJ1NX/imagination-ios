//
//  DebugLog.swift
//  ImaginationGame
//
//  Simple debug logging utility - automatically disabled in release builds
//

import Foundation

/// Debug logging - only prints in DEBUG builds
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
    #endif
}
