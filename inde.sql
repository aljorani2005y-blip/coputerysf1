-- ============================================================
-- ملف SQL موحد لقاعدة بيانات ComLabDB (SQL Server)
-- دمج وتحسين من الملفات ind.sql و inde.sql
-- ============================================================

-- إنشاء قاعدة البيانات إذا لم تكن موجودة
USE master;
GO
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ComLabDB')
BEGIN
    CREATE DATABASE ComLabDB;
END;
GO
USE ComLabDB;
GO

-- ============================================================
-- حذف الجداول القديمة (بترتيب عكسي للعلاقات)
-- ============================================================
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ScheduleConflicts') DROP TABLE ScheduleConflicts;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'LabSchedules') DROP TABLE LabSchedules;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'TeacherSchedules') DROP TABLE TeacherSchedules;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Smart_Schedule_Items') DROP TABLE Smart_Schedule_Items;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'LabSelectedComputers') DROP TABLE LabSelectedComputers;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SmartSchedule') DROP TABLE SmartSchedule;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Smart_Schedule') DROP TABLE Smart_Schedule;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'TableBackups') DROP TABLE TableBackups;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CustomTables') DROP TABLE CustomTables;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CoursePlan1') DROP TABLE CoursePlan1;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ComputerDept_Curriculum') DROP TABLE ComputerDept_Curriculum;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Subjects') DROP TABLE Subjects;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'comLab') DROP TABLE comLab;
GO

-- ============================================================
-- 1. جدول المختبرات (مع حقل lab_code فريد)
-- ============================================================
CREATE TABLE comLab (
    Lab_ID INT PRIMARY KEY IDENTITY(1,1),
    Lab_Name NVARCHAR(100) UNIQUE,
    Supervisor NVARCHAR(100),
    Computer_Count INT NOT NULL DEFAULT 0,
    Number_of_seats INT NOT NULL DEFAULT 0,
    Basic_Software NVARCHAR(MAX),
    computer_error NVARCHAR(MAX),
    Lab_Description NVARCHAR(MAX),
    lab_code INT UNIQUE NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- إدراج بيانات المختبرات
INSERT INTO comLab (Lab_Name, Supervisor, Computer_Count, Number_of_seats, Basic_Software, Lab_Description, lab_code)
VALUES 
(N'مختبر البرمجة (1)', N'د. ايناس شحاذة', 25, 25, N'Visual Studio, VS Code, Python, C++', N'مختبر متخصص بتطوير البرمجيات', 101),
(N'مختبر قواعد البيانات (2)', N'م.د. محمد خوام', 30, 30, N'SQL Server, MySQL, Oracle', N'مختبر متخصص بقواعد البيانات', 102),
(N'مختبر الشبكات (3)', N'م.م وسام حسن', 20, 20, N'Cisco Packet Tracer, Wireshark', N'مختبر متخصص بشبكات الحاسوب', 103),
(N'مختبر الذكاء الاصطناعي (4)', N'م. عماد مجيد', 25, 25, N'TensorFlow, PyTorch, Python', N'مختبر متخصص بالذكاء الاصطناعي', 104);
GO

-- ============================================================
-- 2. جدول المواد الدراسية الرئيسي
-- ============================================================
CREATE TABLE Subjects (
    Subject_ID INT PRIMARY KEY IDENTITY(1,1),
    Subject_Name NVARCHAR(200),
    Stage INT,
    Course INT,
    Theory_Hours INT DEFAULT 0,
    Practical_Hours INT DEFAULT 0,
    TotalUnits AS (Theory_Hours + Practical_Hours) PERSISTED,
    Teacher_Name NVARCHAR(100),
    Practical_Teacher NVARCHAR(100),
    Lab_ID INT NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (Lab_ID) REFERENCES comLab(Lab_ID) ON DELETE SET NULL
);
GO

ALTER TABLE Subjects ADD CONSTRAINT UQ_Subjects_Stage_Course_Name UNIQUE (Subject_Name, Stage, Course);
GO

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
);
GO

ALTER TABLE ComputerDept_Curriculum ADD CONSTRAINT UQ_Curriculum_Stage_Semester_Subject UNIQUE (Stage, Semester, Subject_Ar);
GO

