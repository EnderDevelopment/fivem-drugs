-- ESX items for the drugs system
INSERT INTO `items` (`name`, `label`, `limit`, `rare`, `can_remove`) VALUES
    ('weed',        'Weed',        10, 0, 1),
    ('cocaine',     'Cocaine',     10, 0, 1),
    ('meth',        'Meth',        10, 0, 1),
    ('lsd',         'LSD',         10, 0, 1),
    ('heroin',      'Heroin',      10, 0, 1),
    ('mushrooms',   'Mushrooms',   10, 0, 1),
    ('ecstasy',     'Ecstasy',     10, 0, 1),
    ('oxycodone',   'Oxycodone',   10, 0, 1),
    ('adderall',    'Adderall',    10, 0, 1),
    ('ketamine',    'Ketamine',    10, 0, 1);

-- QBCore items (use this instead if you run QBCore)
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('weed',        'Weed',        100, 0, 1),
    ('cocaine',     'Cocaine',     100, 0, 1),
    ('meth',        'Meth',        100, 0, 1),
    ('lsd',         'LSD',         100, 0, 1),
    ('heroin',      'Heroin',      100, 0, 1),
    ('mushrooms',   'Mushrooms',   100, 0, 1),
    ('ecstasy',     'Ecstasy',     100, 0, 1),
    ('oxycodone',   'Oxycodone',   100, 0, 1),
    ('adderall',    'Adderall',    100, 0, 1),
    ('ketamine',    'Ketamine',    100, 0, 1);
