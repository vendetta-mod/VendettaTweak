import Orion
import VendettaC
import os

class LoadVendettaHook: ClassHook<RCTCxxBridge> {

  func executeApplicationScript(_ script: Data, url: URL, async: Bool) {
    // Fake URL that the modules patch and Vendetta came from
    let source = URL(string: "vendetta")!

    // Determine patches bundle path
    let vendettaPatchesBundlePath =
      FileManager.default.fileExists(
        atPath: "/Library/Application Support/Vendetta/VendettaPatches.bundle")
      ? "/Library/Application Support/Vendetta/VendettaPatches.bundle"
      : "\(Bundle.main.bundleURL.path)/VendettaPatches.bundle"

    // Load patches bundle
    let vendettaPatchesBundle = Bundle(path: vendettaPatchesBundlePath)!

    // List of patches to apply
    let patches = ["modules", "identity", "devtools"]

    // Apply patches
    for patch in patches {
      // Load patch
      if let patchPath = vendettaPatchesBundle.path(forResource: patch, ofType: "js") {
        do {
          // Load patch
          let patchString = try String(contentsOfFile: patchPath)
          if let patchData = patchString.data(using: .utf8) {
            // Load it
            orig.executeApplicationScript(patchData, url: source, async: false)
          }
        } catch {}
      }
    }

    // Load Discord
    orig.executeApplicationScript(script, url: url, async: async)

    // Vendetta URL and URLRequest
    let releaseUrl = URL(
      string: "https://raw.githubusercontent.com/vendetta-mod/builds/master/vendetta.js")!
    let request = URLRequest(url: releaseUrl, cachePolicy: .reloadIgnoringCacheData)

    // Try to load Vendetta
    let vendettaPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("vendetta.js")
    
    // Download Vendetta
    do {
      let vendetta = try NSURLConnection.sendSynchronousRequest(request, returning: nil)
      try vendetta.write(to: vendettaPath)
    } catch {}

    // Load Vendetta
    do {
      let vendetta = try Data(contentsOf: vendettaPath)
      orig.executeApplicationScript(vendetta, url: source, async: async)
    } catch {}
  }
}
