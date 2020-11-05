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