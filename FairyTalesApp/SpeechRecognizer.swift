//
//  SpeechRecognizer.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 25.05.2024.
//

import Foundation
import AVFoundation
import Speech
import Overture
import Dependencies


class SpeechRecognizer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession: AVAudioSession?
    
    
    @Dependency(\.userAccessManager) var userAccessManager
    @Dependency(\.audioSession) var audioSessionShared
    
    
    var recognizedWordsStream: AsyncThrowingStream<Substring, Error> {
        textStream
            .stream
            .flatMap {
                Array($0.split(separator: " ")).publisher.values
            }
            .eraseToThrowingStream()
    }
    
    private let textStream = AsyncThrowingStream<String, Error>.makeStream()
    private var textContinuation: AsyncThrowingStream<String, Error>.Continuation { textStream.continuation }

    @Published var isRecognizing = false
    
    func startRecognition() async {
        
        guard await userAccessManager.askForSpeechRecognition() == .authorized else { return }
        
        do {
            try audioSessionShared.setForRecognition()
        } catch {
            print("Couldn't configure the audio session properly")
        }
        
        inputNode = audioEngine.inputNode
        speechRecognizer = SFSpeechRecognizer()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let speechRecognizer,
              let recognitionRequest,
              let inputNode,
              speechRecognizer.isAvailable
        else {
            assertionFailure("Unable to start the speech recognition!")
            return
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        print("Recording format: \(recordingFormat)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            recognitionRequest.append(buffer)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) {  [weak self] result, error in
            
            guard let self else { return }
            
            if let result {
                textContinuation.yield(result.bestTranscription.formattedString)
            } else if let error {
                textContinuation.yield(with: .failure(error))
                stopRecognition()
            } else if result?.isFinal == true {
                stopRecognition()
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecognizing = true
        } catch {
            print("Coudn't start audio engine!")
            stopRecognition()
        }
    }
    
    func stopRecognition()  {
        recognitionTask?.cancel()
        
        audioEngine.stop()
        
        inputNode?.removeTap(onBus: 0)
        try? audioSession?.setActive(false)
        audioSession = nil
        inputNode = nil
        
        isRecognizing = false
        
        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
    }
    
}
