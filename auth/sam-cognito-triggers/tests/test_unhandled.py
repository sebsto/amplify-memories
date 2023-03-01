import os
import pytest
from pytest_mock import mocker

from src import app

@pytest.fixture()
def cognito_unhandled_event():
    """ Generates Cognito SignUp Event"""

    return {
        "version": "1",
        "region": "eu-central-1",
        "userPoolId": "eu-central-1_5J1OjXlBa",
        "userName": "username",
        "callerContext": {
            "awsSdkVersion": "aws-sdk-unknown-unknown",
            "clientId": "CLIENT_ID_NOT_APPLICABLE"
        },
        "triggerSource": "UNHANDLED",
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

def test_unhandled(cognito_unhandled_event, mocker):

    mocker.patch.dict(os.environ, {'COGNITO_CLIENT_ID':'CLIENT_ID_NOT_APPLICABLE'})
    ret = app.lambda_handler(cognito_unhandled_event, "")

    assert not 'response' in ret