import Orion
import VendettaTweakC
import os

let vendettaLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "vendetta")

class LoadHook: ClassHook<RCTCxxBridge> {
  func executeApplicationScript(_ script: Data, url: URL, async: Bool) {
    os_log("executeApplicationScript called!", log: vendettaLog, type: .debug)
    orig.executeApplicationScript(script, url: url, async: async)
  }
}
