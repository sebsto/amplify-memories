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


@MainActor
final class ViewModel: ObservableObject {
    
    enum AppState {
        case signedOut
        case loading
        case dataAvailable
        case error(Error)
    }
    
    // Global application state
    @Published var state: AppState = .signedOut
    @Published var tabSelected: Int = 0
    
    // main data structure
    var memories : [Memory]
    
    // services
    private var logger = Logger(label: "\(PACKAGE_NAME).ViewModel")
    private var backend = Backend.shared
    public init(memories : [Memory] = []) {
#if DEBUG
        self.logger.logLevel = .debug
#endif
        self.memories = memories
    }
}


// MARK: Signin with Apple functions
extension ViewModel {
    
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
extension ViewModel {
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
extension ViewModel {
    
    func todaysMemories() async  {
        logger.debug("Loading today's memories")
        do {
            let result = try await self.backend.todayMemories()
            self.memories = result.sorted{ $0.moment > $1.moment }
            self.state = .dataAvailable
        } catch {
            logger.error("Can not fetch the memories : \(error)")
        }
    }
    
    func createMemory(description: String, image: UIImage, coordinates: Coordinates?) async {
        
        do {
            // save the image on a background thread
            let imageName = UUID().uuidString
            if let data = image.resize(to: 0.10).pngData() {
                Task {
                    await self.backend.storeImage(name: imageName,
                                                  image: data)
                }
            }

            // save the memory on a background thread
            let user = try await self.backend.currentUser()
            let memory = Memory(owner: user.userId,
                            moment: Date.now,
                            description: description,
                            image: imageName,
                            coordinate: coordinates)
            self.memories.append(memory)
            self.tabSelected = 0 // 0 to switch to today's view
            self.state = .dataAvailable

            Task {
                try await self.backend.createMemory(memory)
            }
            
        } catch {
            logger.error("Can not create memory : \(error)")
        }
        
    }
    
    func imageURL(for memory: Memory) async -> URL? {
        var result : URL?
        
        // mocked data have image name like "landscape1.png"
        // real data have image name like "400E3677-3670-46EF-95E6-586918C1439A"
        let split = memory.image.split(separator: ".")
        if split.count == 2 && split[1] == "png" {
            logger.debug("Mocked data, going to return URL for \(split)")
            result = Bundle.main.url(forResource: String(split[0]), withExtension: String(split[1]))
        } else {
            logger.debug("Real data, computing URL")
            result = await self.backend.imageURL(name: memory.image)
        }
        return result
    }
    
    func updateMemory(_ memory : Memory, favourite: Bool, star: Int) -> Memory {
        
        var updatedMemory = memory
        if memory.validStarRange ~= star {
            updatedMemory.star(count: star)
        } else {
            updatedMemory.star(count: 0)
        }
        updatedMemory.favourite = favourite
        
        //async save to the database
        Task {
            try await self.backend.updateMemory(updatedMemory)
        }
        
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

extension UIImage {
    
    func resize(to percentage: Float) -> UIImage {
        let newSize = CGSize(width: size.width * CGFloat(percentage),
                             height: size.height * CGFloat(percentage))
        return resize(to: newSize)
    }

    func resize(to newSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            let hScale = newSize.height / size.height
            let vScale = newSize.width / size.width
            let scale = max(hScale, vScale) // scaleToFill
            let resizeSize = CGSize(width: size.width*scale, height: size.height*scale)
            var middle = CGPoint.zero
            if resizeSize.width > newSize.width {
                middle.x -= (resizeSize.width-newSize.width)/2.0
            }
            if resizeSize.height > newSize.height {
                middle.y -= (resizeSize.height-newSize.height)/2.0
            }
            
            draw(in: CGRect(origin: middle, size: resizeSize))
        }
    }
}

