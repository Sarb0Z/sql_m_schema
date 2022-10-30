
Create Table Manufacturers
(
  manufacturerId int primary key,
  manufacturerName nvarchar(100)
)

Insert into Manufacturers values (1, 'GlaxoSmithKline')
Insert into Manufacturers values (2, 'nestle')
Insert into Manufacturers values (3, 'K&N''s')
Insert into Manufacturers values (4, 'Honor')
Insert into Manufacturers values (5, 'Dell')
Insert into Manufacturers values (6, 'olpers')

Create Table Products(

  productId int primary key,
  productName nvarchar(50),
  productDetails nvarchar(100),
  price float,
  quantityInStore int,
  manufacturerId int foreign key references Manufacturers(manufacturerId),
)

Insert into Products values (1, 'DELL Inspiron Laptop 5770', 'Core i5, 8GB RAM, 500 SD', 85000, 10, 5)
Insert into Products values (2, 'Honor 9x Mobile', 'Snapdragon processor, 6GB Ram, 128GB Internal Space', 35000, 5, 4)
Insert into Products values (3, 'Chicken Fillet K&Ns', '5 pieces', 650, 30, 3)
Insert into Products values (4, 'nestle water','half liter', 30, 100, 2)
Insert into Products values (5, 'nestle fruit juice','mango flavor- 1 liter', 130, 1000, 2)
Insert into Products values (6, 'paracetamol','100mg', 30, 150, 1)
Insert into Products values (7, 'olpers milk', '1 kg', 140, 100, 6)


Create Table Users
(
  userId int primary key,
  userName nvarchar(100),
  address nvarchar(100),
  dateOfBirth date
)


insert into Users values (1,'ali','iqbal Town Lahore','2000-5-20')
insert into Users values (3,'hafeez','defence phase 7 karachi','1997-6-19')
insert into Users values (2, 'umer', 'johan town', '1998-01-04')

Create Table Orders(

  orderId int primary key,
  userId int foreign key references Users (userId),
  datePlaced date,
  orderStatus varchar(20),
  
  CHECK (orderStatus in ('delivered', 'in-progress', 'cancelled'))
)


insert into Orders values (1 ,3 ,'2020-01-10','delivered')
Insert into Orders values (2, 2, '2020-07-16', 'in-progress')
Insert into Orders values (3, 1, '2017-05-05', 'delivered')
Insert into Orders values (4, 1, '2018-01-01', 'cancelled')
insert into Orders values (5 ,3 ,'2019-5-20','delivered')
Insert into Orders values (6, 1, '2020-07-16', 'in-progress')

Create Table OrderDetails
(
  orderId int foreign key references Orders (orderId),
  productId int foreign key references Products (productId),
  quantityRequired int,
  primary key (orderId, productId)
)


insert into OrderDetails values (1 , 2, 10 )
insert into OrderDetails values (1 , 3, 3)
insert into OrderDetails values (1 , 6 , 10 )
Insert into OrderDetails values (2, 1, 1)
Insert into OrderDetails values (2, 2, 7)
Insert into OrderDetails values (2, 3, 5)
Insert into OrderDetails values (3, 5, 1)
insert into OrderDetails values (4, 1, 1)
insert into OrderDetails values (4, 3, 1)
insert into OrderDetails values (5, 1 , 1 )
insert into OrderDetails values (5, 5, 35 )
insert into OrderDetails values (5, 4, 1 )
Insert into OrderDetails values (5, 7, 2)
Insert into OrderDetails values (6, 5, 1)

select * from Manufacturers;
select * from Products;
select * from Users;
select * from Orders;
select * from OrderDetails;



--ANSWER 1
--part1
alter table [Users]
add gender char NULL

alter table [Users]
add constraint chk_gender
check (gender in ('M', 'F', NULL))

--part2
insert into [OrderDetails](orderId, productId, quantityRequired)
select o.orderId, p.productId, quantityRequired=36
from [Orders] o join [OrderDetails] od
on o.orderId=od.orderId join [Products] p
on od.productId=p.productId
where o.orderStatus='delivered' and p.quantityInStore>5

