## Authentication 

AFTER `amplify push`

- In Cognito User Pool App Client : remove `SRP_AUTH` flow 
- In Cognito User Pool triggers : add Lambda functions on pre-signup, define auth challenge, create auth challenge and verify auth challenge 
- in amplifyconfiguration.json 
```
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH",
```                        
Replace USER_SRP_AUTH with CUSTOM_AUTH
- In Cognito User Pool console, copy the app client ID and report it to template.yaml
- in auth dir : sam build && sam deploy (exact commands in the Makefile)
 

## API 

|  owner  |  moment        |  description  | star  |  favourite |
|---------------------------------------------------------------|
|  sebsto | 20230228172314 | a decsription |  5    |  true      |
|  sebsto | 20230227112345 | a decsription |  2    |  false     |
|  sebsto | 20230226072307 | a decsription |  1    |  false     |


```graphql
type MemoryData 
     @model
     @auth(rules: [{ allow: owner, ownerField: "owner" }]) {
     
  owner: String! @primaryKey(sortKeyFields: ["moment"])
  moment: String!
  description: String
  image: String!
  star: Int!
  favourite: Boolean!
  coordinates: CoordinateData

}

type CoordinateData {
    longitude: Float!
    latitude: Float!
}
```

