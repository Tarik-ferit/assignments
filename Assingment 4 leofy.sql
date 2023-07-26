---Charlie's Chocolate Factory company produces chocolates. The following product information is stored: product name, product ID, and quantity on hand. These chocolates are made up of many components. Each component can be supplied by one or more suppliers. The following component information is kept: component ID, name, description, quantity on hand, suppliers who supply them, when and how much they supplied, and products in which they are used. On the other hand following supplier information is stored: supplier ID, name, and activation status.

---Assumptions

---A supplier can exist without providing components.
---A component does not have to be associated with a supplier. It may already have been in the inventory.
---A component does not have to be associated with a product. Not all components are used in products.
---A product cannot exist without components. 

USE Manufacturer;
CREATE Table	Product (
	prod_id INT IDENTITY (1, 1) PRIMARY KEY,
	prod_name VARCHAR (50),
	quantity INT 
	);

	
CREATE Table	Supplier (
	supp_id INT IDENTITY (1, 1) PRIMARY KEY,
	supp_name VARCHAR (50) ,
	supp_location VARCHAR(50) ,
	supp_country VARCHAR (50),
	is_active BIT
	);
	CREATE Table Component (
	comp_id INT IDENTITY (1, 1) PRIMARY KEY,
	comp_name VARCHAR (50) ,
	[description] VARCHAR(50) ,
	quantity INT
	);
	CREATE TABLE prod_comp (
	prod_id INT NOT NULL,
	comp_id INT NOT NULL,
	quantity_comp INT ,
	FOREIGN KEY (prod_id) REFERENCES Product (prod_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (comp_id) REFERENCES Component (comp_id) ON DELETE CASCADE ON UPDATE CASCADE
);
	CREATE TABLE comp_supp (
	supp_id INT NOT NULL,
	comp_id INT NOT NULL,
	order_date date ,
	quantity  int,
	FOREIGN KEY (supp_id) REFERENCES supplier (supp_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (comp_id) REFERENCES Component (comp_id) ON DELETE CASCADE ON UPDATE CASCADE
	);