-- إدراج البيانات الكاملة للخطة الدراسية (جميع المراحل والفصول)
INSERT INTO ComputerDept_Curriculum (ID, Subject_Ar, Subject_En, Theoretical, Practical, Total_Units, Subject_Level, Teaching_Lang, Instructor, Stage, Semester) VALUES 
-- المرحلة الأولى - الفصل الأول
(1, N'البرمجة بلغة C++', N'Programming using C++', 2, 3, 5, N'تخصصية', N'انكليزي', N'م. حيدر غناوي علوان', N'المرحلة الأولى', N'الفصل الأول'),
(2, N'اساسيات قواعد البيانات', N'Databases Essentials', 2, 3, 5, N'تخصصية', N'انكليزي', N'م.د. محمد خوام احمد', N'المرحلة الأولى', N'الفصل الأول'),
(3, N'الهياكل المتقطعة', N'Discrete Structure', 2, 0, 2, N'تخصصية', N'عربي', N'م. احمد عبد العزيز إسماعيل', N'المرحلة الأولى', N'الفصل الأول'),
(4, N'تطبيقات الحاسوب', N'Computer Applications', 2, 3, 5, N'تخصصية', N'انكليزي', N'م.م عمر عبدالخالق عبدالكريم', N'المرحلة الأولى', N'الفصل الأول'),
(5, N'تصميم منطقي', N'Digital Logic Design', 1, 3, 4, N'مساعدة', N'عربي', N'م.م مخلص حسين خضر', N'المرحلة الأولى', N'الفصل الأول'),
(6, N'حقوق الانسان والديمقراطية', N'Human Rights & Democracy', 2, 0, 2, N'عامة', N'عربي', N'م.م بهاء ناظم حسان', N'المرحلة الأولى', N'الفصل الأول'),
(7, N'اللغة العربية 1', N'Arabic Language 1', 2, 0, 2, N'عامة', N'عربي', N'م. قيس عبد الرحمن جاسم', N'المرحلة الأولى', N'الفصل الأول'),
-- المرحلة الأولى - الفصل الثاني
(8, N'برمجة متقدمة C++', N'Advanced Programming using C++', 2, 3, 5, N'تخصصية', N'انكليزي', N'م. حيدر غناوي علوان', N'المرحلة الأولى', N'الفصل الثاني'),
(9, N'فيجوال بيسك . نت', N'Visual Basic .Net', 1, 3, 4, N'تخصصية', N'انكليزي', N'م.م عمر عبدالخالق عبدالكريم', N'المرحلة الأولى', N'الفصل الثاني'),
(10, N'معمارية الحاسوب', N'Computer Architecture', 1, 2, 3, N'تخصصية', N'عربي', N'م.م مخلص حسين خضر', N'المرحلة الأولى', N'الفصل الثاني'),
(11, N'اساسيات تصميم المواقع الالكترونية', N'Web Site Design', 1, 2, 3, N'تخصصية', N'انكليزي', N'م.م بان نجم عبد الله', N'المرحلة الأولى', N'الفصل الثاني'),
(12, N'اساسيات شبكات الحاسوب', N'Fundamentals of Computer Networks', 1, 2, 3, N'تخصصية', N'انكليزي', N'م.م وسام حسن علي', N'المرحلة الأولى', N'الفصل الثاني'),
(13, N'نظم التشغيل', N'Operating System', 2, 2, 4, N'تخصصية', N'عربي', N'م.د. محمد خوام احمد', N'المرحلة الأولى', N'الفصل الثاني'),
(14, N'اللغة الانكليزية 1', N'English Language 1', 2, 0, 2, N'عامة', N'انكليزي', N'م.م عمر عبدالخالق عبدالكريم', N'المرحلة الأولى', N'الفصل الثاني'),
-- المرحلة الثانية - الفصل الأول
(15, N'البرمجة كائنية التوجه', N'OOP', 2, 3, 5, N'تخصصية', N'عربي', N'م. حيدر غناوي علوان', N'المرحلة الثانية', N'الفصل الأول'),
(16, N'برمجة مرئية متقدمة . نت', N'Advanced Visual Programming .Net', 2, 2, 4, N'تخصصية', N'انكليزي', N'م.م عمر عبدالخالق عبدالكريم', N'المرحلة الثانية', N'الفصل الأول'),
(17, N'قواعد بيانات متقدمة', N'Advanced Databases', 2, 2, 4, N'تخصصية', N'انكليزي', N'م.د. محمد خوام احمد', N'المرحلة الثانية', N'الفصل الأول'),
(18, N'شبكات حاسوب', N'Computer Networks', 1, 2, 3, N'تخصصية', N'انكليزي', N'م.م وسام حسن علي', N'المرحلة الثانية', N'الفصل الأول'),
(19, N'اساسيات الذكاء الاصطناعي', N'Artificial Intelligence Basics', 1, 2, 3, N'مساعدة', N'عربي', N'م. عماد مجيد حميد', N'المرحلة الثانية', N'الفصل الأول'),
(20, N'اللغة العربية 2', N'Arabic Language 2', 2, 0, 2, N'عامة', N'عربي', N'م. قيس عبد الرحمن جاسم', N'المرحلة الثانية', N'الفصل الأول'),
(21, N'جرائم حزب البعث', N'Baath Party Crimes', 1, 0, 1, N'عامة', N'عربي', N'م.م بهاء ناظم حسان', N'المرحلة الثانية', N'الفصل الأول'),
(22, N'طرائق كتابة البحث', N'Research Methods', 2, 0, 2, N'عامة', N'عربي', N'م.م نور عبود جاسم', N'المرحلة الثانية', N'الفصل الأول'),
-- المرحلة الثانية - الفصل الثاني
(23, N'هياكل البيانات', N'Data Structures', 2, 2, 4, N'تخصصية', N'انكليزي', N'ا.م.د. ايناس شحاذة حسين', N'المرحلة الثانية', N'الفصل الثاني'),
(24, N'اساسيات الامن السيبراني', N'Cyber Security Basics', 1, 2, 3, N'تخصصية', N'عربي', N'م.م نور عبود جاسم', N'المرحلة الثانية', N'الفصل الثاني'),
(25, N'تصميم المواقع الالكترونية المتقدمة', N'Advanced Web Design', 1, 2, 3, N'تخصصية', N'عربي', N'م.م نور عبود جاسم', N'المرحلة الثانية', N'الفصل الثاني'),
(26, N'تطبيقات الهاتف النقال', N'Mobile Applications', 1, 2, 3, N'تخصصية', N'عربي', N'م. عماد مجيد حميد', N'المرحلة الثانية', N'الفصل الثاني'),
(27, N'وسائط متعددة', N'Multimedia', 1, 2, 3, N'تخصصية', N'عربي', N'م. حيدر غناوي علوان', N'المرحلة الثانية', N'الفصل الثاني'),
(28, N'اخلاقيات المهنة', N'Professional Ethics', 2, 0, 2, N'عامة', N'عربي', N'م.م بان نجم عبد الله', N'المرحلة الثانية', N'الفصل الثاني'),
(29, N'اللغة الانكليزية 2', N'English 2', 2, 0, 2, N'عامة', N'انكليزي', N'م. احمد عبد العزيز إسماعيل', N'المرحلة الثانية', N'الفصل الثاني'),
(30, N'مشروع البحث', N'Research Project', 0, 2, 2, N'عامة', N'عربي', NULL, N'المرحلة الثانية', N'الفصل الثاني');
GO

