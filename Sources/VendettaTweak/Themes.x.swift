import Orion
import UIKit
import VendettaTweakC
import os

struct Author: Codable {
  let name: String
  let id: String?
}

struct ThemeData: Codable {
  let name: String
  let description: String?
  let authors: [Author]?
  let spec: Int
  let semanticColors: [String: [String]]?
  let rawColors: [String: String]?
}

struct Theme: Codable {
  let id: String
  let selected: Bool
  let data: ThemeData
}

func hexToUIColor(_ hex: String) -> UIColor? {
  let r: CGFloat
  let g: CGFloat
  let b: CGFloat
  let a: CGFloat

  if hex.hasPrefix("#") {
    let start = hex.index(hex.startIndex, offsetBy: 1)
    var hexColor = String(hex[start...])

    if hexColor.count == 6 {
      hexColor.append("ff")
    }

    if hexColor.count == 8 {
      let scanner = Scanner(string: hexColor)
      var hexNumber: UInt64 = 0

      if scanner.scanHexInt64(&hexNumber) {
        r = CGFloat((hexNumber & 0xff00_0000) >> 24) / 255
        g = CGFloat((hexNumber & 0x00ff_0000) >> 16) / 255
        b = CGFloat((hexNumber & 0x0000_ff00) >> 8) / 255
        a = CGFloat(hexNumber & 0x0000_00ff) / 255

        return UIColor(red: r, green: g, blue: b, alpha: a)
      }
    }
  }

  return nil
}

func swizzleDCDThemeColor(_ semanticColors: [String: [String]]) {
  os_log("Swizzling DCDThemeColor", log: vendettaLog, type: .info)

  let DCDTheme: AnyClass = NSClassFromString("DCDTheme")!
  let dcdThemeTarget: AnyClass = object_getClass(DCDTheme)!

  let themeIndexSelector = NSSelectorFromString("themeIndex")
  let themeIndexMethod = class_getClassMethod(dcdThemeTarget, themeIndexSelector)!
  let themeIndexImpl = method_getImplementation(themeIndexMethod)
  typealias ThemeIndexType = @convention(c) (AnyObject, Selector) -> Int
  let themeIndex: ThemeIndexType = unsafeBitCast(themeIndexImpl, to: ThemeIndexType.self)

  let DCDThemeColor: AnyClass = NSClassFromString("DCDThemeColor")!
  os_log("Found instance of DCDThemeColor", log: vendettaLog, type: .debug)
  let target: AnyClass = object_getClass(DCDThemeColor)!

  os_log("Found DCDThemeColor", log: vendettaLog, type: .debug)

  var methodCount: UInt32 = 0
  let methods = class_copyMethodList(target, &methodCount)!

  os_log("DCDThemeColor has %{public}d methods", log: vendettaLog, type: .debug, methodCount)

  for i in 0..<Int(methodCount) {
    let method = methods[i]
    let selector = method_getName(method)
    let methodName = NSStringFromSelector(selector)
    os_log(
      "Found method %{public}@", log: vendettaLog, type: .debug, methodName)
    if let semanticColor = semanticColors[methodName] {
      os_log(
        "Swizzling %{public}@", log: vendettaLog, type: .debug, methodName)

      let originalImpl = method_getImplementation(method)
      typealias OriginalType = @convention(c) (AnyObject, Selector) -> UIColor
      let original = unsafeBitCast(originalImpl, to: OriginalType.self)
      let semanticColorBlock: @convention(block) (AnyObject) -> UIColor = {
        (self: AnyObject) -> UIColor in
        let themeIndexVal = themeIndex(dcdThemeTarget, themeIndexSelector)
        if semanticColor.count - 1 >= themeIndexVal {
          if let semanticUIColor = hexToUIColor(
            semanticColor[themeIndexVal])
          {
            return semanticUIColor
          }
        }

        return original(target, selector)
      }
      let semanticColorImplementation = imp_implementationWithBlock(
        unsafeBitCast(semanticColorBlock, to: AnyObject.self))
      method_setImplementation(
        method, semanticColorImplementation)

    }
  }
  free(methods)
}

func swizzleUIColor(_ rawColors: [String: String]) {
  os_log("Swizzling UIColor", log: vendettaLog, type: .info)

  let UIColor: AnyClass = NSClassFromString("UIColor")!
  os_log("Found instance of UIColor", log: vendettaLog, type: .debug)
  let target: AnyClass = object_getClass(UIColor)!

  os_log("Found UIColor", log: vendettaLog, type: .debug)

  var methodCount: UInt32 = 0
  let methods = class_copyMethodList(target, &methodCount)!

  os_log("UIColor has %{public}d methods", log: vendettaLog, type: .debug, methodCount)

  for i in 0..<Int(methodCount) {
    let method = methods[i]
    let selector = method_getName(method)
    let methodName = NSStringFromSelector(selector)
    os_log(
      "Found method %{public}@", log: vendettaLog, type: .debug, methodName)
    if let rawColor = rawColors[methodName] {
      os_log(
        "Swizzling %{public}@", log: vendettaLog, type: .debug, methodName)
      let rawColorBlock: @convention(block) (AnyObject) -> UIColor = {
        (self: AnyObject) -> UIColor in
        return hexToUIColor(rawColor)!
      }
      let rawColorImplementation = imp_implementationWithBlock(
        unsafeBitCast(rawColorBlock, to: AnyObject.self))
      method_setImplementation(
        method, rawColorImplementation)

    }
  }
  free(methods)
}
