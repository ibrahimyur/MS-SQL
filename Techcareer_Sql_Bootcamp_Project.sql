--1. Tan�m Sorusu: Northwind veritaban�nda toplam ka� tablo vard�r? Bu tablolar�n isimlerini listeleyiniz.

SELECT COUNT(*) AS TableCount
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';


--2. JOIN Sorusu: Her sipari� (Orders) i�in, �irket ad� (CompanyName), �al��an ad� (Employee Full Name), sipari� tarihi ve g�nderici �irketin ad� (Shipper) ile birlikte bir liste ��kar�n.

SELECT ord.OrderID,
       cus.CompanyName,
       emp.FirstName + ' ' + emp.LastName AS 'EmployeeFullName',
       ord.OrderDate,
       sh.CompanyName AS Shipper
FROM nortwind.dbo.Orders ord
JOIN Customers cus ON ord.CustomerID = cus.CustomerID
JOIN Employees emp ON ord.EmployeeID = emp.EmployeeID
JOIN Shippers sh ON ord.ShipVia = sh.ShipperID;


--3. Aggregate Fonksiyon: T�m sipari�lerin toplam tutar�n� bulun. (Order Details tablosundaki Quantity  UnitPrice �zerinden hesaplay�n�z)

SELECT SUM (UnitPrice + Quantity) AS 'Toplam Sipari� Tutar�' 
FROM nortwind.dbo.[Order Details];


--4. Gruplama: Hangi �lkeden ka� m��teri vard�r?

SELECT Country, COUNT(*) AS 'M��teri Say�s�'
FROM nortwind.dbo.Customers
GROUP BY Country;


--5. Subquery Kullan�m�: En pahal� �r�n�n ad�n� ve fiyat�n� listeleyiniz.

SELECT ProductName, UnitPrice
FROM nortwind.dbo.Products
WHERE UnitPrice = (SELECT MAX(UnitPrice) FROM Products);


--6. JOIN ve Aggregate: Her �al��ana d��en sipari� say�s�n� g�steren listeyi olu�turunuz.

SELECT emp.FirstName + ' ' + emp.LastName AS '�al��anAd�Soyad�', 
COUNT(ord.OrderID) AS "Sipari�Say�s�"
FROM Employees emp
LEFT JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
GROUP BY emp.FirstName, emp.LastName;


--7. Tarih Filtreleme: 1997 y�l�nda verilen sipari�leri listeleyiniz.
SELECT *
FROM Orders
WHERE YEAR(OrderDate) = 1997;


--8. CASE Kullan�m�: �r�nleri fiyat aral�klar�na g�re �Ucuz�, �Orta� ve �Pahal�� kategorilere ay�r�n�z.

SELECT ProductName as "�r�n �smi", UnitPrice as "Birim Fiyat", 
       CASE 
           WHEN UnitPrice < 20 THEN 'Ucuz'
           WHEN UnitPrice BETWEEN 20 AND 50 THEN 'Orta'
           ELSE 'Pahal�'
       END AS 'FiyatAral���'
FROM Products;


--9. Nested Subquery: En �ok sipari� verilen �r�n�n ad�n� ve sipari� adedini (adet baz�nda) bulunuz.

SELECT TOP 1 pro.ProductName, SUM(ord.Quantity) AS 'ToplamSiparisAdedi'
FROM nortwind.dbo.Products pro
JOIN [Order Details] ord ON pro.ProductID = ord.ProductID
GROUP BY pro.ProductName
ORDER BY 'ToplamSiparisAdedi' DESC;


--10.View Olu�turma:  �r�nler ve kategoriler bilgilerini birle�tiren bir g�r�n�m (view) olu�turun.

CREATE VIEW UrunlerveKategoriler AS

SELECT pro.ProductID, pro.ProductName, pro.UnitPrice,
cat.CategoryID, cat.CategoryName, cat.Description
FROM nortwind.dbo.Products pro
JOIN Categories cat ON pro.CategoryID = cat.CategoryID;

SELECT * FROM UrunlerveKategoriler;

--11. Trigger: �r�n silindi�inde log tablosuna kay�t yapan bir trigger yaz�n�z.
SELECT * FROM UrunSilmeLog;
--Silinen bilgilerin var oldu�u log tablosu
CREATE TABLE UrunSilmeLog (LogID INT IDENTITY(1,1) PRIMARY KEY, ProductID INT,
ProductName NVARCHAR(40), UnitPrice MONEY
SilmeTarihi DATETIME DEFAULT GETDATE());

--Kay�t edecek tr�gger;
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

--12. Stored Procedure: Belirli bir �lkeye ait m��terileri listeleyen bir stored procedure yaz�n�z.

