--1. Taným Sorusu: Northwind veritabanýnda toplam kaç tablo vardýr? Bu tablolarýn isimlerini listeleyiniz.

SELECT COUNT(*) AS TableCount
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';


--2. JOIN Sorusu: Her sipariþ (Orders) için, Þirket adý (CompanyName), çalýþan adý (Employee Full Name), sipariþ tarihi ve gönderici þirketin adý (Shipper) ile birlikte bir liste çýkarýn.

SELECT ord.OrderID,
       cus.CompanyName,
       emp.FirstName + ' ' + emp.LastName AS 'EmployeeFullName',
       ord.OrderDate,
       sh.CompanyName AS Shipper
FROM nortwind.dbo.Orders ord
JOIN Customers cus ON ord.CustomerID = cus.CustomerID
JOIN Employees emp ON ord.EmployeeID = emp.EmployeeID
JOIN Shippers sh ON ord.ShipVia = sh.ShipperID;


--3. Aggregate Fonksiyon: Tüm sipariþlerin toplam tutarýný bulun. (Order Details tablosundaki Quantity  UnitPrice üzerinden hesaplayýnýz)

SELECT SUM (UnitPrice + Quantity) AS 'Toplam Sipariþ Tutarý' 
FROM nortwind.dbo.[Order Details];


--4. Gruplama: Hangi ülkeden kaç müþteri vardýr?

SELECT Country, COUNT(*) AS 'Müþteri Sayýsý'
FROM nortwind.dbo.Customers
GROUP BY Country;


--5. Subquery Kullanýmý: En pahalý ürünün adýný ve fiyatýný listeleyiniz.

SELECT ProductName, UnitPrice
FROM nortwind.dbo.Products
WHERE UnitPrice = (SELECT MAX(UnitPrice) FROM Products);


--6. JOIN ve Aggregate: Her çalýþana düþen sipariþ sayýsýný gösteren listeyi oluþturunuz.

SELECT emp.FirstName + ' ' + emp.LastName AS 'ÇalýþanAdýSoyadý', 
COUNT(ord.OrderID) AS "SipariþSayýsý"
FROM Employees emp
LEFT JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
GROUP BY emp.FirstName, emp.LastName;


--7. Tarih Filtreleme: 1997 yýlýnda verilen sipariþleri listeleyiniz.
SELECT *
FROM Orders
WHERE YEAR(OrderDate) = 1997;


--8. CASE Kullanýmý: Ürünleri fiyat aralýklarýna göre “Ucuz”, “Orta” ve “Pahalý” kategorilere ayýrýnýz.

SELECT ProductName as "Ürün Ýsmi", UnitPrice as "Birim Fiyat", 
       CASE 
           WHEN UnitPrice < 20 THEN 'Ucuz'
           WHEN UnitPrice BETWEEN 20 AND 50 THEN 'Orta'
           ELSE 'Pahalý'
       END AS 'FiyatAralýðý'
FROM Products;


--9. Nested Subquery: En çok sipariþ verilen ürünün adýný ve sipariþ adedini (adet bazýnda) bulunuz.

SELECT TOP 1 pro.ProductName, SUM(ord.Quantity) AS 'ToplamSiparisAdedi'
FROM nortwind.dbo.Products pro
JOIN [Order Details] ord ON pro.ProductID = ord.ProductID
GROUP BY pro.ProductName
ORDER BY 'ToplamSiparisAdedi' DESC;


--10.View Oluþturma:  Ürünler ve kategoriler bilgilerini birleþtiren bir görünüm (view) oluþturun.

CREATE VIEW UrunlerveKategoriler AS

SELECT pro.ProductID, pro.ProductName, pro.UnitPrice,
cat.CategoryID, cat.CategoryName, cat.Description
FROM nortwind.dbo.Products pro
JOIN Categories cat ON pro.CategoryID = cat.CategoryID;

SELECT * FROM UrunlerveKategoriler;

--11. Trigger: Ürün silindiðinde log tablosuna kayýt yapan bir trigger yazýnýz.
SELECT * FROM UrunSilmeLog;
--Silinen bilgilerin var olduðu log tablosu
CREATE TABLE UrunSilmeLog (LogID INT IDENTITY(1,1) PRIMARY KEY, ProductID INT,
ProductName NVARCHAR(40), UnitPrice MONEY
SilmeTarihi DATETIME DEFAULT GETDATE());

--Kayýt edecek trýgger;
CREATE TRIGGER UrunSilmeLogTrigger ON Products
AFTER DELETE AS
BEGIN
INSERT INTO UrunSilmeLog (ProductID, ProductName, UnitPrice)
SELECT ProductID, ProductName, UnitPrice
FROM deleted;
END;

--Kontrol;
INSERT INTO Products (ProductName) VALUES ('Test');         
DELETE FROM Products WHERE ProductName = 'Test';                        
SELECT * FROM UrunSilmeLog; 

