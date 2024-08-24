//
//  File.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 01.07.2024.
//

import Foundation
import AVFoundation
import Dependencies

 class AudioSession {
    let instance = AVAudioSession.sharedInstance()
    
    func setForPlayback() throws {
        try instance.setCategory(.playback, mode: .default, options: [])
    }
    
    func setForRecognition() throws {
        try instance.setCategory(.record, mode: .measurement, options: .duckOthers)
        try instance.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    func setForRecording() throws {
        try instance.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try instance.setActive(true)
    }
    
    func stop() throws {
        try instance.setActive(false)
    }
}

extension AudioSession: DependencyKey {
    static let liveValue = AudioSession()
}

extension DependencyValues {
   var audioSession: AudioSession {
    get { self[AudioSession.self] }
    set { self[AudioSession.self] = newValue }
  }
}

