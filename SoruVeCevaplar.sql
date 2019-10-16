use NORTHWND
--  Ürünlerin bir listesini ve ürünün o ana kadarki verilmiş en yüksek sipariş miktarını görüntüleyiniz...

select ProductID,(Select ProductName from Products p where p.ProductID=od.ProductID) as Ürün,Max(Quantity) as [Maximum Satış] from [Order Details] od group by ProductID order by 1 

--  Hangi kargo şirketi hangi ürünü en fazla taşımıştır?

select s.CompanyName,
(

select top 1 p.ProductName from [Order Details] od join Orders o on od.OrderID=o.OrderID join Products p on od.ProductID=p.ProductID where o.ShipVia=s.ShipperID group by p.ProductName order by count(p.ProductID) desc

) as ProductName,

(

select top 1 count(p.ProductID) from [Order Details] od join Orders o on od.OrderID=o.OrderID join Products p on od.ProductID=p.ProductID where o.ShipVia=s.ShipperID group by p.ProductID order by count(p.ProductID) desc

) as Total

 from Shippers s order by 3 desc


 -- 01.01.1996 - 01.01.1997 tarihleri arasında en fazla hangi ürün satın alınmıştır?

 select top 1 p.ProductID,p.ProductName,sum(Quantity) as [Satış Adeti] from [Order Details] od join Orders o on o.OrderID=od.OrderID join Products p on p.ProductID=od.ProductID
 where o.OrderDate between '1996-01-01' and '1997-01-01'group by p.ProductID,p.ProductName order by 3 desc


-- Hangi ülkelerde hangi siparişler, en geç teslim edilmiştir?

 select distinct ShipCountry,
 
 (
  select top 1 OrderID from Orders where ShipCountry=o.ShipCountry order by DATEDIFF(DAY,RequiredDate,ShippedDate) desc
 ) as [Order Id] 

  from Orders o order by 1 asc	
 
-- Hangi tedarikçiden en fazla hangi ürün temin edilmiştir? (Stockta var olan ve satılan adetlerin toplamından bulunacak)

select  sup.CompanyName,
(
select TOP 1 p.ProductName from [Order Details] od join Products p on p.ProductID=od.ProductID join Suppliers s on s.SupplierID=p.SupplierID where s.SupplierID=sup.SupplierID
group by p.ProductName order by sum(Quantity) desc
)as ProductId,
(
select TOP 1 sum(Quantity)+(select UnitsInStock from Products where ProductID=od.ProductID) from [Order Details] od join Products p on p.ProductID=od.ProductID join Suppliers s on s.SupplierID=p.SupplierID where s.SupplierID=sup.SupplierID 
group by od.ProductID order by sum(Quantity) desc
) as Miktar

from Suppliers sup order by 2 asc ,3 desc


-- Leka Trading şirketinin tedarik ettiği ürünlerden ortalama ne kadar para kazandık?

select AVG([Toplam Kazanç]) as OrtalamaKazanç from 
(
select ProductName,CAST(SUM(od.Quantity*od.UnitPrice*(1-od.Discount)) as decimal(10,2)) as [Toplam Kazanç] from [Order Details] od join Products p on od.ProductID=p.ProductID join Suppliers s on p.SupplierID=s.SupplierID where s.CompanyName='Leka Trading' group by ProductName
) as tbl

-- 20'den fazla kez siparis edilmis olan urun siparişleri hangi bölgeden verilmiştir?

select distinct ShipCountry from orders o join [Order Details] od on o.OrderID=od.OrderID where Quantity>20 

-- Kategori bazlı olarak en çok para kazandığım ürünlerimden stoğum ne kadar var? (categoryName,ProductName,ToplamTutar,UnitslnStock)

select tbl.CategoryName,tbl.ProductName,tbl.[Toplam Kazanç],p.UnitsInStock from Products p  join
(
select
CategoryName
,(
select top 1 ProductName from Orders o join [Order Details] od on o.OrderID=od.OrderID join Products p on p.ProductID=od.ProductID join Categories c on c.CategoryID=p.CategoryID where c.CategoryID=ctg.CategoryID  group by CategoryName,ProductName order by sum(Quantity*od.UnitPrice) desc
) as ProductName
,(
select top 1 sum(Quantity*od.UnitPrice) from Orders o join [Order Details] od on o.OrderID=od.OrderID join Products p on p.ProductID=od.ProductID join Categories c on c.CategoryID=p.CategoryID where c.CategoryID=ctg.CategoryID  group by CategoryName,ProductName order by sum(Quantity*od.UnitPrice) desc
) as [Toplam Kazanç]

from Categories ctg
) as tbl

 on tbl.ProductName=p.ProductName order by 1 desc


-- Londra'da çalışan en az satış yapan çalışanım hangisidir?


select * from Employees where EmployeeID =

(
select tbl.EmployeeID from
(
select EmployeeId,sum(od.UnitPrice*od.Quantity*(1-od.Discount)) as Tutar from [Order Details] od join orders o on od.OrderID=o.OrderID where EmployeeID in(
select EmployeeID from  Employees where City='london') group by EmployeeID
) as tbl where tbl.Tutar=(
select min(tbl2.tutar) from
(
select EmployeeId,sum(od.UnitPrice*od.Quantity*(1-od.Discount)) as Tutar from [Order Details] od join orders o on od.OrderID=o.OrderID where EmployeeID in(
select EmployeeID from  Employees where City='london') group by EmployeeID
) as tbl2 ) 
)

