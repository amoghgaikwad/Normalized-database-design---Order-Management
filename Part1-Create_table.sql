create database tstamg123;
use tstamg123;

create table items(
itemid char(20),
weight numeric(7),
name char(20),
primary key (itemid)
);

create table busentities
(
entityid char(20),
location char(20),
address char(20),
phone numeric(10),
web char(20),
contact char(20),
primary key (entityid)
);

create table billofmaterials
(
pitem char(20),
mitem char(20),
qtymperitem integer,
primary key (pitem, mitem),
foreign key (pitem) references items (itemid),
foreign key (mitem) references items (itemid)
);

create table supplierdiscounts
(
supplierid char(20),
amount numeric(7,2),
discount numeric(7,2),
primary key (supplierid),
foreign key (supplierid) references busentities (entityid)
);

create table supplyunitpricing
(
supplierid char(20),
item char(20),
ppu numeric(7,2),
primary key (supplierid, item),
foreign key (supplierid) references supplierdiscounts (supplierid),
foreign key (item) references items (itemid) 
);


create table manufdiscounts
(
manufid char(20),
amt numeric(7,2),
discount numeric(7,2),
primary key (manufid),
foreign key (manufid) references busentities (entityid)
);

create table manufunitpricing
(
manuf_id char(20),
pitem char(20),
setupcost numeric(7,2),
prodcostperunit numeric(7,2),
primary key (manuf_id, pitem),
foreign key (manuf_id) references manufdiscounts (manufid),
foreign key (pitem) references items (itemid)
);

create table shippingpricing
(
shipperid char(20),
fromloc char(20),
toloc char(20),
minpackageprice numeric(7,2),
priceperlb numeric(7,2),
amt numeric(7,2),
discount numeric(7,2),
primary key (shipperid, fromloc, toloc),
foreign key (shipperid) references busentities (entityid)
);

create table customerdemand
(
customer char(20),
itemid char(20),
qty integer,
primary key (customer, itemid),
foreign key (itemid) references items (itemid),
foreign key (customer) references busentities (entityid) 
);

create table supplyorders
(
itemid char(20),
supplierid char(20),
qty integer,
primary key (itemid, supplierid),
foreign key (itemid) references items (itemid),
foreign key (supplierid) references supplierdiscounts (supplierid)
);



create table manuforders
(
itemid char(20),
manufid char(20),
qty integer,
primary key (itemid, manufid),
foreign key (itemid) references items (itemid),
foreign key (manufid) references manufdiscounts (manufid)
);

create table shiporders
(
itemid char(20),
shipperid char(20),
senderid char(20),
recipientid char(20),
qty integer,
primary key (itemid, shipperid, senderid, recipientid),
foreign key (itemid) references items (itemid),
foreign key (senderid) references busentities (entityid),
foreign key (shipperid) references busentities (entityid),
foreign key (recipientid) references busentities (entityid)
);
