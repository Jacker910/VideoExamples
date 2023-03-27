import Foundation

private extension String {
    static let hls = "/HLS"
    static let videoExtension = "m3u8"
    static let previewImage = "/PreviewPictures"
    static let imageExtension = "jpg"
}

struct Post: Codable {
    let videoUrl: URL
    let previewImageUrl: URL
}

let manager = FileManager.default
let mainDirectory = "./"
let videoPath = mainDirectory + .hls
let previewImagesPath = mainDirectory + .previewImage

do {
    let videoNames = try readFiles(at: videoPath, withExtension: .videoExtension)
    let imagesNames = try readFiles(at: previewImagesPath, withExtension: .imageExtension)
    try compare(video: videoNames, preview: imagesNames)
    let result: [Post] = videoNames
        .sorted(by: <)
        .compactMap {
            guard
                let videoURL = URL(string: "https://raw.githubusercontent.com/Jacker910/VideoExamples/main/HLS/\($0).\(String.videoExtension)"),
                let imageURL = URL(string: "https://raw.githubusercontent.com/Jacker910/VideoExamples/main/PreviewPictures/\($0).\(String.imageExtension)")
            else { return nil }
            return Post(videoUrl: videoURL, previewImageUrl: imageURL)
        }
    let jsonData = try mapToJson(result)
    try writeJsonToFile(json: jsonData, at: mainDirectory, with: "postsHLS")
} catch let error {
    if error is CompareError {
        print(error.localizedDescription)
        fatalError(error.localizedDescription)
    } else {
        print(error)
        fatalError("\(error)")
    }
}

func readFiles(at directory: String, withExtension: String) throws -> Set<String> {
    let fileManager = FileManager.default
    let url = URL(fileURLWithPath: directory)
    
    let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    return Set( contents.filter { $0.pathExtension == withExtension }.map { $0.deletingPathExtension().lastPathComponent } )
}

func mapToJson(_ posts: [Post]) throws -> Data {
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    return try jsonEncoder.encode(posts)
}

func writeJsonToFile(json: Data, at path: String, with name: String) throws {
    let jsonURL = URL(filePath: mainDirectory + ("/\(name).json"))
    try json.write(to: jsonURL)
}

func compare(video: Set<String>, preview: Set<String>) throws {
    guard video != preview else { return }
    let needPreview = video.subtracting(preview)
    let needVideo = preview.subtracting(video)
    if !needPreview.isEmpty, !needVideo.isEmpty {
        throw CompareError.needImagesAndVideo(video: needVideo, images: needPreview)
    } else if !needPreview.isEmpty {
        throw CompareError.needPreviewImages(needPreview)
    } else {
        throw CompareError.needVideo(needVideo)
    }
}


enum CompareError: LocalizedError {
    case needPreviewImages(Set<String>)
    case needVideo(Set<String>)
    case needImagesAndVideo(video: Set<String>, images: Set<String>)
    
    var errorDescription: String? {
        switch self {
        case .needPreviewImages(let images): return "В папке отсутсвуют превью изображения \(images)"
        case .needVideo(let video): return "Нужны видео \(video)"
        case .needImagesAndVideo(let video, let images): return "Нужны превью изображения \(images) и видео \(video)"
        }
    }
}
