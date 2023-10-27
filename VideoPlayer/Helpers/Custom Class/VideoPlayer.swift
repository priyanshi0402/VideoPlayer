//
//  VideoPlayer.swift
//  VideoPlayer
//
//  Created by Tecocraft on 23/10/23.
//

import Foundation
import UIKit
import AVFoundation

class VideoPlayer: UIView {
    
    private let videoPlayerLayer: AVPlayerLayer = AVPlayerLayer()
    private var player = AVPlayer()
    private var timeObserver: AnyObject?
    
    public var status: PlayerStatus = .new
    public var playingVideo: ((_ progress: Double) -> Void)?
    public var startedVideo: (() -> Void)?
    public var stoppedVideo: (() -> Void)?
    public var pausedVideo: (() -> Void)?
    
    fileprivate(set) var progress: Double = 0.0
    @objc internal var isInteracting: Bool = false
    
    open var videoLength: Double {
        if let duration = player.currentItem?.asset.duration {
            return duration.seconds
        }
        return 0.0
    }
    
    open var currentTime: Double {
        if let time = player.currentItem?.currentTime() {
            return time.seconds
        }

        return 0.0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.videoPlayerLayer.frame = self.bounds
        layer.addSublayer(self.videoPlayerLayer)
        videoPlayerLayer.player = player
        videoPlayerLayer.contentsScale = UIScreen.main.scale
        player.appliesMediaSelectionCriteriaAutomatically = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func setupVideoPlayer(url: URL) {
        let asset = AVAsset(url: url)
        setVideoAsset(asset: asset)
    }
    
    private func setVideoAsset(asset: AVAsset) {
        videoPlayerLayer.videoGravity = .resizeAspect
        
        self.switchTrack(index: 0, isFirstTime: true)
    }
    
    fileprivate func deinitObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        if let video = player.currentItem, video.observationInfo != nil {
            video.removeObserver(self, forKeyPath: "status")
        }
        
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    @objc fileprivate func applicationDidEnterBackground() {
        self.pauseVideo()
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let asset = object as? AVPlayerItem, let keyPath = keyPath else { return }
    
        if keyPath == #keyPath(AVPlayerItem.currentMediaSelection) {
            // Update the displayed subtitle
            updateSubtitle()
        }

        if asset == player.currentItem && keyPath == "status" {
            if asset.status == .readyToPlay {
                if status == .new {
                    status = .readyToPlay
                }
//                if let group = AVAsset(url: Bundle.main.url(forResource: "test_video", withExtension: "mp4")!).mediaSelectionGroup(forMediaCharacteristic: .legible), let subtitleTrack = group.options.last {
//                    self.player.currentItem?.select(subtitleTrack, in: group)
//                }
                addTimeObserver()
                playVideo()
            }
        }
    }
    
    func updateSubtitle() {
//            let subtitleGroup = playerItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
//            let selectedSubtitle = playerItem?.selectedMediaOption(in: subtitleGroup!)
//            
//            // Check if there is a selected subtitle track
//            if let subtitle = selectedSubtitle {
//                // Get the subtitle text and display it
//                subtitleLabel?.text = subtitle.displayName
//            } else {
//                // No subtitle selected, clear the label
//                subtitleLabel?.text = ""
//            }
        }
        
    
    fileprivate func addTimeObserver() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil, using: { [weak self] (time) in
            guard let strongSelf = self/*, strongSelf.status == .playing */else { return }
            
            let currentTime = time.seconds
            strongSelf.progress = currentTime / (strongSelf.videoLength != 0.0 ? strongSelf.videoLength : 1.0)
            strongSelf.playingVideo?(strongSelf.progress)
            //            strongSelf.playingVideo?(strongSelf.progress)
            //            strongSelf.delegate?.playingVideo?(progress: strongSelf.progress)
        }) as AnyObject?
    }
    
    @objc internal func itemDidFinishPlaying(_ notification: Notification) {
        stopVideo()
    }
}

// MARK: - Videoplayer actions
extension VideoPlayer {
    
    func toggleSubtitle() {
        guard let playerItem = self.player.currentItem else { return }
        if let group = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            let locale = Locale(identifier: "en-EN")
            let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
            if let option = options.first {
                self.player.currentItem?.select(option, in: group)
            }
        }
    }
    
    func switchTrack(index: Int, isFirstTime: Bool = false) {
        deinitObservers()
        guard let url = Bundle.main.url(forResource: "test_video", withExtension: "mp4") else { return }
        let asset = AVAsset(url: url)
        let composition = AVMutableComposition()
        
        let currentTime = self.player.currentTime()
        
//        let subtitleTrack = asset.tracks(withMediaType: .subtitle).first!
//        let compositionTrack1 = composition.addMutableTrack(withMediaType: .subtitle, preferredTrackID: kCMPersistentTrackID_Invalid)
//        do {
//            try compositionTrack1?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: subtitleTrack, at: .zero)
//        } catch {
//            print(error.localizedDescription)
//        }
        
        let videoTrack = asset.tracks(withMediaType: .video)[index]
        let subTrack = asset.tracks(withMediaType: .subtitle)[index]
        
        let subtitleTrack = composition.addMutableTrack(withMediaType: .text, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try compositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            try subtitleTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration),
                                                       of: subTrack, at: .zero)
        } catch {
            print(error.localizedDescription)
        }
        
        
        
        
        
//        if let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible)?.options.last {
//            let subtitleTrack = asset.tracks(withMediaType: .subtitle).first
//
//            if let subtitleTrackComposition = composition.addMutableTrack(withMediaType: .subtitle, preferredTrackID: kCMPersistentTrackID_Invalid) {
//                if let segments = subtitleTrack?.segments {
//                    for segment in segments {
//                        do {
//                            try subtitleTrackComposition.insertTimeRange(segment.timeMapping.target, of: subtitleTrack!, at: segment.timeMapping.source.start)
//                        } catch {
//                            print(error.localizedDescription)
//                        }
//                        
//                    }
//                }
//            }

