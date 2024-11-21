//
//  File.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 01.07.2024.
//

import ComposableArchitecture
import AVFoundation

 public class AudioSession {
    let instance = AVAudioSession.sharedInstance()
    
    public func setForPlayback() throws {
        try instance.setCategory(.playback, mode: .default, options: [])
    }
    
    public func setForRecognition() throws {
        try instance.setCategory(.record, mode: .measurement, options: .duckOthers)
        try instance.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    public func setForRecording() throws {
        try instance.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try instance.setActive(true)
    }
    
    public func stop() throws {
        try instance.setActive(false)
    }
}

extension AudioSession: DependencyKey {
    public static let liveValue = AudioSession()
}

public extension DependencyValues {
   var audioSession: AudioSession {
    get { self[AudioSession.self] }
    set { self[AudioSession.self] = newValue }
  }
}

