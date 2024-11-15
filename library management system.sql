create database library2;
use library2;
--- drop database library2;

CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(255) NOT NULL,
    Country VARCHAR(100),
    BirthYear INT
);

CREATE TABLE Books (
    BookID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(255) NOT NULL,
    AuthorID INT,
    genre VARCHAR(50),
    ISBN VARCHAR(20),
    price DECIMAL(10, 2),
    PublicationYear year,
    Publisher VARCHAR(100),
    AvailableCopies INT DEFAULT 1,
    TotalCopies INT,
    check (AvailableCopies <= TotalCopies),
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
);

CREATE TABLE users (
    userID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(100),
    PhoneNumber VARCHAR(20),
    MembershipDate DATE
);

CREATE TABLE Loans (
    LoanID INT PRIMARY KEY AUTO_INCREMENT,
    BookID INT,
    userID INT,
    status ENUM('Checked Out', 'Returned') DEFAULT 'Checked Out',
    LoanDate DATE,
    DueDate DATE,
    ReturnDate DATE,
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (userID) REFERENCES users(userID)
);

INSERT INTO Authors (Name, Country, BirthYear) 
VALUES ('J.K. Rowling', 'UK', 1965), 
       ('George Orwell', 'UK', 1903);

       
INSERT INTO Books (Title, AuthorID, ISBN,genre, PublicationYear, Publisher, TotalCopies, AvailableCopies, price) 
VALUES ('Harry Potter and the Sorcerer''s Stone', 1, '978-3-16-148410-0','Fantasy', 1997, 'Bloomsbury', 5, 5,100.00),
       ('1984', 2, '978-0-452-28423-4','Dystopian', 1949, 'Secker & Warburg', 3, 3,149.99);
       
INSERT INTO users (Name, Email, PhoneNumber, MembershipDate) 
VALUES ('John Doe', 'john.doe@example.com', '123-456-7890', '2023-01-10'),
       ('Jane Smith', 'jane.smith@example.com', '234-567-8901', '2023-02-15');
       
-- borrow a book    
DELIMITER //

CREATE PROCEDURE InsertLoanAndUpdateCopies (
    IN p_BookID INT,
    IN p_userID INT
)
BEGIN
    START TRANSACTION;

    -- Insert new loan record
    INSERT INTO Loans (BookID, userID, LoanDate, DueDate)
    VALUES (p_BookID, p_userID, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY));

    -- Update available copies in Books table
    UPDATE Books
    SET AvailableCopies = AvailableCopies - 1
    WHERE BookID = p_BookID;

    COMMIT;
END //

DELIMITER ;

CALL InsertLoanAndUpdateCopies(1, 1);

--- DROP PROCEDURE IF EXISTS InsertLoanAndUpdateCopies;
--- TRUNCATE table loans;


-- return a book
UPDATE Loans
JOIN Books ON Loans.BookID = Books.BookID
SET Loans.ReturnDate = CURDATE(),
    Books.AvailableCopies = Books.AvailableCopies + 1
WHERE Loans.LoanID = 1;

-- check available book
SELECT Title, AvailableCopies 
FROM Books 
WHERE AvailableCopies > 0;

-- list of books barrowed
SELECT Books.Title, Loans.LoanDate, Loans.DueDate 
FROM Loans
JOIN Books ON Loans.BookID = Books.BookID
WHERE Loans.userID = 1 AND Loans.ReturnDate IS NULL;

-- Count Currently Borrowed Books
SELECT COUNT(*) AS CurrentlyBorrowedBooks
FROM Loans
WHERE ReturnDate IS NULL;

-- Count Total Books Borrowed
SELECT COUNT(*) AS TotalBorrowedBooks
FROM Loans;

-- add a copy of book
UPDATE Books
SET AvailableCopies = AvailableCopies + 1,
    TotalCopies = TotalCopies + 1
WHERE BookID = 1;

