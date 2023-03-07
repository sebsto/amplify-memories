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
        
        enum AppState {
            case signedOut
            case loading
            case dataAvailable([Memory])
            case error(Error)
        }
        
        // Global application state
        @Published var state : AppState = .signedOut
        
        // main data structure
        var memories : [Memory] = []
        
        // services
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
                return //should be a fataError() ?
            }
            
            let user = UserData(credentials: credential)
            logger.debug("\(user.debugDescription())")
            
            Task {
                try! await self.backend.signIn(user)
            }
            
        case .failure(let error):
            logger.error("Failed to sign in with Apple: \(error)")
        }
    }
}

// MARK: Backend authentication-related functions
extension ContentView.ViewModel {
    public func getInitialAuthStatus() async throws {
        
        // when running swift UI preview - do not change isSignedIn flag
        if !PreviewEnvironment.isPreview {
            
            let status = try await Backend.shared.getInitialAuthStatus()
            logger.debug("Initial Auth status is \(status)")
            switch status {
            case .signedIn: self.state = .loading
            case .signedOut, .sessionExpired:  self.state = .signedOut
            }
        }
    }
    
    public func listenAuthUpdate() async {
            for try await status in await Backend.shared.listenAuthUpdate() {
                logger.debug("Auth status loop yielded \(status)")
                switch status {
                case .signedIn:
                    self.state = .loading
                case .signedOut, .sessionExpired:
                    self.memories = []
                    self.state = .signedOut
                }
            }
            logger.error("==== Exited auth status loop =====")
    }
    
    // asynchronously sign out
    // change of status will be picked up by `listenAuthUpdate()`
    // that will trigger the UI update
    public func signOut() {
        Task {
            await Backend.shared.signOut()
        }
    }
    
    // there is no signIn method as Signin With Apple's handler triggers Backend.signIn() 

}

// MARK: Model CRUD functions
extension ContentView.ViewModel {
    
    func todaysMemories() async  {
        do {
            let result = try await self.backend.todayMemories()
            self.state = .dataAvailable(result)
        } catch {
            logger.error("Can not fetch the memories : \(error)")
        }
    }
    
    func createMemory() async {
        do {
            try await self.backend.createMemory()
        } catch {
            logger.error("Can not create memory : \(error)")
        }
    }
    
    func updateMemory(_ memory : Memory, favourite: Bool, star: Int) -> Memory {
        
        var updatedMemory = memory
        if memory.validStarRange ~= star {
            updatedMemory.star(count: star)
        } else {
            updatedMemory.star(count: 0)
        }
        updatedMemory.favourite = favourite
        
        return updatedMemory
    }
}

struct PreviewEnvironment {
    static var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
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

