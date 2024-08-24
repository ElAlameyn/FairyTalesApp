//
//  AudioRecorder.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 25.05.2024.
//

import Foundation
import AVFoundation
import Dependencies

actor AudioRecoder: ObservableObject {
    @Published var recordedText: String = ""
    
    var recorder: AVAudioRecorder?
    
    var delegate: Delegate?

    @Dependency(\.audioSession) var audioSession
    
    var isRecording: Bool {
        if let recorder, recorder.isRecording {
            return true
        }
        return false
    }
    
    func startRecording() {
        do {
            recorder = try AVAudioRecorder(url: Directory.foo, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ])
            
            recorder?.delegate = delegate
            
            try audioSession.setForRecording()
            
            recorder?.record()
        } catch {
            print("Audio error: \(error)")
        }
    }
    
    func stopRecording()  {
        recorder?.stop()
        try? audioSession.stop()
    }
}


final class Delegate: NSObject, AVAudioRecorderDelegate {
  let didFinishRecording: (Bool) -> Void
  let encodeErrorDidOccur: (Error?) -> Void

  init(
    didFinishRecording: @escaping (Bool) -> Void,
    encodeErrorDidOccur: @escaping (Error?) -> Void
  ) {
    self.didFinishRecording = didFinishRecording
    self.encodeErrorDidOccur = encodeErrorDidOccur
  }

@MainActor func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    self.didFinishRecording(flag)
  }

  @MainActor func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    self.encodeErrorDidOccur(error)
  }
}

