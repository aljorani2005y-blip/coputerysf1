-- ============================================================
-- ملف SQL موحد لقاعدة بيانات ComLabDB (MySQL)
-- تم التحويل من SQL Server إلى MySQL مع الحفاظ على نفس المنطق والوظائف
-- ============================================================

-- إنشاء قاعدة البيانات إذا لم تكن موجودة (مع دعم اللغة العربية)
CREATE DATABASE IF NOT EXISTS ComLabDB
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ComLabDB;

-- ============================================================
-- حذف الجداول القديمة (بترتيب عكسي للعلاقات)
-- ============================================================
DROP TABLE IF EXISTS ScheduleConflicts;
DROP TABLE IF EXISTS LabSchedules;
DROP TABLE IF EXISTS TeacherSchedules;
DROP TABLE IF EXISTS Smart_Schedule_Items;
DROP TABLE IF EXISTS LabSelectedComputers;
DROP TABLE IF EXISTS SmartSchedule;
DROP TABLE IF EXISTS Smart_Schedule;
DROP TABLE IF EXISTS TableBackups;
DROP TABLE IF EXISTS CustomTables;
DROP TABLE IF EXISTS CoursePlan1;
DROP TABLE IF EXISTS ComputerDept_Curriculum;
DROP TABLE IF EXISTS Subjects;
DROP TABLE IF EXISTS comLab;

