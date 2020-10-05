drop index cse532.facilityidx;
drop index cse532.zipidx;

drop index cse532.facilityid_index;
drop index cse532.facilitycertid_index;
drop index cse532.uszipcode_index;

create index cse532.facilityidx on cse532.facility(geolocation) extend using db2gse.spatial_index(0.85, 2, 5);

create index cse532.zipidx on cse532.uszip(shape) extend using db2gse.spatial_index(0.85, 2, 5);

CREATE INDEX cse532.facilityid_index on cse532.facility(FacilityId);
CREATE INDEX cse532.facilitycertid_index on cse532.facilitycertification(FacilityId);
CREATE INDEX cse532.uszipcode_index on cse532.uszip(ZCTA5CE10);

runstats on table cse532.facility and indexes all;

runstats on table cse532.uszip and indexes all;