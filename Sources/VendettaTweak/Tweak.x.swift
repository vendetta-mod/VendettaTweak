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

    let documentDirectory = try! FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

    var vendetta = try? Data(contentsOf: documentDirectory.appendingPathComponent("vendetta.js"))

    let group = DispatchGroup()

    group.enter()
    os_log("Fetching vendetta.js", log: vendettaLog, type: .info)
    let vendettaUrl = URL(
      string: "https://raw.githubusercontent.com/vendetta-mod/builds/master/vendetta.js")!
    let vendettaRequest = URLRequest(
      url: vendettaUrl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 3.0)

    let vendettaTask = URLSession.shared.dataTask(with: vendettaRequest) { data, response, error in
      if data != nil {
        os_log("Successfully fetched vendetta.js", log: vendettaLog, type: .debug)
        vendetta = data

        try? vendetta?.write(to: documentDirectory.appendingPathComponent("vendetta.js"))
      }

      group.leave()
    }

    vendettaTask.resume()
    group.wait()

    os_log("Executing original script", log: vendettaLog, type: .info)
    orig.executeApplicationScript(script, url: url, async: false)

    if vendetta != nil {
      os_log("Executing vendetta.js", log: vendettaLog, type: .info)
      orig.executeApplicationScript(vendetta!, url: source, async: false)
    } else {
      os_log("Unable to fetch vendetta.js", log: vendettaLog, type: .error)
    }
  }
}
