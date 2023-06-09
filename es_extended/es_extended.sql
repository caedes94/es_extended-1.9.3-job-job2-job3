CREATE DATABASE IF NOT EXISTS `es_extended`;


ALTER DATABASE `es_extended`
	DEFAULT CHARACTER SET UTF8MB4;
	
ALTER DATABASE `es_extended`
	DEFAULT COLLATE UTF8MB4_UNICODE_CI;

CREATE TABLE `users` (
	`identifier` VARCHAR(60) NOT NULL,
	`accounts` LONGTEXT NULL DEFAULT NULL,
	`group` VARCHAR(50) NULL DEFAULT 'user',
	`inventory` LONGTEXT NULL DEFAULT NULL,
	`job` VARCHAR(20) NULL DEFAULT 'unemployed',
	`job_grade` INT NULL DEFAULT 0,
	`loadout` LONGTEXT NULL DEFAULT NULL,
	`position` longtext NULL DEFAULT NULL,

	PRIMARY KEY (`identifier`)
) ENGINE=InnoDB;


CREATE TABLE `items` (
	`name` VARCHAR(50) NOT NULL,
	`label` VARCHAR(50) NOT NULL,
	`weight` INT NOT NULL DEFAULT 1,
	`rare` TINYINT NOT NULL DEFAULT 0,
	`can_remove` TINYINT NOT NULL DEFAULT 1,

	PRIMARY KEY (`name`)
) ENGINE=InnoDB;


CREATE TABLE `job_grades` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`job_name` VARCHAR(50) DEFAULT NULL,
	`grade` INT NOT NULL,
	`name` VARCHAR(50) NOT NULL,
	`label` VARCHAR(50) NOT NULL,
	`salary` INT NOT NULL,
	`skin_male` LONGTEXT NOT NULL,
	`skin_female` LONGTEXT NOT NULL,

	PRIMARY KEY (`id`)
) ENGINE=InnoDB;



CREATE TABLE `jobs` (
	`name` VARCHAR(50) NOT NULL,
	`label` VARCHAR(50) DEFAULT NULL,

	PRIMARY KEY (`name`)
) ENGINE=InnoDB;


ALTER TABLE `users` ADD IF NOT EXISTS `job` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'unemployed';
ALTER TABLE `users` ADD IF NOT EXISTS `job_grade` int(11) DEFAULT 0;
INSERT INTO `jobs` VALUES ('unemployed','Unemployed');
INSERT INTO `job_grades` VALUES (1,'unemployed',0,'unemployed','Unemployed',200,'{}','{}');



ALTER TABLE `users` ADD IF NOT EXISTS `job2` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'unemployed';
ALTER TABLE `users` ADD IF NOT EXISTS `job2_grade` int(11) DEFAULT 0;
INSERT INTO `jobs` VALUES ('unemployed2','Unemployed2');
INSERT INTO `job_grades` VALUES (1,'unemployed2',0,'unemployed2','Unemployed',200,'{}','{}');


ALTER TABLE `users` ADD IF NOT EXISTS `job3` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'unemployed';
ALTER TABLE `users` ADD IF NOT EXISTS `job3_grade` int(11) DEFAULT 0;
INSERT INTO `job_grades` VALUES (1,'unemployed3',0,'unemployed3','Unemployed',200,'{}','{}');
INSERT INTO `jobs` VALUES ('unemployed3','Unemployed');