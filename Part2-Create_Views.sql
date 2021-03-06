use dbproj;

/*1*/
create or replace view shippedvscustdemand as
(
select c.item, c.customer, c.qty as demandquantity, coalesce(sum(s.qty), 0)  as shippedquantity from customerdemand c
left join shiporders s on s.item = c. item and c.customer = s.recipient 
group by c.item, c.customer, c.qty
);

/*2*/
create or replace view shippedvscustdemand as
(
select c.item, c.customer, c.qty as demandquantity, coalesce(sum(s.qty), 0)  as shippedquantity from customerdemand c
left join shiporders s on s.item = c. item and c.customer = s.recipient 
group by c.item, c.customer, c.qty
);

/*3*/

create or replace view matusedvsshippedtemp as 
(
select recipient, item, sum(qty) as recievedquantity from shiporders
group by recipient, item
);

create or replace view matusedvsshipped as
(
select m.manuf, m.item, b.matitem, m.qty * b.qtymatperitem as productionquantity, coalesce(a.recievedquantity, 0) as recievedquantity from manuforders m
left join billofmaterials b on m.item = b.proditem
left join matusedvsshippedtemp a on a.recipient = m.manuf and a.item = b.matitem
);

/*4*/
create or replace view producedvsshippedtemp as 
(
select sender, item, sum(qty) as shippedquantity from shiporders
group by sender, item
);

create or replace view producedvsshipped as 
(
select m.manuf, m.item, m.qty as productionquantity, coalesce(a.shippedquantity, 0) as shippedquantity from manuforders m
left join producedvsshippedtemp a on a.sender = m.manuf and a.item = m.item
);

/*5*/
create or replace view suppliedvsshippedtemp as
(
select sender, item, sum(qty) as shippedquantity from shiporders
group by sender, item
);

create or replace view suppliedvsshipped as
(
select s.supplier, s.item, s.qty as orderedquantity, coalesce(a.shippedquantity, 0) as shippedquantity from supplyorders s
left join suppliedvsshippedtemp a on a.sender = s.supplier and a.item = s.item
);

/*6*/
create or replace view persuppliercosttemp as
(
select  s.supplier, sum(s.qty * sp.ppu) as totalpricenod  
from supplyorders s
left join supplyunitpricing sp on s.supplier = sp.supplier and s.item = sp. item
group by s.supplier
);

create or replace view persuppliercost as
(
select  st.supplier,
case when (st.totalpricenod >= sd.amt1 and st.totalpricenod < sd.amt2) then 
sd.amt1 + (st.totalpricenod - sd.amt1) * (1 - sd.disc1)
when (st.totalpricenod >= sd.amt2) then 
sd.amt1 + (sd.amt2 - sd.amt1) * (1 - sd.disc1)+ (st.totalpricenod - sd.amt2) * (1 - sd.disc2)
else st.totalpricenod
end as finalsuppliercost
from persuppliercosttemp st 
left join supplierdiscounts sd on st.supplier = sd.supplier
);

/*7*/
create or replace view permanufcosttemp as
(
select m.manuf, sum((m.qty * mp.prodcostperunit) + mp.setupcost) as totalmanufcostnod 
from manuforders m
left join manufunitpricing mp on mp.manuf = m.manuf and mp.proditem = m.item
group by m.manuf
);

create or replace view permanufcost as
(
select mt.manuf,
case when (mt.totalmanufcostnod >= md.amt1) then 
md.amt1 + (mt.totalmanufcostnod - md.amt1) * (1 - md.disc1)
else coalesce(mt.totalmanufcostnod, 0)
end as finalmanufcost
from permanufcosttemp mt
left join manufdiscounts md on md.manuf = mt.manuf
);

/*8*/
create or replace view pershippercosttemp as
(
select so.shipper, b1.shiploc as fromloc, b2.shiploc as toloc, sum(qty * i.unitweight) as totalweight 
from shiporders so
left join busentities b1 on so.sender = b1.entity
left join busentities b2 on so.recipient = b2.entity
left join items i on i.item = so.item
group by so.shipper, b1.shiploc, b2.shiploc
);

create or replace view pershippercosttemp2 as
(
select sp.shipper, sp.fromloc, sp.toloc, sp.minpackageprice,
case when (t.totalweight * sp.priceperlb >= sp.amt1 and t.totalweight * sp.priceperlb < sp.amt2) then sp.amt1 + ((t.totalweight * sp.priceperlb) - sp.amt1) * (1 - sp.disc1)
when (t.totalweight * sp.priceperlb >= sp.amt2) then 
sp.amt1 + (sp.amt2 - sp.amt1) * (1 - sp.disc1) + ((t.totalweight * sp.priceperlb) - sp.amt2) * (1 - sp.disc2)
else t.totalweight * sp.priceperlb
end as discountedcost 
from shippingpricing sp
left join pershippercosttemp t on sp.shipper = t. shipper and sp.fromloc = t.fromloc and sp.toloc = t.toloc
);

create or replace view pershippercosttemp3 as
(
select st.shipper, 
case when (st.minpackageprice > st.discountedcost) then st.minpackageprice
else st.discountedcost
end as totalprice
from pershippercosttemp2 st
);

create or replace view pershippercost as
(
select shipper, sum(totalprice) as totalshippingcost
from pershippercosttemp3
group by(shipper)
);

/*9*/

create or replace view temp1 as(
select coalesce(sum(finalsuppliercost),0) as totalsupplycost from persuppliercost
);
create or replace view temp2 as(
select coalesce(sum(finalmanufcost), 0) as totalmanufcost from permanufcost
);
create or replace view temp3 as(
select coalesce(sum(totalshippingcost), 0) as totalshippingcost from pershippercost
);
create or replace view totalCostBreakdown as(
select totalsupplycost, totalmanufcost, totalshippingcost, totalsupplycost + totalmanufcost + totalshippingcost as OverallCost
from temp1,temp2,temp3
);