-- ============================================================
-- 1. جدول المختبرات (مع حقل lab_code فريد)
-- ============================================================
CREATE TABLE comLab (
    Lab_ID INT PRIMARY KEY AUTO_INCREMENT,
    Lab_Name NVARCHAR(100) UNIQUE,
    Supervisor NVARCHAR(100),
    Computer_Count INT NOT NULL DEFAULT 0,
    Number_of_seats INT NOT NULL DEFAULT 0,
    Basic_Software NVARCHAR(MAX),
    computer_error NVARCHAR(MAX),
    Lab_Description NVARCHAR(MAX),
    lab_code INT UNIQUE NULL,
    IsActive TINYINT(1) DEFAULT 1,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- إدراج بيانات المختبرات
INSERT INTO comLab (Lab_Name, Supervisor, Computer_Count, Number_of_seats, Basic_Software, Lab_Description, lab_code)
VALUES 
('مختبر البرمجة (1)', 'د. ايناس شحاذة', 25, 25, 'Visual Studio, VS Code, Python, C++', 'مختبر متخصص بتطوير البرمجيات', 101),
('مختبر قواعد البيانات (2)', 'م.د. محمد خوام', 30, 30, 'SQL Server, MySQL, Oracle', 'مختبر متخصص بقواعد البيانات', 102),
('مختبر الشبكات (3)', 'م.م وسام حسن', 20, 20, 'Cisco Packet Tracer, Wireshark', 'مختبر متخصص بشبكات الحاسوب', 103),
('مختبر الذكاء الاصطناعي (4)', 'م. عماد مجيد', 25, 25, 'TensorFlow, PyTorch, Python', 'مختبر متخصص بالذكاء الاصطناعي', 104);

-- ============================================================
-- 2. جدول المواد الدراسية الرئيسي
-- ============================================================
CREATE TABLE Subjects (
    Subject_ID INT PRIMARY KEY AUTO_INCREMENT,
    Subject_Name NVARCHAR(200),
    Stage INT,
    Course INT,
    Theory_Hours INT DEFAULT 0,
    Practical_Hours INT DEFAULT 0,
    TotalUnits INT GENERATED ALWAYS AS (Theory_Hours + Practical_Hours) STORED,
    Teacher_Name NVARCHAR(100),
    Practical_Teacher NVARCHAR(100),
    Lab_ID INT NULL,
    IsActive TINYINT(1) DEFAULT 1,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (Lab_ID) REFERENCES comLab(Lab_ID) ON DELETE SET NULL
) ENGINE=InnoDB;

ALTER TABLE Subjects ADD CONSTRAINT UQ_Subjects_Stage_Course_Name UNIQUE (Subject_Name, Stage, Course);

-- ============================================================
-- 3. جدول الخطة الدراسية (كما في ملف Excel)
-- ============================================================
CREATE TABLE ComputerDept_Curriculum (
    ID INT PRIMARY KEY,
    Subject_Ar NVARCHAR(255) NOT NULL,
    Subject_En NVARCHAR(255),
    Theoretical INT DEFAULT 0,
    Practical INT DEFAULT 0,
    Total_Units INT,
    Subject_Level NVARCHAR(50),
    Teaching_Lang NVARCHAR(50),
    Instructor NVARCHAR(255),
    Stage NVARCHAR(50),
    Semester NVARCHAR(50)
) ENGINE=InnoDB;

ALTER TABLE ComputerDept_Curriculum ADD CONSTRAINT UQ_Curriculum_Stage_Semester_Subject UNIQUE (Stage, Semester, Subject_Ar);

-- إدراج البيانات الكاملة للخطة الدراسية (جميع المراحل والفصول)
INSERT INTO ComputerDept_Curriculum (ID, Subject_Ar, Subject_En, Theoretical, Practical, Total_Units, Subject_Level, Teaching_Lang, Instructor, Stage, Semester) VALUES 
-- المرحلة الأولى - الفصل الأول
(1, 'البرمجة بلغة C++', 'Programming using C++', 2, 3, 5, 'تخصصية', 'انكليزي', 'م. حيدر غناوي علوان', 'المرحلة الأولى', 'الفصل الأول'),
(2, 'اساسيات قواعد البيانات', 'Databases Essentials', 2, 3, 5, 'تخصصية', 'انكليزي', 'م.د. محمد خوام احمد', 'المرحلة الأولى', 'الفصل الأول'),
(3, 'الهياكل المتقطعة', 'Discrete Structure', 2, 0, 2, 'تخصصية', 'عربي', 'م. احمد عبد العزيز إسماعيل', 'المرحلة الأولى', 'الفصل الأول'),
(4, 'تطبيقات الحاسوب', 'Computer Applications', 2, 3, 5, 'تخصصية', 'انكليزي', 'م.م عمر عبدالخالق عبدالكريم', 'المرحلة الأولى', 'الفصل الأول'),
(5, 'تصميم منطقي', 'Digital Logic Design', 1, 3, 4, 'مساعدة', 'عربي', 'م.م مخلص حسين خضر', 'المرحلة الأولى', 'الفصل الأول'),
(6, 'حقوق الانسان والديمقراطية', 'Human Rights & Democracy', 2, 0, 2, 'عامة', 'عربي', 'م.م بهاء ناظم حسان', 'المرحلة الأولى', 'الفصل الأول'),
(7, 'اللغة العربية 1', 'Arabic Language 1', 2, 0, 2, 'عامة', 'عربي', 'م. قيس عبد الرحمن جاسم', 'المرحلة الأولى', 'الفصل الأول'),
-- المرحلة الأولى - الفصل الثاني
(8, 'برمجة متقدمة C++', 'Advanced Programming using C++', 2, 3, 5, 'تخصصية', 'انكليزي', 'م. حيدر غناوي علوان', 'المرحلة الأولى', 'الفصل الثاني'),
(9, 'فيجوال بيسك . نت', 'Visual Basic .Net', 1, 3, 4, 'تخصصية', 'انكليزي', 'م.م عمر عبدالخالق عبدالكريم', 'المرحلة الأولى', 'الفصل الثاني'),
(10, 'معمارية الحاسوب', 'Computer Architecture', 1, 2, 3, 'تخصصية', 'عربي', 'م.م مخلص حسين خضر', 'المرحلة الأولى', 'الفصل الثاني'),
(11, 'اساسيات تصميم المواقع الالكترونية', 'Web Site Design', 1, 2, 3, 'تخصصية', 'انكليزي', 'م.م بان نجم عبد الله', 'المرحلة الأولى', 'الفصل الثاني'),
(12, 'اساسيات شبكات الحاسوب', 'Fundamentals of Computer Networks', 1, 2, 3, 'تخصصية', 'انكليزي', 'م.م وسام حسن علي', 'المرحلة الأولى', 'الفصل الثاني'),
(13, 'نظم التشغيل', 'Operating System', 2, 2, 4, 'تخصصية', 'عربي', 'م.د. محمد خوام احمد', 'المرحلة الأولى', 'الفصل الثاني'),
(14, 'اللغة الانكليزية 1', 'English Language 1', 2, 0, 2, 'عامة', 'انكليزي', 'م.م عمر عبدالخالق عبدالكريم', 'المرحلة الأولى', 'الفصل الثاني'),
-- المرحلة الثانية - الفصل الأول
(15, 'البرمجة كائنية التوجه', 'OOP', 2, 3, 5, 'تخصصية', 'عربي', 'م. حيدر غناوي علوان', 'المرحلة الثانية', 'الفصل الأول'),
(16, 'برمجة مرئية متقدمة . نت', 'Advanced Visual Programming .Net', 2, 2, 4, 'تخصصية', 'انكليزي', 'م.م عمر عبدالخالق عبدالكريم', 'المرحلة الثانية', 'الفصل الأول'),
(17, 'قواعد بيانات متقدمة', 'Advanced Databases', 2, 2, 4, 'تخصصية', 'انكليزي', 'م.د. محمد خوام احمد', 'المرحلة الثانية', 'الفصل الأول'),
(18, 'شبكات حاسوب', 'Computer Networks', 1, 2, 3, 'تخصصية', 'انكليزي', 'م.م وسام حسن علي', 'المرحلة الثانية', 'الفصل الأول'),
(19, 'اساسيات الذكاء الاصطناعي', 'Artificial Intelligence Basics', 1, 2, 3, 'مساعدة', 'عربي', 'م. عماد مجيد حميد', 'المرحلة الثانية', 'الفصل الأول'),
(20, 'اللغة العربية 2', 'Arabic Language 2', 2, 0, 2, 'عامة', 'عربي', 'م. قيس عبد الرحمن جاسم', 'المرحلة الثانية', 'الفصل الأول'),
(21, 'جرائم حزب البعث', 'Baath Party Crimes', 1, 0, 1, 'عامة', 'عربي', 'م.م بهاء ناظم حسان', 'المرحلة الثانية', 'الفصل الأول'),
(22, 'طرائق كتابة البحث', 'Research Methods', 2, 0, 2, 'عامة', 'عربي', 'م.م نور عبود جاسم', 'المرحلة الثانية', 'الفصل الأول'),
-- المرحلة الثانية - الفصل الثاني
(23, 'هياكل البيانات', 'Data Structures', 2, 2, 4, 'تخصصية', 'انكليزي', 'ا.م.د. ايناس شحاذة حسين', 'المرحلة الثانية', 'الفصل الثاني'),
(24, 'اساسيات الامن السيبراني', 'Cyber Security Basics', 1, 2, 3, 'تخصصية', 'عربي', 'م.م نور عبود جاسم', 'المرحلة الثانية', 'الفصل الثاني'),
(25, 'تصميم المواقع الالكترونية المتقدمة', 'Advanced Web Design', 1, 2, 3, 'تخصصية', 'عربي', 'م.م نور عبود جاسم', 'المرحلة الثانية', 'الفصل الثاني'),
(26, 'تطبيقات الهاتف النقال', 'Mobile Applications', 1, 2, 3, 'تخصصية', 'عربي', 'م. عماد مجيد حميد', 'المرحلة الثانية', 'الفصل الثاني'),
(27, 'وسائط متعددة', 'Multimedia', 1, 2, 3, 'تخصصية', 'عربي', 'م. حيدر غناوي علوان', 'المرحلة الثانية', 'الفصل الثاني'),
(28, 'اخلاقيات المهنة', 'Professional Ethics', 2, 0, 2, 'عامة', 'عربي', 'م.م بان نجم عبد الله', 'المرحلة الثانية', 'الفصل الثاني'),
(29, 'اللغة الانكليزية 2', 'English 2', 2, 0, 2, 'عامة', 'انكليزي', 'م. احمد عبد العزيز إسماعيل', 'المرحلة الثانية', 'الفصل الثاني'),
(30, 'مشروع البحث', 'Research Project', 0, 2, 2, 'عامة', 'عربي', NULL, 'المرحلة الثانية', 'الفصل الثاني');

-- ============================================================
-- 4. جدول خطة المقررات (نسخة احتياطية/بديلة)
-- ============================================================
CREATE TABLE CoursePlan1 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    stage NVARCHAR(50),
    semester NVARCHAR(50),
    subject_ar NVARCHAR(255),
    subject_en NVARCHAR(255),
    theoretical_hrs INT,
    practical_hrs INT,
    total_units INT,
    instructor_name NVARCHAR(255)
) ENGINE=InnoDB;

