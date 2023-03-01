import os
import pytest
from pytest_mock import mocker

from src import app

# message received when client succeeded custom challenge


@pytest.fixture()
def cognito_define_auth_succeeded():
    """ Generates Cognito DefineAuth Event"""

    return {
        "version": "1",
        "region": "eu-central-1",
        "userPoolId": "eu-central-1_5J1OjXlBa",
        "userName": "appleUserID",
        "callerContext": {
            "awsSdkVersion": "aws-sdk-unknown-unknown",
            "clientId": "1irha5mrk1jjp86ikl7bhkj7gf"
        },
        "triggerSource": "DefineAuthChallenge_Authentication",
        "request": {
            "userAttributes": {},
            "session": [{
                "challengeName": "SRP_A",
                "challengeResult": True,
                "challengeMetadata": "None"
            }, {
                "challengeName": "CUSTOM_CHALLENGE",
                "challengeResult": True,
                "challengeMetadata": "IDP_TOKEN"
            }],
            "userNotFound": False
        },
        "response": {
            "challengeName": "None",
            "issueTokens": "None",
            "failAuthentication": "None"
        }
    }

# message received when initiate auth from amplify


@pytest.fixture()
def cognito_define_auth_srpa():
    """ Generates Cognito DefineAuth Event"""

    return {
        "version": "1",
        "region": "eu-central-1",
        "userPoolId": "eu-central-1_5J1OjXlBa",
        "userName": "appleUserID",
        "callerContext": {
            "awsSdkVersion": "aws-sdk-unknown-unknown",
            "clientId": "1irha5mrk1jjp86ikl7bhkj7gf"
        },
        "triggerSource": "DefineAuthChallenge_Authentication",
        "request": {
            "userAttributes": {},
            "session": [{
                "challengeName": "SRP_A",
                "challengeResult": True,
                "challengeMetadata": "None"
            }],
            "userNotFound": False
        },
        "response": {
            "challengeName": "None",
            "issueTokens": "None",
            "failAuthentication": "None"
        }
    }

# message received when initiate auth from CLI


@pytest.fixture()
def cognito_define_auth_cli():
    """ Generates Cognito DefineAuth Event"""

    return {
        "version": "1",
        "region": "eu-central-1",
        "userPoolId": "eu-central-1_5J1OjXlBa",
        "userName": "appleUserID",
        "callerContext": {
            "awsSdkVersion": "aws-sdk-unknown-unknown",
            "clientId": "1irha5mrk1jjp86ikl7bhkj7gf"
        },
        "triggerSource": "DefineAuthChallenge_Authentication",
        "request": {
            "userAttributes": {},
            "session": [],
            "userNotFound": False
        },
        "response": {
            "challengeName": "None",
            "issueTokens": "None",
            "failAuthentication": "None"
        }
    }

# message received when initiate auth from amplify


@pytest.fixture()
def cognito_define_auth_srpa_no_user():
    """ Generates Cognito DefineAuth Event"""

    return {
        "version": "1",
        "region": "eu-central-1",
        "userPoolId": "eu-central-1_5J1OjXlBa",
        "userName": "appleUserID",
        "callerContext": {
            "awsSdkVersion": "aws-sdk-unknown-unknown",
            "clientId": "1irha5mrk1jjp86ikl7bhkj7gf"
        },
        "triggerSource": "DefineAuthChallenge_Authentication",
        "request": {
            "userAttributes": {},
            "session": [{
                "challengeName": "SRP_A",
                "challengeResult": True,
                "challengeMetadata": "None"
            }],
            "userNotFound": True
        },
        "response": {
            "challengeName": "None",
            "issueTokens": "None",
            "failAuthentication": "None"
        }
    }


def test_define_auth_srpa(cognito_define_auth_srpa, mocker):

    mocker.patch.dict(
        os.environ, {'COGNITO_CLIENT_ID': '1irha5mrk1jjp86ikl7bhkj7gf'})
    ret = app.lambda_handler(cognito_define_auth_srpa, "")

    assert 'response' in ret
    assert 'challengeName' in ret['response']
    assert 'issueTokens' in ret['response']
    assert 'failAuthentication' in ret['response']
    assert ret['response']['issueTokens'] == False
    assert ret['response']['failAuthentication'] == False
    assert ret ['response']['challengeName'] == 'CUSTOM_CHALLENGE'

def test_define_auth_cli(cognito_define_auth_cli, mocker):

    mocker.patch.dict(
        os.environ, {'COGNITO_CLIENT_ID': '1irha5mrk1jjp86ikl7bhkj7gf'})
    ret = app.lambda_handler(cognito_define_auth_cli, "")

    assert 'response' in ret
    assert 'challengeName' in ret['response']
    assert 'issueTokens' in ret['response']
    assert 'failAuthentication' in ret['response']
    assert ret['response']['issueTokens'] == False
    assert ret['response']['failAuthentication'] == False
    assert ret ['response']['challengeName'] == 'CUSTOM_CHALLENGE'

def test_define_auth_custom_challenge_succeeded(cognito_define_auth_succeeded, mocker):

    mocker.patch.dict(
        os.environ, {'COGNITO_CLIENT_ID': '1irha5mrk1jjp86ikl7bhkj7gf'})
    ret = app.lambda_handler(cognito_define_auth_succeeded, "")

    assert 'response' in ret
    assert 'challengeName' in ret['response']
    assert 'issueTokens' in ret['response']
    assert 'failAuthentication' in ret['response']
    assert ret['response']['challengeName'] == 'CUSTOM_CHALLENGE'
    assert ret['response']['issueTokens'] == True
    assert ret['response']['failAuthentication'] == False


def test_define_auth_no_user(cognito_define_auth_srpa_no_user, mocker):

    mocker.patch.dict(
        os.environ, {'COGNITO_CLIENT_ID': '1irha5mrk1jjp86ikl7bhkj7gf'})
    with pytest.raises(Exception) as e:
        _ = app.lambda_handler(cognito_define_auth_srpa_no_user, "")
    assert '[USER_NOT_FOUND]' in str(e.value)