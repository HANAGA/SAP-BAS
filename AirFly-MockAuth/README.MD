# CDS Service with Mock Authorization
--currentlt in the Folder /user/projects/
$ cds init cap1
$ cd cap1

							
**--**File: cap1/db/MyDictionary.cds						
``
namespace fly;

entity Airlines {
	key carrid 	 : String(3);
	    carrname : String(20);
	    currcode : String(5);
}
``
``
entity Flights {
    key carrid 	 : String(3);   
	key connid 	 : String(4);
		cityfrom : String(20);
		cityto   : String(20);
		distance : Decimal(15,2);
}
``

**--File: cap1/db/data/
	fly-Airlines.csv
	fly-Flights.csv

							
**--File: cap1/srv/MyService.cds					
``
using {fly} from '../db/MyDictionary';

@requires : 'authenticated-user'

service InternationalFlights {

    entity Airlines as select from fly.Airlines;
    entity Flights  as select from fly.Flights;

}
``

**--File cap1/.cdsrc.json
``
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
``

				
**--File: cap1/RESTClient.http
``
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
``					
					
--
``
$ cds watch		
``		

**--modify the file cap1/cdsrc.json 
**--to by pass the "authenticated-user" requirement in MyService.cds		
``
{
    "requires":{
        "auth": {
            "strategy":"dummy"
        }
    }
}		
``	