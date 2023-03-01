import os
import pytest
from pytest_mock import mocker

from src import app

@pytest.fixture()
def cognito_signup_event():
    """ Generates Cognito SignUp Event"""

    return {
        "version": "1",
        "region": "eu-central-1",
        "userPoolId": "eu-central-1_5J1OjXlBa",
        "userName": "iusername",
        "callerContext": {
            "awsSdkVersion": "aws-sdk-unknown-unknown",
            "clientId": "CLIENT_ID_NOT_APPLICABLE"
        },
        "triggerSource": "PreSignUp_SignUp",
        "request": {
            "userAttributes": {
                "email_verified": "true",
                "email": "username@email.com"
            },
            "validationData": "None"
        },
        "response": {
            "autoConfirmUser": "False",
            "autoVerifyEmail": "False",
            "autoVerifyPhone": "False"
        }
    }

def test_signup(cognito_signup_event, mocker):

    mocker.patch.dict(os.environ, {'COGNITO_CLIENT_ID':'CLIENT_ID_NOT_APPLICABLE'})
    ret = app.lambda_handler(cognito_signup_event, "")

    assert 'response' in ret
    assert 'autoConfirmUser' in ret['response']
    assert ret['response']['autoConfirmUser'] == True
    assert 'autoVerifyEmail' in ret['response']
    assert ret['response']['autoVerifyEmail'] == True