--part3
delete from [OrderDetails]
where orderId=(select orderId from [Orders] where userId=3)


--ANSWER 2

select top 1 o.orderId, o.userId, u.[address]
from [Orders] o join [Users] u
on o.userId=u.userId
where o.orderId in (select top 3 od.orderId 
					from [OrderDetails] od join [Products] p
					on od.productId=p.productId join [Orders] o
					on od.orderId=o.orderId
					where o.orderStatus<>'Cancelled'
					order by (od.quantityRequired*p.price) desc
					)
order by o.orderId desc


--ANSWER 3

select  u1.*, o1.datePlaced
from [Users] u1 join [Orders] o1
on u1.userId=o1.userId
where u1.userId in (select o.userId
				from [Orders] o join [OrderDetails] od 
				on o.orderId=od.orderId join [Products] p
				on od.productId=p.productId join [Manufacturers] m
				on p.manufacturerId=m.manufacturerId
				where m.manufacturerName like '%le%' or m.manufacturerName like '%la%')
and YEAR(o1.datePlaced)>2016


--ANSWER 4

create view display_active_user
as
select u1.userId, u1.userName, u1.dateOfBirth
from [Users] u1
where EXISTS(
			select u.userId
			from  [Users] u join [Orders] o
			on u.userId=o.userId join [OrderDetails] od
			on o.orderId=od.orderId join [Products] p
			on od.productId=p.productId
			where u.userId=u1.userId
			group by u.userId
			having COUNT(distinct p.productId)=(select COUNT(productId) from [Products])
			) 

select * from [display_active_user]


--ANSWER 5

drop procedure returnProductQuantity
create procedure returnProductQuantity
@orderId int, @productId int, @quantityReturned int, @outputString varchar(255) output
as
begin
	if (@orderId not in (select orderId from [Orders]))
	begin
		set @outputString='Invalid Order Id'
	end
	else if (@orderId in (select orderId from [Orders] where orderStatus='Cancelled'))
	begin
		set @outputString='No product can be returned against cancelled orders'
	end
	else if (@productId not in (select productId from [Products]))
	begin
		set @outputString='Invalid Product Id'
	end
	else if  (@productId not in (select productId from [orderDetails] where orderId=@orderId))
	begin
		set @outputString='Product Id not found in the given order'
	end
	else if (@quantityReturned>=(select quantityRequired from [OrderDetails] where orderId=@orderId))
	begin
		set @outputString='Invalid Quantity'
	end
	else
	begin
		if (@orderId in (select orderId from [Orders] where orderStatus='delivered'))
		begin
			begin
				update [OrderDetails]
				set quantityRequired=quantityRequired-@quantityReturned
				where orderId=@orderId
			end
			begin
				update [Products]
				set quantityInStore=quantityInStore+@quantityReturned
				where productId=@productId
			end
			begin
				set @outputString= CONVERT(varchar, @quantityReturned) + ' amount is refunded.'
			end
		end
		if(@orderId in (select orderId from [Orders] where orderStatus='in-progress'))
		begin
			begin
				update [OrderDetails]
				set quantityRequired=quantityRequired-@quantityReturned
				where orderId=@orderId
			end
			begin
				set @outputString= CONVERT(varchar, 0) + ' amount is refunded.'
			end
		end
	end
end

			
declare @os1 varchar(255)
exec returnProductQuantity 20, 1, 5, @os1 output
select @os1 as 'Output Message'

declare @os2 varchar(255)
exec returnProductQuantity 1, 11, 5, @os2 output
select @os2 as 'Output Message'

declare @os3 varchar(255)
exec returnProductQuantity 4, 1, 5, @os3 output
select @os3 as 'Output Message'

declare @os4 varchar(255)
exec returnProductQuantity 1, 3, 5, @os4 output
select @os4 as 'Output Message'