-- delete a copy of book
UPDATE Books
SET AvailableCopies = AvailableCopies - 1,
    TotalCopies = TotalCopies - 1
WHERE BookID = 1;


--- SELECT DISTINCT
SELECT DISTINCT genre FROM books;

--- ORDER BY
SELECT title, price FROM books ORDER BY price DESC;

-- Aggregate Functions,Aliases
SELECT ROUND(AVG(price), 2) AS avg_price FROM books;

-- LIKE, Wildcards
SELECT title FROM books WHERE title LIKE '%Harry%';

--  BETWEEN, NOT BETWEEN
SELECT title, PublicationYear FROM books WHERE PublicationYear BETWEEN 1900 AND 2000;
SELECT title, PublicationYear FROM books WHERE PublicationYear NOT BETWEEN 1900 AND 2000;

-- join
SELECT b.title, a.name AS author_name
FROM books b
JOIN authors a ON b.AuthorID = a.AuthorID;

-- union operator
SELECT name, email,PhoneNumber FROM users
UNION
SELECT name, email,PhoneNumber FROM users WHERE userid IN (SELECT userid FROM loans);

-- Group By, HAVING Clause
SELECT u.name, COUNT(l.LoanID) AS num_books
FROM users u
JOIN loans l ON u.userID = l.userID
GROUP BY u.name
HAVING COUNT(l.LoanID) > 1;

-- EXISTS Operator
SELECT title FROM books b
WHERE EXISTS (SELECT 1 FROM loans l WHERE l.bookid = b.bookid);

-- ifnull ,isnull
SELECT title, IFNULL(returndate, 'Not Returned Yet') AS status FROM loans l
JOIN books b ON l.bookid = b.bookid;

SELECT ISNULL(returndate) FROM loans l;

-- view
CREATE VIEW borrowed_books AS
SELECT b.title, u.name AS name, l.LoanDate
FROM loans l
JOIN books b ON l .bookid = b.bookid
JOIN users u ON l.userid = u.userid;

SELECT * FROM borrowed_books;

 -- MOD(), ROUND(), TRUNC()

SELECT title, MOD(price, 5) AS price_remainder FROM books;

SELECT title, ROUND(price) AS rounded_price FROM books;

SELECT title, TRUNcate(price, 2) AS truncated_price FROM books;

-- Date Differences and Arithmetic
SELECT DATEDIFF(CURRENT_DATE, LoanDate) AS days_borrowed
FROM loans;
SELECT LoanDate + 7 AS RemainderDate FROM loans; 

-- roll back
START TRANSACTION;

-- Insert a borrow record
INSERT INTO loans (bookid, userid, loandate) VALUES (1, 2, CURRENT_DATE);

-- Rollback if needed
ROLLBACK;
commit;

-- Function-Based Index
CREATE INDEX idx_price_round ON books ((ROUND(price,2)));

-- current time
SELECT current_time();
SELECT current_date();
SELECT CURRENT_TIMESTAMP FROM dual;

-- limit
SELECT * FROM books
ORDER BY PublicationYear  DESC LIMIT 2;


-- Regular Expression Functions
SELECT * FROM authors WHERE name REGEXP '^J';

-- subqueries
SELECT b.title, b.AuthorID
FROM books b
WHERE b.bookid IN (
    SELECT L.bookid
    FROM Loans L
    JOIN users u ON L.loanid = u.userid
    WHERE u.name = 'John Doe' AND L.status = 'Checked Out'
);

-- case expression
UPDATE books
SET AvailableCopies = AvailableCopies + CASE 
        WHEN (SELECT status FROM loans WHERE bookid = books.bookid AND status = 'Checked Out' LIMIT 1) = 'Checked Out' 
        THEN -1 
        WHEN (SELECT status FROM loans WHERE bookid = books.bookid AND status = 'Returned' LIMIT 1) = 'Returned' 
        THEN 1 
    END
WHERE bookid = 1;  



