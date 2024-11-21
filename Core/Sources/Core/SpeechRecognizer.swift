//
//  SpeechRecognizer.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 25.05.2024.
//

import AVFoundation
import ComposableArchitecture
import SharedModels
import Speech

public struct SpeechRecognizerClient {
    public var recognizedSpeech: @Sendable () async -> AsyncThrowingStream<[Substring], Error>
    public var startRecognition: @Sendable () async -> Void
    public var stopRecognition: @Sendable () async -> Void
}

public extension DependencyValues {
    var speechRecognizerClient: SpeechRecognizerClient {
        get { self[SpeechRecognizerClient.self] }
        set { self[SpeechRecognizerClient.self] = newValue }
    }
}

extension SpeechRecognizerClient: DependencyKey {
    public static var liveValue: SpeechRecognizerClient {
        let speechRecognizer = SpeechRecognizer()
        return Self {
            await speechRecognizer.recognizedWordsStream
        } startRecognition: {
            await speechRecognizer.startRecognition()
        } stopRecognition: {
            await speechRecognizer.stopRecognition()
        }
    }
    
    public static var testValue: SpeechRecognizerClient {
        return Self {
            AsyncThrowingStream { continuation in
                continuation.yield(["hello"])
                continuation.yield(["world"])
                continuation.finish()
            }
        } startRecognition: {} stopRecognition: {}
    }
    
    private actor SpeechRecognizer {
        private let audioEngine = AVAudioEngine()
        private var inputNode: AVAudioInputNode?
        private var speechRecognizer: SFSpeechRecognizer?
        private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        private var recognitionTask: SFSpeechRecognitionTask?
        private var audioSession: AVAudioSession?
        
        @Dependency(\.userAccessManager) var userAccessManager
        @Dependency(\.audioSession) var audioSessionShared
        
        var recognizedWordsStream: AsyncThrowingStream<[Substring], Error> {
            textStream
                .stream
                .flatMap { array in
                    let transformed = array.map { $0.getWords() }
                    return Array(transformed).publisher.values
                }
                .eraseToThrowingStream()
        }
        
        private var textStream = AsyncThrowingStream<[String], Error>.makeStream()

        var isRecognizing = false
        
        func startRecognition() async {
            textStream = AsyncThrowingStream<[String], Error>.makeStream()
            let textContinuation = textStream.continuation
            
            guard await userAccessManager.askForSpeechRecognition() == .authorized else { return }
            
            do {
                try audioSessionShared.setForRecognition()
            } catch {
                print("Couldn't configure the audio session properly")
            }
            
            inputNode = audioEngine.inputNode
            speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "ru-RU"))
//            speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "en-US"))
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest?.shouldReportPartialResults = true
            
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
            
            inputNode.removeTap(onBus: 0)
            sleep(1)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
                recognitionRequest.append(buffer)
            }
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                
                guard let self else { return }
                
                if let result {
                    textContinuation.yield(result.transcriptions.map(\.formattedString))
                } else if let error {
                    textContinuation.yield(with: .failure(error))
                    Task { await self.stopRecognition() }
                } else if result?.isFinal == true {
                    Task { await self.stopRecognition() }
                }
            }
            
            audioEngine.prepare()
            
            do {
                try audioEngine.start()
                isRecognizing = true
            } catch {
                print("Coudn't start audio engine!")
                recognitionRequest.endAudio()
                stopRecognition()
            }
        }
        
        func stopRecognition() {
            recognitionTask?.finish()
            recognitionRequest?.endAudio()
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
}
