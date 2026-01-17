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
CREATE TABLE user_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    like_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
CREATE TABLE post_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT,
    action VARCHAR(100),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
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
CREATE TABLE like_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    post_id INT,
    action VARCHAR(50),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE Friends (
    user_id INT NOT NULL,
    friend_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id),
    CHECK (status IN ('pending','accepted')),
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
        INSERT INTO Users(username,password,email)
        VALUES (p_username,p_password,p_email);
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
    IF p_content IS NULL OR TRIM(p_content) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nội dung bài viết không hợp lệ';
    END IF;

    INSERT INTO Posts(user_id,content)
    VALUES (p_user_id,p_content);
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE sp_send_friend_request(
    IN p_sender INT,
    IN p_receiver INT
)
BEGIN
    IF p_sender = p_receiver THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể kết bạn với chính mình';
    END IF;

    IF EXISTS (
        SELECT 1 FROM Friends 
        WHERE user_id = p_sender AND friend_id = p_receiver
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lời mời đã tồn tại';
    END IF;

    INSERT INTO Friends(user_id,friend_id,status)
    VALUES (p_sender,p_receiver,'pending');
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE sp_remove_friend(
    IN p_user INT,
    IN p_friend INT
)
BEGIN
    START TRANSACTION;

    DELETE FROM Friends WHERE user_id = p_user AND friend_id = p_friend;
    DELETE FROM Friends WHERE user_id = p_friend AND friend_id = p_user;

    COMMIT;
END$$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE sp_delete_post(
    IN p_post_id INT,
    IN p_user_id INT
)
BEGIN
    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM Posts 
        WHERE post_id = p_post_id AND user_id = p_user_id
    ) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không có quyền xóa bài viết';
    END IF;

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
CREATE TRIGGER tg_user_register
AFTER INSERT ON Users
FOR EACH ROW
INSERT INTO user_log(user_id,action)
VALUES (NEW.user_id,'REGISTER');
CREATE TRIGGER tg_post_log
AFTER INSERT ON Posts
FOR EACH ROW
INSERT INTO post_log(post_id,action)
VALUES (NEW.post_id,'CREATE_POST');
