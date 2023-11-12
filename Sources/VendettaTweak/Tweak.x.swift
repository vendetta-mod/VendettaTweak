import Orion
import VendettaTweakC
import os

let vendettaLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "vendetta")
let source = URL(string: "vendetta")!

let install_prefix = String(cString: get_install_prefix())
let isJailbroken = FileManager.default.fileExists(atPath: "\(install_prefix)/Library/Application Support/VendettaTweak/VendettaPatches.bundle")

let vendettaPatchesBundlePath = isJailbroken ? "\(install_prefix)/Library/Application Support/VendettaTweak/VendettaPatches.bundle" : "\(Bundle.main.bundleURL.path)/VendettaPatches.bundle"

class FileManagerLoadHook: ClassHook<FileManager> {
  func containerURLForSecurityApplicationGroupIdentifier(_ groupIdentifier: NSString?) -> URL? {
    os_log("containerURLForSecurityApplicationGroupIdentifier called! %{public}@ groupIdentifier", log: vendettaLog, type: .debug, groupIdentifier ?? "nil")

    if (isJailbroken) {
      return orig.containerURLForSecurityApplicationGroupIdentifier(groupIdentifier)
    }

    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let lastPath = paths.last!
    return lastPath.appendingPathComponent("AppGroup")
  }
}

class LoadHook: ClassHook<RCTCxxBridge> {
  func executeApplicationScript(_ script: Data, url: URL, async: Bool) {
    os_log("executeApplicationScript called!", log: vendettaLog, type: .debug)

    let loaderConfig = getLoaderConfig()

    let vendettaPatchesBundle = Bundle(path: vendettaPatchesBundlePath)!
    var patches = ["modules", "identity"]
    if loaderConfig.loadReactDevTools {
      os_log("DevTools patch enabled", log: vendettaLog, type: .info)
      patches.append("devtools")
    }

    os_log("Executing patches", log: vendettaLog, type: .info)
    for patch in patches {
      if let patchPath = vendettaPatchesBundle.url(forResource: patch, withExtension: "js") {
        let patchData = try! Data(contentsOf: patchPath)
        os_log("Executing %{public}@ patch", log: vendettaLog, type: .debug, patch)
        orig.executeApplicationScript(patchData, url: source, async: true)
      }
    }

    let documentDirectory = getDocumentDirectory()

    var vendetta = try? Data(contentsOf: documentDirectory.appendingPathComponent("vendetta.js"))

    let group = DispatchGroup()

    group.enter()
    var vendettaUrl: URL
    if loaderConfig.customLoadUrl.enabled {
      os_log(
        "Custom load URL enabled, with URL %{public}@ ", log: vendettaLog, type: .info,
        loaderConfig.customLoadUrl.url.absoluteString)
      vendettaUrl = loaderConfig.customLoadUrl.url
    } else {
      vendettaUrl = URL(
        string: "https://raw.githubusercontent.com/vendetta-mod/builds/master/vendetta.js")!
    }

    os_log("Fetching vendetta.js", log: vendettaLog, type: .info)
    var vendettaRequest = URLRequest(
      url: vendettaUrl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 3.0)

    if let vendettaEtag = try? String(
      contentsOf: documentDirectory.appendingPathComponent("vendetta_etag.txt")), vendetta != nil
    {
      vendettaRequest.addValue(vendettaEtag, forHTTPHeaderField: "If-None-Match")
    }

    let vendettaTask = URLSession.shared.dataTask(with: vendettaRequest) { data, response, error in
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        os_log("Successfully fetched vendetta.js", log: vendettaLog, type: .debug)
        vendetta = data
        try? vendetta?.write(to: documentDirectory.appendingPathComponent("vendetta.js"))

        let etag = httpResponse.allHeaderFields["Etag"] as? String
        try? etag?.write(
          to: documentDirectory.appendingPathComponent("vendetta_etag.txt"), atomically: true,
          encoding: .utf8)
      }

      group.leave()
    }

    vendettaTask.resume()
    group.wait()

    os_log("Executing original script", log: vendettaLog, type: .info)
    orig.executeApplicationScript(script, url: url, async: async)

    if let themeString = try? String(
      contentsOf: documentDirectory.appendingPathComponent("vendetta_theme.json"))
    {
      orig.executeApplicationScript(
        "globalThis.__vendetta_theme=\(themeString)".data(using: .utf8)!, url: source, async: async)
    }

    if vendetta != nil {
      os_log("Executing vendetta.js", log: vendettaLog, type: .info)
      orig.executeApplicationScript(vendetta!, url: source, async: async)
    } else {
      os_log("Unable to fetch vendetta.js", log: vendettaLog, type: .error)
    }
  }
}

struct VendettaTweak: Tweak {
    func tweakDidActivate() {
      if let themeData = try? Data(
      contentsOf: documentDirectory.appendingPathComponent("vendetta_theme.json")) {
        let theme = try? JSONDecoder().decode(Theme.self, from: themeData)
        if let semanticColors = theme?.data.semanticColors { swizzleDCDThemeColor(semanticColors) }
        if let rawColors = theme?.data.rawColors { swizzleUIColor(rawColors) }
      }
    }
}
