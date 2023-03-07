//
//  Backend.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 01/03/2023.
//

import Foundation
import Logging

import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import ClientRuntime // to control verbosity of AWS SDK


struct Backend {
    
    private var logger = Logger(label: "\(PACKAGE_NAME).Backend")
    
    // singleton class to ensure Amplify is initialized only once
    static let shared = Backend()
    private init() {
#if DEBUG
        self.logger.logLevel = .debug
#endif
        configureAmplify()
    }
    
    func configureAmplify() {
        
//        Amplify.Logging.logLevel = .info
        // reduce verbosity of AWS SDK
        SDKLoggingSystem.initialize(logLevel: .warning)

        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.configure()
            logger.debug("Successfully configured Amplify")
        } catch {
            logger.error("Failed to initialize Amplify: \(error)")
        }
    }
}

// MARK: Amplify Authentication-related functions
extension Backend {
    
    enum AuthStatus {
        case signedIn
        case signedOut
        case sessionExpired
    }
    
    // let's check if user is signedIn or not
    public func getInitialAuthStatus() async throws -> AuthStatus {
        let session = try await Amplify.Auth.fetchAuthSession()
        return session.isSignedIn ? AuthStatus.signedIn : AuthStatus.signedOut
    }
    
    // produce an async stream of updates of AuthStatus
    public func listenAuthUpdate() async -> AsyncStream<AuthStatus> {
        
        return AsyncStream { continuation in
            
            continuation.onTermination = { @Sendable status in
                logger.error("[BACKEND] streaming auth status terminated with status : \(status)")
            }
            
            // listen to auth events.
            // see https://github.com/aws-amplify/amplify-ios/blob/master/Amplify/Categories/Auth/Models/AuthEventName.swift
            let _  = Amplify.Hub.listen(to: .auth) { payload in
                
                switch payload.eventName {
                    
                case HubPayload.EventName.Auth.signedIn:
                    logger.debug("==HUB== User signed In, update UI")
                    continuation.yield(AuthStatus.signedIn)
                case HubPayload.EventName.Auth.signedOut:
                    logger.debug("==HUB== User signed Out, update UI")
                    continuation.yield(AuthStatus.signedOut)
                case HubPayload.EventName.Auth.sessionExpired:
                    logger.debug("==HUB== Session expired, show sign in aui")
                    continuation.yield(AuthStatus.sessionExpired)
                default:
                    //logger.debug("==HUB== \(payload)")
                    break
                }
            }
        }
    }
    
    /*
     * Triggers a Cognito CUSTOM_AUTH FLOW.
     * The password is not used. Cognito asks for a custom challenge.
     * The client app presents the IDP Token (Sign In With Apple) as challenge
     * The token is verified on the server side and authentication is succesful when token is valid
     *
     * The very first time, the user id does not exist on Cognito, an error is returned
     * and the signUp() method is called to dynamically create the user, with all its attributes
     */
    public func signIn(_ user: UserData) async throws {
        
        guard let token = user.token else {
            logger.error("There is no Apple token, abording the Cognito signin procedure")
            return
        }
        
        // start the sign in sequence
        logger.debug("Launching sign in procedure")
        do {
            let result = try await Amplify.Auth.signIn(username: user.userId, password: "dummy password")
            
            if !result.isSignedIn {
                
                switch result.nextStep {
                    
                case .confirmSignInWithCustomChallenge(_):
                    logger.debug("Signin procedure: the next step is to present the token")
                    let result = try await Amplify.Auth.confirmSignIn(challengeResponse: "Apple:::\(token)")
                    if result.isSignedIn {
                        logger.debug("Signin procedure: user signed in successfully")
                    } else {
                        logger.error("Signin procedure: failed to signin")
                    }
                    
                default:
                    logger.error("Signin procedure: unexpected next step")
                }
                
            } else {
                fatalError("Signin procedure: user can not signin without presenting a token")
            }

        } catch let error as AuthError {
            //TODO: how to make this more robust ?
            if error.debugDescription.contains("User does not exist") {
                
                // create the user on the backend
                try await self.signUp(user)
                
                // try signin again
                try await self.signIn(user)
            }
        } catch {
            fatalError("Unexpected error : \(error)")
        }
        
    }
    
    // signout
    public func signOut() async {
        let _ =  await Amplify.Auth.signOut()
        logger.debug("Successfully signed out")
    }
    
    public func signUp(_ user: UserData) async throws {
        
        logger.debug("Starting signup sequence")
        let userAttributes = [AuthUserAttribute(.email, value: user.email),
                              AuthUserAttribute(.givenName, value: user.givenName),
                              AuthUserAttribute(.familyName, value: user.familyName)]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        let _ = try await Amplify.Auth.signUp(username: user.userId, password:randomString(length: 64), options: options)
        logger.debug("Successfully signed up")
        
    }
    
    fileprivate func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-§&@.:/%£$*€#éèçàù"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

// MARK: Data CRUD functions
extension Backend {
    
    func todayMemories() async throws -> [Memory] {
        return Memory.mock
    }
    
    func createMemory() async throws {
        
        let user = try await Amplify.Auth.getCurrentUser()
        
        let coordinate = Memory.mockCoordinates()
        let coordinateData = CoordinateData(longitude: coordinate.longitude, latitude: coordinate.latitude)
        let memory = MemoryData(owner: user.userId,
                                moment: "20220228204500",
                                description: "description",
                                image: "",
                                star:5,
                                favourite: true,
                                coordinates: coordinateData)
        
        let result = try await Amplify.API.mutate(request: .create(memory))
        switch result {
        case .success(let memory):
            logger.debug("Successfully created the memory: \(memory)")
        case .failure(let graphQLError):
            logger.error("Failed to create the memory \(graphQLError)")
            throw graphQLError
        }
    }
}


