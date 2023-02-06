import Foundation

struct CustomLoadUrl: Codable {
  let enabled: Bool
  let url: URL
}

struct LoaderConfig: Codable {
  let customLoadUrl: CustomLoadUrl
  let loadReactDevTools: Bool
}

// The default configuration
let defaultLoaderConfig = LoaderConfig(
  customLoadUrl: CustomLoadUrl(
    enabled: false,
    url: URL(string: "http://localhost:4040/vendetta.js")!
  ),
  loadReactDevTools: false
)

let documentsDirectory = getDocumentsDirectory()
let loaderConfigUrl = documentsDirectory.appendingPathComponent("vendetta_loader.json")

func getLoaderConfig() -> LoaderConfig {
  let fileManager = FileManager.default

  do {
    // Check if the configuration exists
    if fileManager.fileExists(atPath: loaderConfigUrl.path) {
      // try to load it if it does
      let data = try Data(contentsOf: loaderConfigUrl)
      let loaderConfig = try JSONDecoder().decode(LoaderConfig.self, from: data)

      return loaderConfig
    } else {
      // If it doesn't exist, create it
      createLoaderConfig()
      // Return default oconfig
      return defaultLoaderConfig
    }

  } catch {
    // Oops! We failed to load the config. Reset it to defaults.
    createLoaderConfig()
    // Return the default config
    return defaultLoaderConfig
  }
}

func createLoaderConfig() {
  do {
    // Encode default config
    let encodedConfig = try JSONEncoder().encode(defaultLoaderConfig)
    // Write it to disk
    try encodedConfig.write(to: loaderConfigUrl)
  } catch {}
}
