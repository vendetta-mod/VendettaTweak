import Orion
import VendettaC
import os

class LoadVendettaHook: ClassHook<RCTCxxBridge> {

  func executeApplicationScript(_ script: Data, url: URL, async: Bool) {
    // Fake URL that the modules patch and Vendetta came from
    let source = URL(string: "vendetta")!

    let loaderConfig = getLoaderConfig()

    // Determine patches bundle path
    let vendettaPatchesBundlePath =
      FileManager.default.fileExists(
        atPath: "/Library/Application Support/Vendetta/VendettaPatches.bundle")
      ? "/Library/Application Support/Vendetta/VendettaPatches.bundle"
      : "\(Bundle.main.bundleURL.path)/VendettaPatches.bundle"

    // Load patches bundle
    let vendettaPatchesBundle = Bundle(path: vendettaPatchesBundlePath)!

    // List of patches to apply
    var patches = ["modules", "identity"]

    // Add devtools if enabled
    if loaderConfig.loadReactDevTools {
      patches.append("devtools")
    }

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

    // Determine which URL to download Vendetta from
    var url: URL
    if loaderConfig.customLoadUrl.enabled {
      // Custom
      url = loaderConfig.customLoadUrl.url
    } else {
      // Release
      url = URL(
        string: "https://raw.githubusercontent.com/vendetta-mod/builds/master/vendetta.js")!
    }

    // The request to get Vendetta
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
    request.timeoutInterval = 3.0

    // Vendetta's path
    let documentsDirectory = getDocumentsDirectory()
    let vendettaPath = documentsDirectory.appendingPathComponent("vendetta.js")

    // Load Vendetta
    do {
      // Fetch from remote
      let vendetta = try NSURLConnection.sendSynchronousRequest(request, returning: nil)
      // Write to file (for cache)
      try vendetta.write(to: vendettaPath)
      // Execute!
      orig.executeApplicationScript(vendetta, url: source, async: async)
    } catch {
      do {
        // Load from file, if this doesn't work we can't load vendetta for this session :(
        let vendetta = try Data(contentsOf: vendettaPath)
        // Execute!
        orig.executeApplicationScript(vendetta, url: source, async: async)
      } catch {}
    }
  }
}