INSERT INTO CoursePlan1 (stage, semester, subject_ar, subject_en, theoretical_hrs, practical_hrs, total_units, instructor_name)
SELECT Stage, Semester, Subject_Ar, Subject_En, Theoretical, Practical, Total_Units, Instructor
FROM ComputerDept_Curriculum;

-- ============================================================
-- 5. جدول الجدول الذكي (المواعيد)
-- ============================================================
CREATE TABLE SmartSchedule (
    id INT PRIMARY KEY AUTO_INCREMENT,
    stage INT NOT NULL,
    section NVARCHAR(10) NOT NULL,
    day NVARCHAR(20) NOT NULL,
    time_slot NVARCHAR(30) NOT NULL,
    subject_id INT NULL,
    subject_name NVARCHAR(200) NOT NULL,
    teacher NVARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX IX_SmartSchedule_Stage ON SmartSchedule(stage);
CREATE INDEX IX_SmartSchedule_Teacher ON SmartSchedule(teacher);
CREATE INDEX IX_SmartSchedule_DayTime ON SmartSchedule(day, time_slot);
ALTER TABLE SmartSchedule ADD CONSTRAINT UQ_SmartSchedule_Cell UNIQUE (stage, section, day, time_slot);

-- ============================================================
-- 6. جدول الحاسبات المختارة في المختبر
-- ============================================================
CREATE TABLE LabSelectedComputers (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Lab_ID INT NOT NULL,
    PC_Number INT NOT NULL,
    Selected_At DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Lab_ID) REFERENCES comLab(Lab_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_Lab_PC UNIQUE (Lab_ID, PC_Number)
) ENGINE=InnoDB;

-- ============================================================
-- 7. جدول الجداول المخصصة (لحفظ أي بيانات مخصصة)
-- ============================================================
CREATE TABLE CustomTables (
    Table_ID INT PRIMARY KEY AUTO_INCREMENT,
    Table_Name NVARCHAR(100) UNIQUE,
    Table_Data NVARCHAR(MAX),
    Created_By NVARCHAR(100),
    Created_At DATETIME DEFAULT CURRENT_TIMESTAMP,
    Updated_At DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 8. جدول النسخ الاحتياطية للجداول
-- ============================================================
CREATE TABLE TableBackups (
    Backup_ID INT PRIMARY KEY AUTO_INCREMENT,
    Original_Table NVARCHAR(100),
    Backup_Table NVARCHAR(100) UNIQUE,
    Created_At DATETIME DEFAULT CURRENT_TIMESTAMP,
    Table_Data NVARCHAR(MAX),
    Backup_Reason NVARCHAR(200)
) ENGINE=InnoDB;

-- ============================================================
-- 9. جداول إضافية للمواعيد والتضارب (اختيارية)
-- ============================================================
CREATE TABLE Smart_Schedule_Items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    stage NVARCHAR(50) NOT NULL,
    semester NVARCHAR(50) NOT NULL,
    section NVARCHAR(10) NOT NULL,
    subject_ar NVARCHAR(255) NOT NULL,
    subject_en NVARCHAR(255),
    theoretical_hrs INT DEFAULT 0,
    practical_hrs INT DEFAULT 0,
    total_units INT,
    instructor_name NVARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- نسخ المواد لكل الشعب A و B
INSERT INTO Smart_Schedule_Items (stage, semester, section, subject_ar, subject_en, theoretical_hrs, practical_hrs, total_units, instructor_name)
SELECT Stage, Semester, 'A', Subject_Ar, Subject_En, Theoretical, Practical, Total_Units, Instructor
FROM ComputerDept_Curriculum
UNION ALL
SELECT Stage, Semester, 'B', Subject_Ar, Subject_En, Theoretical, Practical, Total_Units, Instructor
FROM ComputerDept_Curriculum;

CREATE TABLE ScheduleConflicts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    conflict_type NVARCHAR(50),
    conflict_description NVARCHAR(MAX),
    subject_id INT,
    conflict_with_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved TINYINT(1) DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE TeacherSchedules (
    id INT PRIMARY KEY AUTO_INCREMENT,
    teacher_name NVARCHAR(255) NOT NULL,
    day NVARCHAR(20),
    time_start TIME,
    time_end TIME,
    subject_id INT,
    lab_id INT,
    stage NVARCHAR(50),
    semester NVARCHAR(50),
    section NVARCHAR(10)
) ENGINE=InnoDB;

CREATE TABLE LabSchedules (
    id INT PRIMARY KEY AUTO_INCREMENT,
    lab_id INT,
    day NVARCHAR(20),
    time_start TIME,
    time_end TIME,
    subject_id INT,
    teacher_name NVARCHAR(255),
    stage NVARCHAR(50),
    semester NVARCHAR(50),
    section NVARCHAR(10),
    FOREIGN KEY (lab_id) REFERENCES comLab(Lab_ID)
) ENGINE=InnoDB;

-- ============================================================
-- 10. ملء جدول Subjects بناءً على الخطة الدراسية مع ربط المختبرات
-- ============================================================
INSERT INTO Subjects (Subject_Name, Stage, Course, Theory_Hours, Practical_Hours, Teacher_Name, Practical_Teacher, Lab_ID)
SELECT 
    c.Subject_Ar,
    CASE 
        WHEN c.Stage = 'المرحلة الأولى' THEN 1
        WHEN c.Stage = 'المرحلة الثانية' THEN 2
        ELSE 0
    END,
    CASE 
        WHEN c.Semester = 'الفصل الأول' THEN 1
        WHEN c.Semester = 'الفصل الثاني' THEN 2
        ELSE 0
    END,
    c.Theoretical,
    c.Practical,
    c.Instructor,
    c.Instructor,
    CASE 
        WHEN c.Subject_Ar LIKE '%قواعد%' OR c.Subject_Ar LIKE '%قاعدة%' THEN 2
        WHEN c.Subject_Ar LIKE '%شبكات%' THEN 3
        WHEN c.Subject_Ar LIKE '%ذكاء%' THEN 4
        ELSE 1   -- المختبر الافتراضي للبرمجة
    END
FROM ComputerDept_Curriculum c
WHERE NOT EXISTS (
    SELECT 1 FROM Subjects s 
    WHERE s.Subject_Name = c.Subject_Ar 
      AND s.Stage = CASE WHEN c.Stage = 'المرحلة الأولى' THEN 1 ELSE 2 END
      AND s.Course = CASE WHEN c.Semester = 'الفصل الأول' THEN 1 ELSE 2 END
);

-- ============================================================
-- 11. إنشاء الفهارس لتحسين الأداء
-- ============================================================
CREATE INDEX IX_Subjects_Stage ON Subjects(Stage, Course);
CREATE INDEX IX_Subjects_Teacher ON Subjects(Teacher_Name);
CREATE INDEX IX_Curriculum_Stage ON ComputerDept_Curriculum(Stage, Semester);
CREATE INDEX IX_CoursePlan_Stage ON CoursePlan1(stage, semester);
CREATE INDEX IX_SmartScheduleItems_Stage ON Smart_Schedule_Items(stage, semester, section);
CREATE INDEX IX_LabSchedules_Lab ON LabSchedules(lab_id);
CREATE INDEX IX_TableBackups_Created ON TableBackups(Created_At DESC);

-- ============================================================
-- 12. الإجراءات المخزنة
-- ============================================================

DELIMITER //

-- إجراء لعرض خطة دراسة كاملة لمرحلة وفصل معين
CREATE PROCEDURE sp_GetStudyPlan(
    IN p_Stage NVARCHAR(50),
    IN p_Semester NVARCHAR(50)
)
BEGIN
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ID) as `ت`,
        Subject_Ar as `اسم المادة (عربي)`,
        Subject_En as `اسم المادة (انكليزي)`,
        Theoretical as `ن`,
        Practical as `ع`,
        Total_Units as `المجموع`,
        Instructor as `مدرس المادة`
    FROM ComputerDept_Curriculum
    WHERE Stage = p_Stage AND Semester = p_Semester
    ORDER BY ID;
END //

-- إجراء لإحصائيات المواد حسب المرحلة والفصل
CREATE PROCEDURE sp_GetSubjectStatistics()
BEGIN
    SELECT 
        Stage,
        Semester,
        COUNT(*) as `عدد المواد`,
        SUM(Theoretical) as `مجموع النظري`,
        SUM(Practical) as `مجموع العملي`,
        SUM(Total_Units) as `مجموع الوحدات`,
        SUM(CASE WHEN Subject_Level = 'تخصصية' THEN 1 ELSE 0 END) as `مواد تخصصية`,
        SUM(CASE WHEN Subject_Level = 'مساعدة' THEN 1 ELSE 0 END) as `مواد مساعدة`,
        SUM(CASE WHEN Subject_Level = 'عامة' THEN 1 ELSE 0 END) as `مواد عامة`
    FROM ComputerDept_Curriculum
    GROUP BY Stage, Semester
    ORDER BY Stage, Semester;
END //

-- إجراء للتحقق من تضارب المدرسين (من يدرس أكثر من 20 ساعة)
CREATE PROCEDURE sp_CheckTeacherConflicts()
BEGIN
    SELECT 
        Instructor,
        SUM(Theoretical + Practical) as TotalHours,
        COUNT(*) as SubjectCount,
        GROUP_CONCAT(Subject_Ar SEPARATOR ', ') as Subjects
    FROM ComputerDept_Curriculum
    WHERE Instructor IS NOT NULL AND Instructor != ''
    GROUP BY Instructor
    HAVING SUM(Theoretical + Practical) > 20
    ORDER BY TotalHours DESC;
END //

-- إجراءات إزالة المكررات (للصيانة)
CREATE PROCEDURE sp_RemoveDuplicateSubjects()
BEGIN
    DELETE FROM Subjects
    WHERE Subject_ID IN (
        SELECT Subject_ID FROM (
            SELECT Subject_ID,
                   ROW_NUMBER() OVER (PARTITION BY Subject_Name, Stage, Course ORDER BY Subject_ID) AS rn
            FROM Subjects
        ) AS dup WHERE rn > 1
    );
END //

CREATE PROCEDURE sp_RemoveDuplicateCurriculum()
BEGIN
    DELETE FROM ComputerDept_Curriculum
    WHERE ID IN (
        SELECT ID FROM (
            SELECT ID,
                   ROW_NUMBER() OVER (PARTITION BY Stage, Semester, Subject_Ar ORDER BY ID) AS rn
            FROM ComputerDept_Curriculum
        ) AS dup WHERE rn > 1
    );
END //

CREATE PROCEDURE sp_RemoveDuplicateLabs()
BEGIN
    DELETE FROM comLab
    WHERE Lab_ID IN (
        SELECT Lab_ID FROM (
            SELECT Lab_ID,
                   ROW_NUMBER() OVER (PARTITION BY Lab_Name ORDER BY Lab_ID) AS rn
            FROM comLab
        ) AS dup WHERE rn > 1
    );
END //

CREATE PROCEDURE sp_RemoveDuplicateSchedule()
BEGIN
    DELETE FROM SmartSchedule
    WHERE id IN (
        SELECT id FROM (
            SELECT id,
                   ROW_NUMBER() OVER (PARTITION BY stage, section, day, time_slot ORDER BY id) AS rn
            FROM SmartSchedule
        ) AS dup WHERE rn > 1
    );
END //

DELIMITER ;

-- ============================================================
-- 13. المشغلات (Triggers)
-- ============================================================

-- تحديث وقت التعديل في comLab (تم باستخدام ON UPDATE CURRENT_TIMESTAMP في تعريف الجدول، لكن نضيف تريجر للمثال)
-- ملاحظة: تم تعريف UpdatedAt مع ON UPDATE CURRENT_TIMESTAMP، لذا لا حاجة لتريجر منفصل.
-- ولكن للحفاظ على التريجر الأصلي (غير ضروري) سنقوم بإنشائه.

DELIMITER //

CREATE TRIGGER trg_comLab_Update
AFTER UPDATE ON comLab
FOR EACH ROW
BEGIN
    UPDATE comLab SET UpdatedAt = CURRENT_TIMESTAMP WHERE Lab_ID = NEW.Lab_ID;
END //

CREATE TRIGGER trg_Subjects_Update
AFTER UPDATE ON Subjects
FOR EACH ROW
BEGIN
    UPDATE Subjects SET UpdatedAt = CURRENT_TIMESTAMP WHERE Subject_ID = NEW.Subject_ID;
END //

-- منع إدراج مادة مكررة في Subjects (محاكاة لـ INSTEAD OF INSERT في MySQL)
-- ملاحظة: يوجد قيد فريد أيضاً، هذا التريجر سيمنع الإدراج ويصدر خطأ بدلاً من تجاهله بصمت.
-- السلوك الأصلي في SQL Server كان يتجاهل التكرار، لكن بسبب عدم دعم INSTEAD OF على الجداول في MySQL، تم تعديله لمنع الإدراج مع رسالة خطأ.
CREATE TRIGGER trg_PreventDuplicateSubject
BEFORE INSERT ON Subjects
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Subjects WHERE Subject_Name = NEW.Subject_Name AND Stage = NEW.Stage AND Course = NEW.Course) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate subject not allowed (Subject_Name, Stage, Course)';
    END IF;
END //

DELIMITER ;

-- ============================================================
-- 14. عرض إحصائيات أولية للتأكد
-- ============================================================
SELECT '✅ تم إنشاء قاعدة البيانات ComLabDB وجميع كائناتها بنجاح' as Status;
SELECT COUNT(*) AS `عدد المختبرات` FROM comLab;
SELECT COUNT(*) AS `عدد المواد في الخطة` FROM ComputerDept_Curriculum;
SELECT COUNT(*) AS `عدد المواد المسجلة في Subjects` FROM Subjects;
SELECT COUNT(*) AS `عدد المواد في الجداول مع الشعب` FROM Smart_Schedule_Items;

-- تشغيل إجراء الإحصائيات كاختبار
CALL sp_GetSubjectStatistics();