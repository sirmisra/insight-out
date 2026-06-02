-- ============================================================================
-- BEHEALTHY CLINIC CHAIN - COMPLETE DATABASE SETUP SCRIPT
-- ============================================================================
-- This script creates the full BeHealthy medical clinic chain dataset:
--   - Database & Schema
--   - 8 Tables with foreign keys
--   - Comprehensive sample data (~50K appointments, 2024 high / 2025 low footfall)
--   - Semantic View for Cortex Analyst
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATABASE & SCHEMA
-- ============================================================================

CREATE DATABASE IF NOT EXISTS BEHEALTHY_DB;
CREATE SCHEMA IF NOT EXISTS BEHEALTHY_DB.CLINIC_DATA;

-- ============================================================================
-- SECTION 2: TABLES
-- ============================================================================

CREATE OR REPLACE TABLE BEHEALTHY_DB.CLINIC_DATA.CLINICS (
    CLINIC_ID INT PRIMARY KEY,
    CLINIC_NAME VARCHAR(100),
    CITY VARCHAR(50),
    STATE VARCHAR(50),
    ZIP_CODE VARCHAR(10),
    ADDRESS VARCHAR(200),
    PHONE VARCHAR(20),
    EMAIL VARCHAR(100),
    CLINIC_TYPE VARCHAR(50),
    TOTAL_ROOMS INT,
    OPERATING_HOURS VARCHAR(50),
    OPENED_DATE DATE,
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    MANAGER_NAME VARCHAR(100),
    LATITUDE FLOAT,
    LONGITUDE FLOAT
);