CREATE PROCEDURE MusterileriUlkeyeGoreListele
@Ulke NVARCHAR(50)
AS
BEGIN 
SELECT CustomerID, CompanyName, ContactName, City
FROM Customers
WHERE Country = @Ulke;
END;

-- �al��t�rma
EXEC MusterileriUlkeyeGoreListele @Ulke = 'Germany';

--13. Left Join Kullan�m�: T�m �r�nlerin tedarik�ileriyle (suppliers) birlikte listesini yap�n. Tedarik�isi olmayan �r�nler de listelensin.

SELECT pro.ProductID, pro.ProductName, sup.SupplierID, sup.CompanyName AS TedarikciSirketi
FROM Products pro
LEFT JOIN Suppliers sup ON pro.SupplierID = sup.SupplierID;

--14. Fiyat Ortalamas�n�n �zerindeki �r�nler: Fiyat� ortalama fiyat�n �zerinde olan �r�nleri listeleyin.

SELECT ProductID, ProductName, UnitPrice
FROM Products
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Products);

--15. En �ok �r�n Satan �al��an: Sipari� detaylar�na g�re en �ok �r�n satan �al��an kimdir?

SELECT TOP 1 emp.EmployeeID, emp.FirstName, emp.LastName, 
SUM(orddet.Quantity) AS ToplamUrunSayisi
FROM Employees emp
JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
JOIN [Order Details] orddet ON ord.OrderID = orddet.OrderID
GROUP BY emp.EmployeeID, emp.FirstName, emp.LastName
ORDER BY ToplamUrunSayisi DESC;

--16. �r�n Sto�u Kontrol�: Stok miktar� 10�un alt�nda olan �r�nleri listeleyiniz.

SELECT ProductName, UnitsInStock
FROM Products
WHERE UnitsInStock < 10;

--17. �irketlere G�re Sipari� Say�s�: Her m��teri �irketinin yapt��� sipari� say�s�n� ve toplam harcamas�n� bulun.

SELECT cust.CompanyName, COUNT(ord.OrderID) AS SiparisSayisi,
SUM(orddet.UnitPrice * orddet.Quantity) AS ToplamHarcama
FROM Customers cust
LEFT JOIN Orders ord ON cust.CustomerID = ord.CustomerID
LEFT JOIN [Order Details] orddet ON ord.OrderID = orddet.OrderID
GROUP BY cust.CompanyName;

--18. En Fazla M��terisi Olan �lke: Hangi �lkede en fazla m��teri var?

SELECT TOP 1 Country FROM Customers 
GROUP BY Country
ORDER BY COUNT(*) DESC;

--19. Her Sipari�teki �r�n Say�s�: Sipari�lerde ka� farkl� �r�n oldu�u bilgisini listeleyin.

SELECT OrderID, COUNT(ProductID) as UrunSayilar FROM [Order Details]
GROUP BY OrderID;

--20. �r�n Kategorilerine G�re Ortalama Fiyat: Her kategoriye g�re ortalama �r�n fiyat�n� bulun.

SELECT cate.CategoryName, AVG(pro.UnitPrice) AS OrtalamaFiyat
FROM Products pro
JOIN Categories cate ON pro.CategoryID = cate.CategoryID
GROUP BY cate.CategoryName;

--21. Ayl�k Sipari� Say�s�: Sipari�leri ay ay gruplayarak ka� sipari� oldu�unu listeleyin.

SELECT DATEPART(month, OrderDate) AS Ay, COUNT(*) AS SiparisSayisi
FROM Orders
GROUP BY DATEPART(month, OrderDate);

--22. �al��anlar�n M��teri Say�s�: Her �al��an�n ilgilendi�i m��teri say�s�n� listeleyin.

SELECT EmployeeID, COUNT(DISTINCT CustomerID) AS Farkl�M��teriSay�s�
FROM Orders
GROUP BY EmployeeID;

--23. Hi� sipari�i olmayan m��terileri listeleyin.

SELECT cus.CustomerID, cus.CompanyName AS '�irketAd�'
FROM Nortwind.dbo.Customers cus
FULL JOIN Orders ord ON cus.CustomerID = ord.CustomerID
WHERE ord.OrderID IS NULL;

--24. Sipari�lerin Nakliye (Freight) Maliyeti Analizi: Nakliye maliyetine g�re en pahal� 5 sipari�i listeleyin.

SELECT TOP 5 ord.OrderID, ord.CustomerID, ord.ShipName , ORD.Freight AS 'Nakliye Maliyeti'
FROM Nortwind.dbo.Orders AS ord
ORDER BY 'Nakliye Maliyeti' DESC;