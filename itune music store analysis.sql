-- Table 1: artist.csv
-- No foreign key dependencies
CREATE TABLE artist (
    artist_id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

-- Table 2: employee.csv
CREATE TABLE employee (
    employee_id SERIAL PRIMARY KEY,
    last_name VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    title VARCHAR(255),
    reports_to INTEGER,
    levels VARCHAR(255),
    birthdate TIMESTAMP, 
    hire_date TIMESTAMP, 
    address VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    country VARCHAR(255),
    postal_code VARCHAR(20),
    phone VARCHAR(50),
    fax VARCHAR(50),
    email VARCHAR(255),
    FOREIGN KEY (reports_to) REFERENCES employee(employee_id)
);
    

-- Table 3: genre.csv
-- No foreign key dependencies
CREATE TABLE genre (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

-- Table 4: media_type.csv
-- No foreign key dependencies
CREATE TABLE media_type (
    media_type_id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

-- Table 5: album.csv
-- Depends on 'artist' table
CREATE TABLE album (
    album_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist_id INTEGER NOT NULL,
    FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
);
-- Table 6: customer.csv
-- Depends on 'employee' table (for support_rep_id)
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    company VARCHAR(255),
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    state VARCHAR(255),
    country VARCHAR(255) NOT NULL,
    postal_code VARCHAR(20),
    phone VARCHAR(50),
    fax VARCHAR(50),
    email VARCHAR(255) NOT NULL,
    support_rep_id INTEGER,
    FOREIGN KEY (support_rep_id) REFERENCES employee(employee_id)
);

-- Table 7: playlist.csv
-- No foreign key dependencies
CREATE TABLE playlist (
    playlist_id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

-- Table 8: track.csv
-- Depends on 'album', 'media_type', 'genre' tables
CREATE TABLE track (
    track_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    album_id INTEGER NOT NULL,
    media_type_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    composer VARCHAR(255),
    milliseconds INTEGER NOT NULL,
    bytes INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (album_id) REFERENCES album(album_id),
    FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id),
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
);

-- Table 9: invoice.csv
-- Depends on 'customer' table
CREATE TABLE invoice (
    invoice_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    invoice_date TIMESTAMP NOT NULL,
    billing_address VARCHAR(255) NOT NULL,
    billing_city VARCHAR(255) NOT NULL,
    billing_state VARCHAR(255),
    billing_country VARCHAR(255) NOT NULL,
    billing_postal_code VARCHAR(20),
    total NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- Table 10: invoice_line.csv
-- Depends on 'invoice' and 'track' tables
CREATE TABLE invoice_line (
    invoice_line_id SERIAL PRIMARY KEY,
    invoice_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    quantity INTEGER NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id),
    FOREIGN KEY (track_id) REFERENCES track(track_id)
);

-- Table 11: playlist_track.csv
-- Depends on 'playlist' and 'track' tables
CREATE TABLE playlist_track (
    playlist_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    PRIMARY KEY (playlist_id, track_id), -- Composite primary key
    FOREIGN KEY (playlist_id) REFERENCES playlist(playlist_id),
    FOREIGN KEY (track_id) REFERENCES track(track_id)
);

---senior most employee based on job title
SELECT
    first_name,
    last_name,
    title,
    hire_date
FROM
    employee
ORDER BY
    hire_date ASC
LIMIT 1;

--country which as most invoices
SELECT
    billing_country,
    COUNT(invoice_id) AS total_invoices
FROM
    invoice
GROUP BY
    billing_country
ORDER BY
    total_invoices DESC;

--Top 3 values of total invoices
SELECT
    total
FROM
    invoice
ORDER BY
    total DESC
LIMIT 3;

--city with best customer
SELECT
    billing_city,
    billing_state, -- Including state for uniqueness, as cities can have the same name in different states
    SUM(total) AS total_revenue
FROM
    invoice
GROUP BY
    billing_city,
    billing_state
ORDER BY
    total_revenue DESC
LIMIT 1;

---Best customer
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(i.total) AS total_spent
FROM
    customer AS c
JOIN
    invoice AS i ON c.customer_id = i.customer_id
GROUP BY
    c.customer_id, c.first_name, c.last_name
ORDER BY
    total_spent DESC
LIMIT 1;

----Email, first name,last name and genre of all rock music listners
SELECT DISTINCT
    c.email,
    c.first_name,
    c.last_name,
    g.name AS genre_name
FROM
    customer AS c
JOIN
    invoice AS i ON c.customer_id = i.customer_id
JOIN
    invoice_line AS il ON i.invoice_id = il.invoice_id
JOIN
    track AS t ON il.track_id = t.track_id
JOIN
    genre AS g ON t.genre_id = g.genre_id
WHERE
    g.name = 'Rock'
ORDER BY
    c.email ASC;

--the Artist name and total track count of the top 10 rock bands
SELECT
    a.name AS artist_name,
    COUNT(t.track_id) AS total_rock_tracks
FROM
    artist AS a
JOIN
    album AS al ON a.artist_id = al.artist_id
JOIN
    track AS t ON al.album_id = t.album_id
JOIN
    genre AS g ON t.genre_id = g.genre_id
WHERE
    g.name = 'Rock'
GROUP BY
    a.name
ORDER BY
    total_rock_tracks DESC
LIMIT 10;

--track names that have a song length longer than the average song length
SELECT
    name,
    milliseconds
FROM
    track
WHERE
    milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY
    milliseconds DESC;

--amount spent by each customer on artists
SELECT
    c.first_name,
    c.last_name,
    ar.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS total_spent
FROM
    customer AS c
JOIN
    invoice AS i ON c.customer_id = i.customer_id
JOIN
    invoice_line AS il ON i.invoice_id = il.invoice_id
JOIN
    track AS t ON il.track_id = t.track_id
JOIN
    album AS al ON t.album_id = al.album_id
JOIN
    artist AS ar ON al.artist_id = ar.artist_id
GROUP BY
    c.customer_id, c.first_name, c.last_name, ar.name
ORDER BY
    total_spent DESC;

--most popular music Genre for each country
WITH CountryGenrePurchases AS (
    SELECT
        i.billing_country,
        g.name AS genre_name,
        COUNT(il.invoice_line_id) AS total_purchases,
        RANK() OVER (PARTITION BY i.billing_country ORDER BY COUNT(il.invoice_line_id) DESC) as rn
    FROM
        invoice AS i
    JOIN
        invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN
        track AS t ON il.track_id = t.track_id
    JOIN
        genre AS g ON t.genre_id = g.genre_id
    GROUP BY
        i.billing_country, g.name
)
SELECT
    billing_country,
    genre_name,
    total_purchases
FROM
    CountryGenrePurchases
WHERE
    rn = 1
ORDER BY
    billing_country, genre_name;
--customer that has spent the most on music for each country

WITH CustomerSpendingByCountry AS (
    SELECT
        i.billing_country,
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(i.total) AS total_spent,
        RANK() OVER (PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) as rn
    FROM
        customer AS c
    JOIN
        invoice AS i ON c.customer_id = i.customer_id
    GROUP BY
        i.billing_country, c.customer_id, c.first_name, c.last_name
)
SELECT
    billing_country,
    first_name,
    last_name,
    total_spent
FROM
    CustomerSpendingByCountry
WHERE
    rn = 1
ORDER BY
    billing_country, total_spent DESC, first_name, last_name;
--Most Popular artist
SELECT
    ar.name AS artist_name,
    COUNT(il.track_id) AS total_tracks_sold
FROM
    artist AS ar
JOIN
    album AS al ON ar.artist_id = al.artist_id
JOIN
    track AS t ON al.album_id = t.album_id
JOIN
    invoice_line AS il ON t.track_id = il.track_id
GROUP BY
    ar.name
ORDER BY
    total_tracks_sold DESC;

--Most Popular Songs
SELECT
    t.name AS track_name,
    COUNT(il.invoice_line_id) AS times_purchased
FROM
    track AS t
JOIN
    invoice_line AS il ON t.track_id = il.track_id
GROUP BY
    t.name
ORDER BY
    times_purchased DESC
LIMIT 1;

--average prices of different types of music
--By Genre
SELECT
    g.name AS genre_name,
    AVG(t.unit_price) AS average_price_per_track
FROM
    genre AS g
JOIN
    track AS t ON g.genre_id = t.genre_id
GROUP BY
    g.name
ORDER BY
    average_price_per_track DESC;
---By media type
SELECT
    mt.name AS media_type_name,
    AVG(t.unit_price) AS average_price_per_track
FROM
    media_type AS mt
JOIN
    track AS t ON mt.media_type_id = t.media_type_id
GROUP BY
    mt.name
ORDER BY
    average_price_per_track DESC;

--By Total Revenue
SELECT
    billing_country,
    SUM(total) AS total_revenue
FROM
    invoice
GROUP BY
    billing_country
ORDER BY
    total_revenue DESC;
--BY No. of Purchases/Invoices
SELECT
    billing_country,
    COUNT(invoice_id) AS total_invoices
FROM
    invoice
GROUP BY
    billing_country
ORDER BY
    total_invoices DESC;