-- ============================================================
-- 4. جدول خطة المقررات (نسخة احتياطية/بديلة)
-- ============================================================
CREATE TABLE CoursePlan1 (
    id INT PRIMARY KEY IDENTITY(1,1),
    stage NVARCHAR(50),
    semester NVARCHAR(50),
    subject_ar NVARCHAR(255),
    subject_en NVARCHAR(255),
    theoretical_hrs INT,
    practical_hrs INT,
    total_units INT,
    instructor_name NVARCHAR(255)
);
GO

INSERT INTO CoursePlan1 (stage, semester, subject_ar, subject_en, theoretical_hrs, practical_hrs, total_units, instructor_name)
SELECT Stage, Semester, Subject_Ar, Subject_En, Theoretical, Practical, Total_Units, Instructor
FROM ComputerDept_Curriculum;
GO

-- ============================================================
-- 5. جدول الجدول الذكي (المواعيد)
-- ============================================================
CREATE TABLE SmartSchedule (
    id INT PRIMARY KEY IDENTITY(1,1),
    stage INT NOT NULL,
    section NVARCHAR(10) NOT NULL,
    day NVARCHAR(20) NOT NULL,
    time_slot NVARCHAR(30) NOT NULL,
    subject_id INT NULL,
    subject_name NVARCHAR(200) NOT NULL,
    teacher NVARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);
