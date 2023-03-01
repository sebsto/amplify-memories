import os

import pytest
from pytest_mock import mocker
from jwcrypto import jwk, jwt

from src import app

# message received when client succeeded custom challenge


@pytest.fixture()
def cognito_verify_auth_challenge():
    """ Generates Cognito Verify Auth Challenge Event"""

    return {
    "version": "1",
    "region": "eu-central-1",
    "userPoolId": "eu-central-1_5J1OjXlBa",
    "userName": "username2",
    "callerContext": {
        "awsSdkVersion": "aws-sdk-unknown-unknown",
        "clientId": "1irha5mrk1jjp86ikl7bhkj7gf"
    },
    "triggerSource": "VerifyAuthChallengeResponse_Authentication",
    "request": {
        "userAttributes": {
            "sub": "bb09a339-38ee-4fad-891a-98969e0b6d4e",
            "email_verified": "true",
            "cognito:user_status": "CONFIRMED",
            "email": "username2@email.com"
        },
        "privateChallengeParameters": {},
        "challengeAnswer": "",
        "userNotFound": False
    },
    "response": {
        "answerCorrect": None
    }
}

NOT_APPLE_TOKEN='Facebook:::eyJraWQiOiI4NkQ4OEtmIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoiY29tLnN0b3JtYWNxLkJpa2VUcmFja2VyIiwiZXhwIjoxNTk3NDk0NDMwLCJpYXQiOjE1OTc0OTM4MzAsInN1YiI6IjAwMTg3MC5lNmMyMDY2N2RmM2M0YjEyYWI5MjNlM2M5MDQzY2FhNC4xMzE2IiwiY19oYXNoIjoiRDdLR1luQkhGTUVLN2xTTHdIODVyZyIsImVtYWlsIjoiYzRrcDJucThueEBwcml2YXRlcmVsYXkuYXBwbGVpZC5jb20iLCJlbWFpbF92ZXJpZmllZCI6InRydWUiLCJpc19wcml2YXRlX2VtYWlsIjoidHJ1ZSIsImF1dGhfdGltZSI6MTU5NzQ5MzgzMCwibm9uY2Vfc3VwcG9ydGVkIjp0cnVlfQ.AnZW7P8HgeUDcwHOwSAL8qRjj9zu1xixYjstGiEAvlTZPI3oOtBU1UMWUijkeKiBQdCVzGsYQ_VlZ5ZRbRgNSBui4ep2hNJ29s8xtv_3z8zX5sCVIgUMJyE7PIoISB6Ut4TEbbHzVtPH6ZwIcWb3mZu0gpWr2hRDPwyDfxbzyj-CTC09AUoRwS_9FVSJLBKqfI722EZUeow-pvNB8EUSw5YeJnarqWqVkHH31_fgRManBOGSu4DygovsGz5hacnIGkljb49IJzuun7GirhMMXsPZtxjkM4zcTcDIeVK61BU6Kg1NNp_MfoiGaizLQlxUUVJivVCK2H0xA7Z5p4sBNA'
TESTING_KEY = jwk.JWK(generate='oct', size=256)

@pytest.fixture()
def valid_token():
    """ Generates a valid token"""

    PREFIX='Apple'
    SEPARATOR=':::'

    token = jwt.JWT(header={"alg": "HS256"},
                    claims={'iss': 'https://appleid.apple.com',
                            'aud': 'com.stormacq.test',
                            'exp': 1597496987 + 99999999, # very far away in the future
                            'iat': 1597496387 + 99999999, # very far away in the future
                            'sub': '001870.e6c20667df3c4b12ab923e3c9043caa4.1316', 
                            'c_hash': 'mKb6-O6aDhcLC-Je2lGCcQ', 
                            'email': 'c4kp2nq8nx@privaterelay.appleid.com', 
                            'email_verified': 'true', 
                            'is_private_email': 'true', 
                            'auth_time': 1597496387, 
                            'nonce_supported': True})
    token.make_signed_token(TESTING_KEY)               
    return PREFIX + SEPARATOR + token.serialize()

@pytest.fixture()
def expired_token():
    """ Generates an expired token"""

    PREFIX='Apple'
    SEPARATOR=':::'

    token = jwt.JWT(header={"alg": "HS256"},
                    claims={'iss': 'https://appleid.apple.com',
                            'aud': 'com.stormacq.test',
                            'exp': 1677661638 - 99999999, # very far away in the past
                            'iat': 1677661638,
                            'sub': '001870.e6c20667df3c4b12ab923e3c9043caa4.1316', 
                            'c_hash': 'd4iwtZAm6-IAipjWkdFh4w', 
                            'email': 'c4kp2nq8nx@privaterelay.appleid.com', 
                            'email_verified': 'true', 
                            'is_private_email': 'true', 
                            'auth_time': 1597496387, 
                            'nonce_supported': True})
    token.make_signed_token(TESTING_KEY)          
    print(token.serialize())     
    return PREFIX + SEPARATOR + token.serialize()


def test_verify_auth_challenge_expired(cognito_verify_auth_challenge, expired_token, mocker):

    mocker.patch.dict(
        os.environ, {'COGNITO_CLIENT_ID': '1irha5mrk1jjp86ikl7bhkj7gf'})

    cognito_verify_auth_challenge['request']['challengeAnswer'] = expired_token       
    cognito_verify_auth_challenge['request']['testing_key'] =  TESTING_KEY.export()
    
    with pytest.raises(Exception) as e:
        _ = app.lambda_handler(cognito_verify_auth_challenge, "")

    assert 'Token expired' in str(e.value)

def test_verify_auth_challenge_not_apple(cognito_verify_auth_challenge, mocker):

    mocker.patch.dict(
        os.environ, {'COGNITO_CLIENT_ID': '1irha5mrk1jjp86ikl7bhkj7gf'})

    cognito_verify_auth_challenge['request']['challengeAnswer'] = NOT_APPLE_TOKEN    
    ret = app.lambda_handler(cognito_verify_auth_challenge, "")

    assert 'response' in ret

    assert 'answerCorrect' in ret['response']
    assert ret['response']['answerCorrect'] == False    

def test_verify_auth_challenge(cognito_verify_auth_challenge, valid_token, mocker):

    mocker.patch.dict(
        os.environ, {'COGNITO_CLIENT_ID': '1irha5mrk1jjp86ikl7bhkj7gf'})

    cognito_verify_auth_challenge['request']['challengeAnswer'] = valid_token      
    cognito_verify_auth_challenge['request']['testing_key'] =  TESTING_KEY.export()
    ret = app.lambda_handler(cognito_verify_auth_challenge, "")

    assert 'response' in ret

    assert 'answerCorrect' in ret['response']
    assert ret['response']['answerCorrect'] == True    