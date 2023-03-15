import Foundation
import os

enum LoaderConfigError: Error {
  case doesNotExist
}

struct CustomLoadUrl: Codable {
  let enabled: Bool
  let url: URL
}

struct LoaderConfig: Codable {
  let customLoadUrl: CustomLoadUrl
  let loadReactDevTools: Bool
}

let defaultLoaderConfig = LoaderConfig(
  customLoadUrl: CustomLoadUrl(
    enabled: false,
    url: URL(string: "http://localhost:4040/vendetta.js")!
  ),
  loadReactDevTools: false
)

let documentDirectory = getDocumentDirectory()
let loaderConfigUrl = documentDirectory.appendingPathComponent("vendetta_loader.json")

func getLoaderConfig() -> LoaderConfig {
  os_log("Getting loader config", log: vendettaLog, type: .debug)
  let fileManager = FileManager.default

  do {
    if fileManager.fileExists(atPath: loaderConfigUrl.path) {
      let data = try Data(contentsOf: loaderConfigUrl)
      let loaderConfig = try JSONDecoder().decode(LoaderConfig.self, from: data)

      os_log("Got loader config", log: vendettaLog, type: .debug)

      return loaderConfig
    } else {
      throw LoaderConfigError.doesNotExist
    }
  } catch {
    os_log("Couldn't get loader config", log: vendettaLog, type: .error)
    createLoaderConfig()

    return defaultLoaderConfig
  }
}

func createLoaderConfig() {
  do {
    let encodedConfig = try JSONEncoder().encode(defaultLoaderConfig)
    try encodedConfig.write(to: loaderConfigUrl)
    os_log("Created loader config", log: vendettaLog, type: .debug)
  } catch {}
}
