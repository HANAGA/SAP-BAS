using {fly} from '../db/MyDictionary';

@requires : 'authenticated-user'

service InternationalFlights {

    entity Airlines as select from fly.Airlines;
    entity Flights  as select from fly.Flights;

}