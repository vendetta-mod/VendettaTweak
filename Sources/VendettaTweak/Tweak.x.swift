import Orion
import VendettaTweakC

class LoadVendettaHook: ClassHook<RCTCxxBridge> {

  func executeApplicationScript(_ script: Data, url: URL, async: Bool) {
    // Fake URL that the modules patch and Vendetta came from
    let source = URL(string: "vendetta")!

    // Load modules patch
    let modulesPatch: String =
      "const oldObjectCreate = this.Object.create; const win = this; win.Object.create = (...args) => { const obj = oldObjectCreate.apply(win.Object, args); if (args[0] === null) { win.modules = obj; win.Object.create = oldObjectCreate; } return obj; };"
    let modulesPatchData = modulesPatch.data(using: .utf8)!
    orig.executeApplicationScript(modulesPatchData, url: source, async: false)

    // Load Discord
    orig.executeApplicationScript(script, url: url, async: async)

    // Vendetta URL and URLRequest
    let releaseUrl = URL(
      string: "https://raw.githubusercontent.com/vendetta-mod/builds/master/vendetta.js")!
    let request = URLRequest(url: releaseUrl, cachePolicy: .reloadIgnoringCacheData)

    // Try to load Vendetta
    do {
      let vendetta = try NSURLConnection.sendSynchronousRequest(request, returning: nil)
      orig.executeApplicationScript(vendetta, url: source, async: async)
    } catch {}
  }
}
