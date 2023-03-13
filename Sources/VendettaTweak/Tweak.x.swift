import Orion
import VendettaTweakC
import os

let vendettaLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "vendetta")
let source = URL(string: "vendetta")!

let vendettaPatchesBundlePath =
  FileManager.default.fileExists(
    atPath: "/Library/Application Support/VendettaTweak/VendettaPatches.bundle")
  ? "/Library/Application Support/VendettaTweak/VendettaPatches.bundle"
  : "\(Bundle.main.bundleURL.path)/VendettaPatches.bundle"

class LoadHook: ClassHook<RCTCxxBridge> {
  func executeApplicationScript(_ script: Data, url: URL, async: Bool) {
    os_log("executeApplicationScript called!", log: vendettaLog, type: .debug)

    let vendettaPatchesBundle = Bundle(path: vendettaPatchesBundlePath)!

    os_log("Executing patches", log: vendettaLog, type: .info)
    for patch in ["modules", "devtools", "identity"] {
      if let patchPath = vendettaPatchesBundle.url(forResource: patch, withExtension: "js") {
        let patchData = try! Data(contentsOf: patchPath)
        os_log("Executing %{public}@ patch", log: vendettaLog, type: .debug, patch)
        orig.executeApplicationScript(patchData, url: source, async: false)
      }
    }

    os_log("Executing original script", log: vendettaLog, type: .info)
    orig.executeApplicationScript(script, url: url, async: false)
  }
}
