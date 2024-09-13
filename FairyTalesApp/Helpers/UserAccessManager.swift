//
//  UserAccessManager.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 01.07.2024.
//

import Foundation
import Dependencies
import Speech
import SwiftUI

struct UserAccessManager {
    var askForSpeechRecognition: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
}

extension UserAccessManager: DependencyKey {
    
    static var liveValue: UserAccessManager { 
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
    
    static let testValue = UserAccessManager(askForSpeechRecognition: {
        return .restricted
    })
}

extension DependencyValues {
    var userAccessManager: UserAccessManager {
        get { self[UserAccessManager.self] }
        set { self[UserAccessManager.self] = newValue }
    }
}