GO

CREATE INDEX IX_SmartSchedule_Stage ON SmartSchedule(stage);
CREATE INDEX IX_SmartSchedule_Teacher ON SmartSchedule(teacher);
CREATE INDEX IX_SmartSchedule_DayTime ON SmartSchedule(day, time_slot);
ALTER TABLE SmartSchedule ADD CONSTRAINT UQ_SmartSchedule_Cell UNIQUE (stage, section, day, time_slot);
GO

-- ============================================================
-- 6. جدول الحاسبات المختارة في المختبر
-- ============================================================
CREATE TABLE LabSelectedComputers (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Lab_ID INT NOT NULL,
    PC_Number INT NOT NULL,
    Selected_At DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (Lab_ID) REFERENCES comLab(Lab_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_Lab_PC UNIQUE (Lab_ID, PC_Number)
);
GO

-- ============================================================
-- 7. جدول الجداول المخصصة (لحفظ أي بيانات مخصصة)
-- ============================================================
CREATE TABLE CustomTables (
    Table_ID INT PRIMARY KEY IDENTITY(1,1),
    Table_Name NVARCHAR(100) UNIQUE,
    Table_Data NVARCHAR(MAX),
    Created_By NVARCHAR(100),
    Created_At DATETIME DEFAULT GETDATE(),
    Updated_At DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================
-- 8. جدول النسخ الاحتياطية للجداول
-- ============================================================
CREATE TABLE TableBackups (
    Backup_ID INT PRIMARY KEY IDENTITY(1,1),
    Original_Table NVARCHAR(100),
    Backup_Table NVARCHAR(100) UNIQUE,
    Created_At DATETIME DEFAULT GETDATE(),
    Table_Data NVARCHAR(MAX),
    Backup_Reason NVARCHAR(200)
);
GO

-- ============================================================
-- 9. جداول إضافية للمواعيد والتضارب (اختيارية)
-- ============================================================
CREATE TABLE Smart_Schedule_Items (
    id INT PRIMARY KEY IDENTITY(1,1),
    stage NVARCHAR(50) NOT NULL,
    semester NVARCHAR(50) NOT NULL,
    section NVARCHAR(10) NOT NULL,
    subject_ar NVARCHAR(255) NOT NULL,
    subject_en NVARCHAR(255),
    theoretical_hrs INT DEFAULT 0,
    practical_hrs INT DEFAULT 0,
    total_units INT,
    instructor_name NVARCHAR(255),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);
GO

-- نسخ المواد لكل الشعب A و B
INSERT INTO Smart_Schedule_Items (stage, semester, section, subject_ar, subject_en, theoretical_hrs, practical_hrs, total_units, instructor_name)
SELECT Stage, Semester, 'A', Subject_Ar, Subject_En, Theoretical, Practical, Total_Units, Instructor
FROM ComputerDept_Curriculum
UNION ALL
SELECT Stage, Semester, 'B', Subject_Ar, Subject_En, Theoretical, Practical, Total_Units, Instructor
FROM ComputerDept_Curriculum;
GO

CREATE TABLE ScheduleConflicts (
    id INT PRIMARY KEY IDENTITY(1,1),
    conflict_type NVARCHAR(50),
    conflict_description NVARCHAR(MAX),
    subject_id INT,
    conflict_with_id INT,
    created_at DATETIME DEFAULT GETDATE(),
    resolved BIT DEFAULT 0
);
GO

CREATE TABLE TeacherSchedules (
    id INT PRIMARY KEY IDENTITY(1,1),
    teacher_name NVARCHAR(255) NOT NULL,
    day NVARCHAR(20),
    time_start TIME,
    time_end TIME,
    subject_id INT,
    lab_id INT,
    stage NVARCHAR(50),
    semester NVARCHAR(50),
    section NVARCHAR(10)
);
GO

CREATE TABLE LabSchedules (
    id INT PRIMARY KEY IDENTITY(1,1),
    lab_id INT FOREIGN KEY REFERENCES comLab(Lab_ID),
    day NVARCHAR(20),
    time_start TIME,
    time_end TIME,
    subject_id INT,
    teacher_name NVARCHAR(255),
    stage NVARCHAR(50),
    semester NVARCHAR(50),
    section NVARCHAR(10)
);
GO

-- ============================================================
-- 10. ملء جدول Subjects بناءً على الخطة الدراسية مع ربط المختبرات
-- ============================================================
INSERT INTO Subjects (Subject_Name, Stage, Course, Theory_Hours, Practical_Hours, Teacher_Name, Practical_Teacher, Lab_ID)
SELECT 
    c.Subject_Ar,
    CASE 
        WHEN c.Stage = N'المرحلة الأولى' THEN 1
        WHEN c.Stage = N'المرحلة الثانية' THEN 2
        ELSE 0
    END,
    CASE 
        WHEN c.Semester = N'الفصل الأول' THEN 1
        WHEN c.Semester = N'الفصل الثاني' THEN 2
        ELSE 0
    END,
    c.Theoretical,
    c.Practical,
    c.Instructor,
    c.Instructor,
    CASE 
        WHEN c.Subject_Ar LIKE N'%قواعد%' OR c.Subject_Ar LIKE N'%قاعدة%' THEN 2
        WHEN c.Subject_Ar LIKE N'%شبكات%' THEN 3
        WHEN c.Subject_Ar LIKE N'%ذكاء%' THEN 4
        ELSE 1   -- المختبر الافتراضي للبرمجة
    END
FROM ComputerDept_Curriculum c
WHERE NOT EXISTS (
    SELECT 1 FROM Subjects s 
    WHERE s.Subject_Name = c.Subject_Ar 
      AND s.Stage = CASE WHEN c.Stage = N'المرحلة الأولى' THEN 1 ELSE 2 END
      AND s.Course = CASE WHEN c.Semester = N'الفصل الأول' THEN 1 ELSE 2 END
);
GO

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
GO

-- ============================================================
-- 12. الإجراءات المخزنة
-- ============================================================

-- إجراء لعرض خطة دراسة كاملة لمرحلة وفصل معين
GO
CREATE PROCEDURE sp_GetStudyPlan
    @Stage NVARCHAR(50),
    @Semester NVARCHAR(50)
AS
BEGIN
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ID) as [ت],
        Subject_Ar as [اسم المادة (عربي)],
        Subject_En as [اسم المادة (انكليزي)],
        Theoretical as [ن],
        Practical as [ع],
        Total_Units as [المجموع],
        Instructor as [مدرس المادة]
    FROM ComputerDept_Curriculum
    WHERE Stage = @Stage AND Semester = @Semester
    ORDER BY ID;
END;
GO

-- إجراء لإحصائيات المواد حسب المرحلة والفصل
CREATE PROCEDURE sp_GetSubjectStatistics
AS
BEGIN
    SELECT 
        Stage,
        Semester,
        COUNT(*) as [عدد المواد],
        SUM(Theoretical) as [مجموع النظري],
        SUM(Practical) as [مجموع العملي],
        SUM(Total_Units) as [مجموع الوحدات],
        SUM(CASE WHEN Subject_Level = N'تخصصية' THEN 1 ELSE 0 END) as [مواد تخصصية],
        SUM(CASE WHEN Subject_Level = N'مساعدة' THEN 1 ELSE 0 END) as [مواد مساعدة],
        SUM(CASE WHEN Subject_Level = N'عامة' THEN 1 ELSE 0 END) as [مواد عامة]
    FROM ComputerDept_Curriculum
    GROUP BY Stage, Semester
    ORDER BY Stage, Semester;
END;
GO

-- إجراء للتحقق من تضارب المدرسين (من يدرس أكثر من 20 ساعة)
CREATE PROCEDURE sp_CheckTeacherConflicts
AS
BEGIN
    SELECT 
        Instructor,
        SUM(Theoretical + Practical) as TotalHours,
        COUNT(*) as SubjectCount,
        STRING_AGG(Subject_Ar, ', ') as Subjects
    FROM ComputerDept_Curriculum
    WHERE Instructor IS NOT NULL AND Instructor != ''
    GROUP BY Instructor
    HAVING SUM(Theoretical + Practical) > 20
    ORDER BY TotalHours DESC;
END;
GO

-- إجراءات إزالة المكررات (للصيانة)
CREATE PROCEDURE sp_RemoveDuplicateSubjects
AS
BEGIN
    SET NOCOUNT ON;
    WITH Duplicates AS (
        SELECT Subject_ID,
               ROW_NUMBER() OVER (PARTITION BY Subject_Name, Stage, Course ORDER BY Subject_ID) AS rn
        FROM Subjects
    )
    DELETE FROM Duplicates WHERE rn > 1;
END;
GO

CREATE PROCEDURE sp_RemoveDuplicateCurriculum
AS
BEGIN
    SET NOCOUNT ON;
    WITH Duplicates AS (
        SELECT ID,
               ROW_NUMBER() OVER (PARTITION BY Stage, Semester, Subject_Ar ORDER BY ID) AS rn
        FROM ComputerDept_Curriculum
    )
    DELETE FROM Duplicates WHERE rn > 1;
END;
GO

CREATE PROCEDURE sp_RemoveDuplicateLabs
AS
BEGIN
    SET NOCOUNT ON;
    WITH Duplicates AS (
        SELECT Lab_ID,
               ROW_NUMBER() OVER (PARTITION BY Lab_Name ORDER BY Lab_ID) AS rn
        FROM comLab
    )
    DELETE FROM Duplicates WHERE rn > 1;
END;
GO

CREATE PROCEDURE sp_RemoveDuplicateSchedule
AS
BEGIN
    SET NOCOUNT ON;
    WITH Duplicates AS (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY stage, section, day, time_slot ORDER BY id) AS rn
        FROM SmartSchedule
    )
    DELETE FROM Duplicates WHERE rn > 1;
