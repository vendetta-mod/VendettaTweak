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

func swizzleDCDThemeColor() {
  os_log("Swizzling DCDThemeColor", log: vendettaLog, type: .info)

  let DCDThemeColor: AnyClass = NSClassFromString("DCDThemeColor")!
  os_log("Found instance of DCDThemeColor", log: vendettaLog, type: .debug)
  let target: AnyClass = object_getClass(DCDThemeColor)!

  os_log("Found DCDThemeColor", log: vendettaLog, type: .debug)

  var methodCount: UInt32 = 0
  let methods = class_copyMethodList(target, &methodCount)

  os_log("DCDThemeColor has %{public}d methods", log: vendettaLog, type: .debug, methodCount)

  for i in 0..<Int(methodCount) {
    let unwrapped = methods![i]
    let methodName = NSStringFromSelector(method_getName(unwrapped))
    os_log(
      "Found method %{public}@", log: vendettaLog, type: .debug, methodName)
  }
}
