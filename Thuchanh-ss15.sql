DROP DATABASE IF EXISTS mini_social_network;
CREATE DATABASE mini_social_network;
USE mini_social_network;
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
CREATE TABLE Comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
CREATE TABLE Likes (
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id) ON DELETE CASCADE
);
CREATE TABLE Friends (
    user_id INT NOT NULL,
    friend_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id),
    CHECK (status IN ('pending', 'accepted')),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
DELIMITER $$

CREATE PROCEDURE sp_register_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(100)
)
BEGIN
    START TRANSACTION;

    IF EXISTS (SELECT 1 FROM Users WHERE username = p_username OR email = p_email) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Username hoặc Email đã tồn tại';
    ELSE
        INSERT INTO Users(username, password, email)
        VALUES (p_username, p_password, p_email);
        COMMIT;
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT
)
BEGIN
    INSERT INTO Posts(user_id, content)
    VALUES (p_user_id, p_content);
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE sp_user_report(IN p_user_id INT)
BEGIN
    SELECT 
        u.username,
        COUNT(DISTINCT p.post_id) AS total_posts,
        COUNT(DISTINCT l.post_id) AS total_likes,
        COUNT(DISTINCT c.comment_id) AS total_comments
    FROM Users u
    LEFT JOIN Posts p ON u.user_id = p.user_id
    LEFT JOIN Likes l ON u.user_id = l.user_id
    LEFT JOIN Comments c ON u.user_id = c.user_id
    WHERE u.user_id = p_user_id
    GROUP BY u.username;
END$$

DELIMITER ;
DELIMITER $$

CREATE TRIGGER tg_check_post_content
BEFORE INSERT ON Posts
FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.content) < 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nội dung bài viết quá ngắn';
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE TRIGGER tg_prevent_duplicate_like
BEFORE INSERT ON Likes
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM Likes
        WHERE user_id = NEW.user_id AND post_id = NEW.post_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể like trùng';
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE TRIGGER tg_check_friend_request
BEFORE INSERT ON Friends
FOR EACH ROW
BEGIN
    IF NEW.user_id = NEW.friend_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể kết bạn với chính mình';
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE TRIGGER tg_accept_friend
AFTER UPDATE ON Friends
FOR EACH ROW
BEGIN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        INSERT IGNORE INTO Friends(user_id, friend_id, status)
        VALUES (NEW.friend_id, NEW.user_id, 'accepted');
    END IF;
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE sp_delete_post(IN p_post_id INT)
BEGIN
    START TRANSACTION;

    DELETE FROM Posts WHERE post_id = p_post_id;

    COMMIT;
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE sp_delete_user(IN p_user_id INT)
BEGIN
    START TRANSACTION;

    DELETE FROM Users WHERE user_id = p_user_id;

    COMMIT;
END$$

DELIMITER ;
	CREATE VIEW vw_user_profile AS
SELECT user_id, username, email, created_at
FROM Users;
CREATE FULLTEXT INDEX idx_post_content ON Posts(content);
CALL sp_register_user('linh', '123456', 'linh@gmail.com');
CALL sp_register_user('nam', 'abcdef', 'nam@gmail.com');

CALL sp_create_post(1, 'Hello Mini Social Network');

INSERT INTO Comments(post_id, user_id, content)
VALUES (1, 2, 'Bài viết hay');

INSERT INTO Likes(user_id, post_id)
VALUES (2, 1);

INSERT INTO Friends(user_id, friend_id)
VALUES (1, 2);

UPDATE Friends SET status = 'accepted'
WHERE user_id = 1 AND friend_id = 2;

CALL sp_user_report(1);
