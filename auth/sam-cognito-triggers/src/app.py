import os 
from utils import jwt_apple

def define_auth_challenge(event):
    print('Define Auth Challenge')

    session_length = len(event['request']['session'])

    # last step, custom challenge received a correct answer
    if session_length > 0 \
        and event['request']['session'][-1]['challengeName'] == 'CUSTOM_CHALLENGE' \
        and event['request']['session'][-1]['challengeResult']:

        # The user provided the right answer; succeed auth
        event['response']['challengeName'] = 'CUSTOM_CHALLENGE'
        event['response']['issueTokens'] = True
        event['response']['failAuthentication'] = False


    # when using Amplify, first step is SRP_A, we bypass it and switch to custom challenge
    elif session_length == 1 \
        and event['request']['session'][-1]['challengeName'] == 'SRP_A':

        event['response']['issueTokens'] = False
        event['response']['failAuthentication'] = False
        event['response']['challengeName'] = 'CUSTOM_CHALLENGE'

    # when using AWS CLI, session is empty
    elif session_length == 0:

        event['response']['issueTokens'] = False
        event['response']['failAuthentication'] = False
        event['response']['challengeName'] = 'CUSTOM_CHALLENGE'

    else:

        # fail authentication in all other cases
        event['response']['issueTokens'] = False
        event['response']['failAuthentication'] = True

    return event

def create_auth_challenge(event):
    print('Create Auth Challenge')

    event['response']['publicChallengeParameters'] = {
        'challenge' : 'present a valid JWT token issued by a recognized provider',
        'providers' : 'Apple'
    }
    event['response']['privateChallengeParameters'] = {}
    event['response']['challengeMetadata'] = "IDP_TOKEN"

    return event

def verify_auth_challenge_response(event):
    print('Verify Auth Challenge Response')

    # verify JWT Token received
    # https://sarunw.com/posts/sign-in-with-apple-3/
    idp_token = event['request']['challengeAnswer']
    print(f'IDTOKEN to verify : {idp_token[0:10]}')

    # I expect to receive a token in the form
    # PROVIDER_NAME:::TOKEN
    TOKEN_SEPARATOR=':::'
    if idp_token.find(TOKEN_SEPARATOR) == -1:
        print(f'There is no token separator in the string received. ' + \
              'Token must be in the form <provider name>:::<base 64 encoded token>')
        event['response']['answerCorrect'] = False
    else:
        (provider, _ , token) = idp_token.partition(TOKEN_SEPARATOR)

        # we only accept apple tokens
        if (provider.lower() != 'apple'):
            print(f'Invalid token provider : {provider}')
            event['response']['answerCorrect'] = False
        else:

            claim = None 
            # For testing only 
            if 'testing_key' in event['request']:
                key = event['request']['testing_key']
                claim = jwt_apple.decode_apple_user_token(token,key)
            else:
                claim = jwt_apple.decode_apple_user_token(token)

            print(claim)
            event['response']['answerCorrect'] = True


    return event

def pre_signup(event):
    print('PreSignUp')

    event['response']['autoConfirmUser'] = True
    event['response']['autoVerifyEmail'] = True

    return event

# https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-pre-authentication.html
def lambda_handler(event, _):
    print('RECEIVED')
    print(event)

    COGNITO_CLIENT_ID = os.environ['COGNITO_CLIENT_ID']
    client_id = event['callerContext']['clientId']
    if client_id not in (COGNITO_CLIENT_ID, 'CLIENT_ID_NOT_APPLICABLE'):
        raise Exception(f'Cannot authenticate users from this user pool app client: {client_id}')

    # when user does not exist, reject the request
    if 'userNotFound' in event['request'] and event['request']['userNotFound']:
        # the [USER_NOT_FOUND] tag is important to let client know the error,
        # I could not find a way to capture a specific exception in the client
        raise Exception(f"User {event['userName']} does not exist in pool {event['userPoolId']}, " +
                        f"please signup first. [USER_NOT_FOUND]")

    result = event
    if event['triggerSource'] == 'DefineAuthChallenge_Authentication':
        result = define_auth_challenge(event)

    elif event['triggerSource'] == 'CreateAuthChallenge_Authentication':
        result = create_auth_challenge(event)

    elif event['triggerSource'] == 'VerifyAuthChallengeResponse_Authentication':
        result = verify_auth_challenge_response(event)

    elif event['triggerSource'] == 'PreSignUp_SignUp':
        result = pre_signup(event)

    else:
        print(f"WARNING - Cognito Event {event['triggerSource']} not handled")
        # force an error on Cognito 
        del result['response']
        
    print('RESPONSE')
    print(result)

    return result

def main(): 
    print("Hello World")

if __name__ == "__main__":
    main()