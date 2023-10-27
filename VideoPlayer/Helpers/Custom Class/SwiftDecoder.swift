//
//  SwiftDecoder.swift
//  VideoPlayer
//
//  Created by Tecocraft on 27/10/23.
//

import Foundation
import Libavformat

class SubtitleDecoder {
    private var formatContext: UnsafeMutablePointer<AVFormatContext>?
    private var codecContext: UnsafeMutablePointer<AVCodecContext>?
    
    init(videoPath: String) {
        // Initialize FFmpeg (usually done once)
        //        av_register_all()
        avformat_network_init()
        
        // Open the video file
        if avformat_open_input(&formatContext, videoPath, nil, nil) < 0 {
            // Handle the error
            print("Failed to open video file")
        } else if avformat_find_stream_info(formatContext, nil) < 0 {
            // Handle the error
            print("Failed to find stream information")
        }
        
        // Find and open the subtitle codec context
        let subtitleStreamIndex = findSubtitleStream()
        if subtitleStreamIndex >= 0 {
            let codecParameters = formatContext!.pointee.streams[subtitleStreamIndex]?.pointee.codecpar
            codecContext = avcodec_alloc_context3(nil)
            if avcodec_parameters_to_context(codecContext, codecParameters) < 0 {
                print("Failed to convert codec parameters to context")
            }
            if avcodec_open2(codecContext, avcodec_find_decoder(codecContext!.pointee.codec_id), nil) < 0 {
                print("Failed to open subtitle codec")
            }
        }
    }
    
    deinit {
        // Clean up FFmpeg and release resources when the instance is deallocated
        if codecContext != nil {
            avcodec_close(codecContext)
        }
        avformat_close_input(&formatContext)
        avformat_network_deinit()
    }
    
    func decodeSubtitles() {
        guard let codecContext = codecContext else {
            print("No subtitle codec context available")
            return
        }
        
        // Create AVPacket and AVSubtitle
        var packet = AVPacket()
        var subtitle = AVSubtitle()
        
        while av_read_frame(formatContext, &packet) == 0 {
            if packet.stream_index == codecContext.pointee.codec_type.rawValue {
                var gotSubtitles: Int32 = 0
                avcodec_decode_subtitle2(codecContext, &subtitle, &gotSubtitles, &packet)
                
                if gotSubtitles != 0 {
                    for i in 0..<Int(subtitle.num_rects) {
                        let subtitleRect = subtitle.rects[i]
                        if let assText = subtitleRect?.pointee.ass {
                            let subtitleText = String(cString: assText)
                            print(subtitleText)
                        }
                    }
                }
            }
            av_packet_unref(&packet)
        }
    }
    
    private func findSubtitleStream() -> Int {
        for i in 0..<Int(formatContext!.pointee.nb_streams) {
            if formatContext!.pointee.streams[i]?.pointee.codecpar.pointee.codec_type == AVMEDIA_TYPE_SUBTITLE {
                return i
            }
        }
        return -1
    }
}
