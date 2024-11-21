//
//  UserAccessManager.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 01.07.2024.
//

import Speech
import SwiftUI
import ComposableArchitecture

public struct UserAccessManager {
    public var askForSpeechRecognition: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
}

extension UserAccessManager: DependencyKey {
    
    public static var liveValue: UserAccessManager {
        @AppStorage("sf_speech_status") var storedStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
        
        if storedStatus != .authorized {
            return UserAccessManager(askForSpeechRecognition: {
                await withCheckedContinuation { send in
                    SFSpeechRecognizer.requestAuthorization { status in
                        @AppStorage("sf_speech_status") var storedStatus  = status
                        send.resume(returning: status)
                    }
                }
            })
        } else  {
            return UserAccessManager(askForSpeechRecognition: { .authorized })
        }
    }
    
    public static let testValue = UserAccessManager(askForSpeechRecognition: {
        return .restricted
    })
}

extension DependencyValues {
    public var userAccessManager: UserAccessManager {
        get { self[UserAccessManager.self] }
        set { self[UserAccessManager.self] = newValue }
    }
}
