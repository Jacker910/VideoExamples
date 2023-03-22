import Foundation

private extension String {
    static let video = "Video"
    static let videoExtension = "mp4"
    static let previewImage = "PreviewPictures"
    static let imageExtension = "jpg"
}

struct Post: Codable {
    let videoUrl: URL
    let previewImageUrl: URL
}

let manager = FileManager.default
let mainDirectory = URL(fileURLWithPath: manager.currentDirectoryPath)
let videoPath = mainDirectory.appendingPathComponent(.video)
let previewImagesPath = mainDirectory.appendingPathComponent(.previewImage)

Task {
    do {
        async let videoNames = readFiles(at: videoPath, withExtension: .videoExtension)
        let imagesNames = try await readFiles(at: previewImagesPath, withExtension: .imageExtension)
        try compare(video: try await videoNames, preview: imagesNames)
        let result: [Post] = try await videoNames
            .sorted(by: <)
            .compactMap {
                guard
                    let videoURL = URL(string: "https://github.com/Jacker910/VideoExamples/raw/main/Video/\($0).mp4"),
                    let imageURL = URL(string: "https://raw.githubusercontent.com/Jacker910/VideoExamples/main/PreviewPictures/\($0).jpg")
                else { return nil }
                return Post(videoUrl: videoURL, previewImageUrl: imageURL)
            }
        let jsonData = try mapToJson(result)
        try writeJsonToFile(json: jsonData, at: mainDirectory.absoluteString, with: "posts")
    } catch let error {
        if error is CompareError {
            fatalError(error.localizedDescription)
        } else {
            fatalError("\(error)")
        }
    }
}

func readFiles(at path: URL, withExtension: String) async throws -> Set<String> {
    let files = try manager.contentsOfDirectory(at: path, includingPropertiesForKeys: [])
        .filter { $0.pathExtension == withExtension}
        .map { $0.deletingPathExtension().lastPathComponent }
    return Set(files)
}

func mapToJson(_ posts: [Post]) throws -> Data {
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    return try jsonEncoder.encode(posts)
}

func writeJsonToFile(json: Data, at path: String, with name: String) throws {
    let jsonURL = mainDirectory.appendingPathComponent("\(name).json")
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
