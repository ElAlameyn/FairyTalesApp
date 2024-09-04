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
import Overture


@MainActor
final class RecognitionViewModel: ObservableObject {
    @Published var playbackMode = LottiePlaybackMode.paused(at: .progress(0))
    @Published var text: AttributedString = ""
    @Published var status = Status.stopRecognition
    
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
    
    init(chapter: Chapter) {
        self.text = AttributedString(chapter.text)
        self.matches = chapter.matches
    }
    
    @Dependency(\.speechRecognizerClient) var speechRecognizer
    
    private var matches = ["plant", "was"]
    
    private func makeTextColored(recognizedWord: Substring) {
        if let range = self.text.range(of: recognizedWord, options: .caseInsensitive) {
            self.text[range].foregroundColor = .green
        }
    }
    
    private func matchToAnimation(recognizedWord: Substring) {
        if self.matches.contains(where: { match in
            match.caseInsensitiveCompare(recognizedWord) == .orderedSame
        }) {
            playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
        }
    }
    
    
    func bind() async {
        do {
            for try await word in await speechRecognizer.recognizedSpeech() {
                makeTextColored(recognizedWord: word)
                matchToAnimation(recognizedWord: word)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func startRecording() async {
        await speechRecognizer.startRecognition()
        status = .startRecognition
    }
    
    func stopRecording() async  {
        await speechRecognizer.stopRecognition()
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
                        Task {
                            await recognitonViewModel.stopRecording()
                        }
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
        .task {
            await recognitonViewModel.bind()
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(RecognitionViewModel(chapter: .helloWorld))
}


// MARK: - For future time

//
//var recordingButton: some View {
//    Button(recordTitle) {
//        buttonDisabled = true
//        recordTitle = recordTitle == "Start recording" ? "Stop recording" : "Start recording"
//        Task {
//            if await recorder.isRecording {
//                await recorder.stopRecording()
//            } else {
//                await recorder.startRecording()
//            }
//            buttonDisabled = false
//        }
//    }
//    .animation(.easeIn)
//    .disabled(buttonDisabled)
//}
//
//var playRecorded: some View {
//    Button("Play recorded video") {
//        try! audioSession.setForPlayback()
//        player.replaceCurrentItem(with: .init(url: Directory.foo))
//        player.play()
//    }
//}
