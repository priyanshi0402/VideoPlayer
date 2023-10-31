//
//  SubtitleExtractor.swift
//  VideoPlayer
//
//  Created by Tecocraft on 31/10/23.
//
import AVFoundation

class SubtitleExtractor {
    private var asset: AVAsset
    private var subtitleTrack: AVAssetTrack?
    var previousFrameTime = CMTime.zero
    var previousActualFrameTime = CFAbsoluteTimeGetCurrent()
    
    init(videoURL: URL) {
        asset = AVAsset(url: videoURL)
        subtitleTrack = findSubtitleTrack()
    }
    
    private func findSubtitleTrack() -> AVAssetTrack? {
        for track in asset.tracks {
            if track.mediaType == AVMediaType.subtitle {
                return track
            }
        }
        return nil
    }
    
    func getSubtitle(time: CMTime) {
        //        for track in self.asset.tracks(withMediaType: .subtitles) {
        guard let subtitleTrack = subtitleTrack else {
            print("Subtitle track not found in the video.")
            return
        }
        do {
            let reader = try AVAssetReader(asset: asset)
            let trackOutput = AVAssetReaderTrackOutput(track: subtitleTrack, outputSettings: nil)
            reader.add(trackOutput)
            reader.timeRange = CMTimeRange(start: time, duration: CMTime(seconds: 1.0, preferredTimescale: 1))
            reader.startReading()
            
            // Read the subtitle samples
            while let sample = trackOutput.copyNextSampleBuffer() {
                if let dataBuffer = CMSampleBufferGetDataBuffer(sample) {
                    var lengthAtOffset: Int = 0
                    var totalLength: Int = 0
                    var dataPointer: UnsafeMutablePointer<Int8>?
                    if CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer) == noErr {
                        if let dataPointer = dataPointer {
                            let subtitleData = Data(bytes: dataPointer, count: totalLength)
                            if let subtitleText = String(data: subtitleData, encoding: .isoLatin1) {
                                print("Subtitle: \(subtitleText)")
                            }
                        }
                    }
                }
            }
            reader.cancelReading()
        } catch {
            print("Error reading subtitle track: \(error.localizedDescription)")
        }
        
    }
    
    func extractSubtitles(at targetTime: CMTime) {
        guard let subtitleTrack = subtitleTrack else {
            print("Subtitle track not found in the video.")
            return
        }
        
        do {
            let assetReader = try AVAssetReader(asset: asset)
            
            let outputSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            
            let output = AVAssetReaderTrackOutput(track: subtitleTrack, outputSettings: nil)
            assetReader.add(output)
            assetReader.startReading()
            
            while let sampleBuffer = output.copyNextSampleBuffer() {
                let sampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
                print("assetReader", sampleTime.seconds, targetTime.seconds)
                
                if CMTimeCompare(sampleTime, targetTime) == 0 {
                    if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                        var bufferLength: size_t = 0
                        var bufferData: UnsafeMutablePointer<Int8>?
                        
                        if CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &bufferLength, totalLengthOut: nil, dataPointerOut: &bufferData) == kCMBlockBufferNoErr {
                            if let data = bufferData {
                                
                                // Process the subtitle data here (data contains the subtitle text)
                                if let subtitleString = String(bytesNoCopy: data, length: bufferLength, encoding: .isoLatin1, freeWhenDone: true) {
                                    print(subtitleString)
                                }
                                
                            }
                        }
                    }
                }
            }
            
            assetReader.cancelReading()
        } catch {
            print("Error extracting subtitles: \(error)")
        }
    }
    
    func extractSubtitleText() {
        guard let subtitleTrack = subtitleTrack else {
            print("Subtitle track not found in the video.")
            return
        }
        
        do {
            let assetReader = try AVAssetReader(asset: asset)
            
            let outputSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            
            let output = AVAssetReaderTrackOutput(track: subtitleTrack, outputSettings: nil)
            assetReader.add(output)
            assetReader.startReading()
            
            var subtitles: [String] = []
            
            while let sampleBuffer = output.copyNextSampleBuffer() {
                
                if let subtitleData = CMSampleBufferGetDataBuffer(sampleBuffer) {
                    let length = CMBlockBufferGetDataLength(subtitleData)
                    var subtitleText = ""
                    let dataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
                    
                    CMBlockBufferCopyDataBytes(subtitleData, atOffset: 0, dataLength: length, destination: dataPointer)
                    if let subtitleString = String(bytesNoCopy: dataPointer, length: length, encoding: .isoLatin1, freeWhenDone: true) {
                        subtitleText = subtitleString
                    }
                    subtitles.append(subtitleText)
                    
                    // Process the extracted subtitle text
                    print(subtitleText)
                }
            }
            print(subtitles.count)
            assetReader.cancelReading()
        } catch {
            print("Error extracting subtitles: \(error)")
        }
    }
}

//class VideoSubtitleExtractor {
//    
//    static func extractSubtitleText(at currentTime: CMTime, from videoURL: URL, completion: @escaping (String?) -> Void) {
//        // Create an AVAsset from the video URL
//        let asset = AVAsset(url: videoURL)
//        
//        // Create an AVAssetReader for reading the text track
//        guard let textTrack = asset.tracks(withMediaType: .subtitle).first else {
//            completion(nil)
//            return
//        }
//        
//        do {
//            let reader = try AVAssetReader(asset: asset)
//            let outputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)]
//            let output = AVAssetReaderTrackOutput(track: textTrack, outputSettings: nil)
//            reader.add(output)
//            // Start reading at the desired time
//            reader.timeRange = CMTimeRange(start: currentTime, duration: CMTime.positiveInfinity)
//            reader.startReading()
//            
//            var subtitleText = ""
//            
//            while let sample = output.copyNextSampleBuffer() {
//                if let subtitleData = CMSampleBufferGetDataBuffer(sample) {
//                    
//                    //                    if let subtitleData = CMSampleBufferGetDataBuffer(sampleBuffer) {
//                    let length = CMBlockBufferGetDataLength(subtitleData)
////                    var subtitleText = ""
//                    let dataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
//                    
//                    CMBlockBufferCopyDataBytes(subtitleData, atOffset: 0, dataLength: length, destination: dataPointer)
//                    if let subtitleString = String(bytesNoCopy: dataPointer, length: length, encoding: .isoLatin1, freeWhenDone: true) {
//                        subtitleText = subtitleString
//                    }
//                    completion(subtitleText.trimmingCharacters(in: .whitespacesAndNewlines))
//
//                }
//            }
//            
//        } catch {
//            print("Error extracting subtitle text: \(error)")
//            completion(nil)
//        }
//    }
//    
//    //    private static func processImageBuffer(_ imageBuffer: CVPixelBuffer) -> String? {
//    //        // Implement your logic to process the image buffer and extract subtitle text here
//    //        // This may involve OCR (Optical Character Recognition) or other techniques
//    //        
//    //        // For the sake of this example, we'll return a sample subtitle text
//    //        let length = CMBlockBufferGetDataLength(subtitleData)
//    //        var subtitleText = ""
//    //        let dataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
//    //        
//    //        CMBlockBufferCopyDataBytes(subtitleData, atOffset: 0, dataLength: length, destination: dataPointer)
//    //        if let subtitleString = String(bytesNoCopy: dataPointer, length: length, encoding: .isoLatin1, freeWhenDone: true) {
//    //            subtitleText = subtitleString
//    //        }
//    //        
//    //        // Process the extracted subtitle text
//    //        print(subtitleText)
//    //        let subtitleText = "Sample Subtitle"
//    //        return subtitleText
//    //    }
//}
//
