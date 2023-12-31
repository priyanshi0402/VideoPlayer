//
//  ViewController.swift
//  VideoPlayer
//
//  Created by Tecocraft on 19/10/23.
//

import UIKit
import AVKit
import Foundation
import AVFoundation

public enum PlayerStatus {
    case new /// A new video has been assigned.
    case readyToPlay /// The video is ready to be played.
    case playing /// The video is currently being played.
    case paused /// The video has been paused.
    case stopped /// The video playback has been stopped.
    case error /// An error occured. For more details use the `error` closure.
}

class ViewController: UIViewController {
    
    @IBOutlet weak var btnSubtitle: UIButton!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var videoContainerView: VideoPlayer!
    @IBOutlet weak var safeAreaBottomView: UIView!
    @IBOutlet weak var dropDownMenu: DropDown!
    @IBOutlet weak var progressSlider: Scrubber!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var bottomControlView: UIView!
    
    private var controlsToggleWorkItem: DispatchWorkItem?
    let videoUrl = Bundle.main.url(forResource: "test_video", withExtension: "mp4")

    var subtitleExtractor: SubtitleExtractor {
        guard let url = self.videoUrl else { return SubtitleExtractor(videoURL: URL(string: "")!) }
        return SubtitleExtractor(videoURL: url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        perform(#selector(self.hideControls), with: nil, afterDelay: 5.0)
        self.setUpDropDownMenu()
        
        self.bottomControlView.backgroundColor = .white.withAlphaComponent(0.75)
        self.progressSlider.tintColor = .blue
        self.progressSlider.trackColor = UIColor.white.cgColor
        
        progressSlider.addTarget(self, action: #selector(ViewController.progressSliderChanged(slider:)), for: [.touchUpInside])
        progressSlider.addTarget(self, action: #selector(ViewController.progressSliderBeginTouch), for: [.touchDown])
        self.setUpVideoView()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleControls))
        tapGestureRecognizer.delegate = self
        self.videoContainerView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    private func setUpVideoView() {
        
        guard let url = self.videoUrl else { return }
        videoContainerView.setupVideoPlayer(url: url)
        lblStartTime.text = self.timeFormatted(totalSeconds: 0)
        lblEndTime.text = self.timeFormatted(totalSeconds: UInt(self.videoContainerView.videoLength))
        self.videoContainerView.playingVideo = { [weak self, weak videoContainerView] progress in
            guard let strongSelf = self, let strongVideoPlayerView = videoContainerView else { return }
            //            print("videoContainerView.playingVideo ====>", progress)
            strongSelf.progressSlider.value = progress
            let currentTime = strongVideoPlayerView.currentTime
            strongSelf.lblStartTime.text = strongSelf.timeFormatted(totalSeconds: UInt(currentTime))
        }
        
//                let subtitleDecoder = SubtitleExtractor(videoPath: url.path)
//        //        subtitleDecoder.subDelegate = self
//        //        // Decode and process subtitles
//                subtitleDecoder.decodeSubtitles()
        
        self.videoContainerView.stoppedVideo = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.btnPlayPause.setImage(.icPlayVideo, for: .normal)
        }
        self.videoContainerView.pausedVideo = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.btnPlayPause.setImage(.icPlayVideo, for: .normal)
        }
        
    }
    
    private func setUpDropDownMenu() {
        self.dropDownMenu.optionArray = ["Front", "Rear"]
        self.dropDownMenu.isSearchEnable = false
        
        self.dropDownMenu.arrowSize = 15
        self.dropDownMenu.selectedRowColor = .clear
        self.dropDownMenu.cornerRadiusDrop = 20
        self.dropDownMenu.rowHeight = 40
        self.dropDownMenu.text = "Front"
        self.dropDownMenu.font = .systemFont(ofSize: 16)
        
        self.dropDownMenu.didSelect { selectedText, index, id in
            if self.dropDownMenu.text ?? "" == selectedText {
                return
            }
            self.videoContainerView.switchTrack(index: index)
        }
    }
    
    
    // MARK: - Button Actions
    
    @IBAction func btnToggleSubtitleAction(_ sender: Any) {
        self.videoContainerView.toggleSubtitle()
    }
    
    @IBAction func expandCollapsViewAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        UIView.animate(withDuration: 0.3) {
            self.topViewHeight.constant = sender.isSelected ? 0 : 70
            self.dropDownMenu.isHidden = sender.isSelected
            self.view.layoutIfNeeded() // Animate the constraint change
        }
        
    }
    
    @IBAction func btnBackwardVideoAction(_ sender: Any) {
        self.videoContainerView.backwardVideo()
    }
    
    @IBAction func btnPreviousVideoAction(_ sender: Any) {
        
    }
    
    @IBAction func btnForwardVideoAction(_ sender: Any) {
        self.videoContainerView.forwardVideo()
    }
    
    @IBAction func btnNextVideoAction(_ sender: Any) {
    }
    
    @IBAction func btnPlayPauseToggleAction(_ sender: UIButton) {
        self.videoContainerView.toggleVideoPlay()
        let image: UIImage = self.videoContainerView.status == .playing ? .icPauseVideo : .icPlayVideo
        sender.setImage(image, for: .normal)
    }
    
    // MARK: - Selector Methods
    
    @objc internal func progressSliderChanged(slider: Scrubber) {
        print("progressSliderChanged", slider.value)
        self.videoContainerView.seek(value: Double(slider.value))
        self.videoContainerView.playVideo()
        
        let currentTime = self.videoContainerView.currentTime
        let time = CMTime(seconds: currentTime, preferredTimescale: 1000)
        
//        subtitleExtractor.extractSubtitles(at: time)
    }
    
    @objc internal func progressSliderBeginTouch() {
        self.videoContainerView.pauseVideo()
    }
    
    @objc internal func hideControls() {
        //        delegate?.willHideControls?()
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomControlView.alpha = 0.0
            self.safeAreaBottomView.alpha = 0.0
        }, completion: { finished in
            //            self.delegate?.didHideControls?()
        })
    }
    
    @objc internal func toggleControls() {
        if bottomControlView.alpha == 1.0 {
            hideControls()
        } else {
            controlsToggleWorkItem?.cancel()
            controlsToggleWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.hideControls()
            })
            
            showControls()
            
            if self.videoContainerView.status == .playing {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: controlsToggleWorkItem!)
            }
        }
    }
    
    internal func showControls() {
        //        delegate?.willShowControls?()
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomControlView.alpha = 1.0
            self.safeAreaBottomView.alpha = 1.0
        }, completion: { finished in
            //            self.delegate?.didShowControls?()
        })
    }
    
    private func timeFormatted(totalSeconds: UInt) -> String {
        //        print("timeFormatted ====>", totalSeconds)
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
}

extension ViewController: UIGestureRecognizerDelegate {
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        if let view = touch.view, view.isDescendant(of: self.view) == true, view != self.videoContainerView,
//            view != videoPlayerControls || touch.location(in: videoPlayerControls).y > videoPlayerControls.bounds.size.height - 50 {
//            return false
//        } else {
//            return true
//        }
//    }
}