END;
GO

-- ============================================================
-- 13. المشغلات (Triggers)
-- ============================================================

-- تحديث وقت التعديل في comLab
GO
CREATE TRIGGER trg_comLab_Update
ON comLab
AFTER UPDATE
AS
BEGIN
    UPDATE comLab
    SET UpdatedAt = GETDATE()
    FROM comLab c
    INNER JOIN inserted i ON c.Lab_ID = i.Lab_ID;
END;
GO

-- تحديث وقت التعديل في Subjects
CREATE TRIGGER trg_Subjects_Update
ON Subjects
AFTER UPDATE
AS
BEGIN
    UPDATE Subjects
    SET UpdatedAt = GETDATE()
    FROM Subjects s
    INNER JOIN inserted i ON s.Subject_ID = i.Subject_ID;
END;
GO

-- منع إدراج مادة مكررة في Subjects (قبل الإدراج)
CREATE TRIGGER trg_PreventDuplicateSubject
ON Subjects
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO Subjects (Subject_Name, Stage, Course, Theory_Hours, Practical_Hours, Teacher_Name, Practical_Teacher, Lab_ID, IsActive, CreatedAt, UpdatedAt)
    SELECT i.Subject_Name, i.Stage, i.Course, i.Theory_Hours, i.Practical_Hours, i.Teacher_Name, i.Practical_Teacher, i.Lab_ID, i.IsActive, i.CreatedAt, i.UpdatedAt
    FROM inserted i
    WHERE NOT EXISTS (
        SELECT 1 FROM Subjects s
        WHERE s.Subject_Name = i.Subject_Name AND s.Stage = i.Stage AND s.Course = i.Course
    );
END;
GO

-- ============================================================
-- 14. عرض إحصائيات أولية للتأكد
-- ============================================================
SELECT '✅ تم إنشاء قاعدة البيانات ComLabDB وجميع كائناتها بنجاح' as Status;
SELECT COUNT(*) AS [عدد المختبرات] FROM comLab;
SELECT COUNT(*) AS [عدد المواد في الخطة] FROM ComputerDept_Curriculum;
SELECT COUNT(*) AS [عدد المواد المسجلة في Subjects] FROM Subjects;
SELECT COUNT(*) AS [عدد المواد في الجداول مع الشعب] FROM Smart_Schedule_Items;
GO

-- تشغيل إجراء الإحصائيات كاختبار
EXEC sp_GetSubjectStatistics;
GO