//             Extract the subtitle text
//            let formatDescriptions = asset.tracks(withMediaType: .text).first?.formatDescriptions as! [CMFormatDescription]
//
//            for formatDescription in formatDescriptions {
//                let locale = CMFormatDescriptionGetExtension(formatDescription, extensionKey: kCMFormatDescriptionExtension_Language as CFString) as? String
//                let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
//                
//                if mediaSubType == kCMMediaSubType_Subtitle {
//                    if let locale = locale {
//                        let metadataGroup = asset.metadata(forFormat: formatDescription as! AVMetadataFormat)
//                        let items = AVMetadataItem.metadataItems(from: metadataGroup, filteredAndSortedAccordingToPreferredLanguages: [.commonKeyTitle])
//                        
//                        for item in items {
//                            if let value = item.stringValue, !value.isEmpty {
//                                print("Locale: \(locale), Subtitle: \(value)")
//                            }
//                        }
//                    }
//                }
//            }
        
//        let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
//        let subtitles = subtitleGroup?.options
        
        // Find the desired subtitle track (e.g., by language or name)
//        let selectedSubtitle = subtitles?.first(where: { $0.displayName == "Unknown language" }) // Change "English" to the desired language or name
//        
//        // Select the desired subtitle track
//        if let selectedSubtitle = selectedSubtitle {
//            playerItem.select(selectedSubtitle, in: subtitleGroup!)
//        }
        // Replace the current player item with the new player item
        let playerItem = AVPlayerItem(asset: composition)
       
        player.replaceCurrentItem(with: playerItem)
        if !isFirstTime {
            player.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }


        player.play()
//        self.player.isClosedCaptionDisplayEnabled = true
//        self.extractSubtitles(from: asset)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)

    }
    
    func extractSubtitles(from asset: AVAsset) {
        // Create an AVAssetReader
//        do {
//            
//            let reader = try AVAssetReader(asset: asset)
//            
//            if let subtitleTrack = asset.tracks(withMediaType: AVMediaType.subtitle).first {
//                let outputSettings: [String: Any] = [
//                    kCMMetadataFormatDescriptionMetadataSpecificationKey as String: [
//                        kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String: AVMetadataIdentifier.iTunesMetadata
//                    ]
//                ]
//                
//                let trackOutput = AVAssetReaderTrackOutput(track: subtitleTrack, outputSettings: outputSettings)
//                reader.add(trackOutput)
//                reader.startReading()
//                
//                while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
//                    if let metadata = CMSampleBufferGetBufferText(sampleBuffer) {
//                        // Process and display the subtitle text
//                        let subtitleText = String(data: metadata, encoding: .utf8)
//                        print(subtitleText ?? "")
//                    }
//                }
//            }
//        } catch {
//            print("Error reading subtitles: \(error.localizedDescription)")
//        }
    }

    
    public func seek(min: Double = 0.0, max: Double = 1.0, value: Double) {
        let value = rangeMap(value, min: min, max: max, newMin: 0.0, newMax: 1.0)
        self.seek(value)
    }
    
    private func seek(_ percentage: Double) {
        progress = min(1.0, max(0.0, percentage))
        guard let currentItem = player.currentItem else { return }

        if progress == 0.0 {
            seekToZero()
            playingVideo?(progress)
//            delegate?.playingVideo?(progress: progress)
        } else {
            let time = CMTime(seconds: progress * currentItem.asset.duration.seconds, preferredTimescale: currentItem.asset.duration.timescale)
            player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (finished) in
//                guard let strongSelf = self else { return }
//                if finished == false {
////                    strongSelf.seekStarted?()
////                    strongSelf.delegate?.seekStarted?()
//                } else {
//                    strongSelf.stoppedVideo?()
////                    strongSelf.seekEnded?()
////                    strongSelf.playingVideo?(strongSelf.progress)
////                    strongSelf.delegate?.seekEnded?()
////                    strongSelf.delegate?.playingVideo?(progress: strongSelf.progress)
//                }
            })
        }
    }
    
    
    fileprivate func seekToZero() {
        progress = 0.0
        let time = CMTime(seconds: 0.0, preferredTimescale: 1)
        player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    @objc open func playVideo() {
        guard let playerItem = player.currentItem else { return }

        if progress >= 1.0 {
            seekToZero()
        }
        status = .playing
        self.player.play()
        startedVideo?()

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)) , name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    public func stopVideo() {
        player.rate = 0.0
        seekToZero()
        status = .stopped
        stoppedVideo?()
    }
    
    public func pauseVideo() {
        player.rate = 0.0
        status = .paused
        pausedVideo?()
    }
    
    public func toggleVideoPlay() {
        if self.status == .playing {
            pauseVideo()
        } else {
            playVideo()
        }
    }
    
    public func forwardVideo() {
        let moveForword : Float64 = 5.0
        let newTime = self.currentTime + moveForword
        if newTime < self.videoLength {
            let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
            player.seek(to: selectedTime)
        } else {
            let selectedTime: CMTime = CMTimeMake(value: Int64(self.videoLength * 1000 as Float64), timescale: 1000)
            player.seek(to: selectedTime)
        }
        player.pause()
        player.play()
    }
    
    public func backwardVideo() {
        let moveBackword: Float64 = 5.0
  
        var newTime = self.currentTime - moveBackword
        if newTime < 0 {
            newTime = 0
        }
        player.pause()
        let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        player.seek(to: selectedTime)
        player.play()
    }
}