-- En fazla satış yapan satıcının rapor verdiği çalışanının siparişleriyle ilgilendiği kaç müşteri vardır?

select c.CompanyName from Customers c where CustomerID in
(
	select distinct CustomerID as Total from orders o
		where o.EmployeeID=
		(
			select top 1 e.ReportsTo from [Order Details] od join Orders o on od.OrderID=o.OrderID join Employees e on					e.EmployeeID=o.EmployeeID group by e.EmployeeID,e.ReportsTo order by sum(UnitPrice*Quantity) desc
		) 
) 
-- Speedy Express ile taşımış ürünlerden fiyatı max olan ürün ve bu ürünün siparişini almış olan çalışanın FullName'ini getiriniz?

select e.EmployeeID,e.FirstName +' '+e.LastName as İsim from Orders o join Employees e on e.EmployeeID=o.EmployeeID where OrderID=(
select tbl.OrderId from
(
select TOP 1 OrderID,Sum(Quantity*UnitPrice*(1-Discount)) as Toplam from [Order Details] where OrderID in 
(
select OrderID from Orders o  join Shippers s on s.ShipperID=o.ShipVia where s.CompanyName='Speedy Express'
 )
 group by OrderID order by Toplam desc
 ) as tbl
)

-- Yıllar bazında en çok taşıma yapan kargo firmaları nelerdir? (Her senenin birincisi)

select YEAR(OrderDate) as Yıl ,s.ShipperID,s.CompanyName,Count(OrderID) as Total from orders o join Shippers s  on s.ShipperID=o.ShipVia  group by YEAR(OrderDate),s.ShipperID,s.CompanyName

-- Çalışanlarım ürün bazında kaç paralık satış yapmışlardır? (UnitPrice*Quantity)

select e.FirstName+' '+e.LastName as Ad,p.ProductName,tbl.Total from Employees e join
(
select EmployeeID,ProductID,sum(Quantity*UnitPrice) as Total from [Order Details] od join orders o on od.OrderID=o.OrderID 
group by ProductID,EmployeeID
) as tbl on tbl.EmployeeID=e.EmployeeID join Products p on p.ProductID=tbl.ProductID order by Ad , ProductName asc

-- Category bazlı yıllara göre toplam kazancı bulunuz? (UnitPrice*Quantity)

select YEAR(OrderDate) as Yıl, c.CategoryName,Sum(Quantity*od.UnitPrice) as Total from Orders o join [Order Details] od on o.OrderID=od.OrderID join Products p on p.ProductID=od.ProductID join Categories c on c.CategoryID=p.CategoryID   group by c.CategoryName,YEAR(OrderDate) order by 2 asc

--Kategori ekleyen bir prosedür olacak eğer o kategori yoksa ekleyecek ve eklenen in id'sini output olarak verecek, varsa da o kategorinin id'sini verecek
go
create procedure SP_AddCategory(@categoryName nvarchar(15),@categoryId int out)
as
begin
	if not exists(select * from Categories where CategoryName=@categoryName)
		begin
			insert into Categories (CategoryName) values (@categoryName)
			set @categoryId=@@IDENTITY
			print 'Yeni kategori eklendi. Id :'+CAST(@categoryId as nvarchar)
		end
	else
		begin
			--set @categoryId=(select CategoryID from Categories where CategoryName=@categoryName)
			select @categoryId=CategoryID from Categories where CategoryName=@categoryName
			print @categoryName+ ' isminde bir kategori zaten var. Id :'+CAST(@categoryId as nvarchar)
		end
end

--Nancy isimli çalışanın aldığı siparişlerin ve tutarlarının listelendiği view'ı oluşturalım
go
create view Nancy_Siparisler
as
select
	[Order Details].OrderID,
	CAST(SUM(UnitPrice*Quantity*(1-Discount)) as decimal(10,2)) as Tutar
from [Order Details]
join Orders on Orders.OrderID=[Order Details].OrderID
where Orders.EmployeeID=(select EmployeeID from Employees where FirstName='Nancy')
group by [Order Details].OrderID


--Eğer bir kişi eklenmeye çalışılırsa, eğer o kişi daha önceden kayıtlı ve pasif durumdaysa onu aktif ederiz aksi taktirde yeni bir kişi oluştururuz.

go 
create trigger CalisanEkle on Employees
instead of insert
as
begin
	if exists(select * from Employees where MailAddress=(select MailAddress from inserted))
		begin
			update Employees set IsDeleted=0,FirstName=(select FirstName from inserted),LastName=(select LastName from inserted) where MailAddress=(select MailAddress from inserted)
		end
	else
		begin
			insert into Employees (FirstName,LastName,MailAddress) values ((select FirstName from inserted),(select LastName from inserted),(select MailAddress from inserted))
		end
end

--Ürünleri ürün adına göre indexleyiniz.
create nonclustered index IX_ProductName on Products(ProductName)


