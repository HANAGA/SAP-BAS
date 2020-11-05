 
  -- Token based CDS Service

--currentlt in the Folder /user/projects/
$ cds init cap1
$ cd cap1

							
--File: cap1/db/MyDictionary.cds						
namespace fly;

entity Airlines {
	key carrid 	 : String(3);
	    carrname : String(20);
	    currcode : String(5);
}


entity Flights {
    key carrid 	 : String(3);   
	key connid 	 : String(4);
		cityfrom : String(20);
		cityto   : String(20);
		distance : Decimal(15,2);
}


--File: cap1/db/data/
	fly-Airlines.csv
	fly-Flights.csv

							
--File: cap1/srv/MyService.cds					
using {fly} from '../db/MyDictionary';

@requires : 'authenticated-user'

service InternationalFlights {

    entity Airlines as select from fly.Airlines;
    entity Flights  as select from fly.Flights;

}


--File cap1/.cdsrc.json
{
    "requires":{
        "auth": {
			"passport":{
				"strategy":"mock",
				"users":{
					"scott":{
						"password":"tiger",
						"roles":["authenticated-user", "admin", "builder"]
					}
				}
			}
		}
    }
}


--Install the node module passport:
$ npm install passport



				
--File: cap1/RESTClient.http
### CDS Service Paths
GET http://localhost:4004


### CDS Service Entities
GET http://localhost:4004/international-flights


### Entity Airlines
GET http://localhost:4004/international-flights/Airlines


### Entity Flights
GET http://localhost:4004/international-flights/Flights
Authorization: Basic scott tiger
Content-Type: application/json
					
					
--
$ cds watch		
		

--modify the file cap1/cdsrc.json 
--to by pass the "authenticated-user" requirement in MyService.cds		
{
    "requires":{
        "auth": {
            "strategy":"dummy"
        }
    }
}	

--=============================================================================
https://cap.cloud.sap/docs/node.js/authentication#jwt

UAA : User Account and Authentication service

--Enable the Authentication Strategy by installing the package
$ npm install @sap/xssec @sap/xsenv


--Next, you need to bind and configure the UAA service
--	1. Create XSUAA Configuration
--	2. Configure the Application
--	3. Set Up the Roles for the Application
--	4. Running Approuter

--1. Create XSUAA Configuration
--Create a folder called "gen" and compile your CDS model with authentication annotations 
--into a full xs-security.json:
$ mkdir gen
$ cds compile srv/ --to xsuaa > gen/xs-security.json
--Note how in "xs-security.json" the admin scope from the CDS model 
--has materialized as a scope and a role template

--Create an XSUAA service with this configuration:
$ cf create-service xsuaa application cap1-uaa -c gen/xs-security.json
--in gen/xs-security.json file, I changed "xsappname" to  "cap1" instead of "cap1"
--Me: to avoid the ERROR: Service broker error: Service broker xsuaa failed with: org.springframework.cloud.servicebroker.exception.ServiceBrokerException: Application with xsappname cap1!t60245 already exists.

--verify the service creation "cap1-uaa" in CF 



--2. Configure the Application
-- Create a default-env.json file in the root of your project and insert this code:
{
   "VCAP_SERVICES": {
     "xsuaa": [
       {
         "name": "cap1-uaa",
         "label": "xsuaa",
         "tags": [ "xsuaa" ],
         "credentials": {
           [...]
         }
       }
     ]
   }
 }

--Create a service key:
$ cf create-service-key cap1-uaa cap1-uaa-key
$ cf service-key cap1-uaa cap1-uaa-key
--You do this, to gain access to the XSUAA credentials.
-- Copy the JSON snippet from the console into the "default-env.jsonfile"
-- in the VCAP_SERVICES.xsuaa.credentials block
 
 
--Enhance your app’s configuration in "package.json" 
--by a "uaa" section inside the "cds.requires" block:
 "cds": {
   "requires": {
     "uaa": {
       "kind": "xsuaa"
     }
   }
 }
 
