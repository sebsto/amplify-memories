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

// MARK: Amplify Identity related functions
extension Backend {
    
    /*
     * Triggers a Cognito CUSTOM_AUTH FLOW.
     * The password is not used. Cognito asks for a custom challenge.
     * The client app presents the IDP Token (Sign In With Apple) as challenge
     * The token is verified on the server side and authentication is succesful when token is valid
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
                    // I do not inspect additionInfo because I wrote the Lambda and I know what it returns
                    // ["providers": "Apple", "challenge": "present a valid JWT token issued by a recognized provider", "USERNAME": "001870....1316"]
                    let result = try await Amplify.Auth.confirmSignIn(challengeResponse: "Apple:::\(token)")
                    if result.isSignedIn {
                        logger.debug("Signin procedure: user signed in succesfully")
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
                try! await self.signUp(user)
                
                // try signin again
                try! await self.signIn(user)
            }
        }
        
    }
    
    // signout globally
    public func signOut() async {
        // https://docs.amplify.aws/lib/auth/signOut/q/platform/ios
        let options = AuthSignOutRequest.Options(globalSignOut: true)
        let _ = await Amplify.Auth.signOut(options: options)
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
    
    func createMemory() async {
        let memory = MemoryData(owner: "sebsto", moment: "20220228204500", description: "description", star:5, favourite: true)
        do {
            let result = try await Amplify.API.mutate(request: .create(memory))
            switch result {
            case .success(let memory):
                print("Successfully created the memory: \(memory)")
            case .failure(let graphQLError):
                print("Failed to create graphql \(graphQLError)")
            }
        } catch let error as APIError {
            print("Failed to create a memory: ", error)
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}


