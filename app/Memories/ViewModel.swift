//
//  ViewModel.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 01/03/2023.
//

import Foundation
import AuthenticationServices
import Logging

//
// a set of functions to support the View and isolate it from the backend
//

extension ContentView {
    @MainActor
    final class ViewModel: ObservableObject {
        
        private var logger = Logger(label: "\(PACKAGE_NAME).ViewModel")
        private var backend = Backend.shared
        public init() {
#if DEBUG
            self.logger.logLevel = .debug
#endif
        }
    }
}

// MARK: Signin with Apple functions
extension ContentView.ViewModel {
    
    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential
            else {
                logger.error("Apple authorization returned empty credentials")
                return
            }
            
            let user = UserData(credentials: credential)
            logger.debug("\(user)")
            
//            self.backend.federateToIdentityPools(with: identityToken)
            Task {
                try! await self.backend.signIn(user)
                
            }
            
        case .failure(let error):
            print("Failure")
            print(error)
        }
    }
}

struct UserData {

    private var logger = Logger(label: "\(PACKAGE_NAME).UserData")

    let userId: String
    let familyName: String
    let givenName: String
    let email: String
    let token: String?
    init(credentials: ASAuthorizationAppleIDCredential) {
        self.userId = credentials.user
        self.familyName = credentials.fullName?.familyName ?? "noFamilyName"
        self.givenName = credentials.fullName?.givenName ?? "noGivenName"
        self.email = credentials.email ?? "noemail@email.com"
        if let token = credentials.identityToken {
            self.token = String(decoding: token, as: UTF8.self)
        } else {
            logger.error("Apple token is nil")
            self.token = nil
        }
    }
    public func debugDescription() -> String {
        return """
        User ID:     \(self.userId)
        Family name: \(self.familyName)
        Given name:  \(self.givenName)
        Email:       \(self.email)
        Token:       \(self.token?.prefix(6) ?? "nil")
"""
    }
}