--This configuration, together with the credentials from default-env.json, is used by the Node.js runtime to validate the JWT token. To verify it, you can run cds env list requires.uaa, which prints the full uaa configuration including the credentials.
$ cds env list requires.uaa
		requires.uaa.credentials.apiurl = https://api.authentication.eu10.hana.ondemand.com
		requires.uaa.credentials.clientid = sb-cap11!t60245
		requires.uaa.credentials.clientsecret = lSnwyEKAZ/MEpFlGZMiPsmYKR2I=
		requires.uaa.credentials.identityzone = ec8b6e7ctrial
		requires.uaa.credentials.identityzoneid = ba98f876-fd1c-46ec-add5-1ef623ddf19c
		requires.uaa.credentials.sburl = https://internal-xsuaa.authentication.eu10.hana.ondemand.com
		requires.uaa.credentials.subaccountid = ba98f876-fd1c-46ec-add5-1ef623ddf19c
		requires.uaa.credentials.tenantid = ba98f876-fd1c-46ec-add5-1ef623ddf19c
		requires.uaa.credentials.tenantmode = dedicated
		requires.uaa.credentials.uaadomain = authentication.eu10.hana.ondemand.com
		requires.uaa.credentials.url = https://ec8b6e7ctrial.authentication.eu10.hana.ondemand.com
		requires.uaa.credentials.verificationkey = -----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAr9e8wKFyTH3HLoDe5PImFLGafzlocK4AfjDYeTx62YFguTnUjhUQ8ub9kgYkJcvAUu3apv6qGlzEQZV2mUYXgXwruMCWwb5kM4qSIsmG3+Aj48cg7sZ0HYKvRPSO46J0TWD5KVh1qAREC7BAmgVyal9mqijtuKwnIqjp+4zqUj3bzUymQyRb8vV6FJ2hMZhFAxy08IBaywa5B/seCC4E3DDtlHw8texPjiVY2VAflB9T6oBqk4FXadUCiD5lQxJ8hvDY4dTverxm++8G6uoWTC1oowQkg7MJjLpvrexQjzgDg2XQFExHjlcJIpny3IsAzEUdDFY1ExqTjvFI3fCPGQIDAQAB-----END PUBLIC KEY-----
		requires.uaa.credentials.xsappname = cap11!t60245
		requires.uaa.credentials.zoneid = ba98f876-fd1c-46ec-add5-1ef623ddf19c
		requires.uaa.kind = xsuaa


 
--Install node modules that are required at runtime to authenticate the user and to read the JWT token:
$ npm install --save passport @sap/xssec @sap/audit-logging
 
 
--3. Set Up the Roles for the Application
--Once you’ve deployed your application to the Cloud Foundry environment and created the service binding to XSUAA, you enter the SAP Cloud Platform Cockpit. In the cockpit, you set up the roles and role collections and assign the role collections to your users. This brings the necessary authorization information into the JWT token when the user logs on to your application through XSUAA and approuter.

--Since XSUAA configuration in cloud cockpit only works on existing applications, you need to temporarily push the app and bind it to the previously created service. You don’t need the app to be running at this stage.

--Push the application without start:
$ cf target     
$ cf push cap1 --no-start --no-manifest --random-route

--Bind your application to your xsuaa service instance:
$ cf bind-service cap1 cap1-uaa

--Create a role collection.
The roles collections are created on subaccount level in the cockpit. 
Navigate to your subaccount and then to Security > Role Collections.

	Example:   role collection:    cap1_Admin_Modeler

--Create roles and add them to your role collection.
The roles are created on application level in the cockpit and based on your role templates. Navigate to the application in the correct space in your subaccount and then go to Security > Roles. 
	Example: role:    modeler
	         Description: created
			 Role Collection: cap1_Admin_Modeler

--Assign the role collections to users.
The user role assignment is done in the Trust Configuration of your subaccount. 
Select the IDP where the user is authenticated.
Enter the E-mail address and select Show Assignments, to see already existing assignments. 
Then select Assign Role Collection to add your user to the role collection.

--4. Running Approuter
The approuter component implements the necessary handshake with XSUAA to let the user log in interactively. The resulting JWT token is sent to the application where it’s used to enforce authorization.

--Create a file app/package.json with the following content:
{
   "name": "approuter",
   "dependencies": {
     "@sap/approuter": "^8"
   },
   "scripts": {
     "start": "node node_modules/@sap/approuter/approuter.js"
   }
}

--Create the approuter configuration file app/xs-app.json with the following content:
{
 "routes": [ {
   "source": "^/(.*)",
   "destination": "srv_api"
  } ]
}


--Create a file app/default-env.json with the following content:
{
 "destinations" : [
   {
     "name": "srv_api",
     "url": "<service-url>",
     "forwardAuthToken": true
   }
 ]
}
--where
srv_api is the destination name from xs-app.json.
<service-url> is the service root of your app, 
for example, http://localhost:4004


Copy the VCAP_SERVICES block of file default-env.json into file app/default-env.json. 
This tells approuter which UAA instance to contact.

--In app/ folder, run
$ npm install  #--install approuter modules
$ npm start    #--start approuter
--This starts an approuter instance on http://localhost:5000

After the approuter is started, log in at http://localhost:5000 and verify that the routes are protected as expected. In our example, if you assigned the admin scope to your user in SAP Cloud Platform cockpit, you can now access http://localhost:5000/admin.


To test UIs w/o a running UAA service, just add this to xs-app.json: "authenticationMethod": "none"
















