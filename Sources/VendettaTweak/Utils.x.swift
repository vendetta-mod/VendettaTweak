import Foundation

func getDocumentDirectory() -> URL {
  return try! FileManager.default.url(
    for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
}
