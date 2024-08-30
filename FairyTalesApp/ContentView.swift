//
//  ContentView.swift
//  FairyTalesApp
//
//  Created by Artiom Kalinkin on 21.05.2024.
//

import SwiftUI
import AVFoundation
import Dependencies
import Lottie

import Combine

@MainActor
final class RecognitionViewModel: ObservableObject {
    @Published var playbackMode = LottiePlaybackMode.paused(at: .progress(0))
    @Published var text: AttributedString = "The plant was grown"
    @Published var status = Status.stopRecognition
    
    private var cancallables = Set<AnyCancellable>()
    
    enum Status {
        case startRecognition
        case stopRecognition
        
        var description: String {
            switch self {
            case .startRecognition:
                return "Stop recognition"
            case .stopRecognition:
                return "Start recognition"
            }
        }
    }
    
    init(_text: AttributedString) {
        self.text = _text
    }
    
    var speechRecognizer = SpeechRecognizer()
    
    private var recognizedText: AnyPublisher<String, Never> {
        speechRecognizer.$text
            .print("Recognized text")
//            .share()
            .eraseToAnyPublisher()
    }
    
    private var matches = ["plant", "was"]
    
    init() {
        recognizedText
            .receive(on: DispatchQueue.main)
            .flatMap { Array($0.split(separator: " ")).publisher }
            .sink {  [weak self] recognizedWord in
                print("Word: \(recognizedWord)")
                guard let self else { return }
                if let range = self.text.range(of: recognizedWord, options: .caseInsensitive) {
                    self.text[range].foregroundColor = .green
                }
            }
            .store(in: &cancallables)
        
        recognizedText
            .flatMap { Array($0.split(separator: " ")).publisher }
            .contains(where: { recognizedWord in
                if self.matches.contains(where: { match in
                    match.caseInsensitiveCompare(recognizedWord) == .orderedSame
                }) {
                    return true
                }
                return false

            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMatch in
                guard let self else { return }
                if isMatch {
                    playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                }
            }
            .store(in: &cancallables)
    }
    
    func startRecording() async {
        await speechRecognizer.startRecognition()
        status = .startRecognition
    }
    
    func stopRecording()  {
        speechRecognizer.stopRecognition()
        status = .stopRecognition
        playbackMode = .paused(at: .progress(0))
    }
}

struct ContentView: View {
    @EnvironmentObject var recognitonViewModel: RecognitionViewModel
    @ObservedObject var recorder = AudioRecoder()
    @State var recordTitle = "Start recording"
    @State var buttonDisabled = false
    @State var isPressed = false
    let player = AVPlayer(url: Directory.foo)
    @Dependency(\.audioSession) var audioSession
    
    var recordingButton: some View {
        Button(recordTitle) {
            buttonDisabled = true
            recordTitle = recordTitle == "Start recording" ? "Stop recording" : "Start recording"
            Task {
                if await recorder.isRecording {
                    await recorder.stopRecording()
                } else {
                    await recorder.startRecording()
                }
                buttonDisabled = false
            }
        }
        .animation(.easeIn)
        .disabled(buttonDisabled)
    }
    
    var playRecorded: some View {
        Button("Play recorded video") {
            try! audioSession.setForPlayback()
            player.replaceCurrentItem(with: .init(url: Directory.foo))
            player.play()
        }
    }
    
    var body: some View {
        VStack {
            
            LottieView(animation: .named("plant_animation"))
                .playbackMode(recognitonViewModel.playbackMode)
            
            Text(recognitonViewModel.text)
            
            Spacer()
                .frame(height: 30)
            
            Circle()
                .frame(width: 40, height: 40)
                .scaleEffect(isPressed ? 1.5 : 1)
                .transition(.scale)
                .foregroundStyle(.red)
                .onTapGesture {
                    withAnimation {
                        isPressed.toggle()
                    }
                    if recognitonViewModel.status == .stopRecognition {
                        Task {
                            await recognitonViewModel.startRecording()
                        }
                    } else {
                        recognitonViewModel.stopRecording()
                    }
                }
                .overlay {
                    if isPressed {
                        Circle()
                            .foregroundStyle(.white)
                            .transition(.scale)
                            .frame(width: 25, height: 25)
                    }
                }

            
            Spacer()
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(RecognitionViewModel(_text: "Hello my boy"))
}
