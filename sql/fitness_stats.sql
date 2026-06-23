CREATE TABLE IF NOT EXISTS `fitness_stats` (
	`identifier` VARCHAR(60) NOT NULL,
	`stat` VARCHAR(32) NOT NULL,
	`level` INT NOT NULL DEFAULT 1,
	`xp` INT NOT NULL DEFAULT 0,
	PRIMARY KEY (`identifier`, `stat`),
	CONSTRAINT `fk_fitness_stats_users_identifier`
		FOREIGN KEY (`identifier`)
		REFERENCES `users` (`identifier`)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;