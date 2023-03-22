import Foundation

private extension String {
    static let video = "Video"
    static let videoExtension = "mp4"
    static let previewImage = "PreviewPictures"
    static let imageExtension = "jpg"
}

let manager = FileManager.default
let mainDirectory = URL(fileURLWithPath: manager.currentDirectoryPath)
let videoPath = mainDirectory.appendingPathComponent(.video)
let previewImagesPath = mainDirectory.appendingPathComponent(.previewImage)

Task {
    do {
        async let videoNames = try await readFiles(at: videoPath, withExtension: .videoExtension)
        let imagesNames = try await readFiles(at: previewImagesPath, withExtension: .imageExtension)
        try compare(video: await videoNames, preview: imagesNames)
        let jsonData = try mapToJson(imagesNames)
        try writeJsonToFile(json: jsonData, at: mainDirectory.absoluteString, with: "filesList")
    } catch let error {
        if error is CompareError {
            print(error.localizedDescription)
        } else {
            print(error)
        }
    }
}

func readFiles(at path: URL, withExtension: String) async throws -> Set<String> {
    let files = try manager.contentsOfDirectory(at: path, includingPropertiesForKeys: [])
        .filter { $0.pathExtension == withExtension}
        .map { $0.deletingPathExtension().lastPathComponent }
    return Set(files)
}

func mapToJson(_ names: Set<String>) throws -> Data {
    let result = Array(names).sorted(by: <)
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = .prettyPrinted
    return try jsonEncoder.encode(result)
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
