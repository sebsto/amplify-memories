import os
import pytest
from pytest_mock import mocker

from src import app

# message received when client succeeded custom challenge


@pytest.fixture()
def cognito_create_auth_challenge():
    """ Generates Cognito Create Auth Challenge Event"""

    return {
  "version": "1",
  "region":  "eu-central-1",
  "userPoolId": "eu-central-1_5J1OjXlBa",
  "userName": "username",
  "callerContext": {
    "awsSdkVersion": "aws-sdk-unknown-unknown",
    "clientId": "1irha5mrk1jjp86ikl7bhkj7gf"
  },
  "triggerSource": "CreateAuthChallenge_Authentication",
  "request": {
    "userAttributes": {
      "sub": "95d7645e-fab5-42ba-99e5-dfc4338f7916",
      "email_verified": "true",
      "cognito:user_status": "FORCE_CHANGE_PASSWORD",
      "email": "username@email.com"
    },
    "challengeName": "CUSTOM_CHALLENGE",
    "session": [],
    "userNotFound": False
  },
  "response": {
    "publicChallengeParameters": None,
    "privateChallengeParameters": None,
    "challengeMetadata": None
  }
}

def test_create_auth_challenge(cognito_create_auth_challenge, mocker):

    mocker.patch.dict(
        os.environ, {'COGNITO_CLIENT_ID': '1irha5mrk1jjp86ikl7bhkj7gf'})
    ret = app.lambda_handler(cognito_create_auth_challenge, "")

    assert 'response' in ret

    assert 'publicChallengeParameters' in ret['response']
    assert 'challenge' in ret['response']['publicChallengeParameters']
    assert 'providers' in ret['response']['publicChallengeParameters']
    assert ret['response']['publicChallengeParameters']['providers'] == 'Apple'
    assert ret['response']['privateChallengeParameters'] == {}
    assert ret['response']['challengeMetadata'] == "IDP_TOKEN"