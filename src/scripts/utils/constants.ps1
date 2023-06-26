﻿$VULNS_PATH = '.\scripts\vulns\'
$UTILS_PATH = '.\scripts\utils\'
$CONFIG_PATH = ".\AD_network.json"

$BAD_PASSWORDS= @('123123', 'baseball', 'abc123', 'football', 'monkey', 'letmein', '696969',
                  'shadow', 'master', '666666', 'qwertyuiop', '123321', 'mustang', '1234567890',
                  'michael', '654321', 'pussy', 'superman', '1qaz2wsx', '7777777', 'fuckyou',
                  '121212', '000000', 'qazwsx', '123qwe', 'killer', 'trustno1', 'jordan',
                  'jennifer', 'zxcvbnm', 'asdfgh', 'hunter', 'buster', 'soccer', 'harley',
                  'batman', 'andrew', 'tigger', 'sunshine', 'iloveyou', 'fuckme', '2000', 'charlie',
                  'robert', 'thomas', 'hockey', 'ranger', 'daniel', 'starwars', 'klaster', '112233',
                  'george', 'asshole', 'computer', 'michelle', 'jessica', 'pepper', '1111', 'zxcvbn',
                  '555555', '11111111', '131313', 'freedom', '777777', 'pass', 'fuck', 'maggie', '159753',
                  'aaaaaa', 'ginger', 'princess', 'joshua', 'cheese', 'amanda', 'summer', 'love', 'ashley',
                  '6969', 'nicole', 'chelsea', 'biteme', 'matthew', 'access', 'yankees', '987654321', 'dallas',
                  'austin', 'thunder', 'taylor', 'matrix', 'william', 'corvette', 'hello', 'martin', 'heather',
                  'secret', 'fucker', 'merlin', 'diamond', '1234qwer', 'gfhjkm', 'hammer', 'silver', '222222',
                  '88888888', 'anthony', 'justin', 'test', 'bailey', 'q1w2e3r4t5', 'patrick', 'internet', 'scooter',
                  'orange', '11111', 'golfer', 'cookie', 'richard', 'samantha', 'bigdog', 'guitar', 'jackson', 'whatever',
                  'mickey', 'chicken', 'sparky', 'snoopy', 'maverick', 'phoenix', 'camaro', 'sexy', 'peanut', 'morgan', 'welcome', 'falcon', 'cowboy', 'ferrari', 'samsung', 'andrea', 'smokey', 'steelers', 'joseph', 'mercedes', 'dakota', 'arsenal', 'eagles', 'melissa', 'boomer', 'booboo', 'spider', 'nascar', 'monster', 'tigers', 'yellow', 'xxxxxx', '123123123', 'gateway', 'marina', 'diablo', 'bulldog', 'qwer1234', 'compaq', 'purple', 'hardcore', 'banana', 'junior', 'hannah', '123654', 'porsche', 'lakers', 'iceman', 'money', 'cowboys', '987654', 'london', 'tennis', '999999', 'ncc1701', 'coffee', 'scooby', '0000', 'miller', 'boston', 'q1w2e3r4', 'fuckoff', 'brandon', 'yamaha', 'chester', 'mother', 'forever', 'johnny', 'edward', '333333', 'oliver', 'redsox', 'player', 'nikita', 'knight', 'fender', 'barney', 'midnight', 'please', 'brandy', 'chicago', 'badboy', 'iwantu', 'slayer', 'rangers', 'charles', 'angel', 'flower', 'bigdaddy', 'rabbit', 'wizard', 'bigdick', 'jasper', 'enter', 'rachel', 'chris', 'steven', 'winner', 'adidas', 'victoria', 'natasha', '1q2w3e4r', 'jasmine', 'winter', 'prince', 'panties', 'marine', 'ghbdtn', 'fishing', 'cocacola', 'casper', 'james', '232323', 'raiders', '888888', 'marlboro', 'gandalf', 'asdfasdf', 'crystal', '87654321', '12344321', 'sexsex', 'golden', 'blowme', 'bigtits', '8675309', 'panther', 'lauren', 'angela', 'bitch', 'spanky', 'thx1138', 'angels', 'madison', 'winston', 'shannon', 'mike', 'toyota', 'blowjob', 'jordan23', 'canada', 'sophie', 'Password', 'apples', 'dick', 'tiger', 'razz', '123abc', 'pokemon', 'qazxsw', '55555', 'qwaszx', 'muffin', 'johnson', 'murphy', 'cooper', 'jonathan', 'liverpoo', 'david', 'danielle', '159357', 'jackie', '1990', '123456a', '789456', 'turtle', 'horny', 'abcd1234', 'scorpion', 'qazwsxedc', '101010', 'butter', 'carlos', 'password1', 'dennis', 'slipknot', 'qwerty123', 'booger', 'asdf', '1991', 'black', 'startrek', '12341234', 'cameron', 'newyork', 'rainbow', 'nathan', 'john', '1992', 'rocket', 'viking', 'redskins', 'butthead', 'asdfghjkl', '1212', 'sierra', 'peaches', 'gemini', 'doctor', 'wilson', 'sandra', 'helpme', 'qwertyui', 'victor', 'florida', 'dolphin', 'pookie', 'captain', 'tucker', 'blue', 'liverpool', 'theman', 'bandit', 'dolphins', 'maddog', 'packers', 'jaguar', 'lovers', 'nicholas', 'united', 'tiffany', 'maxwell', 'zzzzzz', 'nirvana', 'jeremy', 'suckit', 'stupid', 'porn', 'monica', 'elephant', 'giants', 'jackass', 'hotdog', 'rosebud', 'success', 'debbie', 'mountain', '444444', 'xxxxxxxx', 'warrior', '1q2w3e4r5t', 'q1w2e3', '123456q', 'albert', 'metallic', 'lucky', 'azerty', '7777', 'shithead', 'alex', 'bond007', 'alexis', '1111111', 'samson', '5150', 'willie', 'scorpio', 'bonnie', 'gators', 'benjamin', 'voodoo', 'driver', 'dexter', '2112', 'jason', 'calvin', 'freddy', '212121', 'creative', '12345a', 'sydney', 'rush2112', '1989', 'asdfghjk', 'red123', 'bubba', '4815162342', 'passw0rd', 'trouble', 'gunner', 'happy', 'fucking', 'gordon', 'legend', 'jessie', 'stella', 'qwert', 'eminem', 'arthur', 'apple', 'nissan', 'bullshit', 'bear', 'america', '1qazxsw2', 'nothing', 'parker', '4444', 'rebecca', 'qweqwe', 'garfield', '01012011', 'beavis', '69696969', 'jack', 'asdasd', 'december', '2222', '102030', '252525', '11223344', 'magic', 'apollo', 'skippy', '315475', 'girls', 'kitten', 'golf', 'copper', 'braves', 'shelby', 'godzilla', 'beaver', 'fred', 'tomcat', 'august', 'buddy', 'airborne', '1993', '1988', 'lifehack', 'qqqqqq', 'brooklyn', 'animal', 'platinum', 'phantom', 'online', 'xavier', 'darkness', 'blink182', 'power', 'fish', 'green', '789456123', 'voyager', 'police', 'travis', '12qwaszx', 'heaven', 'snowball', 'lover', 'abcdef', '00000', 'pakistan', '007007', 'walter', 'playboy', 'blazer', 'cricket', 'sniper', 'hooters', 'donkey', 'willow', 'loveme', 'saturn', 'therock', 'redwings');


$BAD_ACL = @('GenericAll','GenericWrite','WriteOwner','WriteDACL','Self','WriteProperty');
$SPNS = @('HOST/mssqlserver','DNS/httpserver','LDAP/exserver');

$GROUPS_AVAILABLE = @("marketing",
                      "sales",
                      "accounting",
                      "Office Admin",
                      "IT Admins",
                      "Executives",
                      "Senior management",
                      "Project management",
                      "Developers",
                      "Operations",
                      "Support",
                      "Finance",
                      "HumanResources",
                      "QA",
                      "HelpDesk",
                      "Architects",
                      "DBA",
                      "Auditors",
                      "Research",
                      "Backup");

$TASK_NAMES = @(
        "BackupTask",
        "CleanupTask",
        "DatabaseBackup",
        "MaintenanceTask",
        "ReportGeneration",
        "DataSyncTask",
        "EmailNotification",
        "SystemHealthCheck",
        "LogCleanup",
        "SecurityAudit",
        "DataImportTask",
        "PerformanceMonitoring",
        "DatabaseMaintenance",
        "BackupCleanup",
        "UpdateTask",
        "ScheduledReport",
        "ErrorLogging",
        "DiskCleanup",
        "DataValidation",
        "DatabaseMigration"
    )