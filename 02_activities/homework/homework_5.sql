-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

SELECT vendor_name, product_name, SUM(purchase_per_product) as money_per_product
FROM(
	SELECT DISTINCT vendor_id, product_id, original_price, (original_price * 5) as purchase_per_product, customer_id
	FROM vendor_inventory
	CROSS JOIN customer
	ORDER BY vendor_id, product_id
	) AS x
INNER JOIN vendor as v
ON x.vendor_id = v.vendor_id
INNER JOIN product as p
ON x.product_id = p.product_id
GROUP BY x.vendor_id, x.product_id;

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

CREATE TEMP TABLE product_units as
SELECT *,
	CURRENT_TIMESTAMP as snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units (product_id, product_name, product_size, product_category, product_qty, snapshot_timestamp)
VALUES(11, 'Pears', 'large',  1, 'kg' , CURRENT_TIMESTAMP),
	  (12, 'Plums', 'small',  1, 'kg' , CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE product_id in (11, 12);

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;

UPDATE product_units
SET current_quantity = (
    SELECT COALESCE(vi.quantity, 0) as current_quantity
    FROM (
        SELECT product_id, quantity,
            ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY market_date DESC) as rn
        FROM vendor_inventory
    ) vi
    WHERE vi.product_id = product_units.product_id AND vi.rn = 1
)
WHERE product_id IN (
    SELECT product_id
    FROM vendor_inventory
);
