//
//  UserAccessManager.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 01.07.2024.
//

import Foundation
import Dependencies
import Speech

struct UserAccessManager {
    var askForSpeechRecognition: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
}

extension UserAccessManager: DependencyKey {
    static let liveValue = UserAccessManager(askForSpeechRecognition: {
        await withCheckedContinuation { send in
            SFSpeechRecognizer.requestAuthorization { status in
                send.resume(returning: status)
            }
        }
    })
    
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