CREATE OR REPLACE TABLE BEHEALTHY_DB.CLINIC_DATA.DEPARTMENTS (
    DEPARTMENT_ID INT PRIMARY KEY,
    CLINIC_ID INT,
    DEPARTMENT_NAME VARCHAR(100),
    HEAD_DOCTOR_ID INT,
    FLOOR_NUMBER INT,
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (CLINIC_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.CLINICS(CLINIC_ID)
);

CREATE OR REPLACE TABLE BEHEALTHY_DB.CLINIC_DATA.DOCTORS (
    DOCTOR_ID INT PRIMARY KEY,
    CLINIC_ID INT,
    DEPARTMENT_ID INT,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    SPECIALIZATION VARCHAR(100),
    QUALIFICATION VARCHAR(200),
    EXPERIENCE_YEARS INT,
    CONSULTATION_FEE DECIMAL(10,2),
    PHONE VARCHAR(20),
    EMAIL VARCHAR(100),
    GENDER VARCHAR(10),
    DATE_OF_BIRTH DATE,
    HIRE_DATE DATE,
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    RATING DECIMAL(3,2),
    FOREIGN KEY (CLINIC_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.CLINICS(CLINIC_ID)
);

CREATE OR REPLACE TABLE BEHEALTHY_DB.CLINIC_DATA.PATIENTS (
    PATIENT_ID INT PRIMARY KEY,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    DATE_OF_BIRTH DATE,
    GENDER VARCHAR(10),
    BLOOD_GROUP VARCHAR(5),
    PHONE VARCHAR(20),
    EMAIL VARCHAR(100),
    ADDRESS VARCHAR(200),
    CITY VARCHAR(50),
    STATE VARCHAR(50),
    ZIP_CODE VARCHAR(10),
    EMERGENCY_CONTACT_NAME VARCHAR(100),
    EMERGENCY_CONTACT_PHONE VARCHAR(20),
    INSURANCE_PROVIDER VARCHAR(100),
    INSURANCE_POLICY_NUMBER VARCHAR(50),
    REGISTRATION_DATE DATE,
    ALLERGIES VARCHAR(500),
    CHRONIC_CONDITIONS VARCHAR(500),
    PRIMARY_CLINIC_ID INT,
    FOREIGN KEY (PRIMARY_CLINIC_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.CLINICS(CLINIC_ID)
);

CREATE OR REPLACE TABLE BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS (
    APPOINTMENT_ID INT PRIMARY KEY,
    PATIENT_ID INT,
    DOCTOR_ID INT,
    CLINIC_ID INT,
    DEPARTMENT_ID INT,
    APPOINTMENT_DATE DATE,
    APPOINTMENT_TIME TIME,
    APPOINTMENT_TYPE VARCHAR(50),
    STATUS VARCHAR(30),
    CHECK_IN_TIME TIMESTAMP,
    CHECK_OUT_TIME TIMESTAMP,
    WAIT_TIME_MINUTES INT,
    VISIT_REASON VARCHAR(500),
    NOTES VARCHAR(1000),
    IS_FOLLOW_UP BOOLEAN DEFAULT FALSE,
    REFERRAL_SOURCE VARCHAR(100),
    FOREIGN KEY (PATIENT_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.PATIENTS(PATIENT_ID),
    FOREIGN KEY (DOCTOR_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.DOCTORS(DOCTOR_ID),
    FOREIGN KEY (CLINIC_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.CLINICS(CLINIC_ID)
);

CREATE OR REPLACE TABLE BEHEALTHY_DB.CLINIC_DATA.TREATMENTS (
    TREATMENT_ID INT PRIMARY KEY,
    APPOINTMENT_ID INT,
    PATIENT_ID INT,
    DOCTOR_ID INT,
    CLINIC_ID INT,
    TREATMENT_DATE DATE,
    DIAGNOSIS_CODE VARCHAR(20),
    DIAGNOSIS_DESCRIPTION VARCHAR(500),
    TREATMENT_TYPE VARCHAR(100),
    PROCEDURE_NAME VARCHAR(200),
    PRESCRIPTION VARCHAR(1000),
    LAB_TESTS_ORDERED VARCHAR(500),
    FOLLOW_UP_REQUIRED BOOLEAN DEFAULT FALSE,
    FOLLOW_UP_DATE DATE,
    SEVERITY VARCHAR(20),
    OUTCOME VARCHAR(50),
    FOREIGN KEY (APPOINTMENT_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS(APPOINTMENT_ID),
    FOREIGN KEY (PATIENT_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.PATIENTS(PATIENT_ID),
    FOREIGN KEY (DOCTOR_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.DOCTORS(DOCTOR_ID),
    FOREIGN KEY (CLINIC_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.CLINICS(CLINIC_ID)
);

CREATE OR REPLACE TABLE BEHEALTHY_DB.CLINIC_DATA.BILLING (
    BILL_ID INT PRIMARY KEY,
    APPOINTMENT_ID INT,
    PATIENT_ID INT,
    CLINIC_ID INT,
    BILL_DATE DATE,
    CONSULTATION_CHARGE DECIMAL(10,2),
    TREATMENT_CHARGE DECIMAL(10,2),
    LAB_CHARGE DECIMAL(10,2),
    PHARMACY_CHARGE DECIMAL(10,2),
    TOTAL_AMOUNT DECIMAL(10,2),
    INSURANCE_COVERED DECIMAL(10,2),
    DISCOUNT_AMOUNT DECIMAL(10,2),
    PATIENT_PAYABLE DECIMAL(10,2),
    PAYMENT_STATUS VARCHAR(30),
    PAYMENT_METHOD VARCHAR(30),
    PAYMENT_DATE DATE,
    INVOICE_NUMBER VARCHAR(50),
    FOREIGN KEY (APPOINTMENT_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS(APPOINTMENT_ID),
    FOREIGN KEY (PATIENT_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.PATIENTS(PATIENT_ID),
    FOREIGN KEY (CLINIC_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.CLINICS(CLINIC_ID)
);

CREATE OR REPLACE TABLE BEHEALTHY_DB.CLINIC_DATA.FEEDBACK (
    FEEDBACK_ID INT PRIMARY KEY,
    APPOINTMENT_ID INT,
    PATIENT_ID INT,
    CLINIC_ID INT,
    DOCTOR_ID INT,
    FEEDBACK_DATE DATE,
    OVERALL_RATING INT,
    DOCTOR_RATING INT,
    STAFF_RATING INT,
    FACILITY_RATING INT,
    WAIT_TIME_RATING INT,
    COMMENTS VARCHAR(1000),
    WOULD_RECOMMEND BOOLEAN,
    FEEDBACK_CATEGORY VARCHAR(50),
    FOREIGN KEY (APPOINTMENT_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS(APPOINTMENT_ID),
    FOREIGN KEY (PATIENT_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.PATIENTS(PATIENT_ID),
    FOREIGN KEY (CLINIC_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.CLINICS(CLINIC_ID),
    FOREIGN KEY (DOCTOR_ID) REFERENCES BEHEALTHY_DB.CLINIC_DATA.DOCTORS(DOCTOR_ID)
);

-- ============================================================================
-- SECTION 3: CLINICS DATA (12 clinics across 8 US cities)
-- ============================================================================

INSERT INTO BEHEALTHY_DB.CLINIC_DATA.CLINICS VALUES
(1, 'BeHealthy Downtown Manhattan', 'New York', 'New York', '10001', '245 5th Avenue', '212-555-0101', 'manhattan@behealthy.com', 'Multi-Specialty', 25, '7AM-9PM', '2018-03-15', TRUE, 'Sarah Mitchell', 40.7448, -73.9868),
(2, 'BeHealthy Brooklyn Heights', 'Brooklyn', 'New York', '11201', '120 Montague Street', '718-555-0102', 'brooklyn@behealthy.com', 'Multi-Specialty', 20, '8AM-8PM', '2019-01-10', TRUE, 'David Chen', 40.6935, -73.9925),
(3, 'BeHealthy Chicago Loop', 'Chicago', 'Illinois', '60601', '55 E Washington St', '312-555-0103', 'chicagoloop@behealthy.com', 'Multi-Specialty', 30, '7AM-9PM', '2018-06-20', TRUE, 'Maria Rodriguez', 41.8827, -87.6270),
(4, 'BeHealthy Schaumburg', 'Schaumburg', 'Illinois', '60173', '1440 E Golf Rd', '847-555-0104', 'schaumburg@behealthy.com', 'Family Care', 15, '8AM-7PM', '2020-02-01', TRUE, 'James Walker', 42.0334, -88.0834),
(5, 'BeHealthy Beverly Hills', 'Los Angeles', 'California', '90210', '9400 Brighton Way', '310-555-0105', 'beverlyhills@behealthy.com', 'Multi-Specialty', 28, '7AM-8PM', '2017-11-01', TRUE, 'Jennifer Park', 34.0696, -118.3995),
(6, 'BeHealthy Santa Monica', 'Santa Monica', 'California', '90401', '1223 Wilshire Blvd', '310-555-0106', 'santamonica@behealthy.com', 'Wellness Center', 18, '8AM-8PM', '2020-07-15', TRUE, 'Robert Kim', 34.0195, -118.4912),
(7, 'BeHealthy Houston Medical', 'Houston', 'Texas', '77030', '6550 Fannin St', '713-555-0107', 'houstonmed@behealthy.com', 'Multi-Specialty', 35, '6AM-10PM', '2017-05-10', TRUE, 'Amanda Foster', 29.7070, -95.3964),
(8, 'BeHealthy Dallas Uptown', 'Dallas', 'Texas', '75201', '2801 McKinney Ave', '214-555-0108', 'dallasuptown@behealthy.com', 'Family Care', 20, '8AM-8PM', '2019-09-01', TRUE, 'Michael Brown', 32.8021, -96.7984),
(9, 'BeHealthy Miami Beach', 'Miami', 'Florida', '33139', '450 Collins Ave', '305-555-0109', 'miamibeach@behealthy.com', 'Multi-Specialty', 22, '7AM-9PM', '2019-04-15', TRUE, 'Carlos Vega', 25.7825, -80.1324),
(10, 'BeHealthy Orlando', 'Orlando', 'Florida', '32801', '25 E Central Blvd', '407-555-0110', 'orlando@behealthy.com', 'Family Care', 16, '8AM-7PM', '2021-01-20', TRUE, 'Lisa Thompson', 28.5402, -81.3793),
(11, 'BeHealthy Seattle Capitol Hill', 'Seattle', 'Washington', '98102', '1501 Broadway', '206-555-0111', 'seattle@behealthy.com', 'Multi-Specialty', 24, '7AM-8PM', '2018-08-01', TRUE, 'Kevin Nguyen', 47.6145, -122.3210),
(12, 'BeHealthy Boston Back Bay', 'Boston', 'Massachusetts', '02116', '200 Newbury St', '617-555-0112', 'boston@behealthy.com', 'Multi-Specialty', 26, '7AM-9PM', '2018-11-15', TRUE, 'Patricia Sullivan', 42.3505, -71.0786);

-- ============================================================================
-- SECTION 4: DEPARTMENTS DATA (55 departments across 12 clinics)
-- ============================================================================

INSERT INTO BEHEALTHY_DB.CLINIC_DATA.DEPARTMENTS VALUES
(1,1,'General Medicine',NULL,1,TRUE),(2,1,'Pediatrics',NULL,1,TRUE),(3,1,'Orthopedics',NULL,2,TRUE),(4,1,'Dermatology',NULL,2,TRUE),(5,1,'Cardiology',NULL,3,TRUE),(6,1,'ENT',NULL,3,TRUE),
(7,2,'General Medicine',NULL,1,TRUE),(8,2,'Pediatrics',NULL,1,TRUE),(9,2,'Gynecology',NULL,2,TRUE),(10,2,'Dermatology',NULL,2,TRUE),
(11,3,'General Medicine',NULL,1,TRUE),(12,3,'Cardiology',NULL,1,TRUE),(13,3,'Orthopedics',NULL,2,TRUE),(14,3,'Neurology',NULL,2,TRUE),(15,3,'Pediatrics',NULL,3,TRUE),(16,3,'Oncology',NULL,3,TRUE),
(17,4,'General Medicine',NULL,1,TRUE),(18,4,'Pediatrics',NULL,1,TRUE),(19,4,'Dermatology',NULL,1,TRUE),
(20,5,'General Medicine',NULL,1,TRUE),(21,5,'Cardiology',NULL,1,TRUE),(22,5,'Dermatology',NULL,2,TRUE),(23,5,'Orthopedics',NULL,2,TRUE),(24,5,'Plastic Surgery',NULL,3,TRUE),
(25,6,'General Medicine',NULL,1,TRUE),(26,6,'Wellness & Nutrition',NULL,1,TRUE),(27,6,'Physiotherapy',NULL,1,TRUE),
(28,7,'General Medicine',NULL,1,TRUE),(29,7,'Cardiology',NULL,1,TRUE),(30,7,'Oncology',NULL,2,TRUE),(31,7,'Neurology',NULL,2,TRUE),(32,7,'Pediatrics',NULL,3,TRUE),(33,7,'Orthopedics',NULL,3,TRUE),(34,7,'Gastroenterology',NULL,4,TRUE),
(35,8,'General Medicine',NULL,1,TRUE),(36,8,'Pediatrics',NULL,1,TRUE),(37,8,'Dermatology',NULL,1,TRUE),(38,8,'ENT',NULL,2,TRUE),
(39,9,'General Medicine',NULL,1,TRUE),(40,9,'Cardiology',NULL,1,TRUE),(41,9,'Dermatology',NULL,2,TRUE),(42,9,'Orthopedics',NULL,2,TRUE),
(43,10,'General Medicine',NULL,1,TRUE),(44,10,'Pediatrics',NULL,1,TRUE),(45,10,'Dermatology',NULL,1,TRUE),
(46,11,'General Medicine',NULL,1,TRUE),(47,11,'Cardiology',NULL,1,TRUE),(48,11,'Orthopedics',NULL,2,TRUE),(49,11,'Neurology',NULL,2,TRUE),(50,11,'Pediatrics',NULL,3,TRUE),
(51,12,'General Medicine',NULL,1,TRUE),(52,12,'Cardiology',NULL,1,TRUE),(53,12,'Orthopedics',NULL,2,TRUE),(54,12,'Pediatrics',NULL,2,TRUE),(55,12,'Pulmonology',NULL,3,TRUE);

-- ============================================================================
-- SECTION 5: DOCTORS DATA (55 doctors across all clinics)
-- ============================================================================

INSERT INTO BEHEALTHY_DB.CLINIC_DATA.DOCTORS VALUES
(1,1,1,'Emily','Johnson','General Medicine','MD, FACP',15,150.00,'212-555-1001','e.johnson@behealthy.com','Female','1980-03-12','2018-03-15',TRUE,4.8),
(2,1,2,'Michael','Williams','Pediatrics','MD, FAAP',12,175.00,'212-555-1002','m.williams@behealthy.com','Male','1983-07-22','2018-04-01',TRUE,4.9),
(3,1,3,'Robert','Davis','Orthopedics','MD, FAAOS',20,250.00,'212-555-1003','r.davis@behealthy.com','Male','1975-01-15','2018-03-15',TRUE,4.7),
(4,1,4,'Sarah','Miller','Dermatology','MD, FAAD',10,200.00,'212-555-1004','s.miller@behealthy.com','Female','1985-11-30','2019-01-15',TRUE,4.6),
(5,1,5,'James','Anderson','Cardiology','MD, FACC',18,300.00,'212-555-1005','j.anderson@behealthy.com','Male','1977-06-08','2018-06-01',TRUE,4.9),
(6,1,6,'Lisa','Thomas','ENT','MD, FACS',14,200.00,'212-555-1006','l.thomas@behealthy.com','Female','1981-09-25','2019-06-01',TRUE,4.5),
(7,2,7,'David','Garcia','General Medicine','MD',8,140.00,'718-555-2001','d.garcia@behealthy.com','Male','1987-04-18','2019-01-10',TRUE,4.4),
(8,2,8,'Jessica','Martinez','Pediatrics','MD, FAAP',11,170.00,'718-555-2002','j.martinez@behealthy.com','Female','1984-12-05','2019-02-01',TRUE,4.7),
(9,2,9,'Karen','Wilson','Gynecology','MD, FACOG',16,225.00,'718-555-2003','k.wilson@behealthy.com','Female','1979-08-14','2019-03-01',TRUE,4.8),
(10,2,10,'Andrew','Taylor','Dermatology','MD',7,190.00,'718-555-2004','a.taylor@behealthy.com','Male','1988-02-28','2020-01-15',TRUE,4.3),
(11,3,11,'Richard','Hernandez','General Medicine','MD, FACP',22,160.00,'312-555-3001','r.hernandez@behealthy.com','Male','1973-05-20','2018-06-20',TRUE,4.6),
(12,3,12,'Patricia','Moore','Cardiology','MD, FACC',25,320.00,'312-555-3002','p.moore@behealthy.com','Female','1970-10-11','2018-07-01',TRUE,4.9),
(13,3,13,'Thomas','Jackson','Orthopedics','MD, FAAOS',17,240.00,'312-555-3003','t.jackson@behealthy.com','Male','1978-03-03','2018-08-01',TRUE,4.5),
(14,3,14,'Nancy','White','Neurology','MD, FAAN',19,280.00,'312-555-3004','n.white@behealthy.com','Female','1976-07-19','2019-01-15',TRUE,4.8),
(15,3,15,'Daniel','Harris','Pediatrics','MD, FAAP',13,165.00,'312-555-3005','d.harris@behealthy.com','Male','1982-11-07','2019-06-01',TRUE,4.7),
(16,3,16,'Michelle','Clark','Oncology','MD, FASCO',21,350.00,'312-555-3006','m.clark@behealthy.com','Female','1974-01-30','2019-09-01',TRUE,4.9),
(17,4,17,'Steven','Lewis','General Medicine','MD',6,130.00,'847-555-4001','s.lewis@behealthy.com','Male','1989-06-12','2020-02-01',TRUE,4.3),
(18,4,18,'Laura','Robinson','Pediatrics','MD',9,155.00,'847-555-4002','l.robinson@behealthy.com','Female','1986-04-25','2020-03-01',TRUE,4.6),
(19,4,19,'Brian','Walker','Dermatology','MD',5,180.00,'847-555-4003','b.walker@behealthy.com','Male','1990-08-15','2021-01-10',TRUE,4.2),
(20,5,20,'Jennifer','Young','General Medicine','MD, FACP',16,155.00,'310-555-5001','j.young@behealthy.com','Female','1979-09-08','2017-11-01',TRUE,4.7),
(21,5,21,'Christopher','Allen','Cardiology','MD, FACC',20,310.00,'310-555-5002','c.allen@behealthy.com','Male','1975-02-14','2018-01-15',TRUE,4.8),
(22,5,22,'Amanda','King','Dermatology','MD, FAAD',12,210.00,'310-555-5003','a.king@behealthy.com','Female','1983-06-30','2018-06-01',TRUE,4.9),
(23,5,23,'Mark','Wright','Orthopedics','MD, FAAOS',15,245.00,'310-555-5004','m.wright@behealthy.com','Male','1980-12-01','2018-03-01',TRUE,4.6),
(24,5,24,'Stephanie','Scott','Plastic Surgery','MD, FACS',14,400.00,'310-555-5005','s.scott@behealthy.com','Female','1981-10-22','2019-01-01',TRUE,4.8),
(25,6,25,'Kevin','Green','General Medicine','MD',7,135.00,'310-555-6001','k.green@behealthy.com','Male','1988-03-17','2020-07-15',TRUE,4.4),
(26,6,26,'Rachel','Adams','Wellness & Nutrition','ND, CNS',10,180.00,'310-555-6002','r.adams@behealthy.com','Female','1985-07-09','2020-08-01',TRUE,4.7),
(27,6,27,'Jason','Nelson','Physiotherapy','DPT',8,120.00,'310-555-6003','j.nelson@behealthy.com','Male','1987-11-28','2020-09-01',TRUE,4.5),
(28,7,28,'Catherine','Hill','General Medicine','MD, FACP',18,155.00,'713-555-7001','c.hill@behealthy.com','Female','1977-04-05','2017-05-10',TRUE,4.6),
(29,7,29,'Peter','Ramirez','Cardiology','MD, FACC',22,315.00,'713-555-7002','p.ramirez@behealthy.com','Male','1973-08-20','2017-06-01',TRUE,4.9),
(30,7,30,'Diana','Campbell','Oncology','MD, FASCO',24,360.00,'713-555-7003','d.campbell@behealthy.com','Female','1971-12-12','2017-07-01',TRUE,4.8),
(31,7,31,'Anthony','Mitchell','Neurology','MD, FAAN',17,275.00,'713-555-7004','a.mitchell@behealthy.com','Male','1978-02-08','2018-01-15',TRUE,4.7),
(32,7,32,'Sandra','Roberts','Pediatrics','MD, FAAP',14,170.00,'713-555-7005','s.roberts@behealthy.com','Female','1981-05-19','2018-06-01',TRUE,4.8),
(33,7,33,'George','Carter','Orthopedics','MD',11,235.00,'713-555-7006','g.carter@behealthy.com','Male','1984-09-30','2019-01-01',TRUE,4.5),
(34,7,34,'Helen','Phillips','Gastroenterology','MD, FACG',16,260.00,'713-555-7007','h.phillips@behealthy.com','Female','1979-06-14','2019-06-01',TRUE,4.7),
(35,8,35,'Frank','Evans','General Medicine','MD',9,140.00,'214-555-8001','f.evans@behealthy.com','Male','1986-01-22','2019-09-01',TRUE,4.4),
(36,8,36,'Martha','Turner','Pediatrics','MD',7,155.00,'214-555-8002','m.turner@behealthy.com','Female','1988-10-08','2019-10-01',TRUE,4.5),
(37,8,37,'Raymond','Parker','Dermatology','MD',6,185.00,'214-555-8003','r.parker@behealthy.com','Male','1989-03-15','2020-03-01',TRUE,4.3),
(38,8,38,'Betty','Collins','ENT','MD',10,195.00,'214-555-8004','b.collins@behealthy.com','Female','1985-08-27','2020-01-15',TRUE,4.6),
(39,9,39,'Henry','Stewart','General Medicine','MD, FACP',14,150.00,'305-555-9001','h.stewart@behealthy.com','Male','1981-04-30','2019-04-15',TRUE,4.5),
(40,9,40,'Dorothy','Sanchez','Cardiology','MD, FACC',19,305.00,'305-555-9002','d.sanchez@behealthy.com','Female','1976-11-16','2019-05-01',TRUE,4.8),
(41,9,41,'Arthur','Morris','Dermatology','MD, FAAD',11,200.00,'305-555-9003','a.morris@behealthy.com','Male','1984-07-03','2019-09-01',TRUE,4.6),
(42,9,42,'Gloria','Rogers','Orthopedics','MD',8,230.00,'305-555-9004','g.rogers@behealthy.com','Female','1987-02-19','2020-06-01',TRUE,4.4),
(43,10,43,'Edward','Reed','General Medicine','MD',5,125.00,'407-555-0001','e.reed@behealthy.com','Male','1990-12-10','2021-01-20',TRUE,4.2),
(44,10,44,'Virginia','Cook','Pediatrics','MD',8,150.00,'407-555-0002','v.cook@behealthy.com','Female','1987-05-25','2021-02-15',TRUE,4.5),
(45,10,45,'Philip','Morgan','Dermatology','MD',6,175.00,'407-555-0003','p.morgan@behealthy.com','Male','1989-09-18','2021-06-01',TRUE,4.3),
(46,11,46,'Ruth','Bell','General Medicine','MD, FACP',15,150.00,'206-555-1101','r.bell@behealthy.com','Female','1980-01-07','2018-08-01',TRUE,4.7),
(47,11,47,'Lawrence','Murphy','Cardiology','MD, FACC',20,310.00,'206-555-1102','l.murphy@behealthy.com','Male','1975-06-23','2018-09-01',TRUE,4.8),
(48,11,48,'Marie','Bailey','Orthopedics','MD, FAAOS',13,240.00,'206-555-1103','m.bailey@behealthy.com','Female','1982-10-14','2019-01-01',TRUE,4.6),
(49,11,49,'Carl','Rivera','Neurology','MD, FAAN',18,280.00,'206-555-1104','c.rivera@behealthy.com','Male','1977-03-29','2019-06-01',TRUE,4.7),
(50,11,50,'Joyce','Cooper','Pediatrics','MD, FAAP',11,165.00,'206-555-1105','j.cooper@behealthy.com','Female','1984-08-11','2019-09-01',TRUE,4.9),
(51,12,51,'Albert','Richardson','General Medicine','MD, FACP',17,155.00,'617-555-1201','a.richardson@behealthy.com','Male','1978-05-06','2018-11-15',TRUE,4.6),
(52,12,52,'Frances','Cox','Cardiology','MD, FACC',21,320.00,'617-555-1202','f.cox@behealthy.com','Female','1974-09-17','2018-12-01',TRUE,4.9),
(53,12,53,'Eugene','Howard','Orthopedics','MD',10,230.00,'617-555-1203','e.howard@behealthy.com','Male','1985-02-22','2019-03-01',TRUE,4.5),
(54,12,54,'Ann','Ward','Pediatrics','MD, FAAP',12,170.00,'617-555-1204','a.ward@behealthy.com','Female','1983-07-04','2019-06-15',TRUE,4.7),
(55,12,55,'Ralph','Torres','Pulmonology','MD, FCCP',16,270.00,'617-555-1205','r.torres@behealthy.com','Male','1979-11-30','2019-09-01',TRUE,4.8);

-- ============================================================================
-- SECTION 6: PATIENTS DATA (100 patients across all clinics)
-- ============================================================================

INSERT INTO BEHEALTHY_DB.CLINIC_DATA.PATIENTS VALUES
(1,'John','Smith','1985-06-15','Male','A+','212-555-2001','john.smith@email.com','123 Main St','New York','New York','10001','Mary Smith','212-555-2002','Aetna','AET-100001','2019-01-15','Penicillin','Hypertension',1),
(2,'Emma','Johnson','1990-03-22','Female','B+','212-555-2003','emma.j@email.com','456 Park Ave','New York','New York','10002','Tom Johnson','212-555-2004','BlueCross','BC-100002','2019-02-20','None','None',1),
(3,'Liam','Williams','1978-11-08','Male','O+','718-555-2005','liam.w@email.com','789 Atlantic Ave','Brooklyn','New York','11201','Sara Williams','718-555-2006','UnitedHealth','UH-100003','2019-03-10','Sulfa drugs','Type 2 Diabetes',2),
(4,'Olivia','Brown','2015-07-30','Female','A-','718-555-2007','olivia.parent@email.com','321 Court St','Brooklyn','New York','11201','Mark Brown','718-555-2008','Cigna','CIG-100004','2019-04-05','None','Asthma',2),
(5,'Noah','Jones','1965-01-20','Male','AB+','312-555-2009','noah.j@email.com','100 Michigan Ave','Chicago','Illinois','60601','Linda Jones','312-555-2010','Aetna','AET-100005','2018-07-01','Aspirin','Heart Disease, Hypertension',3),
(6,'Sophia','Davis','1992-09-14','Female','O-','312-555-2011','sophia.d@email.com','200 State St','Chicago','Illinois','60601','Jake Davis','312-555-2012','BlueCross','BC-100006','2018-08-15','None','None',3),
(7,'James','Miller','1988-04-03','Male','B-','847-555-2013','james.m@email.com','500 Golf Rd','Schaumburg','Illinois','60173','Nancy Miller','847-555-2014','UnitedHealth','UH-100007','2020-03-01','Latex','None',4),
(8,'Ava','Wilson','2018-12-25','Female','A+','847-555-2015','ava.parent@email.com','600 Roselle Rd','Schaumburg','Illinois','60173','Chris Wilson','847-555-2016','Humana','HUM-100008','2020-04-15','None','None',4),
(9,'William','Taylor','1970-08-19','Male','O+','310-555-2017','william.t@email.com','100 Rodeo Dr','Los Angeles','California','90210','Ann Taylor','310-555-2018','Kaiser','KP-100009','2018-01-10','None','Arthritis',5),
(10,'Isabella','Anderson','1995-02-14','Female','AB-','310-555-2019','isabella.a@email.com','200 Beverly Dr','Los Angeles','California','90210','Rick Anderson','310-555-2020','Anthem','ANT-100010','2018-03-20','Codeine','Eczema',5),
(11,'Benjamin','Thomas','1982-10-07','Male','A+','310-555-2021','ben.t@email.com','300 Montana Ave','Santa Monica','California','90401','Sue Thomas','310-555-2022','BlueCross','BC-100011','2020-08-01','None','Obesity',6),
(12,'Mia','Jackson','1998-05-18','Female','B+','310-555-2023','mia.j@email.com','400 Ocean Ave','Santa Monica','California','90401','Dale Jackson','310-555-2024','Aetna','AET-100012','2020-09-15','None','None',6),
(13,'Ethan','White','1958-12-30','Male','O+','713-555-2025','ethan.w@email.com','100 Fannin St','Houston','Texas','77030','Carol White','713-555-2026','UnitedHealth','UH-100013','2017-06-01','Morphine','COPD, Diabetes',7),
(14,'Charlotte','Harris','1975-03-11','Female','A-','713-555-2027','charlotte.h@email.com','200 Main St','Houston','Texas','77030','Paul Harris','713-555-2028','Cigna','CIG-100014','2017-08-15','None','Breast Cancer Survivor',7),
(15,'Alexander','Martin','2010-06-22','Male','B+','713-555-2029','alex.parent@email.com','300 Travis St','Houston','Texas','77030','Kim Martin','713-555-2030','BlueCross','BC-100015','2018-01-10','Peanuts','ADHD',7),
(16,'Amelia','Thompson','1989-07-04','Female','O-','214-555-2031','amelia.t@email.com','100 McKinney Ave','Dallas','Texas','75201','Greg Thompson','214-555-2032','Aetna','AET-100016','2019-10-01','None','None',8),
(17,'Daniel','Garcia','1972-11-28','Male','AB+','214-555-2033','daniel.g@email.com','200 Elm St','Dallas','Texas','75201','Rosa Garcia','214-555-2034','Humana','HUM-100017','2019-11-15','Ibuprofen','High Cholesterol',8),
(18,'Harper','Martinez','2016-04-09','Female','A+','305-555-2035','harper.parent@email.com','100 Collins Ave','Miami','Florida','33139','Luis Martinez','305-555-2036','BlueCross','BC-100018','2019-05-01','None','None',9),
(19,'Matthew','Robinson','1960-09-15','Male','O+','305-555-2037','matt.r@email.com','200 Ocean Dr','Miami','Florida','33139','Diane Robinson','305-555-2038','Medicare','MED-100019','2019-06-15','Penicillin','Atrial Fibrillation',9),
(20,'Evelyn','Clark','1993-01-27','Female','B-','407-555-2039','evelyn.c@email.com','100 Central Blvd','Orlando','Florida','32801','Tom Clark','407-555-2040','UnitedHealth','UH-100020','2021-02-01','None','None',10),
(21,'Henry','Rodriguez','1980-05-12','Male','A+','206-555-2041','henry.r@email.com','100 Broadway','Seattle','Washington','98102','Maria Rodriguez','206-555-2042','Premera','PRE-100021','2018-09-01','None','Hypertension',11),
(22,'Abigail','Lewis','1997-08-30','Female','O+','206-555-2043','abigail.l@email.com','200 Pine St','Seattle','Washington','98102','Jim Lewis','206-555-2044','Aetna','AET-100022','2019-01-15','Latex','None',11),
(23,'Sebastian','Lee','1968-02-14','Male','AB+','617-555-2045','seb.l@email.com','100 Newbury St','Boston','Massachusetts','02116','Helen Lee','617-555-2046','BlueCross','BC-100023','2019-01-10','None','Parkinson Disease',12),
(24,'Emily','Walker','1991-12-03','Female','B+','617-555-2047','emily.w@email.com','200 Boylston St','Boston','Massachusetts','02116','Rick Walker','617-555-2048','Tufts','TUF-100024','2019-03-20','Aspirin','None',12),
(25,'Jack','Hall','1986-07-19','Male','O-','212-555-2049','jack.h@email.com','500 Lexington Ave','New York','New York','10001','Pam Hall','212-555-2050','Aetna','AET-100025','2019-06-01','None','Migraine',1),
(26,'Ella','Allen','2012-03-08','Female','A+','212-555-2051','ella.parent@email.com','600 Madison Ave','New York','New York','10001','Bill Allen','212-555-2052','UnitedHealth','UH-100026','2019-08-15','Eggs','Asthma',1),
(27,'Owen','Young','1974-10-25','Male','B+','718-555-2053','owen.y@email.com','400 Flatbush Ave','Brooklyn','New York','11201','Jean Young','718-555-2054','Cigna','CIG-100027','2019-11-01','None','Back Pain',2),
(28,'Scarlett','Hernandez','1999-06-17','Female','O+','312-555-2055','scarlett.h@email.com','300 Wabash Ave','Chicago','Illinois','60601','Carlos Hernandez','312-555-2056','BlueCross','BC-100028','2019-04-15','None','None',3),
(29,'Lucas','King','1963-04-02','Male','A-','312-555-2057','lucas.k@email.com','400 Clark St','Chicago','Illinois','60601','Betty King','312-555-2058','Medicare','MED-100029','2018-09-01','Statins','CHF, Diabetes',3),
(30,'Grace','Wright','1987-09-11','Female','AB+','310-555-2059','grace.w@email.com','500 Wilshire Blvd','Los Angeles','California','90210','Tom Wright','310-555-2060','Anthem','ANT-100030','2018-06-01','None','Anxiety',5),
(31,'Michael','Lopez','1976-08-23','Male','A+','713-555-2061','michael.l@email.com','400 Hermann Dr','Houston','Texas','77030','Teresa Lopez','713-555-2062','BlueCross','BC-100031','2017-09-15','None','Gastric Ulcer',7),
(32,'Chloe','Hill','1994-01-16','Female','O+','713-555-2063','chloe.h@email.com','500 Holcombe Blvd','Houston','Texas','77030','Dave Hill','713-555-2064','Aetna','AET-100032','2018-02-01','Shellfish','None',7),
(33,'Jackson','Scott','2014-11-05','Male','B-','214-555-2065','jackson.parent@email.com','300 Ross Ave','Dallas','Texas','75201','Amy Scott','214-555-2066','Cigna','CIG-100033','2020-01-15','None','None',8),
(34,'Lily','Green','1983-06-28','Female','A+','305-555-2067','lily.g@email.com','300 Brickell Ave','Miami','Florida','33139','Bob Green','305-555-2068','UnitedHealth','UH-100034','2019-08-01','None','Thyroid Disorder',9),
(35,'Aiden','Adams','1971-03-15','Male','O+','206-555-2069','aiden.a@email.com','300 Capitol Hill','Seattle','Washington','98102','Sue Adams','206-555-2070','Premera','PRE-100035','2018-10-15','None','Gout',11),
(36,'Zoe','Nelson','2017-08-12','Female','AB-','617-555-2071','zoe.parent@email.com','300 Commonwealth Ave','Boston','Massachusetts','02116','Mike Nelson','617-555-2072','Tufts','TUF-100036','2019-06-01','Dairy','None',12),
(37,'Mason','Carter','1955-07-07','Male','O+','312-555-2073','mason.c@email.com','500 Dearborn St','Chicago','Illinois','60601','Dorothy Carter','312-555-2074','Medicare','MED-100037','2018-10-01','None','Prostate Cancer',3),
(38,'Aria','Mitchell','1996-04-20','Female','B+','310-555-2075','aria.m@email.com','600 Santa Monica Blvd','Santa Monica','California','90401','Joe Mitchell','310-555-2076','Kaiser','KP-100038','2020-10-01','None','None',6),
(39,'Logan','Perez','1981-11-13','Male','A-','407-555-2077','logan.p@email.com','200 Church St','Orlando','Florida','32801','Nina Perez','407-555-2078','Humana','HUM-100039','2021-04-01','Penicillin','Obesity',10),
(40,'Riley','Roberts','1988-08-05','Female','O-','206-555-2079','riley.r@email.com','400 University St','Seattle','Washington','98102','Dan Roberts','206-555-2080','Aetna','AET-100040','2019-03-01','None','Depression',11),
(41,'Carter','Turner','1967-12-22','Male','AB+','617-555-2081','carter.t@email.com','400 Tremont St','Boston','Massachusetts','02116','Barb Turner','617-555-2082','BlueCross','BC-100041','2019-08-15','None','COPD',12),
(42,'Nora','Phillips','1993-02-09','Female','A+','212-555-2083','nora.p@email.com','700 Broadway','New York','New York','10001','Sam Phillips','212-555-2084','Aetna','AET-100042','2020-01-10','None','None',1),
(43,'Caleb','Campbell','1979-09-28','Male','O+','718-555-2085','caleb.c@email.com','500 Smith St','Brooklyn','New York','11201','Jane Campbell','718-555-2086','UnitedHealth','UH-100043','2020-02-15','NSAIDs','Kidney Stones',2),
(44,'Hannah','Parker','2013-05-14','Female','B+','312-555-2087','hannah.parent@email.com','600 Rush St','Chicago','Illinois','60601','Ed Parker','312-555-2088','Cigna','CIG-100044','2019-07-01','None','None',3),
(45,'Dylan','Evans','1984-03-18','Male','A+','847-555-2089','dylan.e@email.com','700 Meacham Rd','Schaumburg','Illinois','60173','Gail Evans','847-555-2090','BlueCross','BC-100045','2020-06-01','None','Lower Back Pain',4),
(46,'Layla','Edwards','1969-10-31','Female','O+','310-555-2091','layla.e@email.com','700 Sunset Blvd','Los Angeles','California','90210','Roy Edwards','310-555-2092','Kaiser','KP-100046','2018-08-15','Codeine','Osteoporosis',5),
(47,'Luke','Collins','1990-12-07','Male','B-','713-555-2093','luke.c@email.com','600 Kirby Dr','Houston','Texas','77030','Pat Collins','713-555-2094','Cigna','CIG-100047','2018-04-01','None','None',7),
(48,'Penelope','Stewart','1977-06-21','Female','AB+','214-555-2095','penelope.s@email.com','400 Pearl St','Dallas','Texas','75201','Hank Stewart','214-555-2096','Aetna','AET-100048','2020-03-15','None','Fibromyalgia',8),
(49,'Gabriel','Sanchez','2019-02-28','Male','A+','305-555-2097','gabriel.parent@email.com','400 Lincoln Rd','Miami','Florida','33139','Rosa Sanchez','305-555-2098','BlueCross','BC-100049','2020-01-01','None','None',9),
(50,'Stella','Morris','1961-05-03','Female','O-','407-555-2099','stella.m@email.com','300 Magnolia Ave','Orlando','Florida','32801','Frank Morris','407-555-2100','Medicare','MED-100050','2021-05-01','Sulfa drugs','Diabetes, Hypertension',10);

INSERT INTO BEHEALTHY_DB.CLINIC_DATA.PATIENTS VALUES
(51,'Isaac','Rogers','1986-11-14','Male','B+','212-555-3001','isaac.r@email.com','800 7th Ave','New York','New York','10001','Wendy Rogers','212-555-3002','UnitedHealth','UH-100051','2020-03-15','None','Anxiety',1),
(52,'Victoria','Reed','1973-04-06','Female','A-','312-555-3003','victoria.r@email.com','700 Lake Shore Dr','Chicago','Illinois','60601','Tom Reed','312-555-3004','Aetna','AET-100052','2019-01-20','None','Rheumatoid Arthritis',3),
(53,'Nathan','Cook','1995-08-22','Male','O+','310-555-3005','nathan.c@email.com','800 Robertson Blvd','Los Angeles','California','90210','Liz Cook','310-555-3006','Anthem','ANT-100053','2019-05-01','None','None',5),
(54,'Aurora','Morgan','2011-01-30','Female','AB+','713-555-3007','aurora.parent@email.com','700 Texas Ave','Houston','Texas','77030','Dan Morgan','713-555-3008','BlueCross','BC-100054','2018-06-15','Peanuts','None',7),
(55,'Eli','Bell','1966-09-08','Male','O+','206-555-3009','eli.b@email.com','500 Pine St','Seattle','Washington','98102','Grace Bell','206-555-3010','Premera','PRE-100055','2019-04-01','None','Atrial Fibrillation',11),
(56,'Hazel','Murphy','1991-07-19','Female','B-','617-555-3011','hazel.m@email.com','500 Beacon St','Boston','Massachusetts','02116','Nick Murphy','617-555-3012','Tufts','TUF-100056','2019-11-15','None','None',12),
(57,'Adrian','Bailey','1980-02-25','Male','A+','718-555-3013','adrian.b@email.com','600 Prospect Pl','Brooklyn','New York','11201','Lisa Bailey','718-555-3014','Cigna','CIG-100057','2020-05-01','None','Sleep Apnea',2),
(58,'Violet','Rivera','2016-10-12','Female','O-','847-555-3015','violet.parent@email.com','800 Higgins Rd','Schaumburg','Illinois','60173','Carlos Rivera','847-555-3016','Humana','HUM-100058','2020-08-15','None','None',4),
(59,'Miles','Cooper','1957-06-04','Male','AB-','305-555-3017','miles.c@email.com','500 Biscayne Blvd','Miami','Florida','33139','Rose Cooper','305-555-3018','Medicare','MED-100059','2020-02-01','Morphine','Heart Failure',9),
(60,'Ivy','Richardson','1994-12-28','Female','A+','214-555-3019','ivy.r@email.com','500 Main St','Dallas','Texas','75201','Kevin Richardson','214-555-3020','BlueCross','BC-100060','2020-06-01','None','None',8),
(61,'Aaron','Cox','1983-03-17','Male','O+','212-555-3021','aaron.c@email.com','900 Amsterdam Ave','New York','New York','10001','Beth Cox','212-555-3022','Aetna','AET-100061','2020-07-15','None','Hypertension',1),
(62,'Clara','Howard','1976-08-09','Female','B+','312-555-3023','clara.h@email.com','800 Halsted St','Chicago','Illinois','60601','Jim Howard','312-555-3024','UnitedHealth','UH-100062','2019-09-01','Penicillin','Migraine',3),
(63,'Elijah','Ward','1989-01-31','Male','A+','310-555-3025','elijah.w@email.com','900 Pico Blvd','Santa Monica','California','90401','Ann Ward','310-555-3026','Kaiser','KP-100063','2021-01-15','None','None',6),
(64,'Ruby','Torres','2014-06-15','Female','O+','713-555-3027','ruby.parent@email.com','800 Wheeler Ave','Houston','Texas','77030','Pedro Torres','713-555-3028','Aetna','AET-100064','2019-02-01','None','Asthma',7),
(65,'Colton','Peterson','1970-11-20','Male','AB+','206-555-3029','colton.p@email.com','600 Olive Way','Seattle','Washington','98102','Sandy Peterson','206-555-3030','Premera','PRE-100065','2019-07-01','Statins','Diabetes',11),
(66,'Madeline','Gray','1997-05-04','Female','B-','617-555-3031','madeline.g@email.com','600 Huntington Ave','Boston','Massachusetts','02116','Tim Gray','617-555-3032','BlueCross','BC-100066','2020-02-01','None','None',12),
(67,'Chase','Ramirez','1964-07-27','Male','O-','718-555-3033','chase.r@email.com','700 DeKalb Ave','Brooklyn','New York','11201','Maria Ramirez','718-555-3034','Medicare','MED-100067','2020-09-15','NSAIDs','Prostate Issues',2),
(68,'Savannah','James','1992-03-13','Female','A-','847-555-3035','savannah.j@email.com','900 Woodfield Rd','Schaumburg','Illinois','60173','Bill James','847-555-3036','BlueCross','BC-100068','2021-01-01','None','None',4),
(69,'Ian','Watson','1978-10-06','Male','A+','305-555-3037','ian.w@email.com','600 Alton Rd','Miami','Florida','33139','Pat Watson','305-555-3038','UnitedHealth','UH-100069','2020-04-15','None','Hypertension',9),
(70,'Autumn','Brooks','1985-12-19','Female','O+','407-555-3039','autumn.b@email.com','400 Sand Lake Rd','Orlando','Florida','32801','Dan Brooks','407-555-3040','Humana','HUM-100070','2021-07-01','None','None',10),
(71,'Parker','Kelly','1959-04-11','Male','B+','212-555-3041','parker.k@email.com','1000 W End Ave','New York','New York','10001','Joan Kelly','212-555-3042','Medicare','MED-100071','2020-11-01','Codeine','COPD, CHF',1),
(72,'Sadie','Sanders','1996-09-02','Female','AB-','312-555-3043','sadie.s@email.com','900 Armitage Ave','Chicago','Illinois','60601','Mark Sanders','312-555-3044','Cigna','CIG-100072','2020-03-15','None','None',3),
(73,'Dominic','Price','1981-06-08','Male','O+','310-555-3045','dominic.p@email.com','1000 3rd St','Los Angeles','California','90210','Sarah Price','310-555-3046','Anthem','ANT-100073','2019-10-01','None','Sleep Apnea',5),
(74,'Bella','Bennett','2017-02-20','Female','A+','713-555-3047','bella.parent@email.com','900 San Jacinto St','Houston','Texas','77030','Kate Bennett','713-555-3048','BlueCross','BC-100074','2019-05-15','Eggs','None',7),
(75,'Levi','Wood','1974-08-14','Male','B-','206-555-3049','levi.w@email.com','700 15th Ave','Seattle','Washington','98102','Carol Wood','206-555-3050','Aetna','AET-100075','2019-11-01','None','Gout',11),
(76,'Claire','Barnes','1990-04-26','Female','O-','617-555-3051','claire.b@email.com','700 Atlantic Ave','Boston','Massachusetts','02116','Fred Barnes','617-555-3052','Tufts','TUF-100076','2020-05-01','None','None',12),
(77,'Asher','Ross','1968-01-18','Male','A+','718-555-3053','asher.r@email.com','800 4th Ave','Brooklyn','New York','11201','Linda Ross','718-555-3054','UnitedHealth','UH-100077','2021-02-15','None','Diabetes',2),
(78,'Piper','Henderson','1993-11-09','Female','AB+','305-555-3055','piper.h@email.com','700 Washington Ave','Miami','Florida','33139','Bill Henderson','305-555-3056','Aetna','AET-100078','2020-08-01','None','None',9),
(79,'Xavier','Coleman','1977-05-22','Male','O+','214-555-3057','xavier.c@email.com','600 Harwood St','Dallas','Texas','75201','Pat Coleman','214-555-3058','Cigna','CIG-100079','2020-10-15','Sulfa drugs','High Cholesterol',8),
(80,'Willow','Jenkins','2019-09-07','Female','B+','407-555-3059','willow.parent@email.com','500 Lee Rd','Orlando','Florida','32801','Tim Jenkins','407-555-3060','BlueCross','BC-100080','2021-09-01','None','None',10),
(81,'Thomas','Perry','1962-07-13','Male','A-','212-555-3061','thomas.p@email.com','1100 Riverside Dr','New York','New York','10001','Kay Perry','212-555-3062','Medicare','MED-100081','2021-01-15','None','Prostate Cancer',1),
(82,'Addison','Powell','1987-12-04','Female','O+','312-555-3063','addison.p@email.com','1000 Webster Ave','Chicago','Illinois','60601','Ray Powell','312-555-3064','BlueCross','BC-100082','2020-06-01','None','Endometriosis',3),
(83,'Wyatt','Long','1975-03-29','Male','B+','310-555-3065','wyatt.l@email.com','1100 Bundy Dr','Los Angeles','California','90210','Sue Long','310-555-3066','Kaiser','KP-100083','2020-01-15','None','Hypertension',5),
(84,'Naomi','Patterson','1998-08-16','Female','A+','713-555-3067','naomi.pa@email.com','1000 Westheimer Rd','Houston','Texas','77030','Jim Patterson','713-555-3068','Aetna','AET-100084','2019-08-01','None','None',7),
(85,'Leo','Hughes','1956-11-25','Male','O-','206-555-3069','leo.h@email.com','800 Madison St','Seattle','Washington','98102','Betty Hughes','206-555-3070','Premera','PRE-100085','2020-01-01','Penicillin','Heart Failure, COPD',11),
(86,'Elena','Flores','1992-06-30','Female','AB+','617-555-3071','elena.f@email.com','800 Boylston St','Boston','Massachusetts','02116','Tom Flores','617-555-3072','Tufts','TUF-100086','2020-08-15','None','None',12),
(87,'Cooper','Washington','1984-02-07','Male','A+','847-555-3073','cooper.w@email.com','1000 Salem Dr','Schaumburg','Illinois','60173','Jane Washington','847-555-3074','Humana','HUM-100087','2021-03-01','None','Acid Reflux',4),
(88,'Luna','Butler','2013-10-18','Female','O+','214-555-3075','luna.parent@email.com','700 Cedar Springs','Dallas','Texas','75201','Sam Butler','214-555-3076','UnitedHealth','UH-100088','2020-12-01','Dairy','None',8),
(89,'Elias','Simmons','1969-05-20','Male','B-','305-555-3077','elias.s@email.com','800 Espanola Way','Miami','Florida','33139','Rose Simmons','305-555-3078','Medicare','MED-100089','2020-11-01','None','Kidney Disease',9),
(90,'Paisley','Foster','1991-09-12','Female','A+','407-555-3079','paisley.f@email.com','600 International Dr','Orlando','Florida','32801','Dan Foster','407-555-3080','Cigna','CIG-100090','2022-01-01','None','None',10),
(91,'Lincoln','Gonzales','1980-08-03','Male','O+','212-555-3081','lincoln.g@email.com','1200 Columbus Ave','New York','New York','10001','Maria Gonzales','212-555-3082','Aetna','AET-100091','2021-04-01','None','Anxiety, Insomnia',1),
(92,'Genesis','Bryant','1973-01-15','Female','B+','718-555-3083','genesis.b@email.com','900 Sterling Pl','Brooklyn','New York','11201','Don Bryant','718-555-3084','BlueCross','BC-100092','2021-06-01','None','Osteoporosis',2),
(93,'Jaxon','Alexander','1988-06-27','Male','AB-','312-555-3085','jaxon.a@email.com','1100 Division St','Chicago','Illinois','60601','Pat Alexander','312-555-3086','UnitedHealth','UH-100093','2020-09-15','None','None',3),
(94,'Emery','Russell','2015-12-11','Female','A-','310-555-3087','emery.parent@email.com','1200 Montana Ave','Santa Monica','California','90401','Tim Russell','310-555-3088','Anthem','ANT-100094','2021-05-01','None','Eczema',6),
(95,'Ezra','Griffin','1965-03-08','Male','O-','713-555-3089','ezra.g@email.com','1100 Smith St','Houston','Texas','77030','Carol Griffin','713-555-3090','Cigna','CIG-100095','2019-10-15','Aspirin','Lung Cancer',7),
(96,'Kinsley','Diaz','1994-07-21','Female','B+','206-555-3091','kinsley.d@email.com','900 Republican St','Seattle','Washington','98102','Leo Diaz','206-555-3092','Premera','PRE-100096','2020-04-01','None','None',11),
(97,'Grayson','Hayes','1982-10-14','Male','A+','617-555-3093','grayson.h@email.com','900 Congress St','Boston','Massachusetts','02116','Val Hayes','617-555-3094','BlueCross','BC-100097','2020-11-01','None','Hypertension',12),
(98,'Isla','Myers','2018-04-25','Female','O+','214-555-3095','isla.parent@email.com','800 Swiss Ave','Dallas','Texas','75201','Kate Myers','214-555-3096','Aetna','AET-100098','2021-03-15','None','None',8),
(99,'Mateo','Ford','1971-09-16','Male','AB+','305-555-3097','mateo.f@email.com','900 Meridian Ave','Miami','Florida','33139','Sue Ford','305-555-3098','UnitedHealth','UH-100099','2021-01-01','None','Diabetes',9),
(100,'Elise','Hamilton','1986-04-30','Female','A+','407-555-3099','elise.h@email.com','700 Curry Ford Rd','Orlando','Florida','32801','Bob Hamilton','407-555-3100','Humana','HUM-100100','2022-03-01','None','None',10);

-- ============================================================================
-- SECTION 7: APPOINTMENTS DATA
-- 2024 = HIGH footfall (~28,600 appointments)
-- 2025 = LOW footfall (~21,600 appointments, ~25% decline)
-- ============================================================================

-- 2024 HIGH FOOTFALL
INSERT INTO BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS
WITH raw_data AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS RN,
        DATEADD('day', UNIFORM(0, 364, RANDOM()), '2024-01-01')::DATE AS APT_DATE,
        UNIFORM(1, 12, RANDOM()) AS CLINIC_ID,
        UNIFORM(1, 100, RANDOM()) AS PATIENT_ID,
        UNIFORM(1, 55, RANDOM()) AS DOCTOR_ID
    FROM TABLE(GENERATOR(ROWCOUNT => 40000))
)
SELECT
    RN AS APPOINTMENT_ID,
    PATIENT_ID, DOCTOR_ID, CLINIC_ID,
    NULL AS DEPARTMENT_ID,
    APT_DATE AS APPOINTMENT_DATE,
    TIMEADD('minute', 480 + UNIFORM(0, 540, RANDOM()), '00:00'::TIME) AS APPOINTMENT_TIME,
    CASE MOD(RN, 5) 
        WHEN 0 THEN 'Walk-In' WHEN 1 THEN 'Scheduled' WHEN 2 THEN 'Scheduled'
        WHEN 3 THEN 'Follow-Up' ELSE 'Urgent'
    END AS APPOINTMENT_TYPE,
    CASE MOD(ABS(HASH(RN)), 20)
        WHEN 0 THEN 'Cancelled' WHEN 1 THEN 'No-Show' ELSE 'Completed'
    END AS STATUS,
    NULL AS CHECK_IN_TIME, NULL AS CHECK_OUT_TIME,
    UNIFORM(5, 45, RANDOM()) AS WAIT_TIME_MINUTES,
    CASE MOD(ABS(HASH(RN)), 10)
        WHEN 0 THEN 'Annual Physical' WHEN 1 THEN 'Cough and Cold' WHEN 2 THEN 'Back Pain'
        WHEN 3 THEN 'Skin Rash' WHEN 4 THEN 'Follow-up Visit' WHEN 5 THEN 'Headache'
        WHEN 6 THEN 'Joint Pain' WHEN 7 THEN 'Chest Pain' WHEN 8 THEN 'Abdominal Pain'
        ELSE 'Vaccination'
    END AS VISIT_REASON,
    NULL AS NOTES,
    CASE WHEN MOD(RN, 5) = 3 THEN TRUE ELSE FALSE END AS IS_FOLLOW_UP,
    CASE MOD(RN, 4)
        WHEN 0 THEN 'Self' WHEN 1 THEN 'Doctor Referral' WHEN 2 THEN 'Online' ELSE 'Insurance'
    END AS REFERRAL_SOURCE
FROM raw_data
WHERE DAYOFWEEK(APT_DATE) NOT IN (0, 6);

-- 2025 LOW FOOTFALL (~25% decline)
INSERT INTO BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS
WITH raw_data AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS RN,
        DATEADD('day', UNIFORM(0, 364, RANDOM()), '2025-01-01')::DATE AS APT_DATE,
        UNIFORM(1, 12, RANDOM()) AS CLINIC_ID,
        UNIFORM(1, 100, RANDOM()) AS PATIENT_ID,
        UNIFORM(1, 55, RANDOM()) AS DOCTOR_ID
    FROM TABLE(GENERATOR(ROWCOUNT => 30000))
)
SELECT
    40000 + RN AS APPOINTMENT_ID,
    PATIENT_ID, DOCTOR_ID, CLINIC_ID,
    NULL AS DEPARTMENT_ID,
    APT_DATE AS APPOINTMENT_DATE,
    TIMEADD('minute', 480 + UNIFORM(0, 540, RANDOM()), '00:00'::TIME) AS APPOINTMENT_TIME,
    CASE MOD(RN, 5) 
        WHEN 0 THEN 'Walk-In' WHEN 1 THEN 'Scheduled' WHEN 2 THEN 'Scheduled'
        WHEN 3 THEN 'Follow-Up' ELSE 'Telehealth'
    END AS APPOINTMENT_TYPE,
    CASE MOD(ABS(HASH(RN)), 15)
        WHEN 0 THEN 'Cancelled' WHEN 1 THEN 'Cancelled' WHEN 2 THEN 'No-Show' ELSE 'Completed'
    END AS STATUS,
    NULL AS CHECK_IN_TIME, NULL AS CHECK_OUT_TIME,
    UNIFORM(5, 45, RANDOM()) AS WAIT_TIME_MINUTES,
    CASE MOD(ABS(HASH(RN)), 10)
        WHEN 0 THEN 'Annual Physical' WHEN 1 THEN 'Cough and Cold' WHEN 2 THEN 'Back Pain'
        WHEN 3 THEN 'Skin Rash' WHEN 4 THEN 'Follow-up Visit' WHEN 5 THEN 'Headache'
        WHEN 6 THEN 'Joint Pain' WHEN 7 THEN 'Chest Pain' WHEN 8 THEN 'Abdominal Pain'
        ELSE 'Vaccination'
    END AS VISIT_REASON,
    NULL AS NOTES,
    CASE WHEN MOD(RN, 5) = 3 THEN TRUE ELSE FALSE END AS IS_FOLLOW_UP,
    CASE MOD(RN, 4)
        WHEN 0 THEN 'Self' WHEN 1 THEN 'Doctor Referral' WHEN 2 THEN 'Online' ELSE 'Insurance'
    END AS REFERRAL_SOURCE
FROM raw_data
WHERE DAYOFWEEK(APT_DATE) NOT IN (0, 6);

-- ============================================================================
-- SECTION 8: TREATMENTS DATA (linked to completed appointments)
-- ============================================================================

INSERT INTO BEHEALTHY_DB.CLINIC_DATA.TREATMENTS
WITH completed_appts AS (
    SELECT 
        APPOINTMENT_ID, PATIENT_ID, DOCTOR_ID, CLINIC_ID, APPOINTMENT_DATE,
        ROW_NUMBER() OVER (ORDER BY APPOINTMENT_ID) AS RN
    FROM BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS
    WHERE STATUS = 'Completed'
)
SELECT
    RN AS TREATMENT_ID, APPOINTMENT_ID, PATIENT_ID, DOCTOR_ID, CLINIC_ID,
    APPOINTMENT_DATE AS TREATMENT_DATE,
    CASE MOD(RN, 12) WHEN 0 THEN 'J06.9' WHEN 1 THEN 'M54.5' WHEN 2 THEN 'I10' WHEN 3 THEN 'L30.9' WHEN 4 THEN 'R51' WHEN 5 THEN 'M25.50' WHEN 6 THEN 'R07.9' WHEN 7 THEN 'E11.9' WHEN 8 THEN 'J20.9' WHEN 9 THEN 'K21.0' WHEN 10 THEN 'N39.0' ELSE 'R10.9' END AS DIAGNOSIS_CODE,
    CASE MOD(RN, 12) WHEN 0 THEN 'Upper Respiratory Infection' WHEN 1 THEN 'Low Back Pain' WHEN 2 THEN 'Essential Hypertension' WHEN 3 THEN 'Dermatitis' WHEN 4 THEN 'Headache' WHEN 5 THEN 'Joint Pain' WHEN 6 THEN 'Chest Pain' WHEN 7 THEN 'Type 2 Diabetes' WHEN 8 THEN 'Acute Bronchitis' WHEN 9 THEN 'GERD' WHEN 10 THEN 'Urinary Tract Infection' ELSE 'Abdominal Pain' END AS DIAGNOSIS_DESCRIPTION,
    CASE MOD(RN, 5) WHEN 0 THEN 'Medication' WHEN 1 THEN 'Procedure' WHEN 2 THEN 'Therapy' WHEN 3 THEN 'Consultation' ELSE 'Diagnostic' END AS TREATMENT_TYPE,
    CASE MOD(RN, 8) WHEN 0 THEN 'Physical Examination' WHEN 1 THEN 'Blood Test' WHEN 2 THEN 'X-Ray' WHEN 3 THEN 'Prescription Medication' WHEN 4 THEN 'ECG' WHEN 5 THEN 'Wound Dressing' WHEN 6 THEN 'Ultrasound' ELSE 'Physiotherapy Session' END AS PROCEDURE_NAME,
    CASE MOD(RN, 6) WHEN 0 THEN 'Amoxicillin 500mg TID x7d' WHEN 1 THEN 'Ibuprofen 400mg PRN' WHEN 2 THEN 'Lisinopril 10mg daily' WHEN 3 THEN 'Hydrocortisone cream BID' WHEN 4 THEN 'Metformin 500mg BID' ELSE 'Omeprazole 20mg daily' END AS PRESCRIPTION,
    CASE MOD(RN, 4) WHEN 0 THEN 'CBC, BMP' WHEN 1 THEN 'Lipid Panel' WHEN 2 THEN 'HbA1c' ELSE NULL END AS LAB_TESTS_ORDERED,
    CASE WHEN MOD(RN, 3) = 0 THEN TRUE ELSE FALSE END AS FOLLOW_UP_REQUIRED,
    CASE WHEN MOD(RN, 3) = 0 THEN DATEADD('day', UNIFORM(14, 30, RANDOM()), APPOINTMENT_DATE) ELSE NULL END AS FOLLOW_UP_DATE,
    CASE MOD(RN, 4) WHEN 0 THEN 'Mild' WHEN 1 THEN 'Moderate' WHEN 2 THEN 'Mild' ELSE 'Severe' END AS SEVERITY,
    CASE MOD(RN, 5) WHEN 0 THEN 'Improved' WHEN 1 THEN 'Resolved' WHEN 2 THEN 'Stable' WHEN 3 THEN 'Under Treatment' ELSE 'Referred' END AS OUTCOME
FROM completed_appts;

-- ============================================================================
-- SECTION 9: BILLING DATA (linked to completed appointments)
-- ============================================================================

INSERT INTO BEHEALTHY_DB.CLINIC_DATA.BILLING
WITH completed_appts AS (
    SELECT 
        APPOINTMENT_ID, PATIENT_ID, CLINIC_ID, APPOINTMENT_DATE,
        ROW_NUMBER() OVER (ORDER BY APPOINTMENT_ID) AS RN
    FROM BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS
    WHERE STATUS = 'Completed'
)
SELECT
    RN AS BILL_ID, APPOINTMENT_ID, PATIENT_ID, CLINIC_ID,
    APPOINTMENT_DATE AS BILL_DATE,
    CASE WHEN CLINIC_ID IN (5, 7, 3) THEN UNIFORM(200, 400, RANDOM())::DECIMAL(10,2) ELSE UNIFORM(100, 250, RANDOM())::DECIMAL(10,2) END AS CONSULTATION_CHARGE,
    UNIFORM(0, 500, RANDOM())::DECIMAL(10,2) AS TREATMENT_CHARGE,
    CASE WHEN MOD(RN, 3) = 0 THEN UNIFORM(50, 300, RANDOM())::DECIMAL(10,2) ELSE 0 END AS LAB_CHARGE,
    UNIFORM(0, 200, RANDOM())::DECIMAL(10,2) AS PHARMACY_CHARGE,
    0 AS TOTAL_AMOUNT, 0 AS INSURANCE_COVERED, 0 AS DISCOUNT_AMOUNT, 0 AS PATIENT_PAYABLE,
    CASE MOD(RN, 6) WHEN 0 THEN 'Paid' WHEN 1 THEN 'Paid' WHEN 2 THEN 'Paid' WHEN 3 THEN 'Paid' WHEN 4 THEN 'Pending' ELSE 'Partial' END AS PAYMENT_STATUS,
    CASE MOD(RN, 5) WHEN 0 THEN 'Credit Card' WHEN 1 THEN 'Insurance' WHEN 2 THEN 'Cash' WHEN 3 THEN 'Debit Card' ELSE 'Insurance' END AS PAYMENT_METHOD,
    APPOINTMENT_DATE AS PAYMENT_DATE,
    'INV-' || LPAD(RN::VARCHAR, 8, '0') AS INVOICE_NUMBER
FROM completed_appts;

UPDATE BEHEALTHY_DB.CLINIC_DATA.BILLING
SET 
    TOTAL_AMOUNT = CONSULTATION_CHARGE + TREATMENT_CHARGE + LAB_CHARGE + PHARMACY_CHARGE,
    INSURANCE_COVERED = (CONSULTATION_CHARGE + TREATMENT_CHARGE + LAB_CHARGE + PHARMACY_CHARGE) * UNIFORM(40, 80, RANDOM()) / 100.0,
    DISCOUNT_AMOUNT = CASE WHEN MOD(BILL_ID, 10) = 0 THEN (CONSULTATION_CHARGE + TREATMENT_CHARGE + LAB_CHARGE + PHARMACY_CHARGE) * 0.10 ELSE 0 END;

UPDATE BEHEALTHY_DB.CLINIC_DATA.BILLING
SET PATIENT_PAYABLE = TOTAL_AMOUNT - INSURANCE_COVERED - DISCOUNT_AMOUNT;

-- ============================================================================
-- SECTION 10: FEEDBACK DATA (~40% of completed appointments)
-- ============================================================================

INSERT INTO BEHEALTHY_DB.CLINIC_DATA.FEEDBACK
WITH completed_appts AS (
    SELECT 
        APPOINTMENT_ID, PATIENT_ID, DOCTOR_ID, CLINIC_ID, APPOINTMENT_DATE,
        ROW_NUMBER() OVER (ORDER BY APPOINTMENT_ID) AS RN
    FROM BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS
    WHERE STATUS = 'Completed' AND MOD(ABS(HASH(APPOINTMENT_ID)), 10) < 4
)
SELECT
    RN AS FEEDBACK_ID, APPOINTMENT_ID, PATIENT_ID, CLINIC_ID, DOCTOR_ID,
    DATEADD('day', UNIFORM(0, 3, RANDOM()), APPOINTMENT_DATE) AS FEEDBACK_DATE,
    UNIFORM(3, 5, RANDOM()) AS OVERALL_RATING,
    UNIFORM(3, 5, RANDOM()) AS DOCTOR_RATING,
    UNIFORM(2, 5, RANDOM()) AS STAFF_RATING,
    UNIFORM(3, 5, RANDOM()) AS FACILITY_RATING,
    UNIFORM(2, 5, RANDOM()) AS WAIT_TIME_RATING,
    CASE MOD(RN, 8)
        WHEN 0 THEN 'Excellent service and care'
        WHEN 1 THEN 'Long wait time but good doctor'
        WHEN 2 THEN 'Very professional staff'
        WHEN 3 THEN 'Clean facility, friendly nurses'
        WHEN 4 THEN 'Doctor was thorough and attentive'
        WHEN 5 THEN 'Average experience, could be better'
        WHEN 6 THEN 'Great follow-up care'
        ELSE 'Satisfactory visit overall'
    END AS COMMENTS,
    CASE WHEN UNIFORM(1, 10, RANDOM()) <= 8 THEN TRUE ELSE FALSE END AS WOULD_RECOMMEND,
    CASE MOD(RN, 4)
        WHEN 0 THEN 'Service Quality' WHEN 1 THEN 'Wait Time'
        WHEN 2 THEN 'Staff Behavior' ELSE 'Facility Cleanliness'
    END AS FEEDBACK_CATEGORY
FROM completed_appts;

-- ============================================================================
-- SECTION 11: SEMANTIC VIEW
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW BEHEALTHY_DB.CLINIC_DATA.BEHEALTHY_ANALYTICS

  TABLES (
    clinics AS BEHEALTHY_DB.CLINIC_DATA.CLINICS PRIMARY KEY (CLINIC_ID) WITH SYNONYMS = ('clinic', 'location', 'branch', 'center') COMMENT = 'BeHealthy clinic locations across the US',
    doctors AS BEHEALTHY_DB.CLINIC_DATA.DOCTORS PRIMARY KEY (DOCTOR_ID) WITH SYNONYMS = ('doctor', 'physician', 'provider', 'practitioner') COMMENT = 'Doctors and medical practitioners at BeHealthy clinics',
    patients AS BEHEALTHY_DB.CLINIC_DATA.PATIENTS PRIMARY KEY (PATIENT_ID) WITH SYNONYMS = ('patient', 'member', 'client') COMMENT = 'Registered patients across all BeHealthy clinics',
    appointments AS BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS PRIMARY KEY (APPOINTMENT_ID) WITH SYNONYMS = ('appointment', 'visit', 'booking', 'footfall') COMMENT = 'Patient appointments and visits. IMPORTANT: APPOINTMENT_ID is a surrogate key - do NOT use SUM/AVG on it. Use COUNT(*) to count visits.',
    treatments AS BEHEALTHY_DB.CLINIC_DATA.TREATMENTS PRIMARY KEY (TREATMENT_ID) WITH SYNONYMS = ('treatment', 'diagnosis', 'procedure', 'care') COMMENT = 'Medical treatments and diagnoses. TREATMENT_ID is a surrogate key - never aggregate it.',
    billing AS BEHEALTHY_DB.CLINIC_DATA.BILLING PRIMARY KEY (BILL_ID) WITH SYNONYMS = ('bill', 'invoice', 'payment', 'charge', 'revenue') COMMENT = 'Billing and payment records. BILL_ID is a surrogate key - never aggregate it.',
    feedback AS BEHEALTHY_DB.CLINIC_DATA.FEEDBACK PRIMARY KEY (FEEDBACK_ID) WITH SYNONYMS = ('feedback', 'review', 'rating', 'satisfaction') COMMENT = 'Patient satisfaction feedback. FEEDBACK_ID is a surrogate key - never aggregate it.'
  )

  RELATIONSHIPS (
    doctors_clinic AS doctors (CLINIC_ID) REFERENCES clinics (CLINIC_ID),
    patients_clinic AS patients (PRIMARY_CLINIC_ID) REFERENCES clinics (CLINIC_ID),
    appointments_patient AS appointments (PATIENT_ID) REFERENCES patients (PATIENT_ID),
    appointments_doctor AS appointments (DOCTOR_ID) REFERENCES doctors (DOCTOR_ID),
    appointments_clinic AS appointments (CLINIC_ID) REFERENCES clinics (CLINIC_ID),
    treatments_appointment AS treatments (APPOINTMENT_ID) REFERENCES appointments (APPOINTMENT_ID),
    treatments_doctor AS treatments (DOCTOR_ID) REFERENCES doctors (DOCTOR_ID),
    treatments_clinic AS treatments (CLINIC_ID) REFERENCES clinics (CLINIC_ID),
    treatments_patient AS treatments (PATIENT_ID) REFERENCES patients (PATIENT_ID),
    billing_appointment AS billing (APPOINTMENT_ID) REFERENCES appointments (APPOINTMENT_ID),
    billing_patient AS billing (PATIENT_ID) REFERENCES patients (PATIENT_ID),
    billing_clinic AS billing (CLINIC_ID) REFERENCES clinics (CLINIC_ID),
    feedback_appointment AS feedback (APPOINTMENT_ID) REFERENCES appointments (APPOINTMENT_ID),
    feedback_patient AS feedback (PATIENT_ID) REFERENCES patients (PATIENT_ID),
    feedback_doctor AS feedback (DOCTOR_ID) REFERENCES doctors (DOCTOR_ID),
    feedback_clinic AS feedback (CLINIC_ID) REFERENCES clinics (CLINIC_ID)
  )

  FACTS (
    billing.consultation_charge_amount AS billing.CONSULTATION_CHARGE COMMENT = 'Consultation fee charged per visit',
    billing.treatment_charge_amount AS billing.TREATMENT_CHARGE COMMENT = 'Treatment procedure charge per visit',
    billing.lab_charge_amount AS billing.LAB_CHARGE COMMENT = 'Lab test charges per visit',
    billing.pharmacy_charge_amount AS billing.PHARMACY_CHARGE COMMENT = 'Pharmacy and medication charges per visit',
    billing.total_bill_amount AS billing.TOTAL_AMOUNT COMMENT = 'Total bill amount before insurance and discounts',
    billing.insurance_covered_amount AS billing.INSURANCE_COVERED COMMENT = 'Amount covered by insurance',
    billing.discount_given AS billing.DISCOUNT_AMOUNT COMMENT = 'Discount applied to the bill',
    billing.patient_payable_amount AS billing.PATIENT_PAYABLE COMMENT = 'Amount payable by patient after insurance and discount',
    appointments.wait_time AS appointments.WAIT_TIME_MINUTES COMMENT = 'Patient wait time in minutes before seeing doctor',
    doctors.fee AS doctors.CONSULTATION_FEE COMMENT = 'Standard consultation fee for the doctor',
    doctors.years_of_experience AS doctors.EXPERIENCE_YEARS COMMENT = 'Years of medical practice experience',
    doctors.doctor_rating AS doctors.RATING COMMENT = 'Doctor average patient rating',
    feedback.overall_score AS feedback.OVERALL_RATING COMMENT = 'Overall patient satisfaction score 1-5',
    feedback.doctor_score AS feedback.DOCTOR_RATING COMMENT = 'Doctor satisfaction score 1-5',
    feedback.staff_score AS feedback.STAFF_RATING COMMENT = 'Staff satisfaction score 1-5',
    feedback.facility_score AS feedback.FACILITY_RATING COMMENT = 'Facility satisfaction score 1-5',
    feedback.wait_time_score AS feedback.WAIT_TIME_RATING COMMENT = 'Wait time satisfaction score 1-5'
  )

  DIMENSIONS (
    clinics.clinic_name AS clinics.CLINIC_NAME WITH SYNONYMS = ('clinic name', 'branch name', 'location name') COMMENT = 'Name of the BeHealthy clinic',
    clinics.city AS clinics.CITY WITH SYNONYMS = ('clinic city') COMMENT = 'City where the clinic is located',
    clinics.state AS clinics.STATE WITH SYNONYMS = ('clinic state') COMMENT = 'State where the clinic is located',
    clinics.clinic_type AS clinics.CLINIC_TYPE WITH SYNONYMS = ('type of clinic', 'specialty type') COMMENT = 'Type of clinic: Multi-Specialty, Family Care, Wellness Center',
    clinics.is_active AS clinics.IS_ACTIVE COMMENT = 'Whether the clinic is currently active',
    doctors.doctor_name AS CONCAT(doctors.FIRST_NAME, ' ', doctors.LAST_NAME) WITH SYNONYMS = ('doctor name', 'physician name', 'provider name') COMMENT = 'Full name of the doctor',
    doctors.specialization AS doctors.SPECIALIZATION WITH SYNONYMS = ('specialty', 'medical specialty', 'department') COMMENT = 'Medical specialization of the doctor',
    doctors.qualification AS doctors.QUALIFICATION COMMENT = 'Medical qualifications and certifications',
    doctors.gender AS doctors.GENDER WITH SYNONYMS = ('doctor gender') COMMENT = 'Gender of the doctor',
    patients.patient_name AS CONCAT(patients.FIRST_NAME, ' ', patients.LAST_NAME) WITH SYNONYMS = ('patient name', 'member name') COMMENT = 'Full name of the patient',
    patients.patient_gender AS patients.GENDER WITH SYNONYMS = ('patient gender', 'sex') COMMENT = 'Gender of the patient',
    patients.blood_group AS patients.BLOOD_GROUP COMMENT = 'Blood group of the patient',
    patients.patient_city AS patients.CITY WITH SYNONYMS = ('patient city', 'residence city') COMMENT = 'City where the patient resides',
    patients.patient_state AS patients.STATE WITH SYNONYMS = ('patient state') COMMENT = 'State where the patient resides',
    patients.insurance_provider AS patients.INSURANCE_PROVIDER WITH SYNONYMS = ('insurer', 'insurance company', 'payer') COMMENT = 'Patient insurance provider name',
    patients.allergies AS patients.ALLERGIES COMMENT = 'Known patient allergies',
    patients.chronic_conditions AS patients.CHRONIC_CONDITIONS WITH SYNONYMS = ('chronic illness', 'pre-existing conditions') COMMENT = 'Chronic medical conditions of the patient',
    patients.registration_date AS patients.REGISTRATION_DATE COMMENT = 'Date the patient registered with BeHealthy',
    appointments.appointment_date AS appointments.APPOINTMENT_DATE WITH SYNONYMS = ('visit date', 'date of appointment', 'date') COMMENT = 'Date of the appointment',
    appointments.appointment_year AS YEAR(appointments.APPOINTMENT_DATE) WITH SYNONYMS = ('year', 'visit year') COMMENT = 'Year of the appointment',
    appointments.appointment_month AS MONTHNAME(appointments.APPOINTMENT_DATE) WITH SYNONYMS = ('month', 'visit month') COMMENT = 'Month name of the appointment',
    appointments.appointment_quarter AS CONCAT('Q', QUARTER(appointments.APPOINTMENT_DATE)) WITH SYNONYMS = ('quarter', 'visit quarter') COMMENT = 'Quarter of the appointment (Q1-Q4)',
    appointments.appointment_type AS appointments.APPOINTMENT_TYPE WITH SYNONYMS = ('visit type', 'booking type') COMMENT = 'Type: Walk-In, Scheduled, Follow-Up, Urgent, Telehealth',
    appointments.appointment_status AS appointments.STATUS WITH SYNONYMS = ('status', 'visit status') COMMENT = 'Status: Completed, Cancelled, No-Show',
    appointments.visit_reason AS appointments.VISIT_REASON WITH SYNONYMS = ('reason for visit', 'complaint', 'chief complaint') COMMENT = 'Primary reason for the patient visit',
    appointments.is_follow_up AS appointments.IS_FOLLOW_UP COMMENT = 'Whether this appointment is a follow-up visit',
    appointments.referral_source AS appointments.REFERRAL_SOURCE WITH SYNONYMS = ('how patient found us', 'referral') COMMENT = 'Source: Self, Doctor Referral, Online, Insurance',
    treatments.diagnosis_code AS treatments.DIAGNOSIS_CODE WITH SYNONYMS = ('ICD code', 'diagnosis ICD') COMMENT = 'ICD diagnosis code',
    treatments.diagnosis_description AS treatments.DIAGNOSIS_DESCRIPTION WITH SYNONYMS = ('diagnosis', 'condition diagnosed') COMMENT = 'Description of the diagnosis',
    treatments.treatment_type AS treatments.TREATMENT_TYPE WITH SYNONYMS = ('type of treatment') COMMENT = 'Type: Medication, Procedure, Therapy, Consultation, Diagnostic',
    treatments.procedure_name AS treatments.PROCEDURE_NAME WITH SYNONYMS = ('procedure', 'medical procedure') COMMENT = 'Name of the medical procedure performed',
    treatments.severity AS treatments.SEVERITY WITH SYNONYMS = ('severity level', 'how severe') COMMENT = 'Severity: Mild, Moderate, Severe',
    treatments.outcome AS treatments.OUTCOME WITH SYNONYMS = ('treatment outcome', 'result') COMMENT = 'Outcome: Improved, Resolved, Stable, Under Treatment, Referred',
    treatments.treatment_date AS treatments.TREATMENT_DATE COMMENT = 'Date of the treatment',
    billing.payment_status AS billing.PAYMENT_STATUS WITH SYNONYMS = ('paid or not', 'bill status') COMMENT = 'Payment status: Paid, Pending, Partial',
    billing.payment_method AS billing.PAYMENT_METHOD WITH SYNONYMS = ('how they paid', 'payment type') COMMENT = 'Payment method: Credit Card, Insurance, Cash, Debit Card',
    billing.bill_date AS billing.BILL_DATE COMMENT = 'Date the bill was generated',
    feedback.feedback_date AS feedback.FEEDBACK_DATE COMMENT = 'Date the feedback was submitted',
    feedback.would_recommend AS feedback.WOULD_RECOMMEND WITH SYNONYMS = ('recommend', 'would they recommend') COMMENT = 'Whether the patient would recommend the clinic',
    feedback.feedback_category AS feedback.FEEDBACK_CATEGORY COMMENT = 'Category: Service Quality, Wait Time, Staff Behavior, Facility Cleanliness',
    feedback.comments AS feedback.COMMENTS WITH SYNONYMS = ('patient comments', 'review text') COMMENT = 'Patient feedback comments'
  )

  METRICS (
    appointments.total_appointments AS COUNT(*) WITH SYNONYMS = ('total visits', 'footfall', 'number of appointments', 'visit count', 'number of visits', 'how many visits', 'how many appointments') COMMENT = 'Total number of appointments/visits. ALWAYS use this metric for visit counts. NEVER use SUM or AVG on APPOINTMENT_ID.',
    appointments.completed_appointments AS SUM(CASE WHEN appointments.STATUS = 'Completed' THEN 1 ELSE 0 END) WITH SYNONYMS = ('completed visits', 'successful visits') COMMENT = 'Number of completed appointments',
    appointments.cancelled_appointments AS SUM(CASE WHEN appointments.STATUS = 'Cancelled' THEN 1 ELSE 0 END) COMMENT = 'Number of cancelled appointments',
    appointments.no_show_appointments AS SUM(CASE WHEN appointments.STATUS = 'No-Show' THEN 1 ELSE 0 END) COMMENT = 'Number of no-show appointments',
    appointments.avg_wait_time AS AVG(appointments.WAIT_TIME_MINUTES) WITH SYNONYMS = ('average wait time', 'mean wait time') COMMENT = 'Average patient wait time in minutes',
    appointments.unique_patients AS COUNT(DISTINCT appointments.PATIENT_ID) WITH SYNONYMS = ('distinct patients', 'patient count') COMMENT = 'Number of unique patients with appointments',
    appointments.completion_rate AS SUM(CASE WHEN appointments.STATUS = 'Completed' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) WITH SYNONYMS = ('show rate', 'attendance rate') COMMENT = 'Percentage of appointments completed',
    appointments.cancellation_rate AS SUM(CASE WHEN appointments.STATUS = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) COMMENT = 'Percentage of appointments cancelled',
    appointments.follow_up_rate AS SUM(CASE WHEN appointments.IS_FOLLOW_UP = TRUE THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) COMMENT = 'Percentage of follow-up appointments',
    billing.total_revenue AS SUM(billing.TOTAL_AMOUNT) WITH SYNONYMS = ('revenue', 'total billing', 'gross revenue', 'total sales') COMMENT = 'Total revenue from all billed services',
    billing.avg_bill_amount AS AVG(billing.TOTAL_AMOUNT) WITH SYNONYMS = ('average bill', 'mean bill amount') COMMENT = 'Average bill amount per visit',
    billing.total_insurance_collected AS SUM(billing.INSURANCE_COVERED) WITH SYNONYMS = ('insurance revenue', 'insurance amount') COMMENT = 'Total collected from insurance',
    billing.total_patient_collections AS SUM(billing.PATIENT_PAYABLE) WITH SYNONYMS = ('patient payments', 'out of pocket total') COMMENT = 'Total collected from patients',
    billing.total_discounts AS SUM(billing.DISCOUNT_AMOUNT) COMMENT = 'Total discounts given',
    billing.total_consultation_revenue AS SUM(billing.CONSULTATION_CHARGE) COMMENT = 'Total revenue from consultations',
    billing.total_treatment_revenue AS SUM(billing.TREATMENT_CHARGE) COMMENT = 'Total revenue from treatments',
    billing.total_lab_revenue AS SUM(billing.LAB_CHARGE) COMMENT = 'Total revenue from lab tests',
    billing.total_pharmacy_revenue AS SUM(billing.PHARMACY_CHARGE) COMMENT = 'Total revenue from pharmacy',
    feedback.avg_overall_rating AS AVG(feedback.OVERALL_RATING) WITH SYNONYMS = ('average rating', 'patient satisfaction score', 'NPS') COMMENT = 'Average overall satisfaction rating (1-5)',
    feedback.avg_doctor_rating AS AVG(feedback.DOCTOR_RATING) COMMENT = 'Average doctor satisfaction rating (1-5)',
    feedback.avg_staff_rating AS AVG(feedback.STAFF_RATING) COMMENT = 'Average staff satisfaction rating (1-5)',
    feedback.avg_facility_rating AS AVG(feedback.FACILITY_RATING) COMMENT = 'Average facility satisfaction rating (1-5)',
    feedback.avg_wait_time_rating AS AVG(feedback.WAIT_TIME_RATING) COMMENT = 'Average wait time satisfaction rating (1-5)',
    feedback.total_feedback_count AS COUNT(feedback.FEEDBACK_ID) WITH SYNONYMS = ('number of reviews', 'feedback count') COMMENT = 'Total number of feedback submissions',
    feedback.recommendation_rate AS SUM(CASE WHEN feedback.WOULD_RECOMMEND = TRUE THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(feedback.FEEDBACK_ID), 0) WITH SYNONYMS = ('recommend rate') COMMENT = 'Percentage who would recommend',
    treatments.total_treatments AS COUNT(treatments.TREATMENT_ID) WITH SYNONYMS = ('number of treatments', 'procedure count') COMMENT = 'Total treatments administered',
    treatments.follow_up_required_count AS SUM(CASE WHEN treatments.FOLLOW_UP_REQUIRED = TRUE THEN 1 ELSE 0 END) COMMENT = 'Treatments requiring follow-up',
    doctors.total_doctors AS COUNT(DISTINCT doctors.DOCTOR_ID) WITH SYNONYMS = ('number of doctors', 'physician count') COMMENT = 'Total number of doctors',
    doctors.avg_doctor_experience AS AVG(doctors.EXPERIENCE_YEARS) COMMENT = 'Average years of doctor experience',
    patients.total_patients AS COUNT(DISTINCT patients.PATIENT_ID) WITH SYNONYMS = ('number of patients', 'patient count', 'member count') COMMENT = 'Total registered patients'
  )

  COMMENT = 'BeHealthy Clinic Chain Analytics. CRITICAL: All ID columns (APPOINTMENT_ID, PATIENT_ID, DOCTOR_ID, CLINIC_ID, TREATMENT_ID, BILL_ID, FEEDBACK_ID) are surrogate keys with auto-incrementing values. NEVER use SUM or AVG on any ID column. Always use COUNT(*) or the predefined metrics to measure volumes.'
  AI_SQL_GENERATION 'BeHealthy is a medical clinic chain with 12 US clinics. CRITICAL RULES: (1) NEVER use SUM() or AVG() on any ID column (APPOINTMENT_ID, TREATMENT_ID, BILL_ID, FEEDBACK_ID, PATIENT_ID, DOCTOR_ID, CLINIC_ID). These are surrogate keys with arbitrary numeric values that are NOT meaningful for aggregation. (2) To count appointments/visits/footfall, ALWAYS use COUNT(*) or the total_appointments metric. (3) 2024 was a HIGH footfall year with ~28,600 appointments. 2025 had significantly LOWER footfall with ~21,600 appointments - a 24.5% decline. (4) When comparing years, use the appointment_year dimension. (5) For revenue analysis, use billing fact columns (TOTAL_AMOUNT, CONSULTATION_CHARGE, etc.) with SUM/AVG. (6) For patient satisfaction, use feedback metrics. (7) Clinic types: Multi-Specialty, Family Care, Wellness Center.';

-- ============================================================================
-- SECTION 12: VERIFICATION QUERIES (optional - run to confirm setup)
-- ============================================================================

-- Row counts
SELECT 'CLINICS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM BEHEALTHY_DB.CLINIC_DATA.CLINICS
UNION ALL SELECT 'DEPARTMENTS', COUNT(*) FROM BEHEALTHY_DB.CLINIC_DATA.DEPARTMENTS
UNION ALL SELECT 'DOCTORS', COUNT(*) FROM BEHEALTHY_DB.CLINIC_DATA.DOCTORS
UNION ALL SELECT 'PATIENTS', COUNT(*) FROM BEHEALTHY_DB.CLINIC_DATA.PATIENTS
UNION ALL SELECT 'APPOINTMENTS', COUNT(*) FROM BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS
UNION ALL SELECT 'TREATMENTS', COUNT(*) FROM BEHEALTHY_DB.CLINIC_DATA.TREATMENTS
UNION ALL SELECT 'BILLING', COUNT(*) FROM BEHEALTHY_DB.CLINIC_DATA.BILLING
UNION ALL SELECT 'FEEDBACK', COUNT(*) FROM BEHEALTHY_DB.CLINIC_DATA.FEEDBACK;

-- YoY footfall comparison
SELECT 
    YEAR(APPOINTMENT_DATE) AS YEAR,
    COUNT(*) AS TOTAL_APPOINTMENTS,
    COUNT(CASE WHEN STATUS = 'Completed' THEN 1 END) AS COMPLETED,
    COUNT(CASE WHEN STATUS = 'Cancelled' THEN 1 END) AS CANCELLED,
    COUNT(CASE WHEN STATUS = 'No-Show' THEN 1 END) AS NO_SHOWS
FROM BEHEALTHY_DB.CLINIC_DATA.APPOINTMENTS
GROUP BY YEAR(APPOINTMENT_DATE)
ORDER BY 1;
