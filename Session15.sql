/*
 * DATABASE SETUP - SESSION 15 EXAM
 * Database: StudentManagement
 */

DROP DATABASE IF EXISTS StudentManagement;
CREATE DATABASE StudentManagement;
USE StudentManagement;

-- =============================================
-- 1. TABLE STRUCTURE
-- =============================================

CREATE TABLE Students (
    StudentID CHAR(5) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    TotalDebt DECIMAL(10,2) DEFAULT 0
);

CREATE TABLE Subjects (
    SubjectID CHAR(5) PRIMARY KEY,
    SubjectName VARCHAR(50) NOT NULL,
    Credits INT CHECK (Credits > 0)
);

CREATE TABLE Grades (
    StudentID CHAR(5),
    SubjectID CHAR(5),
    Score DECIMAL(4,2),
    PRIMARY KEY (StudentID, SubjectID),
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID)
);

CREATE TABLE GradeLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID CHAR(5),
    OldScore DECIMAL(4,2),
    NewScore DECIMAL(4,2),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. SEED DATA
-- =============================================

INSERT INTO Students VALUES
('SV01', 'Ho Khanh Linh', 5000000),
('SV03', 'Tran Thi Khanh Huyen', 0);

INSERT INTO Subjects VALUES
('SB01', 'Co so du lieu', 3),
('SB02', 'Lap trinh Java', 4),
('SB03', 'Lap trinh C', 3);

INSERT INTO Grades VALUES
('SV01', 'SB01', 8.5),
('SV03', 'SB02', 3.0);

-- =============================================
-- 3. TRIGGER
-- =============================================

DROP TRIGGER IF EXISTS tg_CheckScore;

DELIMITER $$

CREATE TRIGGER tg_CheckScore
BEFORE INSERT ON Grades
FOR EACH ROW
BEGIN
    IF NEW.Score < 0 THEN
	SET NEW.Score = 0;
    ELSEIF NEW.Score > 10 THEN
	SET NEW.Score = 10;
    END IF;
END$$

DELIMITER ;

-- =============================================
-- 4. TRANSACTION (CÂU 2)
-- =============================================

START TRANSACTION;

INSERT INTO Students (StudentID, FullName)
VALUES ('SV02', 'Ha Bich Ngoc');

UPDATE Students
SET TotalDebt = 5000000
WHERE StudentID = 'SV02';

COMMIT;
-- Câu 3 :  Để chống tiêu cực trong thi cử, mọi hành động sửa đổi điểm số cần được ghi lại. Hãy viết Trigger tên tg_LogGradeUpdate chạy sau khi cập nhật (AFTER UPDATE) trên bảng Grades.
-- Yêu cầu: Khi điểm số thay đổi, hãy tự động chèn một dòng vào bảng GradeLog với các thông tin: StudentID, OldScore (lấy từ OLD), NewScore (lấy từ NEW), và ChangeDate là thời gian hiện tại (NOW()).

DROP TRIGGER IF EXISTS tg_LogGradeUpdate;

DELIMITER $$

CREATE TRIGGER tg_LogGradeUpdate
AFTER UPDATE ON Grades
FOR EACH ROW
BEGIN
    IF OLD.Score <> NEW.Score THEN
	INSERT INTO GradeLog (StudentID, OldScore, NewScore, ChangeDate)
	VALUES (
            OLD.StudentID,
            OLD.Score,
            NEW.Score,
            NOW()
        );
    END IF;
END$$

DELIMITER ;