--12. Stored Procedure: Belirli bir ülkeye ait müþterileri listeleyen bir stored procedure yazýnýz.

CREATE PROCEDURE MusterileriUlkeyeGoreListele
@Ulke NVARCHAR(50)
AS
BEGIN 
SELECT CustomerID, CompanyName, ContactName, City
FROM Customers
WHERE Country = @Ulke;
END;

-- Çalýþtýrma
EXEC MusterileriUlkeyeGoreListele @Ulke = 'Germany';

--13. Left Join Kullanýmý: Tüm ürünlerin tedarikçileriyle (suppliers) birlikte listesini yapýn. Tedarikçisi olmayan ürünler de listelensin.

SELECT pro.ProductID, pro.ProductName, sup.SupplierID, sup.CompanyName AS TedarikciSirketi
FROM Products pro
LEFT JOIN Suppliers sup ON pro.SupplierID = sup.SupplierID;

--14. Fiyat Ortalamasýnýn Üzerindeki Ürünler: Fiyatý ortalama fiyatýn üzerinde olan ürünleri listeleyin.

SELECT ProductID, ProductName, UnitPrice
FROM Products
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Products);

--15. En Çok Ürün Satan Çalýþan: Sipariþ detaylarýna göre en çok ürün satan çalýþan kimdir?

SELECT TOP 1 emp.EmployeeID, emp.FirstName, emp.LastName, 
SUM(orddet.Quantity) AS ToplamUrunSayisi
FROM Employees emp
JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
JOIN [Order Details] orddet ON ord.OrderID = orddet.OrderID
GROUP BY emp.EmployeeID, emp.FirstName, emp.LastName
ORDER BY ToplamUrunSayisi DESC;

--16. Ürün Stoðu Kontrolü: Stok miktarý 10’un altýnda olan ürünleri listeleyiniz.

SELECT ProductName, UnitsInStock
FROM Products
WHERE UnitsInStock < 10;

--17. Þirketlere Göre Sipariþ Sayýsý: Her müþteri þirketinin yaptýðý sipariþ sayýsýný ve toplam harcamasýný bulun.

SELECT cust.CompanyName, COUNT(ord.OrderID) AS SiparisSayisi,
SUM(orddet.UnitPrice * orddet.Quantity) AS ToplamHarcama
FROM Customers cust
LEFT JOIN Orders ord ON cust.CustomerID = ord.CustomerID
LEFT JOIN [Order Details] orddet ON ord.OrderID = orddet.OrderID
GROUP BY cust.CompanyName;

--18. En Fazla Müþterisi Olan Ülke: Hangi ülkede en fazla müþteri var?

SELECT TOP 1 Country FROM Customers 
GROUP BY Country
ORDER BY COUNT(*) DESC;

--19. Her Sipariþteki Ürün Sayýsý: Sipariþlerde kaç farklý ürün olduðu bilgisini listeleyin.

SELECT OrderID, COUNT(ProductID) as UrunSayilar FROM [Order Details]
GROUP BY OrderID;

--20. Ürün Kategorilerine Göre Ortalama Fiyat: Her kategoriye göre ortalama ürün fiyatýný bulun.

SELECT cate.CategoryName, AVG(pro.UnitPrice) AS OrtalamaFiyat
FROM Products pro
JOIN Categories cate ON pro.CategoryID = cate.CategoryID
GROUP BY cate.CategoryName;

--21. Aylýk Sipariþ Sayýsý: Sipariþleri ay ay gruplayarak kaç sipariþ olduðunu listeleyin.

SELECT DATEPART(month, OrderDate) AS Ay, COUNT(*) AS SiparisSayisi
FROM Orders
GROUP BY DATEPART(month, OrderDate);

--22. Çalýþanlarýn Müþteri Sayýsý: Her çalýþanýn ilgilendiði müþteri sayýsýný listeleyin.

SELECT EmployeeID, COUNT(DISTINCT CustomerID) AS FarklýMüþteriSayýsý
FROM Orders
GROUP BY EmployeeID;

--23. Hiç sipariþi olmayan müþterileri listeleyin.

SELECT cus.CustomerID, cus.CompanyName AS 'ÞirketAdý'
FROM Nortwind.dbo.Customers cus
FULL JOIN Orders ord ON cus.CustomerID = ord.CustomerID
WHERE ord.OrderID IS NULL;

--24. Sipariþlerin Nakliye (Freight) Maliyeti Analizi: Nakliye maliyetine göre en pahalý 5 sipariþi listeleyin.

SELECT TOP 5 ord.OrderID, ord.CustomerID, ord.ShipName , ORD.Freight AS 'Nakliye Maliyeti'
FROM Nortwind.dbo.Orders AS ord
ORDER BY 'Nakliye Maliyeti' DESC;