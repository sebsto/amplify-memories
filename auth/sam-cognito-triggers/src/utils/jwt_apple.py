# inspired by https://gist.github.com/davidhariri/b053787aabc9a8a9cc0893244e1549fe
# and https://sarunw.com/posts/sign-in-with-apple-3/

from time import time
import json
import os

from jwcrypto import jwk, jwt, jws
import requests

APPLE_PUBLIC_KEY_URL = "https://appleid.apple.com/auth/keys"
APPLE_PUBLIC_KEYS = None
APPLE_KEY_CACHE_EXP = 60 * 60 * 24
APPLE_LAST_KEY_FETCH = 0


def _fetch_apple_public_key():
    # Check to see if the public key is unset or is stale before returning
    global APPLE_LAST_KEY_FETCH
    global APPLE_PUBLIC_KEYS

    NOW=int(time())
    if (APPLE_LAST_KEY_FETCH + APPLE_KEY_CACHE_EXP) <  NOW or APPLE_PUBLIC_KEYS is None:
        key_payload = requests.get(APPLE_PUBLIC_KEY_URL).json()

        APPLE_PUBLIC_KEYS = jwk.JWKSet.from_json(json.dumps(key_payload))
        
        APPLE_LAST_KEY_FETCH = NOW

    return APPLE_PUBLIC_KEYS


def decode_apple_user_token(apple_user_token, key=None):

    # key is passed just for testing, 
    # otherwise, use Apple Public keys 
    if key is None:
        keys = _fetch_apple_public_key()
    else:
        key_object = json.loads(key)
        keys = jwk.JWK(**key_object)
    
    token = None 
    try:
        token = jwt.JWT(jwt=apple_user_token, key=keys)

    except jws.InvalidJWSObject as e:
        print(e)
        raise Exception("Invalid JWT object")
    except jwt.JWTExpired as e:
        print(e)
        raise Exception("Token expired")
    except jwt.JWTNotYetValid as e:
        print(e)
        raise Exception("Token not yet valid")
    except jwt.JWTMissingClaim as e:
        print(e)
        raise Exception("Token has no claims")
    except jwt.JWTInvalidClaimFormat as e:
        print(e)
        raise Exception("Token has an invalid claim")
    except jwt.JWTMissingKeyID as e:
        print(e)
        raise Exception("Token is missing Key ID (kid)")
    except jwt.JWTMissingKey as e:
        print(e)
        raise Exception("Public Key Set has no matching Key ID (kid)")
    except Exception as e:
        print(e)
        print(type(e))
        raise Exception("Unknown error when reading Apple token")

    token_dict = json.loads(token.claims)

    if not token_dict['iss'] == 'https://appleid.apple.com':
        raise Exception(f"Not an Apple JWT token : {token_dict['iss']}")

    # other things to verify ?
    
    return token_dict

if __name__ == '__main__':
    print('Testing JWT Keys')  
    keys = _fetch_apple_public_key()
    print(keys)

    TOKEN='eyJraWQiOiI4NkQ4OEtmIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoiY29tLnN0b3JtYWNxLkJpa2VUcmFja2VyIiwiZXhwIjoxNTk3NDk2OTg3LCJpYXQiOjE1OTc0OTYzODcsInN1YiI6IjAwMTg3MC5lNmMyMDY2N2RmM2M0YjEyYWI5MjNlM2M5MDQzY2FhNC4xMzE2IiwiY19oYXNoIjoibUtiNi1PNmFEaGNMQy1KZTJsR0NjUSIsImVtYWlsIjoiYzRrcDJucThueEBwcml2YXRlcmVsYXkuYXBwbGVpZC5jb20iLCJlbWFpbF92ZXJpZmllZCI6InRydWUiLCJpc19wcml2YXRlX2VtYWlsIjoidHJ1ZSIsImF1dGhfdGltZSI6MTU5NzQ5NjM4Nywibm9uY2Vfc3VwcG9ydGVkIjp0cnVlfQ.Q9xJHW6drkJwz9BhIzTbn39PSgcGDEZkfGdNWe1Y_PAgGip-Up1laTfo89G34xFVIDCir9MZcd-FE-ojM1o9rmk1XtGQBV0XNsvexePP3AD15ScEleu8bNbnBvsWuWoQlHBc9F6RLJ2bUxpbZuVc01WjWk3YyT6FfsRDi6jWzo6_4mrykI-NY3RQXn0i2Yrtikgm163RcR8ZMTth_7ynBvRXpFydv1zWbAp6sRazEuS8iS7b09_5tuJ4leIVQXDcT1CNi1cq-XNjHj1_R7TQUoCXzHmVrwuml5R0lhmH6hkZa8eBvzTD-yZluIlr9DuTfr1jsQqeq7CGXPhGIWMSWA'
    token =  decode_apple_user_token(TOKEN)

    print(token)
  