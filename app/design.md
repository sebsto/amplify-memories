## Authentication 

https://aws.amazon.com/blogs/mobile/federating-users-using-sign-in-with-apple-and-aws-amplify-for-swift/

In Cognito User Pool App Client : remove `SRP_AUTH` flow 
In Cognito User Pool triggers : add Lambda function on pre-signup, define auth challenge, create auth challenge and verify auth challenge 
 
In amplifyconfiguration.json 
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH",
                        
Replace USER_SRP_AUTH with CUSTOM_AUTH

Same in awsconfiguration.json ??                   

## API 

|  owner  |  moment        |  description  | star  |  favourite |
|---------------------------------------------------------------|
|  sebsto | 20230228172314 | a decsription |  5    |  true      |
|  sebsto | 20230227112345 | a decsription |  2    |  false     |
|  sebsto | 20230226072307 | a decsription |  1    |  false     |



type MemoryData @model @auth(rules: [{ allow: owner, ownerField: "owner" }]) {
  owner: String! @primaryKey(sortKeyFields: ["moment"])
  moment: String!
  description: String
  image: String 
  star: Int
  favourite: Boolean
}

